import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../pages/home_page.dart';

class PersonalInfoPage extends StatefulWidget {
  final User user;

  const PersonalInfoPage({Key? key, required this.user}) : super(key: key);

  @override
  _PersonalInfoPageState createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _deviceModelController = TextEditingController();

  Future<void> _submitPersonalInfo() async {
    if (_formKey.currentState!.validate()) {
      String firstName = _firstNameController.text.trim();
      String lastName = _lastNameController.text.trim();
      int age = int.parse(_ageController.text.trim());
      String deviceModel = _deviceModelController.text.trim();

      // Save the personal information to Firestore
      await FirebaseFirestore.instance
          .collection('googleAccounts')
          .doc(widget.user.email)
          .collection('personalInfo')
          .doc('info') // Use a fixed document ID
          .set({
        'uid': widget.user.uid,
        'email': widget.user.email,
        'firstName': firstName,
        'lastName': lastName,
        'age': age,
        'deviceModel': deviceModel,
      });

      // Navigate to the HomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => HomePage(
                  email: '',
                )),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Personal Information'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(labelText: 'First Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(labelText: 'Last Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your age';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid age';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _deviceModelController,
                decoration: InputDecoration(labelText: 'Device Model'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your device model';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitPersonalInfo,
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
