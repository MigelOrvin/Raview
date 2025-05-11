import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:raview/designdata/auto/isdarkmode.dart';
import 'package:raview/mainfile/homepage/detailhomepage/explorewidget/displaylistplace.dart';
import 'package:raview/mainfile/homepage/detailhomepage/explorewidget/searchbarexplore.dart';
import 'package:raview/mainfile/homepage/detailplace/detailplace.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final CollectionReference categoryRef = FirebaseFirestore.instance.collection(
    'Categories',
  );
  int selected = 0;
  String? selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  bool _isMapView = false;
  
  // Map controller and markers
  final Completer<GoogleMapController> _mapController = Completer();
  CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(-6.2088, 106.8456), // Default Jakarta coordinate
    zoom: 14.0,
  );
  Map<MarkerId, Marker> _markers = {};
  Set<Marker> get markers => _markers.values.toSet();
  bool _isLoadingMap = true;

  @override
  void initState() {
    super.initState();
    selectedCategory = 'ALL';
    _getUserLocation();
    _loadPlacesFromFirebase();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      
      // Move camera to user's location if map controller is ready
      if (_mapController.isCompleted) {
        final GoogleMapController controller = await _mapController.future;
        controller.animateCamera(CameraUpdate.newCameraPosition(updatedCameraPosition));
      }
      
      setState(() {
        _isLoadingMap = false;
      });
    } catch (e) {
      print("Error getting location: $e");
      setState(() {
        _isLoadingMap = false;
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
            title: data['nama'] ?? 'Unnamed Place',
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
  
  void _toggleView() {
    setState(() {
      _isMapView = !_isMapView;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SearchBarAndFilter(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  searchQuery = val.trim();
                });
              },
            ),
            // Only show category list in list view
            if (!_isMapView) catagoryList(size),
            Expanded(
              child: _isMapView 
                ? _buildMapView()
                : Displaylistplace(
                    jenis: selectedCategory!,
                    searchQuery: searchQuery,
                  ),
            )
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: context.isDarkMode
            ? const Color(0xffFAFAFA).withOpacity(0.9)
            : const Color(0xff1E1E1E).withOpacity(0.9),
        elevation: 3,
        onPressed: _toggleView,
        icon: Icon(
          _isMapView ? Icons.list : Icons.map_outlined, 
          color: context.isDarkMode ? Colors.black : Colors.white
        ),
        label: Text(
          _isMapView ? 'List View' : 'Map View',
          style: TextStyle(
            color: context.isDarkMode ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: _initialCameraPosition,
          markers: markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          onMapCreated: (GoogleMapController controller) {
            if (!_mapController.isCompleted) {
              _mapController.complete(controller);
              // Move to user location if we already have it
              if (!_isLoadingMap) {
                controller.animateCamera(
                  CameraUpdate.newCameraPosition(_initialCameraPosition)
                );
              }
            }
          },
        ),
        if (_isLoadingMap)
          Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xff98855A),
              ),
            ),
          ),
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
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
                  if (_mapController.isCompleted) {
                    final GoogleMapController controller = await _mapController.future;
                    controller.animateCamera(CameraUpdate.zoomIn());
                  }
                },
                child: Icon(Icons.add, color: Colors.white),
              ),
              SizedBox(height: 16),
              FloatingActionButton(
                heroTag: 'btn3',
                backgroundColor: const Color(0xff98855A),
                onPressed: () async {
                  if (_mapController.isCompleted) {
                    final GoogleMapController controller = await _mapController.future;
                    controller.animateCamera(CameraUpdate.zoomOut());
                  }
                },
                child: Icon(Icons.remove, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SearchBarAndFilter(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  searchQuery = val.trim();
                });
              },
            ),
            catagoryList(size),
            Expanded(
              child: Displaylistplace(
                jenis: selectedCategory!,
                searchQuery: searchQuery,
              ),
            )
          ],
        ),
      ),      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: const MapInfo(),
    );
  }

  StreamBuilder<QuerySnapshot<Object?>> catagoryList(Size size) {
    return StreamBuilder(
            stream: categoryRef.orderBy('jenis', descending: false).snapshots(),
            builder: (context, streamSnapshot) {
              if (streamSnapshot.hasData) {
                return Stack(
                  children: [
                    Positioned(
                      top: 70,
                      left: 0,
                      right: 0,
                      child: Divider(
                        color:
                            context.isDarkMode
                                ? Colors.white12
                                : Colors.black12,
                      ),
                    ),
                    SizedBox(
                      height: size.height * 0.12,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        scrollDirection: Axis.horizontal,
                        itemCount: streamSnapshot.data!.docs.length,
                        physics: BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selected = index;
                                selectedCategory = streamSnapshot
                                    .data!.docs[index]['jenis'];
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.only(
                                top: 10,
                                right: 20,
                                left: 20,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    height: 32,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                    child: Image.network(
                                      streamSnapshot
                                          .data!
                                          .docs[index]['image'],
                                      color:
                                          selected == index
                                              ? context.isDarkMode
                                                  ? Colors.white
                                                  : Colors.black
                                              : context.isDarkMode
                                              ? Colors.white54
                                              : Colors.black45,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    streamSnapshot.data!.docs[index]['jenis'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          selected == index
                                              ? context.isDarkMode
                                                  ? Colors.white
                                                  : Colors.black
                                              : context.isDarkMode
                                              ? Colors.white54
                                              : Colors.black45,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Container(
                                    height: 3,
                                    width: 50,
                                    color:
                                        selected == index
                                            ? context.isDarkMode
                                                ? Colors.white
                                                : Colors.black
                                            : Colors.transparent,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }
              return Center(child: CircularProgressIndicator());
            },
          );
  }
}
