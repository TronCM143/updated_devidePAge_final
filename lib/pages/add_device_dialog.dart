import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddDeviceDialog extends StatefulWidget {
  final Function(String email) onEmailMatched;

  const AddDeviceDialog({required this.onEmailMatched, Key? key})
      : super(key: key);

  @override
  _AddDeviceDialogState createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<AddDeviceDialog> {
  final TextEditingController _emailController = TextEditingController();
  bool _isChecking = false;
  bool _isMatched = false;
  String? _errorMessage;
  bool _isEmailFound = false;

  void _sendDeviceRequest(String email, String currentUserEmail) async {
    try {
      // Add the email as a document under the "deviceRequests" subcollection of the current user
      await FirebaseFirestore.instance
          .collection('googleAccounts')
          .doc(currentUserEmail)
          .collection('deviceRequests')
          .doc(email)
          .set({
        'sentRequestFrom': currentUserEmail,
        'sentRequestTo': email,
        // Add more details if needed.
      });

      // Also, add the request under the "acceptRequest" subcollection of the requested user
      await FirebaseFirestore.instance
          .collection('googleAccounts')
          .doc(email)
          .collection('acceptRequest')
          .doc(currentUserEmail)
          .set({
        'sentRequestFrom': currentUserEmail,
      });

      // Show a confirmation snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Device request sent to $email'),
        ),
      );

      // Delay the popping of the dialog until after the animation has completed
      Future.delayed(Duration(milliseconds: 500), () {
        Navigator.pop(context);
      });
    } catch (error) {
      // Handle errors if necessary
      print("Error sending device request: $error");
      // Show an error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending device request'),
        ),
      );
    }
  }

  void _checkEmail() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null; // Reset error message
      _isEmailFound = false; // Reset email found flag
    });

    String email = _emailController.text.trim();

    if (email.isNotEmpty) {
      // Check if email is not empty
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('googleAccounts')
          .doc(email)
          .get();

      if (doc.exists) {
        // Email exists in "googleAccounts" collection
        setState(() {
          _isMatched = true; // Set _isMatched to true if device is found
          _isEmailFound = true; // Set email found flag to true
        });

        // Check if the email exists in the "deviceRequests" subcollection
        DocumentSnapshot deviceRequestDoc = await FirebaseFirestore.instance
            .collection('googleAccounts')
            .doc(FirebaseAuth.instance.currentUser!.email)
            .collection('deviceRequests')
            .doc(email)
            .get();

        if (deviceRequestDoc.exists) {
          setState(() {
            _errorMessage = 'Email already exists in device requests!';
          });
        }
      } else {
        // Email not found in "googleAccounts" collection
        setState(() {
          _isMatched = false; // Set _isMatched to false if device is not found
          _errorMessage = 'Email not found!';
        });
      }
    } else {
      setState(() {
        _isMatched = false;
        _errorMessage =
            'Please enter a valid email'; // Provide an error message for empty email
      });
    }

    setState(() {
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Device'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Device Email',
              errorText: _errorMessage,
              // Conditionally set text color based on email found flag
              labelStyle: TextStyle(
                color: _isEmailFound ? Colors.green : Colors.black,
              ),
            ),
          ),
          SizedBox(height: 20),
          if (_isChecking) CircularProgressIndicator(),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: _isMatched
              ? () => _sendDeviceRequest(
                    _emailController.text.trim(),
                    FirebaseAuth.instance.currentUser!.email!,
                  )
              : null,
          child: Text('Add'),
        ),
        ElevatedButton(
          onPressed: _checkEmail,
          child: Text('Check'),
        ),
      ],
    );
  }
}
