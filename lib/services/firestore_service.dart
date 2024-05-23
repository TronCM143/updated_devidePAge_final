import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  static Future<void> fetchLocationFromFirestore({
    required String email,
    required ValueChanged<LatLng?> onLocationFetched,
    required ValueChanged<LatLng?> onLocationUpdated,
  }) async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('googleAccounts')
          .doc(email)
          .get();

      if (documentSnapshot.exists) {
        var locationData = documentSnapshot['location'] as GeoPoint?;
        if (locationData != null) {
          double latitude = locationData.latitude;
          double longitude = locationData.longitude;
          LatLng newLocation = LatLng(latitude, longitude);
          print('New location fetched: $newLocation');
          onLocationFetched(newLocation);

          documentSnapshot.reference.snapshots().listen((snapshot) {
            if (snapshot.exists) {
              var updatedLocationData = snapshot['location'] as GeoPoint?;
              if (updatedLocationData != null) {
                double latitude = updatedLocationData.latitude;
                double longitude = updatedLocationData.longitude;
                LatLng updatedLocation = LatLng(latitude, longitude);
                print('New location updated: $updatedLocation');
                onLocationUpdated(updatedLocation);
              }
            }
          });
        }
      }
    } catch (e) {
      print('Error fetching location from Firestore: $e');
    }
  }
}
