import 'package:ebv/screens/voip/voip_view.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';


class DialPadScreen extends StatefulWidget {
  const DialPadScreen({super.key});

  @override
  State<DialPadScreen> createState() => _DialPadScreenState();
}

class _DialPadScreenState extends State<DialPadScreen> {

  String enteredNumber = '';
  final double buttonSize = 60.0;

  void onNumberPressed(String number) {
    if(enteredNumber.length<=12){
      setState(() {
        enteredNumber += number;
      });
    }
  }

  void onDeletePressed() {
    if (enteredNumber.isNotEmpty) {
      setState(() {
        enteredNumber = enteredNumber.substring(0, enteredNumber.length - 1);
      });
    }
  }

  Future<void> makeCall() async {
    if(enteredNumber.length>6 && enteredNumber.isNotEmpty){
      // _showCustomDialog(context,enteredNumber);
    }else{
      Fluttertoast.showToast(
        msg: "Enter Your valid Number",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.grey[300],
        textColor: Colors.black,
        fontSize: 14.0,
      );
    }
  }


  void _showCustomDialog(BuildContext context,enteredNumber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Call Confirmation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Would you like to call this number?'),
              const SizedBox(height: 16),
              Text('$enteredNumber',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[300],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                         Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>VOIPView()));
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.call, size: 20),
                          SizedBox(width: 8),
                          Text('Call'),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VOIP DIALPAD',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          leading: IconButton(onPressed: ()=> Navigator.pop(context), icon: Icon(Icons.arrow_back_ios_new,color: Colors.white,)),
          title: const Text('VOIP CALL', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          backgroundColor: Colors.blue[800],
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SafeArea(
          child: Column(
            children: [

              SizedBox(height: 10,),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      border: Border.all(color: Colors.grey)),
                  margin: const EdgeInsets.only(top: 30, bottom: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 30,vertical: 8),
                  alignment: Alignment.center,
                  child: Text(
                    enteredNumber.isEmpty ? '00 00 00 00 00' : enteredNumber,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 10,),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: GridView.count(
                    crossAxisCount: 3,
                    childAspectRatio: 1.1,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // Numbers 1-9
                      for (int i = 1; i <= 9; i++)
                        DialButton(
                          number: i.toString(),
                          letters: _getLettersForNumber(i),
                          onPressed: onNumberPressed,
                          size: buttonSize,
                          backgroundColor: Colors.white,
                          textColor: Colors.blue[800]!,
                          letterColor: Colors.grey[600]!,
                        ),

                      // Asterisk button
                      DialButton(
                        number: '*',
                        letters: '',
                        onPressed: onNumberPressed,
                        size: buttonSize,
                        backgroundColor: Colors.grey[200]!,
                        textColor: Colors.blue[800]!,
                      ),

                      // Zero button
                      DialButton(
                        number: '0',
                        letters: '+',
                        onPressed: onNumberPressed,
                        size: buttonSize,
                        backgroundColor: Colors.white,
                        textColor: Colors.blue[800]!,
                        letterColor: Colors.grey[600]!,
                      ),

                      // Pound button
                      DialButton(
                        number: '#',
                        letters: '',
                        onPressed: onNumberPressed,
                        size: buttonSize,
                        backgroundColor: Colors.grey[200]!,
                        textColor: Colors.blue[800]!,
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom action buttons
              Padding(
                padding: const EdgeInsets.all(30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Delete button
                    GestureDetector(
                      onTap: onDeletePressed,
                      onLongPress: () {
                        setState(() {
                          enteredNumber = '';
                        });
                      },
                      child: Container(
                        width: buttonSize,
                        height: buttonSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[300],
                        ),
                        child: Icon(Icons.backspace,
                            size: 28,
                            color: Colors.grey[700]),
                      ),
                    ),

                    // Call button
                    FloatingActionButton(
                      onPressed: makeCall,
                      backgroundColor: Colors.green[600],
                      elevation: 5,
                      child: const Icon(Icons.call,
                          size: 28,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLettersForNumber(int number) {
    switch (number) {
      case 2: return 'ABC';
      case 3: return 'DEF';
      case 4: return 'GHI';
      case 5: return 'JKL';
      case 6: return 'MNO';
      case 7: return 'PQRS';
      case 8: return 'TUV';
      case 9: return 'WXYZ';
      default: return '';
    }
  }
}

class DialButton extends StatelessWidget {
  final String number;
  final String letters;
  final Function(String) onPressed;
  final double size;
  final Color backgroundColor;
  final Color textColor;
  final Color? letterColor;

  const DialButton({
    super.key,
    required this.number,
    required this.letters,
    required this.onPressed,
    required this.size,
    required this.backgroundColor,
    required this.textColor,
    this.letterColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onPressed(number),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              number,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            if (letters.isNotEmpty)
              Text(
                letters,
                style: TextStyle(
                  fontSize: 12,
                  color: letterColor ?? textColor.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}