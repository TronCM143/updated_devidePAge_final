import 'package:location/location.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService {
  static final Location _locationController = Location();

  static Future<void> getLocationUpdates() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _locationController.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
      if (!_serviceEnabled) {
        // Handle the case where the user denies access to location services
        return;
      }
    }

    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        // Handle the case where the user denies location permission
        return;
      }
    }

    // Get the current user's email
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userEmail = user.email!;

      // Listen for location updates
      try {
        _locationController.onLocationChanged
            .listen((LocationData locationData) async {
          double latitude = locationData.latitude!;
          double longitude = locationData.longitude!;

          // Store the location in Firestore under the current user's email
          await FirebaseFirestore.instance
              .collection('googleAccounts')
              .doc(userEmail)
              .set({
            'location': GeoPoint(latitude, longitude),
          }, SetOptions(merge: true));

          print('Location uploaded to Firestore');
        });
      } catch (e) {
        // Handle any errors that occur while listening for location updates
        print('Error getting location updates: $e');
      }
    }
  }

  static Future<LocationData?> getCurrentLocation() async {
    try {
      bool _serviceEnabled;
      PermissionStatus _permissionGranted;

      _serviceEnabled = await _locationController.serviceEnabled();
      if (!_serviceEnabled) {
        _serviceEnabled = await _locationController.requestService();
        if (!_serviceEnabled) {
          // Handle the case where the user denies access to location services
          print('Error: Location services are disabled');
          return null;
        }
      }

      _permissionGranted = await _locationController.hasPermission();
      if (_permissionGranted == PermissionStatus.denied) {
        _permissionGranted = await _locationController.requestPermission();
        if (_permissionGranted != PermissionStatus.granted) {
          // Handle the case where the user denies location permission
          print('Error: Location permission denied');
          return null;
        }
      }

      return await _locationController.getLocation();
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }
}
