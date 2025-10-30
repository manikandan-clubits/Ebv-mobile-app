import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../screens/auth/email_login.dart';
import '../services/storage_services.dart';

class ShoeAlert extends StatelessWidget {
  final String message;

  ShoeAlert({required this.message});

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(
        'Are you sure you want to Logout?',
        style: TextStyle(fontSize: 18),
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text('You will be returned to the login screen'),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () {
            Navigator.pop(context);
          },
          isDestructiveAction: true, // Red color for cancel
          child: Text('Cancel'),
        ),
        CupertinoDialogAction(
          onPressed: () async {
            await StorageServices.delete("userInfo");
            await StorageServices.delete("roleData");
            Navigator.pushReplacement(
              context,
              CupertinoPageRoute(builder: (context) => SignIn()),
            );
          },
          isDefaultAction: true, // Green color for logout
          child: Text('Logout'),
        ),
      ],
    );
  }
}

// Function to show the exit confirmation dialog
Future<bool?> showExitConfirmationDialog(BuildContext context) {
  return showCupertinoDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return CupertinoAlertDialog(
        title: Text('Exit App'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text('Are you sure you want to exit the app?'),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            isDestructiveAction: true,
            child: Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(true),
            isDefaultAction: true,
            child: Text('Exit'),
          ),
        ],
      );
    },
  );
}


Future<bool?> showOtpExitDialog(BuildContext context) {
  return showCupertinoDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return CupertinoAlertDialog(
        title: Text('Info'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text("You can't Back to Screen."),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            isDestructiveAction: true,
            child: Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(true),
            isDefaultAction: true,
            child: Text('Exit'),
          ),
        ],
      );
    },
  );
}
