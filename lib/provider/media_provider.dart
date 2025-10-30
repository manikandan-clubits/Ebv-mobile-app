


import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio;
import 'dart:typed_data';



class MediaNotifier extends StateNotifier<File?> {
  final dynamic? ref;

  MediaNotifier(this.ref) : super(null);


  Future<String> pickImage(ImagePicker picker, ImageSource source,var type) async {
    var result;
    final pickedFile = await picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (pickedFile != null) {
      state = File(pickedFile.path);

      final compressedImage = await FlutterImageCompress.compressWithFile(
        pickedFile.path,
        minWidth: 800,
        minHeight: 800,
        quality: 85,
      );

      if (compressedImage != null) {
        await uploadImage(compressedImage,pickedFile);
        result = await uploadImage(compressedImage,pickedFile);
      }
    }
    return result;
  }

  dynamic uploadImage(Uint8List imageBytes,pickedFile) async {
    try {
      dio.FormData formData = dio.FormData.fromMap({
        'image': dio.MultipartFile.fromBytes(
          imageBytes,
          filename: pickedFile.path.split('/').last,
        ),
      });

      dio.Dio dioInstance = dio.Dio();
      final response = await dioInstance.post(
        'https://dev-storage-api-service-g2eegmbtg2dmbhbg.southindia-01.azurewebsites.net/upload/large-file',
        data: formData,
        options: dio.Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        Fluttertoast.showToast(
          msg: "Media Saved Successfully!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.SNACKBAR,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        final imageUrl = responseData['url'];
        return imageUrl;
      } else {
        return "";
      }
    } catch (e) {
      print('Error uploading image: $e');
    }
  }


}


final imageProvider = StateNotifierProvider<MediaNotifier, File?>((ref) {
  return MediaNotifier(ref);
});
