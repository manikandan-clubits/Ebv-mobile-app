// import 'dart:convert';
// import 'dart:typed_data';
// import 'dart:math';
// import 'package:cryptography/cryptography.dart';
// import 'package:rsa_oaep_dart/rsa_oaep_dart.dart';
//
// String base64EncodeU8(Uint8List data) => base64.encode(data);
// Uint8List base64DecodeToU8(String base64Str) => base64.decode(base64Str);
//
// Future<Map<String, dynamic>> encryptMessage(
//     String text,
//     RSAPublicKey senderPublicKey, // use RSA public key directly
//     RSAPublicKey receiverPublicKey,
//     String sender,
//     String receiver,
//     ) async {
//   final aesGcm = AesGcm.with256bits();
//   final secretKey = await aesGcm.newSecretKey();
//
//   final aesKeyBytes = await secretKey.extractBytes();
//   final aesKeyBase64 = base64EncodeU8(Uint8List.fromList(aesKeyBytes));
//
//   final rsaOaep = RSAOAEP(hash: SHA256Digest());
//
//   final encryptedKeyForSender = rsaOaep.encryptString(aesKeyBase64, senderPublicKey);
//   final encryptedKeyForReceiver = rsaOaep.encryptString(aesKeyBase64, receiverPublicKey);
//
//   // Generate nonce properly
//   final nonce = List<int>.generate(12, (_) => Random.secure().nextInt(256));
//   final secretBox = await aesGcm.encrypt(
//     utf8.encode(text),
//     secretKey: secretKey,
//     nonce: nonce,
//   );
//
//   return {
//     'sender': sender,
//     'receiver': receiver,
//     'iv': base64EncodeU8(Uint8List.fromList(nonce)),
//     'encryptedAesKeyForSender': base64EncodeU8(Uint8List.fromList(encryptedKeyForSender)),
//     'encryptedAesKeyForReceiver': base64EncodeU8(Uint8List.fromList(encryptedKeyForReceiver)),
//     'encryptedText': base64EncodeU8(secretBox.cipherText as Uint8List),
//     'createdAt': DateTime.now().toIso8601String(),
//   };
// }
//
// Future<String> decryptMessage(
//     Map<String, dynamic> encryptedMessage,
//     RSAPrivateKey privateKey,
//     String senderId,
//     ) async {
//   try {
//     final isSender = encryptedMessage['sender'] == senderId;
//     final encKeyB64 = isSender
//         ? encryptedMessage['encryptedAesKeyForSender']
//         : encryptedMessage['encryptedAesKeyForReceiver'];
//
//     if (encKeyB64 == null) throw Exception('Missing encrypted AES key');
//
//     final rsaOaep = RSAOAEP(hash: SHA256Digest());
//
//     final aesKeyBase64Bytes = rsaOaep.decryptString(
//       base64DecodeToU8(encKeyB64) as String,
//       privateKey,
//     );
//
//     final aesKeyBase64 = utf8.decode(aesKeyBase64Bytes as List<int>);
//     final aesKeyBytes = base64DecodeToU8(aesKeyBase64);
//
//     final aesGcm = AesGcm.with256bits();
//     final secretKey = SecretKey(aesKeyBytes);
//
//     final nonce = base64DecodeToU8(encryptedMessage['iv']);
//     final cipherText = base64DecodeToU8(encryptedMessage['encryptedText']);
//
//     final clearText = await aesGcm.decrypt(
//       SecretBox(cipherText, nonce: nonce, mac: Mac.empty),
//       secretKey: secretKey,
//     );
//
//     return utf8.decode(clearText);
//   } catch (e) {
//     return 'Unable to display the message...';
//   }
// }
//
// void main() async {
//
//   // Generate keys for demo (in real apps, load keys from PEM or storage)
//   final keyPair = RSAKeyUtils.generateKeyPair(bitLength: 2048);
//
//   // Encrypt message
//   final encrypted = await encryptMessage(
//     'Hello Flutter encryption!',
//     keyPair.publicKey,
//     keyPair.publicKey,
//     'senderId123',
//     'receiverId456',
//   );
//
//   print('Encrypted message: $encrypted');
//
//   // Decrypt message
//   final decryptedText = await decryptMessage(
//     encrypted,
//     keyPair.privateKey,
//     'receiverId456',
//   );
//
//   print('Decrypted message: $decryptedText');
// }
