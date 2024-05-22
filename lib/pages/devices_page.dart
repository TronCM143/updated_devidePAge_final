import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:cloud_firestore/cloud_firestore.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({Key? key}) : super(key: key);

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  Map<String, dynamic>? _personalInfo;
  List<Map<String, dynamic>> _deviceRequests = [];
  List<Map<String, dynamic>> _pairedDevices = [];

  @override
  void initState() {
    super.initState();
    // Fetch personal information of the current device
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Devices'),
          actions: [
            IconButton(
              onPressed: _viewRequests,
              icon: Icon(Icons.notifications),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display current email and personal info in a container
            Padding(
              padding: EdgeInsets.all(16),
              child: FutureBuilder<DocumentSnapshot>(
                future: _getPersonalInfo(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Text('No personal info available for this email');
                  } else {
                    var data = snapshot.data!.data() as Map<String, dynamic>;
                    String fullName =
                        '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}';
                    return Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Email: ${FirebaseAuth.instance.currentUser?.email ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text('Name: $fullName'),
                          Text('Age: ${data['age'] ?? 'N/A'}'),
                          Text('Device Model: ${data['deviceModel'] ?? 'N/A'}'),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
            // Paired devices section
            Expanded(
              child: _pairedDevices.isNotEmpty
                  ? ListView.builder(
                      itemCount: _pairedDevices.length,
                      itemBuilder: (context, index) {
                        var device = _pairedDevices[index];
                        return ListTile(
                          title: Text(device['email']),
                          subtitle: Text(
                            'Name: ${device['name']}, Age: ${device['age']}',
                          ),
                        );
                      },
                    )
                  : Center(
                      child: ElevatedButton(
                        onPressed: () => _addDevice(),
                        child: Text('Add Device'),
                      ),
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _viewRequests,
          child: Icon(Icons.notifications),
        ),
      ),
    );
  }

  Future<DocumentSnapshot> _getPersonalInfo() async {
    // Get the current user from FirebaseAuth
    User? user = FirebaseAuth.instance.currentUser;

    // Check if user is authenticated
    if (user != null) {
      String currentDeviceEmail =
          user.email!; // Get the email of the current user
      // Fetch personal information using the current device's email
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('googleAccounts')
          .doc(currentDeviceEmail)
          .collection('personalInfo')
          .doc(
              'info') // Assuming 'info' is the document ID containing the personal info
          .get();

      return doc;
    } else {
      throw Exception('No authenticated user');
    }
  }

  void _viewRequests() {
    // Fetch device requests from Firestore
    FirebaseFirestore.instance
        .collection('googleAccounts')
        .where('requests', isEqualTo: true)
        .get()
        .then((querySnapshot) {
      List<Map<String, dynamic>> requests = [];
      querySnapshot.docs.forEach((doc) {
        requests.add(doc.data());
      });

      setState(() {
        _deviceRequests = requests;
      });

      // Show pop-up container
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Device Requests'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: _deviceRequests.map((request) {
                return ListTile(
                  title: Text(request['email']),
                  subtitle:
                      Text('Name: ${request['name']}, Age: ${request['age']}'),
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

  void _acceptRequest(Map<String, dynamic> request) {
    // Fetch requested device info from Firestore and display
    // Assuming 'personalInfo' is the subcollection name
    FirebaseFirestore.instance
        .collection('googleAccounts')
        .doc(request['email'])
        .collection('personalInfo')
        .doc('info')
        .get()
        .then((doc) {
      var deviceInfo = doc.data();

      // Display requested device info
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Requested Device Info'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${request['email']}'),
                Text('Name: ${deviceInfo?['name'] ?? 'N/A'}'),
                Text('Age: ${deviceInfo?['age'] ?? 'N/A'}'),
                // Display other device info fields as needed
              ],
            ),
          );
        },
      );
    });

    // Remove request from Firestore
    FirebaseFirestore.instance
        .collection('googleAccounts')
        .doc(request['email'])
        .update({
      'requests': false
    }); // Assuming 'requests' field controls device requests
  }

  void _cancelRequest(Map<String, dynamic> request) {
    // Cancel device request
    // Remove request from Firestore
    FirebaseFirestore.instance
        .collection('googleAccounts')
        .doc(request['email'])
        .update({
      'requests': false
    }); // Assuming 'requests' field controls device requests

    // Update UI
    setState(() {
      _deviceRequests.remove(request);
    });
  }

  void _addDevice() {
    // Implement adding a device
    print('Adding a new device');
  }
}
