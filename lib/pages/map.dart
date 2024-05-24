import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;
import 'package:google_sign_in/google_sign_in.dart';

import '../services/location_service.dart';
import 'select_entity_dialog.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  LatLng? _currentP;
  List<DocumentSnapshot> _accounts = [];
  LatLng? _selectedLocation;
  String? _userEmail;
  BitmapDescriptor? _currentMarkerIcon;
  BitmapDescriptor? _selectedMarkerIcon;
  static const LatLng _pGooglePlex =
      LatLng(6.485651218461966, 124.85593053388185);

  StreamSubscription<LocationData>? _locationSubscription;
  StreamSubscription<DocumentSnapshot>? _selectedUserLocationSubscription;
  String? _profilePictureUrl;

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
    _getLocationUpdates();
    _fetchAccountsFromFirestore();
    _getUserEmail();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _selectedUserLocationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadProfilePicture() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      if (currentUser.providerData.any((userInfo) =>
          userInfo.providerId == GoogleAuthProvider.PROVIDER_ID)) {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final googleUser = await googleSignIn.signInSilently();
        if (googleUser != null) {
          setState(() {
            _profilePictureUrl = googleUser.photoUrl;
          });
          await _storeProfilePictureToFirestore(
              currentUser.email!, _profilePictureUrl);
        }
      } else {
        setState(() {
          _profilePictureUrl = null;
        });
      }
    }
  }

  Future<void> _storeProfilePictureToFirestore(
      String email, String? profilePictureUrl) async {
    try {
      final userRef =
          FirebaseFirestore.instance.collection('googleAccounts').doc(email);
      await userRef
          .set({'profileImageUrl': profilePictureUrl}, SetOptions(merge: true));
      print('Profile picture URL stored to Firestore for user $email');
    } catch (e) {
      print('Error storing profile picture URL to Firestore: $e');
    }
  }

  Future<BitmapDescriptor> _getCustomMarker(String imageUrl) async {
    try {
      final http.Response response = await http.get(Uri.parse(imageUrl));
      final Uint8List bytes = response.bodyBytes;

      final ui.Codec codec =
          await ui.instantiateImageCodec(bytes, targetWidth: 100);
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ByteData? byteData =
          await fi.image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List resizedBytes = byteData!.buffer.asUint8List();

      // Convert the image to a circular shape
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);
      final Paint paint = Paint()..isAntiAlias = true;
      final Radius radius = Radius.circular(50); // Radius for circular shape
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(0.0, 0.0, 100.0, 100.0),
          topLeft: radius,
          topRight: radius,
          bottomLeft: radius,
          bottomRight: radius,
        ),
        paint
          ..shader = ImageShader(
            await _getImageFromMemory(resizedBytes),
            TileMode.clamp,
            TileMode.clamp,
            Matrix4.identity().storage,
          ),
      );
      final img = await pictureRecorder.endRecording().toImage(100, 100);
      final ByteData? byteDataCircle =
          await img.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List circleBytes = byteDataCircle!.buffer.asUint8List();

      return BitmapDescriptor.fromBytes(circleBytes);
    } catch (e) {
      print('Error loading custom marker image: $e');
      return BitmapDescriptor.defaultMarker;
    }
  }

  Future<ui.Image> _getImageFromMemory(Uint8List byteData) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(byteData, (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }

  Future<void> _getUserEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('googleAccounts')
          .doc(user.email)
          .get();
      if (userDoc.exists && userDoc['profileImageUrl'] != null) {
        String profileImageUrl = userDoc['profileImageUrl'];
        BitmapDescriptor customMarker = await _getCustomMarker(profileImageUrl);
        setState(() {
          _userEmail = user.email;
          _currentMarkerIcon = customMarker;
        });
      } else {
        setState(() {
          _userEmail = user.email;
          _currentMarkerIcon =
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
        });
      }
    }
  }

  Future<void> _getLocationUpdates() async {
    try {
      await LocationService.getLocationUpdates();
      _locationSubscription =
          LocationService.locationStream.listen((LocationData locationData) {
        setState(() {
          _currentP = LatLng(locationData.latitude!, locationData.longitude!);
          _uploadLocationToFirestore(
              locationData.latitude!, locationData.longitude!);
        });
      });
    } catch (e) {
      print('Error getting location updates: $e');
    }
  }

  Future<void> _uploadLocationToFirestore(
      double latitude, double longitude) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userEmail = user.email!;
        await FirebaseFirestore.instance
            .collection('googleAccounts')
            .doc(userEmail)
            .set({
          'location': GeoPoint(latitude, longitude),
        }, SetOptions(merge: true));
        print('Location uploaded to Firestore');
      }
    } catch (e) {
      print('Error uploading location to Firestore: $e');
    }
  }

  Future<void> _fetchAccountsFromFirestore() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('googleAccounts').get();
      setState(() {
        _accounts = querySnapshot.docs;
      });
    } catch (e) {
      print('Error fetching accounts: $e');
    }
  }

  Future<void> _fetchLocationFromFirestore(String email) async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('googleAccounts')
          .doc(email)
          .get();

      if (documentSnapshot.exists) {
        var locationData = documentSnapshot['location'] as GeoPoint?;
        var profileImageUrl = documentSnapshot['profileImageUrl'] as String?;

        if (locationData != null && profileImageUrl != null) {
          double latitude = locationData.latitude;
          double longitude = locationData.longitude;
          LatLng newLocation = LatLng(latitude, longitude);

          BitmapDescriptor customMarker =
              await _getCustomMarker(profileImageUrl);

          setState(() {
            _selectedLocation = newLocation;
            _selectedMarkerIcon = customMarker;
          });
          _cameraToPosition(_currentP!, _selectedLocation!);
        }

        _selectedUserLocationSubscription
            ?.cancel(); // Cancel any previous subscription
        _selectedUserLocationSubscription =
            documentSnapshot.reference.snapshots().listen((snapshot) async {
          if (snapshot.exists) {
            var locationData = snapshot['location'] as GeoPoint?;
            var profileImageUrl = snapshot['profileImageUrl'] as String?;
            if (locationData != null && profileImageUrl != null) {
              double latitude = locationData.latitude;
              double longitude = locationData.longitude;
              LatLng newLocation = LatLng(latitude, longitude);
              BitmapDescriptor customMarker =
                  await _getCustomMarker(profileImageUrl);
              setState(() {
                _selectedLocation = newLocation;
                _selectedMarkerIcon = customMarker;
              });
              _cameraToPosition(_currentP!, _selectedLocation!);
            }
          }
        });
      }
    } catch (e) {
      print('Error fetching location from Firestore: $e');
    }
  }

  Future<void> _cameraToPosition(LatLng pos1, LatLng pos2) async {
    final GoogleMapController controller = await _mapController.future;

    // Calculate the bounds that include both positions
    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        pos1.latitude <= pos2.latitude ? pos1.latitude : pos2.latitude,
        pos1.longitude <= pos2.longitude ? pos1.longitude : pos2.longitude,
      ),
      northeast: LatLng(
        pos1.latitude >= pos2.latitude ? pos1.latitude : pos2.latitude,
        pos1.longitude >= pos2.longitude ? pos1.longitude : pos2.longitude,
      ),
    );

    // Adjust the camera position to fit the bounds
    CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 50);

    await controller.animateCamera(cameraUpdate);
  }

  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};

    if (_currentP != null) {
      markers.add(
        Marker(
          markerId: MarkerId("_currentLocation"),
          icon: _currentMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          position: _currentP!,
        ),
      );
    }

    if (_selectedLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId("_selectedLocation"),
          icon: _selectedMarkerIcon ?? BitmapDescriptor.defaultMarker,
          position: _selectedLocation!,
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Home',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            fontFamily: 'Montserrat',
          ),
        ),
      ),
      body: Column(
        children: [
          if (_userEmail != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('User Email: $_userEmail'),
            ),
          ElevatedButton(
            onPressed: () {
              _showEntityListDialog();
            },
            child: const Text('Select Device'),
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) =>
                  _mapController.complete(controller),
              initialCameraPosition: const CameraPosition(
                target: _pGooglePlex,
                zoom: 10,
              ),
              markers: _buildMarkers(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEntityListDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        // Filter out the current user's email from the accounts list
        List<DocumentSnapshot> filteredAccounts =
            _accounts.where((account) => account.id != _userEmail).toList();

        return SelectEntityDialog(
          accounts: filteredAccounts,
          onEntitySelected: (emailDoc) {
            String email = emailDoc.id; // Use the document ID as the email
            _fetchLocationFromFirestore(email);
          },
        );
      },
    );
  }
}
