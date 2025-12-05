// import 'package:encrypt/encrypt.dart' as encrypt;
// import 'package:pointycastle/api.dart';
// import 'package:pointycastle/asymmetric/api.dart';
// import 'package:pointycastle/key_generators/api.dart';
// import 'package:pointycastle/key_generators/rsa_key_generator.dart';
// import 'package:pointycastle/random/fortuna_random.dart';
// import 'package:flutter/material.dart';
// import 'dart:typed_data';
//
//
// void main() {
//
//   runApp(const MaterialApp(home: RsaChatDemo()));
// }
//
//
// class RsaChatDemo extends StatefulWidget {
//   const RsaChatDemo({super.key});
//
//   @override
//   State<RsaChatDemo> createState() => _RsaChatDemoState();
// }
//
// class _RsaChatDemoState extends State<RsaChatDemo> {
//
//
//   final TextEditingController _controller = TextEditingController();
//   late RSAPublicKey publicKey;
//   late RSAPrivateKey privateKey;
//
//   final List<Map<String, String>> messages = [];
//
//
//   // Generate RSA Key Pair
//   generateRSAKeyPair() {
//
//     final rnd = FortunaRandom()..seed(KeyParameter(Uint8List.fromList(List.generate(32, (i) => i + 1))));
//     final params = RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 25);
//     final keyGen = RSAKeyGenerator()..init(ParametersWithRandom(params, rnd));
//     return keyGen.generateKeyPair();
//   }
//
// // RSA Encryption / Decryption helpers
//   String encryptWithPublicKey(String plaintext, RSAPublicKey publicKey) {
//     final encrypter = encrypt.Encrypter(encrypt.RSA(publicKey: publicKey));
//     final encrypted = encrypter.encrypt(plaintext);
//     return encrypted.base64;
//   }
//
//   String decryptWithPrivateKey(String ciphertext, RSAPrivateKey privateKey) {
//     final encrypter = encrypt.Encrypter(encrypt.RSA(privateKey: privateKey));
//     final decrypted = encrypter.decrypt64(ciphertext);
//     return decrypted;
//   }
//
//   @override
//   void initState() {
//     final keypair = generateRSAKeyPair();
//     publicKey = keypair.publicKey as RSAPublicKey;
//
//
//     privateKey = keypair.privateKey as RSAPrivateKey;
//   }
//
//   void sendEncryptedMessage() {
//     final plaintext = _controller.text.trim();
//     if (plaintext.isEmpty) return;
//
//     // Encrypt with own public key (simulating recipient)
//     final encryptedMessage = encryptWithPublicKey(plaintext, publicKey);
//
//     messages.add({
//       'encrypted': encryptedMessage,
//       'plaintext': plaintext,
//     });
//     setState(() {});
//     print("encryptedMessage$encryptedMessage");
//     _controller.clear();
//   }
//
//   String decryptMessage(String encrypted) {
//     return decryptWithPrivateKey(encrypted, privateKey);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(title: Text('RSA Encryption Demo')),
//         body: Column(
//           children: [
//             Expanded(
//                 child: ListView.builder(
//                   itemCount: messages.length,
//                   itemBuilder: (_, index) {
//                     final msg = messages[index];
//                     final decryptedMessage = decryptMessage(msg['encrypted']!);
//                     return ListTile(
//                       title: Text(decryptedMessage,style: TextStyle(color: Colors.black),),
//                       subtitle: Text('Encrypted: ${msg['encrypted']}'),
//                     );
//                   },
//                 )),
//
//             Row(
//               children: [
//                 Expanded(
//                     child: TextField(
//                       controller: _controller,
//                       decoration: InputDecoration(hintText: 'Enter message'),
//                     )),
//                 IconButton(
//                   icon: Icon(Icons.send),
//                   onPressed: sendEncryptedMessage,
//                 ),
//               ],
//             )
//           ],
//         ));
//   }
// }
