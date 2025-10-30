import 'package:ebv/screens/home/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ebv/provider/patient_provider.dart';

class VOIPView extends ConsumerStatefulWidget {
  final String? patientId,selectedCountry;
  const VOIPView({super.key, this.patientId,this.selectedCountry});

  @override
  ConsumerState<VOIPView> createState() => _VOIPViewState();
}

class _VOIPViewState extends ConsumerState<VOIPView> {
  String errorMessage = "";
  bool webViewReady = false;
  late final void Function(String selectedCountry)? onCountrySelected;
  late final Uri VoipUri;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(patientProvider.notifier).readUser();
    });

    if(widget.selectedCountry=="US"){
      VoipUri = Uri.parse(
        Uri.encodeFull(
          'https://calldesk.pulsework360.com/Dialer/3996c82aa955ab45fcc76f39d217f371/clicktocallpage.php?userID=2711002&secret=Clubuser@1002&authID=3996c82aa955ab45fcc76f39d217f371&data=${widget.patientId}_bab44c3f-495e-4e7f-b5e0-dc6fa3c57eeb',
        ),
      );
    }else{
      VoipUri = Uri.parse(
        Uri.encodeFull(
            'https://calldesk.pulsework360.com/Dialer/3996c82aa955ab45fcc76f39d217f371/clicktocallpage.php?userID=2711001&secret=Clubuser@1001&authID=3996c82aa955ab45fcc76f39d217f371&data=${widget.patientId}_bab44c3f-495e-4e7f-b5e0-dc6fa3c57eeb'
        ),
      );

    }

    _initializePermissions();
  }

  Future<void> _initializePermissions() async {
    final micStatus = await Permission.microphone.request();

    if (!micStatus.isGranted) {
      setState(() {
        errorMessage = "Microphone permission denied. Please enable it in app settings.";
      });
    }
  }

  Future<void> _launchVoipURL(Uri uri,String phoneNumber) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
        webViewConfiguration: const WebViewConfiguration(enableJavaScript: true),
      );
      Future.delayed(const Duration(seconds: 10), () {
        // ref.read(patientProvider.notifier).fetchVOIP(widget.patientId,phoneNumber,widget.selectedCountry);

      });
      if (!launched) {
        setState(() => errorMessage = "Could not launch VOIP URL.");
      } else {
        setState(() => webViewReady = true);
      }
    } catch (e) {
      setState(() => errorMessage = "Failed to launch URL: $e");
    }
  }

  String selected = 'IN'; // Default selection

  void _selectCountry(String country) {
    setState(() {
      selected = country;
    });
    onCountrySelected?.call(country);
  }


  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(patientProvider.notifier);
    final state = ref.watch(patientProvider);
    double buttonWidth = MediaQuery.of(context).size.width * 0.85;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("VOIP"),
        actions: [Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(widget.patientId.toString()),
        )],
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20,),
            const Text(
              "Click to Call",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),

            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(errorMessage, style: const TextStyle(color: Colors.red)),
              ),

            SizedBox(
              width: buttonWidth,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.call),
                label: const Text('  IVR (Primary) - 18887225505'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.green,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.green),
                ),
                onPressed: () async {
                  await _launchVoipURL(VoipUri, '18887225505');
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: buttonWidth,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.phone),
                label: const Text('IVR (Secondary) - 18002446224'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.blue),
                ),
                onPressed: webViewReady
                    ? () => _launchVoipURL(VoipUri, '18002446224')
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: buttonWidth,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.home),
                label: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 60.0),
                  child: Text('Go Home'),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                ),
                onPressed: () {
                 Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home(),));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String countryCode) {
    final bool isSelected = selected == countryCode;
    return ElevatedButton(
      onPressed: () => _selectCountry(countryCode),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey.shade300,
        foregroundColor: isSelected ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(countryCode),
    );
  }
}

