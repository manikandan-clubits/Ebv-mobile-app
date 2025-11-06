import 'dart:async';
import 'dart:developer';
import 'dart:isolate';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:ebv/services/toast_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../models/user_model.dart';
import '../screens/auth/change_password.dart';
import '../screens/home/home.dart' hide SplashScreen;
import '../screens/auth/email_login.dart';
import '../screens/auth/otp.dart';
import '../screens/auth/otp_login.dart';
import '../screens/splash_screen.dart';
import '../services/api_service.dart';
import '../services/storage_services.dart';

class signinState {
  final FormGroup loginForm;
  final UserModel? userInfo;
  final bool isLoading;
  final bool isVerifyLoading;
  final TextEditingController? mobileOtp;
  final String? otpPin;
  final String attemptMsg;
  final String? otpType;
  final int? remainingSeconds;

  signinState({
    required this.loginForm,
    this.isLoading = false,
    this.isVerifyLoading = false,
    this.mobileOtp,
    this.otpType,
    this.attemptMsg="",
    this.userInfo,
    this.otpPin,
    this.remainingSeconds,
  });

  signinState copyWith({
    FormGroup? loginForm,
    bool? isLoading,
    UserModel? userInfo,
    bool? isVerifyLoading,
    String? otpPin,
    String? attemptMsg,
    String? otpType,
    int? remainingSeconds,
    TextEditingController? mobileOtp,
  }) {
    return signinState(
      loginForm: loginForm ?? this.loginForm,
      userInfo: userInfo ?? this.userInfo,
      isLoading: isLoading ?? this.isLoading,
      isVerifyLoading: isVerifyLoading ?? this.isVerifyLoading,
      mobileOtp: mobileOtp ?? this.mobileOtp,
      otpType: otpType ?? this.otpType,
      attemptMsg: attemptMsg ?? this.attemptMsg,
      otpPin: otpPin ?? this.otpPin,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    );
  }
}


final countdownTimerProvider = StateNotifierProvider<CountdownTimerNotifier, int>(
      (ref) => CountdownTimerNotifier(),
);

final resendTriggerProvider = StateProvider<bool>((ref) => false);


class CountdownTimerNotifier extends StateNotifier<int> {
  Timer? _timer;

  CountdownTimerNotifier() : super(0);

  void startTimer() {
    if (_timer != null && _timer!.isActive) return; // Prevent multiple timers
    state = 90;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state > 0) {
        state--;
      } else {
        timer.cancel();
      }
    });
  }

  bool get isRunning => state > 0; // Helper to check timer status

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}



class SigninProvider extends StateNotifier<signinState> {

  late FirebaseMessaging _messaging;
  String? tokens;
  String? deviceId;
  Isolate? isolate;
  late ReceivePort receivePort;

  SigninProvider() : super(signinState(
      loginForm: FormGroup({
        "Email": FormControl<String>(validators: [Validators.required, Validators.email]),
        "Password": FormControl<String>(validators: [Validators.required]),
        "ipAddress": FormControl(value: ""),
        "loginMethod": FormControl(value: "Web-LoginWithPassword"),
      }),
    ),);

  Future<String?> getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      return (await deviceInfo.androidInfo).id;
    } else if (Platform.isIOS) {
      return (await deviceInfo.iosInfo).identifierForVendor;
    }
    return null;
  }

  setEmailMobileValue(value){
    state=state.copyWith(mobileOtp:value);
  }

  setOtpPin(value){
    state=state.copyWith(otpPin:value);
  }


  setOtpType(context,value){
    state=state.copyWith(otpType: value);
    Navigator.push(context, MaterialPageRoute(builder: (context)=> SignInEmailMobileView()));
  }


  void navigateToLogin(BuildContext context) async {
    await StorageServices.delete("userInfo");
    await StorageServices.delete('accessToken');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => SignIn()),
          (route) => false,
    );
    ToastService.showErrorSnackbar(context, 'Sorry Your Token has been expired');
  }


  Future<void> signIn(BuildContext context) async {
    try {
      state = state.copyWith(isLoading: true, attemptMsg: '');

      final email = state.loginForm.value['Email']?.toString().trim() ?? '';
      final password = state.loginForm.value['Password']?.toString().trim() ?? '';

      final Map<String, dynamic> body = {
        "Mobile": "",
        "Email": email,
        "Password": password,
        "IP": "27.4.25.58",
        "DeviceId": "",
        "FCMToken": '',
        "IsMobile": 0
      };

      log("Request body: $body");

      final response = await ApiService().post(
        '/user/login',
        body,
        encrypt: true,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 500) {
        _handleServerError(context,response);
        return;
      }

      if (response.statusCode != 200) {
        return;
      }

      if (response.data == null || !response.data.containsKey('encryptedData') || !response.data.containsKey('iv')) {
        return;
      }

      final res = ApiService().decryptData(response.data['encryptedData']!, response.data['iv']!);

      if (res['Status'] == "Success") {
        await _handleSuccessfulLogin(res, context);
      } else {
        final errorMessage = res['message'] ?? 'Login failed. Please try again.';
        ToastService.showErrorSnackbar(context,errorMessage.toString());
      }

    } catch (e) {
      log('Unexpected error in signIn: $e');
    } finally {
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  void _handleServerError(context,response) {
    final res = ApiService().decryptData(
        response.data['encryptedData']!,
        response.data['iv']!
    );
    String errorMessage;

    switch (response.statusCode) {
      case 500:
        errorMessage = res['message'].toString();
        break;
      default:
        errorMessage = 'Server error (${response.statusCode}). Please try again later.';
    }
    ToastService.showErrorSnackbar(context,errorMessage);
  }



  Future<void> _handleSuccessfulLogin(
      Map<String, dynamic> response, BuildContext context) async {
    await StorageServices.delete("userInfo");
    await StorageServices.delete("accessToken");
    final userData = response['UserDetails'];
    final authToken = response['Token'];

    final UserModel newUser = UserModel.fromJson(userData);
    await StorageServices.write('userInfo', newUser.toJson());
    await StorageServices.write('accessToken', authToken);

    // Update state
    state = state.copyWith(
      isLoading: false,
      userInfo: newUser,
      attemptMsg: '',
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => SplashScreen()),
          (route) => false,
    );
  }


  Future<String> getFCMToken() async {
    _messaging = FirebaseMessaging.instance;
    final token = await _messaging.getToken();
    return token ?? ""; // Handle null case
  }


  void _showErrorSnackbar(context,String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }


  void signInWithEmailOtp(BuildContext context, emailController, WidgetRef ref) async {
    state = state.copyWith(mobileOtp: emailController);

    final token = await getFCMToken();
    Map<String, dynamic> body = {
      "Mobile": "",
      "Email": emailController.text.trim(),
      "Password": "",
      "IP": "",
      "DeviceId": deviceId ?? "", // Handle potential null deviceId
      "FCMToken": token ?? "",
      "IsMobile": 1
    };

    log("body$body");

    try {
      // Show loading state before API call
      state = state.copyWith(isLoading: true);
      final response = await ApiService().post('/user/login', body, encrypt: true,);
      final res=  ApiService().decryptData(response.data['encryptedData']!, response.data['iv']);
      if (res != null) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => OtpScreen()));
      }

    } catch (e) {
      state = state.copyWith(isLoading: false);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void  verifyOtp(context,var otp) async {
    state = state.copyWith(isVerifyLoading: true);
    deviceId = await getDeviceId();
    Map<String, dynamic> body = {
      "Email": state.mobileOtp!.text.toString().trim(),
      "Mobile":"",
      "OTP":otp,
      "ISLogin": 1
    };
    log("body${body.toString()}");
    try {
      final response = await ApiService().post('/user/verify/otp', body, encrypt: true,);
      final res=  ApiService().decryptData(response.data['encryptedData']!, response.data['iv']);

      if (res!=null) {
        var data = res['UserDetails'];
        var token = res['Token'];

        await StorageServices.delete("userInfo");
        await StorageServices.delete("token");

        UserModel newUser = UserModel.fromJson(data);

        await StorageServices.write('userInfo', newUser.toJson());
        await StorageServices.write('token',token);

        state = state.copyWith(isVerifyLoading: false);

        Navigator.push(
            context, MaterialPageRoute(builder: (context) => Home()));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Otp verified Successfully')),
        );
        state = state.copyWith(isVerifyLoading: false);
      } else {
        state = state.copyWith(isVerifyLoading: false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['Message'])),
        );
      }
    }  catch (e) {
      print(e);
      state = state.copyWith(isVerifyLoading: false);
    }
  }

  void  forgotVerifyOtp(context,var otp) async {
    deviceId = await getDeviceId();
    state = state.copyWith(isVerifyLoading: true);

    Map<String, dynamic> body = {
    "Email": state.mobileOtp!.text.toString().trim(),
    "Mobile":"",
    "OTP":otp,
    "ISLogin": 0
    };

    log("body${body.toString()}");
    try {
      final response = await ApiService().post('/api/resident/resloginotpvalidation', body, encrypt: true,);
      final res=  ApiService().decryptData(response.data['encryptedData']!, response.data['iv']);

      if (res['success']) {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => changepassword()));


        Fluttertoast.showToast(
          msg: "Otp verified Successfully",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.SNACKBAR,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 14.0,
        );
        state = state.copyWith(isVerifyLoading: false);
      } else {
        state = state.copyWith(isVerifyLoading: false);
        _showErrorSnackbar(context,res['message']);
      }
    }  catch (e) {
      state = state.copyWith(isVerifyLoading: false);
    }finally{
      state = state.copyWith(isVerifyLoading: false);
    }
  }

  void  updatePassword(context,var password) async {
    state = state.copyWith(isLoading: true);

    Map<String, dynamic> body = {
      "Email": state.mobileOtp!.text.toString().trim(),
      "Pwd": password.toString().trim(),
    };

    log("body${body.toString()}");
    try {

      dynamic response = await ApiService().put('https://dev-hrms-backend.azurewebsites.net/api/resident/updatepassword', body);
      final res=  ApiService().decryptData(response.data['encryptedData']!, response.data['iv']);
      log("response${response.toString()}");
      if (res!=null) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => SignIn()));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password Updated Successfully')),
        );

        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'])),
        );

      }
    }  catch (e) {
      state = state.copyWith(isLoading: false);
    }finally{
      state = state.copyWith(isLoading: false);
    }
  }

  void  resentOtp(WidgetRef ref) async {
    state = state.copyWith(isLoading: true);
    Map<String, dynamic> body = {
      "Email": state.mobileOtp?.text.toString().trim()
    };
    log(body.toString());
    try {
      final response = await ApiService().post('/api/Resident/GenerateOTP', body, encrypt: true,);
      final res=  ApiService().decryptData(response.data['encryptedData']!, response.data['iv']);
      if (res['status']==200) {
        Fluttertoast.showToast(
          msg: res['message'],
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.SNACKBAR,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 14.0,
        );
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

final signInProvider = StateNotifierProvider<SigninProvider, signinState>((ref) {
  return SigninProvider();
});


class EmailValidator {
  static bool validate(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    return emailRegex.hasMatch(email);
  }
}