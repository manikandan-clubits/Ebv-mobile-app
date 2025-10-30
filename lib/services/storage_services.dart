import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';



class  StorageServices{
  final androidOptions = const AndroidOptions(encryptedSharedPreferences: true);
  final iosOptions =
  const IOSOptions(accessibility: KeychainAccessibility.first_unlock);
  static  var storage = FlutterSecureStorage();


  static  write(key, value) async {
    await storage.write(key: key, value: json.encode(value));
  }

  static dynamic read(key) async {
    return json.decode(await storage.read(key: key) ?? 'null');
  }


  static delete(key) async {
    await storage.delete(key: key);
  }

  deleteAll() async {
    await storage.deleteAll();
  }

}