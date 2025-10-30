import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/authenticator_provider.dart';

class Authenticator extends ConsumerStatefulWidget {
  const Authenticator({super.key});

  @override
  ConsumerState<Authenticator> createState() => _AuthenticatorState();
}

class _AuthenticatorState extends ConsumerState<Authenticator> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authenticatorProvider.notifier).readUser());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authenticatorProvider);
    final notifier = ref.read(authenticatorProvider.notifier);
    final email =  state.userInfo?['Email'];
    final otp = state.otp ?? '';
    final isActive = state.response?['Status'] == "Active";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Authenticator', style: TextStyle(
            fontSize: 18, color: Colors.black,fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
             Container(
               width: double.infinity,
               color: Colors.blue,
               child:  Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Row(
                   children: [
                     Container(
                       width: 48,
                       height: 48,
                       decoration: BoxDecoration(
                         color: Colors.white,
                         shape: BoxShape.circle,
                       ),
                       child: const Icon(Icons.security,
                           color: Colors.blue, size: 28),
                     ),
                     const SizedBox(width: 16),
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [

                         const Text('Authentication',
                             style: TextStyle(
                                 fontSize: 16,
                                 fontWeight: FontWeight.bold,
                                 color: Colors.black87)),
                        //  Text(email.toString().isNotEmpty ?email:"--",
                        //      style: const TextStyle(
                        //          fontSize: 14, color: Colors.white)),
                       ],
                     ),
                   ],
                 ),
               ),
               ),
              const SizedBox(height: 28),
              // OTP Card
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ONE-TIME PASSWORD',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue,
                              letterSpacing: 1.0)),
                      const SizedBox(height: 8),


                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isActive ? state.otp.toString() : '••••••',
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4.0)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.green[50]
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(4)),
                            child: Text(!state.isExpired ? 'ACTIVE' : 'INACTIVE',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color:
                                    isActive ? Colors.green : Colors.grey)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (state.isLoading)
                        const LinearProgressIndicator()
                      else if (state.otp != null && !state.isExpired)
                        Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(
                                    'Expires in ${state.remainingSeconds} seconds',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: state.remainingSeconds <= 10
                                            ? Colors.red
                                            : Colors.grey[700])),
                              ],
                            ),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: state.remainingSeconds / 90,
                              backgroundColor: Colors.grey[200],
                              color: state.remainingSeconds <= 10
                                  ? Colors.red
                                  : Colors.blue,
                            ),
                          ],
                        )
                      else if (state.isExpired)
                          Column(
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      size: 16, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('OTP has expired',
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.red)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: notifier.resendOTP,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: const Text('RESEND OTP'),
                                ),
                              ),
                            ],
                          ),
                      const SizedBox(height: 24),

                      // Information Section
                      const Text('Security Tips',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SecurityTipItem(
                              icon: Icons.lock,
                              text: 'Never share your OTP with anyone'),
                          SecurityTipItem(
                              icon: Icons.timer,
                              text: 'OTP expires in 90 seconds'),
                          SecurityTipItem(
                              icon: Icons.warning,
                              text: 'Clubits will never ask for your OTP'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SecurityTipItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const SecurityTipItem({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.black),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
