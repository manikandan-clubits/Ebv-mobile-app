import 'dart:async';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/storage_services.dart';


class AuthenticatorState {

  final  Map<String,dynamic>? userInfo;
  final bool isLoading;
  final Map<String, dynamic>? response;
  final DateTime? expiryTime;
  final int remainingSeconds;
  final String? otp;
  final bool isExpired;

  AuthenticatorState({
    this.userInfo,
    this.response,
    this.otp,
    this.isLoading = false,
    this.expiryTime,
    this.remainingSeconds = 0,
    this.isExpired = false,
  });

  AuthenticatorState copyWith({
    Map<String,dynamic>? userInfo,
    bool? isLoading,
    Map<String, dynamic>? response,
    String? otp,
    DateTime? expiryTime,
    int? remainingSeconds,
    bool? isExpired,
  }) {
    return AuthenticatorState(
      userInfo: userInfo ?? this.userInfo,
      isLoading: isLoading ?? this.isLoading,
      response: response ?? this.response,
      otp: otp ?? this.otp,
      expiryTime: expiryTime ?? this.expiryTime,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isExpired: isExpired ?? this.isExpired,
    );
  }
}


class AuthenticatorNotifier extends StateNotifier<AuthenticatorState> {
  AuthenticatorNotifier() : super(AuthenticatorState());
  // final ApiService apiService = ApiService();
  Timer? _timer;

  Future<void> fetchOTP() async {
    state = state.copyWith(isLoading: true,otp: null);
    try {
      final params = {"EmailId": state.userInfo?['Email']};
      log("params$params");
      final response = await ApiService().post('/user/getotp', params);
      final res=  ApiService().decryptData(response.data['encryptedData']!, response.data['iv']);

      if (res != null) {
        _handleOTPResponse(res['data'][0]);
      }
    } catch (e) {
      print('Error fetching OTP: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }


  Future<void> readUser() async {
    final storedUserInfo = await StorageServices.read('userInfo');
    state = state.copyWith(userInfo: storedUserInfo ?? {});
    fetchOTP();
  }

  void _handleOTPResponse(Map<String, dynamic> response) {
    _timer?.cancel();

    final lastUpdated = DateTime.parse(response['LastUpdatedOn']);
    final expiryTime = lastUpdated.add(const Duration(seconds: 90));
    final initialRemaining = expiryTime.difference(DateTime.now()).inSeconds;

    state = state.copyWith(
      response: response,
      otp: response['LoginOTP'],
      expiryTime: expiryTime,
      remainingSeconds: initialRemaining > 0 ? initialRemaining : 0,
      isExpired: initialRemaining <= 0,
    );

    if (initialRemaining > 0) {
      _startTimer(expiryTime);
    }
  }

  void _startTimer(DateTime expiryTime) {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final remaining = expiryTime.difference(now).inSeconds;

      if (remaining <= 0) {
        _timer?.cancel();
        state = state.copyWith(
          otp: null,
          remainingSeconds: 0,
          isExpired: true,
        );
      } else {
        state = state.copyWith(remainingSeconds: remaining);
      }
    });
  }

  Future<void> resendOTP() async {
    _timer?.cancel();
    // state = state.copyWith(
    //   otp: null,
    //   remainingSeconds: 0,
    //   isExpired: false,
    // );
    await resentOtpCall();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void>  resentOtpCall() async {
    state = state.copyWith(isLoading: true);
    Map<String, dynamic> body = {
        "Email": state.userInfo?['Email'],
        "Mobile": "",
        "Password": "",
        "IP": "113.193.238.61"
    };
    log(body.toString());
    try {
      dynamic response = await ApiService().post('/user/login', body);
      final res=  ApiService().decryptData(response.data['encryptedData']!, response.data['iv']);

      fetchOTP();
      if (res!=null) {
      } else {
        state = state.copyWith(isLoading: false);
      }
    }  catch (e) {
      state = state.copyWith(isLoading: false);
    }finally{
      state = state.copyWith(isLoading: false);
    }
  }

}

final authenticatorProvider =
    StateNotifierProvider<AuthenticatorNotifier, AuthenticatorState>(
        (ref) => AuthenticatorNotifier());
