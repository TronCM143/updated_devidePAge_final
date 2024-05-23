import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'device_operations.dart';

class DevicesPage extends StatefulWidget {
  DevicesPage({Key? key}) : super(key: key);

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  List<Map<String, dynamic>> _deviceRequests = [];
  List<Map<String, dynamic>> _pairedDevices = [];
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _fetchPairedDevices();
    _fetchDeviceRequests(); // Fetch device requests on page load
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  void _fetchPairedDevices() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String currentDeviceEmail = user.email!;
      QuerySnapshot pairedDevicesSnapshot = await FirebaseFirestore.instance
          .collection('googleAccounts')
          .doc(currentDeviceEmail)
          .collection('pairedDevices')
          .get();

      List<Map<String, dynamic>> pairedDevices = [];
      for (var doc in pairedDevicesSnapshot.docs) {
        pairedDevices.add(doc.data() as Map<String, dynamic>);
      }

      if (_isMounted) {
        setState(() {
          _pairedDevices = pairedDevices;
        });
      }
    }
  }

  void _fetchDeviceRequests() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String currentDeviceEmail = user.email!;
      QuerySnapshot requestsSnapshot = await FirebaseFirestore.instance
          .collection('googleAccounts')
          .doc(currentDeviceEmail)
          .collection('deviceRequests')
          .get();

      List<Map<String, dynamic>> deviceRequests = [];
      for (var doc in requestsSnapshot.docs) {
        deviceRequests.add(doc.data() as Map<String, dynamic>);
      }

      if (_isMounted) {
        setState(() {
          _deviceRequests = deviceRequests;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Devices'),
          actions: [
            IconButton(
              onPressed: () => DeviceOperations.viewRequests(
                  context, _deviceRequests, _acceptRequest, _cancelRequest),
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
                        return Container(
                          padding: EdgeInsets.all(16),
                          margin:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email: ${device['email']}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text('Name: ${device['name'] ?? 'N/A'}'),
                              Text('Age: ${device['age'] ?? 'N/A'}'),
                              Text(
                                  'Device Model: ${device['deviceModel'] ?? 'N/A'}'),
                            ],
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text('No paired devices.'),
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _sendDeviceRequest('email@example.com'),
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  Future<DocumentSnapshot> _getPersonalInfo() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String currentDeviceEmail = user.email!;
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('googleAccounts')
          .doc(currentDeviceEmail)
          .collection('personalInfo')
          .doc('info')
          .get();

      return doc;
    } else {
      throw Exception('No authenticated user');
    }
  }

  void _acceptRequest(Map<String, dynamic> request) async {
    DeviceOperations.acceptRequest(request, _fetchPairedDeviceDetails, context);
  }

  void _cancelRequest(Map<String, dynamic> request) async {
    DeviceOperations.cancelRequest(
      request,
      _deviceRequests,
      () => setState(() {}),
    );
  }

  void _sendDeviceRequest(String email) async {
    String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
    DeviceOperations.showAddDeviceDialog(context, email, currentUserEmail);
  }

  void _fetchPairedDeviceDetails(String email) {
    DeviceOperations.fetchPairedDeviceDetails(
      email,
      _pairedDevices,
      () => setState(() {}),
      context,
    );
  }
}
