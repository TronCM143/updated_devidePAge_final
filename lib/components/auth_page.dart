import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../pages/home_page.dart';
import 'login_or_register_page.dart';
import 'personal_info_page.dart'; // New page for entering personal information
// Import the DevicesPage

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  Future<bool> checkIfPersonalInfoExists(String email) async {
    DocumentSnapshot personalInfoDoc = await FirebaseFirestore.instance
        .collection('googleAccounts')
        .doc(email)
        .collection('personalInfo')
        .doc('info')
        .get();
    return personalInfoDoc.exists;
  }

  Future<void> storeAuthenticatedEmail(String email) async {
    await FirebaseFirestore.instance
        .collection('googleAccounts')
        .doc(email)
        .set({
      'email': email,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.error != null) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Invalid Credentials',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Montserrat'),
                ),
              ),
            );
          } else if (snapshot.hasData) {
            // if logged in
            User user = snapshot.data!;
            return FutureBuilder<bool>(
              future: checkIfPersonalInfoExists(user.email!),
              builder: (context, AsyncSnapshot<bool> userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (userSnapshot.hasError) {
                  return const Center(child: Text('Error checking user data'));
                } else if (userSnapshot.data == false) {
                  // New user, store email and ask for personal information
                  storeAuthenticatedEmail(user.email!);
                  return PersonalInfoPage(user: user);
                } else {
                  // Existing user with personal info, go to home page
                  return HomePage(
                      email: user.email!); // Pass the email to the DevicesPage
                }
              },
            );
          } else {
            // no account
            return const LoginOrRegisterPage();
          }
        },
      ),
    );
  }
}
