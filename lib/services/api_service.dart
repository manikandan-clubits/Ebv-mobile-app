import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ebv/services/storage_services.dart';
import '../screens/auth/email_login.dart';

class ApiService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    initialize();
  }

  // Configuration
  static const String _baseUrl = "https://dev-ebv-backend-ffafgsdhg8chbvcy.southindia-01.azurewebsites.net";
  static const String _refreshTokenUrl = "/user/verify/token";
  static const Duration _timeout = Duration(seconds: 120);
  static const int _maxRetries = 1;

  static const String _secretKeyBase64 = "VSZKsJvYFlufUGRcg8szIVBJ3tLf0eh1V2Xq4LuWy5U=";
  final encrypt.Key _encryptionKey = encrypt.Key(base64.decode(_secretKeyBase64));

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: _timeout,
    receiveTimeout: _timeout,
    headers: {
      'Content-Type': 'application/json',
    },
    validateStatus: (status) => true,
  ));

  bool _isRefreshingToken = false;

  void initialize() {
    _dio.interceptors.clear();
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequestInterceptor,
      onError: _onErrorInterceptor,
      onResponse: _onResponseInterceptor,
    ));
  }

  void _onResponseInterceptor(
      Response response,
      ResponseInterceptorHandler handler,
      ) {
    handler.next(response);
  }

  Map<String, String> encryptData(dynamic data) {
    try {
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey, mode: encrypt.AESMode.cbc));

      final jsonString = json.encode(data);
      final encrypted = encrypter.encrypt(jsonString, iv: iv);

      return {
        'encryptedData': base64.encode(encrypted.bytes),
        'iv': base64.encode(iv.bytes)
      };
    } catch (e) {
      throw Exception('Failed to encrypt data');
    }
  }

  dynamic decryptData(String encryptedDataBase64, String ivBase64) {
    try {
      final encryptedBytes = base64.decode(encryptedDataBase64);
      final ivBytes = base64.decode(ivBase64);

      final iv = encrypt.IV(ivBytes);
      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey, mode: encrypt.AESMode.cbc));

      final decrypted = encrypter.decrypt(encrypt.Encrypted(encryptedBytes), iv: iv);
      return json.decode(decrypted);
    } catch (e) {
      throw Exception('Failed to decrypt data');
    }
  }

  Future<dynamic> auth(String apiString, dynamic data) async {
    try {
      final encrypted = encryptData(data);

      final response = await http.post(
        Uri.parse(apiString),
        headers: {
          "Content-Type": "application/json",
        },
        body: json.encode(encrypted),
      );

      if (response.statusCode == 200) {
        var responseBody = json.decode(utf8.decode(response.bodyBytes));
        if (responseBody is Map && responseBody.containsKey('encryptedData') && responseBody.containsKey('iv')) {
          return decryptData(responseBody['encryptedData'], responseBody['iv']);
        }
        return responseBody;
      } else {
        var responseBody = json.decode(utf8.decode(response.bodyBytes));
        if (responseBody is Map && responseBody.containsKey('encryptedData') && responseBody.containsKey('iv')) {
          return decryptData(responseBody['encryptedData'], responseBody['iv']);
        }
        return responseBody;
      }
    } catch (e) {
      print("HTTP Request Error: $e");
      rethrow;
    }
  }

  Future<void> _onRequestInterceptor(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    try {
      if (options.path != _refreshTokenUrl.replaceFirst(_baseUrl, '')) {
        final accessToken = await StorageServices.read('accessToken');
        if (accessToken != null) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
      }
      handler.next(options);
    } catch (e) {
      handler.reject(DioError(
        requestOptions: options,
        error: 'Failed to add authentication headers: $e',
      ));
    }
  }

  Future<void> _onErrorInterceptor(
      DioError error,
      ErrorInterceptorHandler handler,
      ) async {
    if (_isRefreshingToken) return handler.next(error);
    if (error.response?.statusCode == 500) {
      return handler.resolve(error.response!);
    }

    if (error.response?.statusCode == 401) {
      try {
        _redirectToLogin();
        final newToken = await _refreshToken();
        _isRefreshingToken = false;

        if (newToken.isNotEmpty) {
          await StorageServices.write('accessToken', newToken);
          final request = error.requestOptions;
          request.headers['Authorization'] = 'Bearer $newToken';

          try {
            final response = await _dio.request(
              request.path,
              data: request.data,
              queryParameters: request.queryParameters,
              options: Options(
                method: request.method,
                headers: request.headers,
              ),
            );
            return handler.resolve(response);
          } catch (e) {
            return handler.next(error);
          }
        } else {
          _redirectToLogin();
          return handler.reject(error);
        }
      } catch (e) {
        _isRefreshingToken = false;
        _redirectToLogin();
        return handler.reject(error);
      }
    }
    return handler.next(error);
  }

  Future<String> _refreshToken() async {
    try {
      final refreshToken = await StorageServices.read('token');
      if (refreshToken == null) return "";

      final response = await Dio().post(
        _refreshTokenUrl,
        data: {'refreshToken': refreshToken},
        options: Options(headers: {
          'Content-Type': 'application/json',
        }),
      );

      if (response.statusCode == 200) {
        return response.data['accessToken']?.toString() ?? "";
      }
      return "";
    } catch (e) {
      return "";
    }
  }

  void _redirectToLogin() async {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => SignIn()),
          (route) => false,
    );
    await StorageServices.delete('accessToken');
  }

  Future<Response> get(String endpoint, Map<String, dynamic>? params) async {
    return _requestWithRetry(
          () => _dio.get(endpoint, queryParameters: params),
    );
  }


  Future<Response> post(String endpoint, dynamic data, {bool encrypt = false}) async {
    return _requestWithRetry(() async {
      dynamic requestData = data;

      if (encrypt) {
        requestData = encryptData(data);
      }

      return _dio.post(endpoint, data: requestData);
    });
  }

  Future<Response> put(String endpoint, dynamic data, {bool encrypt = false}) async {
    return _requestWithRetry(() async {
      dynamic requestData = data;

      if (encrypt) {
        requestData = encryptData(data);
      }

      return _dio.put(endpoint, data: requestData);
    });
  }

  Future<Response> delete(String endpoint) async {
    return _requestWithRetry(
          () => _dio.delete(endpoint),
    );
  }

  Future<Response> _requestWithRetry(Future<Response> Function() request) async {
    int attempt = 0;
    DioError? lastError;

    while (attempt < _maxRetries) {
      try {
        final response = await request();

        // For 500 errors, return the response instead of throwing
        if (response.statusCode == 500) {
          return response;
        }

        // For other successful status codes, return the response
        if (response.statusCode! >= 200 && response.statusCode! < 300) {
          return response;
        }

        // For other error status codes, throw an exception
        throw DioError(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Request failed with status code: ${response.statusCode}',
        );
      } on DioError catch (e) {
        lastError = e;
        attempt++;
        if (attempt >= _maxRetries) break;
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    throw lastError ?? Exception('Request failed after $_maxRetries attempts');
  }

  bool isServerError(Response response) {
    return response.statusCode != null && response.statusCode! >= 500 && response.statusCode! < 600;
  }

  String getErrorMessage(Response response) {
    if (response.data is Map) {
      return response.data['Message'] ?? response.data['message'] ?? 'Server error occurred';
    }
    return 'Server error (${response.statusCode})';
  }
}