import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:raview/designdata/auto/isdarkmode.dart';
import 'package:raview/mainfile/homepage/detailplace/detailplace.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer();
  
  // Default location (will be replaced with user's location)
  CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(-6.2088, 106.8456), // Default Jakarta coordinate
    zoom: 14.0,
  );
  
  bool _isLoading = true;
  Map<MarkerId, Marker> _markers = {};
  Set<Marker> get markers => _markers.values.toSet();
  
  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _loadPlacesFromFirebase();
  }
    Future<void> _getUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      final updatedCameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 16.0, // Increased zoom level to show more detail
      );
      
      setState(() {
        _initialCameraPosition = updatedCameraPosition;
        
        // Add a marker for user's current location
        final markerId = MarkerId("currentLocation");
        _markers[markerId] = Marker(
          markerId: markerId,
          position: LatLng(position.latitude, position.longitude),
          infoWindow: InfoWindow(title: "Your Location"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        );
      });
      
      // Move camera to user's location
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(updatedCameraPosition));
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print("Error getting location: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadPlacesFromFirebase() async {
    try {
      final placesSnapshot = await FirebaseFirestore.instance
          .collection('allPlace')
          .get();
      
      for (var placeDoc in placesSnapshot.docs) {
        final data = placeDoc.data();
        
        // Skip if location data is missing
        if (!data.containsKey('latitude') || 
            !data.containsKey('longitude') || 
            data['latitude'] == null || 
            data['longitude'] == null) {
          continue;
        }
        
        final double lat = double.parse(data['latitude'].toString());
        final double lng = double.parse(data['longitude'].toString());
        
        final markerId = MarkerId(placeDoc.id);
        final marker = Marker(
          markerId: markerId,
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: data['name'] ?? 'Unnamed Place',
            snippet: data['address'] ?? 'No address provided',
          ),
          onTap: () {
            _onMarkerTapped(placeDoc);
          },
        );
        
        setState(() {
          _markers[markerId] = marker;
        });
      }
    } catch (e) {
      print("Error loading places: $e");
    }
  }
  
  void _onMarkerTapped(DocumentSnapshot placeDoc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaceDetailScreen(place: placeDoc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Places Map',
          style: TextStyle(
            color: context.isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 15,
              color: context.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialCameraPosition,
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xff98855A),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'btn1',
            backgroundColor: const Color(0xff98855A),
            onPressed: () async {
              _getUserLocation();
            },
            child: Icon(Icons.my_location, color: Colors.white),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'btn2',
            backgroundColor: const Color(0xff98855A),
            onPressed: () async {
              final GoogleMapController controller = await _controller.future;
              controller.animateCamera(CameraUpdate.zoomIn());
            },
            child: Icon(Icons.add, color: Colors.white),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'btn3',
            backgroundColor: const Color(0xff98855A),
            onPressed: () async {
              final GoogleMapController controller = await _controller.future;
              controller.animateCamera(CameraUpdate.zoomOut());
            },
            child: Icon(Icons.remove, color: Colors.white),
          ),
        ],
      ),
    );
  }
}