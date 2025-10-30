import 'dart:async';
import 'dart:io';
import 'package:ebv/screens/auth/email_login.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:riverpod/riverpod.dart';
import '../services/api_service.dart';
import '../services/storage_services.dart';

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier();
});

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AuthState {

  final dynamic userInfo;
  final bool isLoading;
  final bool isTokenVerified;
  final String? error;

  AuthState({
    this.userInfo,
    this.isLoading = true,
    this.isTokenVerified = false,
    this.error,
  });

  AuthState copyWith({
    dynamic userInfo,
    bool? isLoading,
    bool? isTokenVerified,
    String? error,
  }) {
    return AuthState(
      userInfo: userInfo ?? this.userInfo,
      isLoading: isLoading ?? this.isLoading,
      isTokenVerified: isTokenVerified ?? this.isTokenVerified,
      error: error ?? this.error,
    );
  }
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier() : super(AuthState()) {}

  Future<void> initializeAuth(BuildContext context) async {
    try {
      state = state.copyWith(isLoading: true);

      // Check if token exists and is valid
      final bool isTokenValid = await verifyToken(context);

      if (isTokenValid) {
        // Token is valid, user stays on current screen
        state = state.copyWith(
            isLoading: false,
            isTokenVerified: true,
            error: null
        );
      } else {
        // Token is invalid or expired, redirect to sign in
        state = state.copyWith(
            isLoading: false,
            isTokenVerified: false,
            userInfo: null
        );

      }
    } catch (e) {
      state = state.copyWith(
          error: e.toString(),
          isLoading: false,
          isTokenVerified: false
      );

      // On error, also redirect to sign in
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SignIn()),
        );
      });
    }
  }

  Future<bool> verifyToken([BuildContext? context]) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final String? accessToken = await StorageServices.read('accessToken');
      if (accessToken == null || accessToken.isEmpty) {
        _showErrorToast('No token found',context);
        await _clearInvalidAuthData();
        state = state.copyWith(
            isLoading: false,
            isTokenVerified: false,
            userInfo: null
        );
        return false;
      }

      final Map<String, dynamic> body = {
        "Token": accessToken,
      };

      final response = await ApiService().post(
        '/user/verify/token',
        body,
        encrypt: true,
      );

      print("Response status: ${response.statusCode}");

      if (response.statusCode == 400) {
        await _clearInvalidAuthData();
        state = state.copyWith(
            isLoading: false,
            isTokenVerified: false,
            userInfo: null
        );
        return false;
      } else if (response.statusCode == 401) {
        _showErrorToast('Token expired or invalid',context);
        await _clearInvalidAuthData();
        state = state.copyWith(
            isLoading: false,
            isTokenVerified: false,
            userInfo: null
        );
        return false;
      } else if (response.statusCode != 200) {
        await _clearInvalidAuthData();
        state = state.copyWith(
            isLoading: false,
            isTokenVerified: false,
            userInfo: null
        );
        return false;
      }

      if (response.data == null) {
        await _clearInvalidAuthData();
        state = state.copyWith(
            isLoading: false,
            isTokenVerified: false,
            userInfo: null
        );
        return false;
      }

      // Decrypt response data
      final String? encryptedData = response.data['encryptedData'];
      final String? iv = response.data['iv'];

      if (encryptedData == null || iv == null) {
        await _clearInvalidAuthData();
        state = state.copyWith(
            isLoading: false,
            isTokenVerified: false,
            userInfo: null
        );
        return false;
      }

      final Map<String, dynamic>? result = ApiService().decryptData(encryptedData, iv);
      if (result == null) {
        await _clearInvalidAuthData();
        state = state.copyWith(
            isLoading: false,
            isTokenVerified: false,
            userInfo: null
        );
        return false;
      }

      final bool isValid = result['message']?.toString().toLowerCase() == 'valid token';
      final int? statusCode = result['statusCode'];

      if (isValid) {
        _showSuccessToast('Token Verified Successfully');
        state = state.copyWith(
            isLoading: false,
            isTokenVerified: true
        );
        return true;
      } else {
        await _clearInvalidAuthData();
        state = state.copyWith(
            isLoading: false,
            isTokenVerified: false,
            userInfo: null
        );
        return false;
      }
    } catch (e) {
      await _clearInvalidAuthData();
      state = state.copyWith(
          isLoading: false,
          isTokenVerified: false,
          userInfo: null,
          error: e.toString()
      );
      return false;
    }
  }

  Future<void> _clearInvalidAuthData() async {
    try {
      await StorageServices.delete("userInfo");
      await StorageServices.delete('accessToken');
    } catch (e) {
      print('Error clearing auth data: $e');
    }
  }

  void _showErrorToast(String message,context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  Future<void> loadUserInfo() async {
    try {
      final userInfo = await StorageServices.read("userInfo");
      state = state.copyWith(userInfo: userInfo);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateUserInfo(dynamic userInfo) async {
    try {
      state = state.copyWith(userInfo: userInfo, isTokenVerified: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> logout() async {
    try {
      await _clearInvalidAuthData();
      state = AuthState(
          userInfo: null,
          isLoading: false,
          isTokenVerified: false,
          error: null
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}