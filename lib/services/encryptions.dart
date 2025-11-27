import 'dart:convert';
import 'dart:typed_data';
import 'package:ebv/models/chat_model.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/asymmetric/api.dart' as pc;

class EncryptServices {
  // Helper to parse public key PEM
  static pc.RSAPublicKey parsePublicKey(String pemString) {
    List<int> publicKeyDER;
    try {
      // Try reading as PEM first
      final parser = encrypt.RSAKeyParser();
      final key = parser.parse(pemString);
      return key as pc.RSAPublicKey;
    } catch (e) {
      // If it fails, it might be a raw base64 string (SPKI) or just missing headers
      // Try wrapping in PEM headers if missing
      if (!pemString.contains('-----BEGIN PUBLIC KEY-----')) {
        String formattedPem =
            '-----BEGIN PUBLIC KEY-----\n$pemString\n-----END PUBLIC KEY-----';
        try {
          final parser = encrypt.RSAKeyParser();
          final key = parser.parse(formattedPem);
          return key as pc.RSAPublicKey;
        } catch (_) {
          // If that fails too, maybe it is just raw DER bytes in base64?
          // But RSAKeyParser expects PEM.
          // Let's assume standard PEM or Base64 of PEM body.
          rethrow;
        }
      }
      rethrow;
    }
  }

  // Helper to parse private key PEM
  static pc.RSAPrivateKey parsePrivateKey(String pemString) {
    String pemKey = pemString.trim();
    if (!pemKey.startsWith('-----BEGIN')) {
      pemKey =
          '-----BEGIN PRIVATE KEY-----\n$pemKey\n-----END PRIVATE KEY-----';
    }
    final parser = encrypt.RSAKeyParser();
    final key = parser.parse(pemKey);
    return key as pc.RSAPrivateKey;
  }

  static Future<EncryptedMessage> encryptMessage({
    required var content,
    required var publicKeyRef,
    required var receiverPubKeyRef,
    required var senderId,
    required var receiverId,
  }) async {
    try {
      // 1. Generate AES-GCM Key (256 bits = 32 bytes)
      final aesKey = encrypt.Key.fromSecureRandom(32);
      final aesKeyBytes = aesKey.bytes;
      final aesStr = base64.encode(aesKeyBytes);

      // 2. Import Sender Public Key & Encrypt AES Key for Sender
      final senderPubKey = parsePublicKey(publicKeyRef);
      final senderEncrypter = encrypt.Encrypter(encrypt.RSA(
        publicKey: senderPubKey,
        encoding: encrypt.RSAEncoding.OAEP,
        digest: encrypt.RSADigest.SHA256,
      ));
      final encForSender = senderEncrypter.encrypt(aesStr);

      // 3. Import Receiver Public Key & Encrypt AES Key for Receiver
      // Note: JS code checks sessionStorage if receiverPubKeyRef is null,
      // here we assume it's passed or we handle it before calling this.
      if (receiverPubKeyRef.isEmpty) {
        throw Exception('No receiver public key available');
      }
      final receiverPubKey = parsePublicKey(receiverPubKeyRef);
      final receiverEncrypter = encrypt.Encrypter(encrypt.RSA(
        publicKey: receiverPubKey,
        encoding: encrypt.RSAEncoding.OAEP,
        digest: encrypt.RSADigest.SHA256,
      ));
      final encForReceiver = receiverEncrypter.encrypt(aesStr);

      // 4. Encrypt Message Content with AES-GCM
      final iv = encrypt.IV.fromSecureRandom(12); // 12 bytes IV for GCM
      final aesEncrypter = encrypt.Encrypter(
        encrypt.AES(aesKey, mode: encrypt.AESMode.gcm),
      );
      final cipher = aesEncrypter.encrypt(content, iv: iv);

      return EncryptedMessage(
        senderId: senderId,
        receiverId: receiverId,
        iv: iv.base64,
        encryptedAesKeyForSender: encForSender.base64,
        encryptedAesKeyForReceiver: encForReceiver.base64,
        encryptedText: cipher.base64,
      );
    } catch (e) {
      print('Encrypt error: $e');
      rethrow;
    }
  }

  static Future<GroupEncryptedMessage> encryptMessageGroup({
    required String content,
    required String publicKeyRef,
    required List<GroupPublicKey> groupReceivers,
    required String senderId,
    required String groupId,
  }) async {
    try {
      // Step 1: Generate AES-GCM key
      final aesKey = encrypt.Key.fromSecureRandom(32);
      final aesKeyBytes = aesKey.bytes;
      final aesStr = base64.encode(aesKeyBytes);

      // Step 2: Import sender's public key & Encrypt AES key for sender
      final senderPubKey = parsePublicKey(publicKeyRef);
      final senderEncrypter = encrypt.Encrypter(encrypt.RSA(
        publicKey: senderPubKey,
        encoding: encrypt.RSAEncoding.OAEP,
        digest: encrypt.RSADigest.SHA256,
      ));
      final encForSender = senderEncrypter.encrypt(aesStr);

      // Step 3 & 4: Encrypt AES key for each group member
      List<Map<String, String>> validReceivers = [];

      for (var receiver in groupReceivers) {
        if (receiver.publicKey.isEmpty) {
          print('No public key found for receiver ${receiver.userId}');
          continue;
        }

        try {
          final receiverPubKey = parsePublicKey(receiver.publicKey);
          final receiverEncrypter = encrypt.Encrypter(encrypt.RSA(
            publicKey: receiverPubKey,
            encoding: encrypt.RSAEncoding.OAEP,
            digest: encrypt.RSADigest.SHA256,
          ));
          final encForReceiver = receiverEncrypter.encrypt(aesStr);

          validReceivers.add({
            'receiverId': receiver.userId,
            'encryptedAesKey': encForReceiver.base64,
          });
        } catch (e) {
          print('Error encrypting for receiver ${receiver.userId}: $e');
        }
      }

      // Step 6: Encrypt the actual message with AES-GCM
      final iv = encrypt.IV.fromSecureRandom(12);
      final aesEncrypter = encrypt.Encrypter(
        encrypt.AES(aesKey, mode: encrypt.AESMode.gcm),
      );
      final cipher = aesEncrypter.encrypt(content, iv: iv);

      // Step 7: Return encrypted payload
      return GroupEncryptedMessage(
        encryptedText: cipher.base64,
        iv: iv.base64,
        encryptedAesKeyForSender: encForSender.base64,
        groupReceivers: validReceivers,
        groupId: groupId,
      );
    } catch (e) {
      print('Group Encrypt error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> decryptMessageGroup({
    required Message messageData,
    required var privateKeyRef,
    required var currentUserId,
  }) async {
    try {
      String? encKeyB64;

      // Find the encrypted key for the current user
      if (messageData.groupReceivers != null) {
        final receiverKeyObj = messageData.groupReceivers!.firstWhere(
          (keyObj) =>
              keyObj['receiverId'].toString() == currentUserId.toString(),
          orElse: () => {},
        );
        if (receiverKeyObj.isNotEmpty) {
          encKeyB64 = receiverKeyObj['encryptedAesKey'];
        }
      }

      // Also check if I am the sender, then I should use encryptedAesKeyForSender
      if (encKeyB64 == null &&
          messageData.senderID.toString() == currentUserId.toString()) {
        encKeyB64 = messageData.encryptedAesKeyForSender;
      }

      if (encKeyB64 == null) {
        print('No encrypted AES key found for this receiver in group chat.');
        return {'text': 'Unable to display the message...'};
      }

      // Parse Private Key
      final privateKey = parsePrivateKey(privateKeyRef);

      // Decrypt AES Key using RSA-OAEP
      final rsaEncrypter = encrypt.Encrypter(encrypt.RSA(
        privateKey: privateKey,
        encoding: encrypt.RSAEncoding.OAEP,
        digest: encrypt.RSADigest.SHA256,
      ));

      final encryptedAesKey = encrypt.Encrypted.fromBase64(encKeyB64);
      final decryptedAesKeyString = rsaEncrypter.decrypt(encryptedAesKey);

      // The decrypted string is Base64 of the raw AES key bytes
      final aesKeyBytes = base64.decode(decryptedAesKeyString);
      final aesKey = encrypt.Key(aesKeyBytes);

      // Decrypt Content
      final iv = encrypt.IV.fromBase64(messageData.iv!);
      final aesEncrypter = encrypt.Encrypter(
        encrypt.AES(aesKey, mode: encrypt.AESMode.gcm),
      );

      final encryptedContent =
          encrypt.Encrypted.fromBase64(messageData.content);
      final decryptedContent = aesEncrypter.decrypt(encryptedContent, iv: iv);

      return {'text': decryptedContent};
    } catch (e) {
      print('Group Decrypt error: $e');
      return {'text': 'Unable to display the message...'};
    }
  }

  static Future<Map<String, dynamic>> decryptMessage(
    Message m,
    var privateKeyRef,
    var senderId,
  ) async {
    try {
      final isSender = m.senderID == senderId;
      final encKeyB64 =
          isSender ? m.encryptedAesKeyForSender : m.encryptedAesKeyForReceiver;

      if (encKeyB64 == null || encKeyB64.isEmpty) {
        return {'text': 'Unable to display the message...'};
      }

      // 1. Parse Private Key
      final privateKey = parsePrivateKey(privateKeyRef);

      // 2. Decrypt AES Key using RSA-OAEP (SHA-256)
      final rsaEncrypter = encrypt.Encrypter(encrypt.RSA(
        privateKey: privateKey,
        encoding: encrypt.RSAEncoding.OAEP,
        digest: encrypt.RSADigest.SHA256,
      ));

      final encryptedAesKey = encrypt.Encrypted.fromBase64(encKeyB64);
      final decryptedAesKeyString = rsaEncrypter.decrypt(encryptedAesKey);

      // The decrypted string is a Base64 string of the actual AES key bytes
      // JS: const aesRaw = Uint8Array.from(atob(aesKeyStr), (c) => c.charCodeAt(0));
      final aesKeyBytes = base64.decode(decryptedAesKeyString);

      // 3. Decrypt Message Content using AES-GCM
      final aesKey = encrypt.Key(aesKeyBytes);
      final iv = encrypt.IV.fromBase64(m.iv!);

      final aesEncrypter = encrypt.Encrypter(
        encrypt.AES(aesKey, mode: encrypt.AESMode.gcm),
      );

      final encryptedContent = encrypt.Encrypted.fromBase64(m.content);
      final decryptedContent = aesEncrypter.decrypt(encryptedContent, iv: iv);
      print("decryptedContent$decryptedContent");

      return {'text': decryptedContent};
    } catch (e) {
      print('Decrypt error: $e');
      return {'text': 'Unable to display the message...'};
    }
  }
}
