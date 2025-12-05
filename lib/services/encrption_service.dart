// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:cryptography/cryptography.dart';
// import '../models/chat_model.dart';
// import 'dart:math';

// import 'package:rsa_pkcs/rsa_pkcs.dart';

// class EncryptionService {
//   static const int aesKeyLength = 32; // 256 bits
//   static const int ivLength = 12; // 96 bits for GCM

//   // Main decryption method - matches React decryptMessage
// //   Future<String> decryptMessage({
// //     required Message messageData,
// //     required String? privateKey,
// //     required int? currentUserId,
// //   }) async {
// //     try {
// //       // Validate inputs
// //       if (privateKey == null || privateKey.isEmpty) {
// //         print('❌ Private key is null or empty');
// //         return messageData.content ?? '';
// //       }
// //
// //       if (currentUserId == null) {
// //         print('❌ Current user ID is null');
// //         return messageData.content ?? '';
// //       }
// //
// //       // Check if message is encrypted
// //       final encryptedText = messageData.content ?? '';
// //       final iv = messageData.iv;
// //       final isSender = messageData.senderID == currentUserId;
// //       final encKeyB64 = isSender ? messageData.encryptedAesKeyForSender : messageData.encryptedAesKeyForReceiver;
// //
// //       print("🔐 decryption data check:");
// //       print("  - IV present: ${iv}");
// //       print("  - currentUserId ${currentUserId}");
// //       print("  - encryptedAesKeyForSender ${encKeyB64}");
// //       print("  - Encrypted content present: ${encryptedText}");
// //       print("  - privateKey ${privateKey}");
// //
// //       // If no encryption data, return original content
// //       if (encryptedText.isEmpty || iv == null || iv.isEmpty || encKeyB64 == null || encKeyB64.isEmpty) {
// //         print('ℹ️ Message not encrypted or missing encryption data');
// //         return encryptedText;
// //       }
// //
// //
// //
// //       // Use the exact React-compatible approach
// //       try {
// //
// //         return await _decryptReactCompatible(encryptedText, iv, encKeyB64, privateKey);
// //       } catch (e, stackTrace) {
// //         print('❌ decryption failed: $e');
// //         print('Stack trace: $stackTrace');
// //         return 'Unable to display the message...';
// //       }
// //
// //     } catch (e, stackTrace) {
// //       print('💥 Decrypt error: $e');
// //       print('Stack trace: $stackTrace');
// //       return 'Unable to display the message...';
// //     }
// //   }
// //
// //   // EXACT MATCH for React decryptMessage function
// //   Future<String> _decryptReactCompatible(String encryptedText, String iv, String encKeyB64, String privateKey) async {
// //     print("🔄 Using exact React-compatible approach");
// //
// //     try {
// //       // Step 1: Parse private key with improved parsing
// //       final rsaPrivateKey = parsePrivateKeyImproved(privateKey);
// //       print("✅ Private key parsed successfully");
// //
// //       // Step 2: Create RSA encrypter - use OAEP as it's more standard
// //       final decrypterRsa = encrypt.Encrypter(encrypt.RSA(
// //         privateKey: rsaPrivateKey,
// //         encoding: encrypt.RSAEncoding.OAEP,
// //       ));
// //       print("Using OAEP padding for RSA");
// //
// //       // Step 3: Decrypt the AES key
// //       final encryptedAesKeyBytes = base64.decode(encKeyB64);
// //       print("Encrypted AES key length: ${encryptedAesKeyBytes.length} bytes");
// //       print("Encrypted AES key base64: $encKeyB64");
// //
// //       // Step 4: RSA decrypt the AES key using alternative method (since it works)
// //       print("Using alternative RSA decryption method...");
// //       final decryptedAesKeyBytes = _decryptRsaAlternative(rsaPrivateKey, encryptedAesKeyBytes);
// //       print('✅ RSA Decryption successful');
// //       print('Decrypted AES key bytes length: ${decryptedAesKeyBytes.length}');
// //       print('Decrypted AES key hex: ${_bytesToHex(decryptedAesKeyBytes)}');
// //
// //       // Step 5: Fix IV length issue
// //       final fixedIv = _fixIvLength(iv);
// //       print("Original IV: $iv (${iv.length} chars)");
// //       print("Fixed IV length: ${fixedIv.length} bytes");
// //
// //       // Step 6: Try different AES key interpretations with fixed IV
// //       String? decrypted;
// //
// //       // Method 1: Direct bytes as AES key (most common)
// //       try {
// //         if (decryptedAesKeyBytes.length >= 32) {
// //           // Take first 32 bytes for AES-256
// //           final aesKeyBytes = decryptedAesKeyBytes.sublist(0, 32);
// //           final aesKey = encrypt.Key(Uint8List.fromList(aesKeyBytes));
// //           decrypted = _decryptAesContent(encryptedText, fixedIv, aesKey);
// //           if (decrypted.isNotEmpty) {
// //             print("✅ Direct bytes method succeeded");
// //             return decrypted;
// //           }
// //         } else {
// //           print("Decrypted key too short: ${decryptedAesKeyBytes.length} bytes (need 32 for AES-256)");
// //         }
// //       } catch (e) {
// //         print("Direct bytes method failed: $e");
// //       }
// //
// //       // Method 2: Use exactly 32 bytes (pad if needed)
// //       try {
// //         List<int> aesKeyBytes;
// //         if (decryptedAesKeyBytes.length >= 32) {
// //           aesKeyBytes = decryptedAesKeyBytes.sublist(0, 32);
// //         } else {
// //           // Pad with zeros if too short
// //           aesKeyBytes = List<int>.from(decryptedAesKeyBytes);
// //           while (aesKeyBytes.length < 32) {
// //             aesKeyBytes.add(0);
// //           }
// //           print("Padded AES key to 32 bytes");
// //         }
// //         final aesKey = encrypt.Key(Uint8List.fromList(aesKeyBytes));
// //         decrypted = _decryptAesContent(encryptedText, fixedIv, aesKey);
// //         if (decrypted.isNotEmpty) {
// //           print("✅ Padded bytes method succeeded");
// //           return decrypted;
// //         }
// //       } catch (e) {
// //         print("Padded bytes method failed: $e");
// //       }
// //
// //       // Method 3: Try interpreting as hex string
// //       try {
// //         final keyHex = decryptedAesKeyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
// //         if (keyHex.length >= 64) { // 64 hex chars = 32 bytes
// //           final hexKey = keyHex.substring(0, 64);
// //           final aesKeyBytes = _hexToBytes(hexKey);
// //           final aesKey = encrypt.Key(Uint8List.fromList(aesKeyBytes));
// //           decrypted = _decryptAesContent(encryptedText, fixedIv, aesKey);
// //           if (decrypted.isNotEmpty) {
// //             print("✅ Hex interpretation method succeeded");
// //             return decrypted;
// //           }
// //         }
// //       } catch (e) {
// //         print("Hex interpretation method failed: $e");
// //       }
// //
// //       throw Exception("All AES key interpretation methods failed");
// //
// //     } catch (e, stackTrace) {
// //       print('❌ Overall decryption failed: $e');
// //       print('Stack trace: $stackTrace');
// //       rethrow;
// //     }
// //   }
// //
// // // Fix IV length to exactly 16 bytes
// //   String _fixIvLength(String iv) {
// //     try {
// //       // Decode the IV from base64
// //       final ivBytes = base64.decode(iv);
// //       print("Original IV bytes length: ${ivBytes.length}");
// //
// //       if (ivBytes.length == 16) {
// //         // IV is already correct length, return as is
// //         return iv;
// //       } else if (ivBytes.length > 16) {
// //         // Take first 16 bytes
// //         final fixedBytes = ivBytes.sublist(0, 16);
// //         return base64.encode(fixedBytes);
// //       } else {
// //         // Pad with zeros to reach 16 bytes
// //         final fixedBytes = List<int>.from(ivBytes);
// //         while (fixedBytes.length < 16) {
// //           fixedBytes.add(0);
// //         }
// //         return base64.encode(fixedBytes);
// //       }
// //     } catch (e) {
// //       print("Error fixing IV length: $e");
// //       // If IV is not base64, try other interpretations
// //
// //       // If IV is hex string
// //       if (iv.length == 32 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(iv)) {
// //         final ivBytes = _hexToBytes(iv);
// //         if (ivBytes.length == 16) {
// //           return base64.encode(ivBytes);
// //         }
// //       }
// //
// //       // If all else fails, create a deterministic IV from the string
// //       final bytes = utf8.encode(iv.padRight(16).substring(0, 16));
// //       return base64.encode(bytes);
// //     }
// //   }
// //
// // // Alternative RSA decryption method using pointycastle directly
// //   List<int> _decryptRsaAlternative(RSAPrivateKey privateKey, List<int> encryptedBytes) {
// //
// //
// //     final cipher = RSAEngine()
// //       ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
// //
// //     final result = cipher.process(encryptedBytes as Uint8List);
// //     print('✅ Alternative RSA decryption successful');
// //     return result;
// //   }
// //
// // // Helper method to convert bytes to hex string
// //   String _bytesToHex(List<int> bytes) {
// //     return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
// //   }
// //
// // // Helper method to convert hex string to bytes
// //   List<int> _hexToBytes(String hex) {
// //     final result = <int>[];
// //     for (int i = 0; i < hex.length; i += 2) {
// //       result.add(int.parse(hex.substring(i, i + 2), radix: 16));
// //     }
// //     return result;
// //   }
// //
// // // AES decryption method with better error handling
// //   String _decryptAesContent(String encryptedText, String iv, encrypt.Key key) {
// //     try {
// //       final encrypter = encrypt.Encrypter(encrypt.AES(
// //         key,
// //         mode: encrypt.AESMode.cbc,
// //         padding: 'PKCS7',
// //       ));
// //
// //       final ivObj = encrypt.IV.fromBase64(iv);
// //       final encryptedObj = encrypt.Encrypted.fromBase64(encryptedText);
// //
// //       final decrypted = encrypter.decrypt(encryptedObj, iv: ivObj);
// //       print("#decryptAesContentdecrypted$decrypted");
// //       // Validate decryption result
// //       if (decrypted.isEmpty) {
// //         throw Exception("Decrypted content is empty");
// //       }
// //
// //       print("✅ AES decryption successful, decrypted length: ${decrypted.length}");
// //       return decrypted;
// //     } catch (e) {
// //       print('AES decryption failed: $e');
// //       rethrow;
// //     }
// //   }
// //
// //   dynamic parsePrivateKeyImproved(String privateKey) {
// //     try {
// //       print("🔑 Parsing private key...");
// //       String cleanedKey = privateKey.trim();
// //
// //       // Log first part of the key for debugging
// //       print("Key starts with: ${cleanedKey.substring(0, min(50, cleanedKey.length))}...");
// //
// //       // Remove headers and footers for clean base64 extraction
// //       cleanedKey = cleanedKey.replaceAll('-----BEGIN PRIVATE KEY-----', '');
// //       cleanedKey = cleanedKey.replaceAll('-----END PRIVATE KEY-----', '');
// //       cleanedKey = cleanedKey.replaceAll('-----BEGIN RSA PRIVATE KEY-----', '');
// //       cleanedKey = cleanedKey.replaceAll('-----END RSA PRIVATE KEY-----', '');
// //       cleanedKey = cleanedKey.replaceAll('-----BEGIN ENCRYPTED PRIVATE KEY-----', '');
// //       cleanedKey = cleanedKey.replaceAll('-----END ENCRYPTED PRIVATE KEY-----', '');
// //       cleanedKey = cleanedKey.replaceAll(RegExp(r'\s'), ''); // Remove all whitespace
// //
// //       print("Cleaned key length: ${cleanedKey.length}");
// //
// //       // Re-add PEM headers for both common formats and try parsing
// //       List<String> pemFormatsToTry = [
// //         '''-----BEGIN PRIVATE KEY-----\n$cleanedKey\n-----END PRIVATE KEY-----''',          // PKCS#8
// //         '''-----BEGIN RSA PRIVATE KEY-----\n$cleanedKey\n-----END RSA PRIVATE KEY-----''',  // PKCS#1
// //       ];
// //
// //       for (final pemFormat in pemFormatsToTry) {
// //         try {
// //           print("Trying PEM format: ${pemFormat.split('\n').first}...");
// //           final key = encrypt.RSAKeyParser().parse(pemFormat);
// //           print("✅ Private key parsed successfully");
// //           return key;
// //         } catch (e) {
// //           print("Format failed: $e");
// //           continue;
// //         }
// //       }
// //
// //       // If all else fails, try direct parsing of cleaned key (rarely works)
// //       try {
// //         print("Trying direct parsing...");
// //         return encrypt.RSAKeyParser().parse(cleanedKey);
// //       } catch (e) {
// //         print("Direct parsing failed: $e");
// //         rethrow;
// //       }
// //     } catch (e, stackTrace) {
// //       print('💥 Private key parsing failed: $e');
// //       print('Stack trace: $stackTrace');
// //       rethrow;
// //     }
// //   }
// //
// //
// //
// //   bool isValidBase64(String str) {
// //     try {
// //       base64.decode(str);
// //       return true;
// //     } catch (e) {
// //       return false;
// //     }
// //   }
// //
// //
// //   // Group message decryption - matches React decryptMessageGroup
// //   Future<String> decryptMessageGroup({
// //     required Message messageData,
// //     required String? privateKey,
// //     required int? currentUserId,
// //   }) async {
// //     print("=== GROUP DECRYPTION STARTED ===");
// //     print("decryptMessageGroup - currentUserId: $currentUserId");
// //
// //     try {
// //       if (privateKey == null || privateKey.isEmpty || currentUserId == null) {
// //         print('Private key or current user ID is invalid');
// //         return 'Unable to display the message...';
// //       }
// //
// //       // Extract encryption data from message
// //       final encryptedText = messageData.content ?? '';
// //       final iv = messageData.iv;
// //       final encryptedAesKey = _getGroupEncryptedAesKeyForUser(messageData, currentUserId.toString());
// //
// //       print("Group encryption check:");
// //       print("  - IV present: ${iv != null && iv.isNotEmpty}");
// //       print("  - AES Key present: ${encryptedAesKey != null && encryptedAesKey.isNotEmpty}");
// //       print("  - Encrypted content present: ${encryptedText.isNotEmpty}");
// //
// //       if (encryptedText.isEmpty || iv == null || iv.isEmpty || encryptedAesKey == null || encryptedAesKey.isEmpty) {
// //         print('Group message not encrypted or missing encryption data');
// //         return 'Unable to display the message...';
// //       }
// //
// //       // Use React-compatible approach for group messages
// //       try {
// //         return await _decryptReactCompatible(encryptedText, iv, encryptedAesKey, privateKey);
// //       } catch (e) {
// //         print("Group decryption failed: $e");
// //         return 'Unable to display the message...';
// //       }
// //
// //     } catch (e, stackTrace) {
// //       print('💥 Group decryption error: $e');
// //       print('Stack trace: $stackTrace');
// //       return 'Unable to display the message...';
// //     }
// //   }

//   // INDIVIDUAL MESSAGE ENCRYPTION - Exact match for React encryptMessage
//   // Future<EncryptedMessage> encryptMessage({
//   //   required String content,
//   //   required String senderPublicKey,
//   //   required String receiverPublicKey,
//   //   required String senderId,
//   //   required String receiverId,
//   // }) async {
//   //   try {
//   //     print("=== INDIVIDUAL ENCRYPTION STARTED ===");
//   //
//   //     // Step 1: Generate random AES key and IV
//   //     final aesKey = encrypt.Key.fromSecureRandom(aesKeyLength);
//   //     final iv = encrypt.IV.fromSecureRandom(ivLength);
//   //
//   //     // Step 2: Encrypt the content with AES-GCM
//   //     final encrypter = encrypt.Encrypter(encrypt.AES(aesKey, mode: encrypt.AESMode.gcm));
//   //     final encrypted = encrypter.encrypt(content, iv: iv);
//   //
//   //     // Step 3: Export AES key as base64 string
//   //     final aesKeyBase64 = base64.encode(aesKey.bytes);
//   //
//   //     // Step 4: Parse public keys with improved parsing
//   //     final senderRsaPublicKey = _parsePublicKeyImproved(senderPublicKey);
//   //     final receiverRsaPublicKey = _parsePublicKeyImproved(receiverPublicKey);
//   //
//   //     // Step 5: Encrypt AES key for sender
//   //     final encrypterRsaSender = encrypt.Encrypter(encrypt.RSA(
//   //       publicKey: senderRsaPublicKey,
//   //       encoding: encrypt.RSAEncoding.OAEP,
//   //     ));
//   //
//   //     final aesKeyBytes = utf8.encode(aesKeyBase64);
//   //     final encryptedAesKeyForSender = encrypterRsaSender.encryptBytes(aesKeyBytes);
//   //
//   //     // Step 6: Encrypt AES key for receiver
//   //     final encrypterRsaReceiver = encrypt.Encrypter(encrypt.RSA(
//   //       publicKey: receiverRsaPublicKey,
//   //       encoding: encrypt.RSAEncoding.OAEP,
//   //     ));
//   //     final encryptedAesKeyForReceiver = encrypterRsaReceiver.encryptBytes(aesKeyBytes);
//   //
//   //     print("✅ Individual encryption succeeded");
//   //
//   //     return EncryptedMessage(
//   //       encryptedText: base64.encode(encrypted.bytes),
//   //       iv: base64.encode(iv.bytes),
//   //       encryptedAesKeyForSender: base64.encode(encryptedAesKeyForSender.bytes),
//   //       encryptedAesKeyForReceiver: base64.encode(encryptedAesKeyForReceiver.bytes),
//   //       senderId: senderId,
//   //       receiverId: receiverId,
//   //     );
//   //   } catch (e, stackTrace) {
//   //     print('💥 Individual encryption failed: $e');
//   //     print('Stack trace: $stackTrace');
//   //     throw Exception('Encryption failed: $e');
//   //   }
//   // }

//   Future<Map<String, dynamic>> encryptMessage({
//     required String text,
//     required String senderPublicKeyPem,
//     required String receiverPublicKeyPem,
//     required int sender,
//     required int receiver,
//   }) async {

//     // --------------------
//     // 1. Generate AES Key
//     // --------------------
//     final aes = AesGcm.with256bits();
//     final secretKey = await aes.newSecretKey(); // AES key
//     final aesRawBytes = await secretKey.extractBytes();

//     // Convert AES raw key → base64 → UTF-8 string (React format)
//     final aesStr = base64.encode(aesRawBytes); // same as JS: btoa()

//     // -------------------------
//     // 2. Load RSA Public Keys
//     // -------------------------
//     final parser = encrypt.RSAKeyParser();

//     final senderPubKey = parser.parse(senderPublicKeyPem);
//     final receiverPubKey = parser.parse(receiverPublicKeyPem);

//     // -------------------------------
//     // 3. RSA Encrypt AES key (SHA256)
//     // -------------------------------
//     final aesStrBytes = utf8.encode(aesStr);

//     final encForSender = Rsa().encryptOaep(
//       aesStrBytes,
//       senderPubKey,
//       RsaOaepHash.sha256,
//     );

//     final encForReceiver = Rsa().encryptOaep(
//       aesStrBytes,
//       receiverPubKey,
//       RsaOaepHash.sha256,
//     );

//     // -------------------------
//     // 4. AES-GCM Encrypt Text
//     // -------------------------
//     final iv = aes.newNonce(); // 12 bytes like JS WebCrypto
//     final secretBox = await aes.encrypt(
//       utf8.encode(text),
//       secretKey: secretKey,
//       nonce: iv,
//     );

//     // ciphertext + tag (React format)
//     final cipherWithTag = Uint8List.fromList(
//       [...secretBox.cipherText, ...secretBox.mac.bytes],
//     );

//     // -------------------------
//     // 5. Return React-style Data
//     // -------------------------
//     return {
//       "sender": sender,
//       "receiver": receiver,
//       "iv": base64.encode(iv),
//       "encryptedAesKeyForSender": base64.encode(encForSender),
//       "encryptedAesKeyForReceiver": base64.encode(encForReceiver),
//       "encryptedText": base64.encode(cipherWithTag),
//       "createdAt": DateTime.now().toIso8601String(),
//     };
//   }

//   // Improved public key parsing
//   dynamic _parsePublicKeyImproved(String publicKey) {
//     try {
//       print("🔑 Parsing public key...");
//       String cleanedKey = publicKey.trim();

//       // Remove all possible PEM headers/footers
//       cleanedKey = cleanedKey.replaceAll('-----BEGIN PUBLIC KEY-----', '');
//       cleanedKey = cleanedKey.replaceAll('-----END PUBLIC KEY-----', '');
//       cleanedKey = cleanedKey.replaceAll('-----BEGIN RSA PUBLIC KEY-----', '');
//       cleanedKey = cleanedKey.replaceAll('-----END RSA PUBLIC KEY-----', '');
//       cleanedKey = cleanedKey.replaceAll(RegExp(r'\s'), '');

//       // Try different PEM formats
//       List<String> pemFormatsToTry = [
//         '''-----BEGIN PUBLIC KEY-----\n$cleanedKey\n-----END PUBLIC KEY-----''',
//         '''-----BEGIN RSA PUBLIC KEY-----\n$cleanedKey\n-----END RSA PUBLIC KEY-----''',
//       ];

//       for (final pemFormat in pemFormatsToTry) {
//         try {
//           final key = encrypt.RSAKeyParser().parse(pemFormat);
//           print("✅ Public key parsed successfully");
//           return key;
//         } catch (e) {
//           continue;
//         }
//       }

//       // If all PEM formats fail, try direct parsing
//       return encrypt.RSAKeyParser().parse(cleanedKey);

//     } catch (e) {
//       print('💥 Public key parsing error: $e');
//       rethrow;
//     }
//   }

//   // GROUP MESSAGE ENCRYPTION - Exact match for React encryptMessageGroup
//   Future<GroupEncryptedMessage> encryptMessageGroup({
//     required String content,
//     required String senderPublicKey,
//     required List<GroupPublicKey> groupPublicKeys,
//     required String groupId,
//   }) async {
//     try {
//       print("=== GROUP ENCRYPTION STARTED ===");

//       // Step 1: Generate random AES key and IV
//       final aesKey = encrypt.Key.fromSecureRandom(aesKeyLength);
//       final iv = encrypt.IV.fromSecureRandom(ivLength);

//       // Step 2: Encrypt the content with AES-GCM
//       final encrypter = encrypt.Encrypter(encrypt.AES(aesKey, mode: encrypt.AESMode.gcm));
//       final encrypted = encrypter.encrypt(content, iv: iv);

//       // Step 3: Export AES key as base64 string
//       final aesKeyBase64 = base64.encode(aesKey.bytes);
//       final aesKeyBytes = utf8.encode(aesKeyBase64);

//       // Step 4: Parse sender public key
//       final senderRsaPublicKey = _parsePublicKeyImproved(senderPublicKey);
//       final encrypterRsaSender = encrypt.Encrypter(encrypt.RSA(
//         publicKey: senderRsaPublicKey,
//         encoding: encrypt.RSAEncoding.OAEP,
//       ));
//       final encryptedAesKeyForSender = encrypterRsaSender.encryptBytes(aesKeyBytes);

//       // Step 5: Encrypt AES key for each group member
//       final groupReceivers = <Map<String, String>>[];

//       for (final memberKey in groupPublicKeys) {
//         try {
//           final memberRsaPublicKey = _parsePublicKeyImproved(memberKey.publicKey);
//           final encrypterRsaMember = encrypt.Encrypter(encrypt.RSA(
//             publicKey: memberRsaPublicKey,
//             encoding: encrypt.RSAEncoding.OAEP,
//           ));
//           final encryptedAesKeyForMember = encrypterRsaMember.encryptBytes(aesKeyBytes);

//           groupReceivers.add({
//             'userId': memberKey.userId,
//             'encryptedAesKey': base64.encode(encryptedAesKeyForMember.bytes),
//           });
//         } catch (e) {
//           print("❌ Failed to encrypt for group member ${memberKey.userId}: $e");
//         }
//       }

//       print("✅ Group encryption succeeded for ${groupReceivers.length} members");

//       return GroupEncryptedMessage(
//         encryptedText: base64.encode(encrypted.bytes),
//         iv: base64.encode(iv.bytes),
//         encryptedAesKeyForSender: base64.encode(encryptedAesKeyForSender.bytes),
//         groupReceivers: groupReceivers,
//         groupId: groupId,
//       );
//     } catch (e, stackTrace) {
//       print('💥 Group encryption failed: $e');
//       print('Stack trace: $stackTrace');
//       throw Exception('Group encryption failed: $e');
//     }
//   }

//   // Helper method to get encrypted AES key for group message
//   String? _getGroupEncryptedAesKeyForUser(Message message, String userId) {
//     print("Getting group AES key for user: $userId, sender: ${message.senderID}");

//     // Check if this user is the sender
//     if (message.senderID.toString() == userId) {
//       return message.encryptedAesKeyForSender;
//     }

//     // Check in group receivers
//     if (message.groupReceivers != null) {
//       for (final receiver in message.groupReceivers!) {
//         if (receiver['userId'] == userId) {
//           return receiver['encryptedAesKey'];
//         }
//       }
//     }

//     print("No matching group AES key found for user: $userId");
//     return null;
//   }

//   // Utility method to convert array buffer to base64
//   String arrayBufferToBase64(Uint8List buffer) {
//     return base64.encode(buffer);
//   }

//   // Utility method to convert base64 to array buffer
//   Uint8List base64ToArrayBuffer(String base64Str) {
//     return base64.decode(base64Str);
//   }

// }
