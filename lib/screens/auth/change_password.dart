import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/signIn_provider.dart';

class ChangePassword extends ConsumerStatefulWidget {
  const ChangePassword({super.key});

  @override
  _ChangePasswordState createState() => _ChangePasswordState();
}

class _ChangePasswordState extends ConsumerState<ChangePassword> {
  late SignInNotifier signInNotifier;
  late TextEditingController changePassword;

  @override
  void initState() {
    super.initState();
    changePassword = TextEditingController();

    Future.microtask(() {
      ref.read(signInProvider.notifier).readUser();
      signInNotifier = ref.read(signInProvider.notifier);
    });
    super.initState();
  }

  @override
  void dispose() {
    changePassword.dispose();
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
              const Text('Change Your Password',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
               Text(
                '${state.userInfo?.email.toString()}',
                textAlign: TextAlign.start,
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: changePassword,
                textAlign: TextAlign.start,
                keyboardType: TextInputType.text,
                style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 14),
                decoration: InputDecoration(
                  suffixIcon:
                      const Icon(Icons.mobile_friendly, color: Colors.black),
                  border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5))),
                  fillColor: Colors.grey[200],
                  hintText: 'John@gmail.com',
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 14.0),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                  child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    signInNotifier.updatePassword(context, changePassword.text);
                  },
                  style: ButtonStyle(
                    backgroundColor:
                    MaterialStateProperty.all<Color>(Color(0xFF8548D0)),
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
                        visible: state.isLoading,
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
                        'Update Password',
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
              // Text("userInfo${state.userInfo?.email.toString()}")

            ],
          ),
        ),
      ),
    );
  }
}
