import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/signIn_provider.dart';
import '../../themes/theme_colors.dart';
import 'email_login.dart';


class SignInEmailMobileView extends ConsumerStatefulWidget {

  @override
  _SignInEmailMobileViewState createState() => _SignInEmailMobileViewState();
}

class _SignInEmailMobileViewState extends ConsumerState<SignInEmailMobileView> {
  late TextEditingController mobileNumber;

  @override
  void initState() {
    super.initState();
    mobileNumber = TextEditingController();
  }

  @override
  void dispose() {
    mobileNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signInProvider);
    var screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: ThemeColor.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.20),
                  Image.asset(
                    width: 200,
                    'assets/images/dentiverify-logo.png',
                  ),
                  SizedBox(height: screenHeight * 0.10),

                  // Mobile/Email Input
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text(
                        'Mobile/Email',
                        textAlign: TextAlign.start,
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                      SizedBox(height: screenHeight * 0.006),
                      TextField(
                        controller: mobileNumber,
                        textAlign: TextAlign.start,
                        keyboardType: TextInputType.text,
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w500, fontSize: 14),
                        decoration: InputDecoration(
                          suffixIcon: const Icon(Icons.mobile_friendly, color: Colors.black),
                          border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(5))),
                          fillColor: Colors.grey[200],
                          hintText: 'John@gmail.com',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.020),



                      // Send OTP Button
                      Center(
                        child: SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF29BFFF),
                                  Color(0xFF8548D0) // Purple end
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent, // Must be transparent
                                shadowColor: Colors.transparent, // Remove default shadow
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                padding: EdgeInsets.zero, // Remove default padding
                              ),
                              onPressed: () {
                                if(mobileNumber.text.isNotEmpty) {
                                  final timerValue = ref.watch(countdownTimerProvider);
                                  final timerNotifier = ref.read(countdownTimerProvider.notifier);
                                  final isResending = ref.watch(resendTriggerProvider);
                                  if (isResending) return;
                                  ref.read(resendTriggerProvider.notifier).state = true;
                                  Future.delayed(const Duration(seconds: 1), () {
                                    ref.read(resendTriggerProvider.notifier).state = false;
                                    timerNotifier.startTimer(); // Restart the timer
                                  });
                                  ref.read(signInProvider.notifier).signInWithEmailOtp(context, mobileNumber,ref);}
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (state.isLoading)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                    ),
                                  const SizedBox(width: 15),
                                  const Text(
                                    'Send',
                                    style: TextStyle(color: ThemeColor.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // SizedBox(height: screenHeight * 0.020),
                      SizedBox(height: screenHeight * 0.010),
                      const Center(child: Text('Or', style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(height: screenHeight * 0.010),

                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SignIn())),

                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),  // Slightly larger radius
                            border: Border.all(
                              color: const Color(0xFF8548D0),  // Using your purple color for border
                              width: 1.5,  // Slightly thicker border
                            ),
                            color: Colors.white,  // White background
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8548D0).withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,  // More horizontal padding
                              vertical: 12,  // More vertical padding
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Back',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,  // Semi-bold instead of bold
                                    fontSize: 16,  // Slightly larger font
                                    color: const Color(0xFF8548D0),
                                    letterSpacing: 0.5,  // Slight letter spacing
                                  ),
                                ),
                                const SizedBox(width: 8),  // Add space between text and icon
                                Icon(
                                  Icons.login,  // Add an icon
                                  color: const Color(0xFF8548D0),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    ],
                  ),
                ],
              ),
            )
          ],
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
