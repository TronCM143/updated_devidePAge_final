import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_device_dialog.dart';

class DeviceOperations {
  static void viewRequests(
      BuildContext context,
      List<Map<String, dynamic>> deviceRequests,
      Function(Map<String, dynamic>) _acceptRequest,
      Function(Map<String, dynamic>) _cancelRequest) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String currentDeviceEmail = user.email!;

      FirebaseFirestore.instance
          .collection('googleAccounts')
          .doc(currentDeviceEmail)
          .collection('deviceRequests')
          .get()
          .then((querySnapshot) {
        List<Map<String, dynamic>> requests = [];
        querySnapshot.docs.forEach((doc) {
          requests.add(doc.data() as Map<String, dynamic>);
        });

        deviceRequests.clear();
        deviceRequests.addAll(requests);

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Device Requests'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: deviceRequests.map((request) {
                  return ListTile(
                    title: Text(request['requesterEmail'] ?? 'Unknown Email'),
                    subtitle: Text(
                        'Added by: ${request['requesterEmail'] ?? 'Unknown Email'}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _acceptRequest(request),
                          icon: Icon(Icons.check),
                        ),
                        IconButton(
                          onPressed: () => _cancelRequest(request),
                          icon: Icon(Icons.close),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      });
    }
  }

  static void acceptRequest(Map<String, dynamic> request,
      Function(String) _fetchPairedDeviceDetails, BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String currentDeviceEmail = user.email!;

      DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore
          .instance
          .collection('googleAccounts')
          .doc(request['requesterEmail'])
          .collection('personalInfo')
          .doc('info')
          .get();

      if (doc.exists) {
        var deviceInfo = doc.data();
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Requested Device Info'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Email: ${request['requesterEmail'] ?? 'Unknown Email'}'),
                  Text(
                      'Name: ${deviceInfo?['firstName'] ?? 'Unknown'} ${deviceInfo?['lastName'] ?? 'Unknown'}'),
                  Text('Age: ${deviceInfo?['age'] ?? 'Unknown'}'),
                  Text(
                      'Device Model: ${deviceInfo?['deviceModel'] ?? 'Unknown'}'),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('googleAccounts')
                        .doc(currentDeviceEmail)
                        .collection('pairedDevices')
                        .doc(request['requesterEmail'])
                        .set({'email': request['requesterEmail']});

                    await FirebaseFirestore.instance
                        .collection('googleAccounts')
                        .doc(request['requesterEmail'])
                        .collection('acceptDevice')
                        .doc(currentDeviceEmail)
                        .set({'email': currentDeviceEmail});

                    _fetchPairedDeviceDetails(request['requesterEmail']);
                    Navigator.pop(context);
                  },
                  child: Text('Confirm'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
              ],
            );
          },
        );

        FirebaseFirestore.instance
            .collection('googleAccounts')
            .doc(currentDeviceEmail)
            .collection('deviceRequests')
            .doc(request['requesterEmail'])
            .delete();
      }
    }
  }

  static void cancelRequest(Map<String, dynamic> request,
      List<Map<String, dynamic>> deviceRequests, VoidCallback setState) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String currentDeviceEmail = user.email!;
      FirebaseFirestore.instance
          .collection('googleAccounts')
          .doc(currentDeviceEmail)
          .collection('deviceRequests')
          .doc(request['requesterEmail'])
          .delete()
          .then((_) {
        setState(); // Removed the argument from setState
        deviceRequests.remove(request);
      });
    }
  }

  static void fetchPairedDeviceDetails(
      String email,
      List<Map<String, dynamic>> pairedDevices,
      VoidCallback setState,
      BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String currentDeviceEmail = user.email!;
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('googleAccounts')
          .doc(email)
          .collection('personalInfo')
          .doc('info')
          .get();

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        String fullName =
            '${data['firstName'] ?? 'Unknown'} ${data['lastName'] ?? 'Unknown'}';
        var device = {
          'email': email,
          'name': fullName,
          'age': data['age'] ?? 'Unknown',
          'deviceModel': data['deviceModel'] ?? 'Unknown',
        };

        if (!pairedDevices.any((d) => d['email'] == email)) {
          setState(); // Removed the argument from setState
          pairedDevices.add(device);

          await FirebaseFirestore.instance
              .collection('googleAccounts')
              .doc(currentDeviceEmail)
              .collection('pairedDevices')
              .doc(email)
              .set(device);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Device is already paired.')),
          );
        }
      }
    }
  }

  static void showAddDeviceDialog(
      BuildContext context, String email, String currentUserEmail) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddDeviceDialog(
          onEmailMatched: (email) async {
            _sendDeviceRequest(email, currentUserEmail, context);
          },
        );
      },
    );
  }

  static void _sendDeviceRequest(
      String email, String currentUserEmail, BuildContext context) async {
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('googleAccounts')
        .doc(email)
        .get();

    if (userSnapshot.exists) {
      await FirebaseFirestore.instance
          .collection('googleAccounts')
          .doc(email)
          .collection('deviceRequests')
          .doc(currentUserEmail)
          .set({
        'requesterEmail': currentUserEmail,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Device request sent to $email'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User with email $email does not exist'),
        ),
      );
    }
  }
}
