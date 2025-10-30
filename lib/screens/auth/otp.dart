import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../../enums.dart';
import '../../provider/signIn_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  late SigninProvider signInNotifier;
  late TextEditingController otp;


  @override
  void initState() {
    super.initState();
    otp = TextEditingController();

    Future.microtask(() {
      signInNotifier = ref.read(signInProvider.notifier);

    });
    super.initState();
  }



  @override
  void dispose() {
    otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signInProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Image.asset(
                'assets/images/sms.png',
                height: 56,
                width: 56,
              ),

              const SizedBox(height: 15),
              const Text('Check Your SMS | Email',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'We sent an OTP to',
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(width:5,),
                  Expanded(
                    child: Text(
                      state.mobileOtp!.text,
                      style: const TextStyle(fontSize: 14,color: Colors.blue),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),


    const SizedBox(height: 25),

              PinFieldAutoFill(
                controller: otp,
                keyboardType: TextInputType.number,
                autoFocus: true,
                decoration: BoxLooseDecoration(
                  radius: const Radius.circular(10),
                  strokeColorBuilder: const FixedColorBuilder(Colors.grey),
                ),
                codeLength: 6,
              ),

              const SizedBox(height: 20),


              Center(
                  child: SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: () {
                    if(otp.text.isNotEmpty) {
                      if (state.otpType == MethodType.forgotPassword) {
                        FocusScope.of(context).unfocus();
                        signInNotifier.forgotVerifyOtp(context, otp.text);
                      } else {
                        FocusScope.of(context).unfocus();
                        signInNotifier.verifyOtp(context, otp.text);
                      }
                    }
                  },
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.grey),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Visibility(
                        visible: state.isVerifyLoading,
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Text(
                        'Verify OTP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn't receive the OTP?"),
                  const SizedBox(width: 10),

                  Consumer(
                    builder: (context, ref, child) {
                      final timerValue = ref.watch(countdownTimerProvider);
                      final timerNotifier = ref.read(countdownTimerProvider.notifier);
                      final isResending = ref.watch(resendTriggerProvider);

                      return Row(
                        children: [
                          timerValue == 0
                              ? GestureDetector(
                            onTap: () {
                              if (isResending) return; // Prevent multiple resends
                              ref.read(resendTriggerProvider.notifier).state = true;
                              Future.delayed(const Duration(seconds: 1), () {
                                ref.read(resendTriggerProvider.notifier).state = false;
                                timerNotifier.startTimer(); // Restart the timer
                              });
                              signInNotifier.resentOtp(ref);

                            },
                            child: Text(
                              isResending ? "sending..." : "Click to Resend OTP",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                              : Text(
                            "$timerValue sec",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar : Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Text(
          'Copyright © 2025 Genyus. All rights reserved',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
