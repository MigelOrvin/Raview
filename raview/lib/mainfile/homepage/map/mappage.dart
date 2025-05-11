import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:raview/designdata/auto/isdarkmode.dart';
import 'package:raview/mainfile/homepage/detailplace/detailplace.dart';
import 'package:raview/service/map_helper.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer();
  
  CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(-2.9761, 104.7754), 
    zoom: 14.0,
  );
  
  bool _isLoading = true;
  Map<MarkerId, Marker> _markers = {};
  Set<Marker> get markers => _markers.values.toSet();
  Position? _currentPosition;
  
  DocumentSnapshot? _selectedPlace;
  double? _distanceToSelectedPlace;
  bool _showPlaceInfo = false;
  
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];
  
  bool _hasActiveSearch = false;
  String? _selectedPlaceId;
      @override
  void initState() {
    super.initState();
    _getUserLocation();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        if (args.containsKey('placeId')) {
          _openPlaceFromId(args['placeId']);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  Future<void> _openPlaceFromId(String placeId) async {
    try {
      final placeDoc = await FirebaseFirestore.instance
          .collection('allPlace')
          .doc(placeId)
          .get();
      
      if (placeDoc.exists) {
        final data = placeDoc.data() as Map<String, dynamic>;
        if (data.containsKey('posisi') && data['posisi'] != null) {
          final GeoPoint position = data['posisi'] as GeoPoint;
          
          setState(() {
            _markers.clear();
          });
          
          _addPlaceMarker(placeDoc, position);
          
          _moveToLocation(LatLng(position.latitude, position.longitude));
          
          _onMarkerTapped(placeDoc, position);
          
          setState(() {
            _hasActiveSearch = true;
            _selectedPlaceId = placeId;
          });
        }
      }
    } catch (e) {
      print("Error opening place from ID: $e");
    }
  }

  Future<void> _getUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      _currentPosition = position;
      
      final updatedCameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 16.0,
      );
      
      setState(() {
        _initialCameraPosition = updatedCameraPosition;
      });
      
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
  
  void _addPlaceMarker(DocumentSnapshot placeDoc, GeoPoint position) {
    final data = placeDoc.data() as Map<String, dynamic>;
    final markerId = MarkerId(placeDoc.id);
    final placeName = data['nama'] ?? 'Tempat Tanpa Nama';
    
    final marker = Marker(
      markerId: markerId,
      position: LatLng(position.latitude, position.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
        title: placeName,
        snippet: data['alamat'] ?? 'Alamat tidak tersedia',
      ),
      onTap: () {
        _onMarkerTapped(placeDoc, position);
      },
    );
    
    setState(() {
      _markers[markerId] = marker;
    });
  }
  
  void _onMarkerTapped(DocumentSnapshot placeDoc, GeoPoint placePosition) async {
    setState(() {
      _selectedPlace = placeDoc;
      _showPlaceInfo = true;
      
      if (_currentPosition != null) {
        _distanceToSelectedPlace = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          placePosition.latitude,
          placePosition.longitude,
        );
      }
    });
    
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(
      LatLng(
        placePosition.latitude - 0.0015, 
        placePosition.longitude
      )
    ));
  }
  
  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) return;
    
    setState(() {
      _searchResults = [];
    });
    
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('allPlace')
          .where('nama', isGreaterThanOrEqualTo: query)
          .where('nama', isLessThanOrEqualTo: query + '\uf8ff')
          .get();
      
      setState(() {
        _searchResults = querySnapshot.docs;
      });
    } catch (e) {
      print('Error searching places: $e');
      setState(() {
        _searchResults = [];
      });
    }
  }
  
  void _addSearchResultToMap(DocumentSnapshot placeDoc) {
    final data = placeDoc.data() as Map<String, dynamic>;
    
    if (data.containsKey('posisi') && data['posisi'] != null) {
      final GeoPoint position = data['posisi'] as GeoPoint;
      
      setState(() {
        _markers.clear();
      });
      
      _addPlaceMarker(placeDoc, position);
      
      _moveToLocation(LatLng(position.latitude, position.longitude));
      
      _onMarkerTapped(placeDoc, position);
      
      setState(() {
        _hasActiveSearch = true;
        _selectedPlaceId = placeDoc.id;
      });
    }
  }
  
  Future<void> _moveToLocation(LatLng location) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(location, 16.0));
  }
  
  Future<void> _launchMapsUrl(double lat, double lng, String placeName) async {
    try {
      await MapHelper.openMap(lat, lng, placeName);
    } catch (e) {
      print('Error opening map: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak dapat membuka Google Maps'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _navigateToDetailPlace() {
    if (_selectedPlace != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlaceDetailScreen(place: _selectedPlace!),
        ),
      );
    }
  }

  Widget _buildSearchBar() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari tempat terdekat...',
          hintStyle: TextStyle(
            color: Colors.black54,
            fontSize: 16,
          ),
          prefixIcon: Container(
            padding: EdgeInsets.all(12),
            child: Icon(Icons.search, color: Color(0xff98855A), size: 24),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? Container(
                  padding: EdgeInsets.all(12),
                  child: GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {
                        _searchResults = [];
                      });
                    },
                    child: Icon(Icons.close, color: Color(0xff98855A), size: 20),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xff98855A), width: 1.5),
          ),
        ),
        onChanged: (value) {
          if (value.length > 2) {
            _searchPlaces(value);
          } else if (value.isEmpty) {
            setState(() {
              _searchResults = [];
            });
          }
        },
        style: TextStyle(
          color: Colors.black87,
          fontSize: 16,
        ),
      ),
    );
  }
    
  Widget _buildPlaceInfoCard() {
    final placeData = _selectedPlace!.data() as Map<String, dynamic>;
    final placeName = placeData['nama'] ?? 'Tempat Tanpa Nama';
    final placeAddress = placeData['alamat'] ?? 'Alamat tidak tersedia';
    final placeCategory = placeData['jenis'] ?? 'Kategori tidak tersedia';
    String distanceText = 'Jarak tidak tersedia';
    
    if (_distanceToSelectedPlace != null) {
      if (_distanceToSelectedPlace! < 1000) {
        distanceText = '${_distanceToSelectedPlace!.toStringAsFixed(0)} meter dari Anda';
      } else {
        final distanceKm = _distanceToSelectedPlace! / 1000;
        distanceText = '${distanceKm.toStringAsFixed(1)} km dari Anda';
      }
    }
    
    String? imageUrl = placeData['imageUrl'];
    List<String> images = [];
    if (placeData.containsKey('images') && placeData['images'] != null) {
      images = List<String>.from(placeData['images']);
    }
    
    if ((imageUrl == null || imageUrl.isEmpty) && images.isNotEmpty) {
      imageUrl = images[0];
    }
    
    final jamBuka = placeData['jambuka'] ?? '-';
    final jamTutup = placeData['jamtutup'] ?? '-';
    
    return GestureDetector(
      onTap: _navigateToDetailPlace,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xff98855A), Color(0xffB4A46A)],
                ),
                image: imageUrl != null && imageUrl.isNotEmpty 
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.3),
                        BlendMode.darken
                      )
                    ) 
                  : null,
              ),
              padding: EdgeInsets.all(16),
              alignment: Alignment.bottomLeft,
              child: Text(
                placeName,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  shadows: [
                    Shadow(
                      blurRadius: 3.0,
                      color: Colors.black.withOpacity(0.5),
                      offset: Offset(1.0, 1.0),
                    ),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, size: 20, color: Color(0xff98855A)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          placeAddress,
                          style: TextStyle(fontSize: 14, color: context.isDarkMode ? Colors.white : Colors.black87),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  
                  Row(
                    children: [
                      Icon(Icons.category, size: 20, color: Color(0xff98855A)),
                      SizedBox(width: 8),
                      Text(
                        placeCategory,
                        style: TextStyle(fontSize: 14, color:context.isDarkMode ? Colors.white : Colors.black87),
                      ),
                      SizedBox(width: 20),
                      Icon(Icons.access_time, size: 20, color: Color(0xff98855A)),
                      SizedBox(width: 8),
                      Text(
                        '$jamBuka - $jamTutup',
                        style: TextStyle(fontSize: 14, color:context.isDarkMode ? Colors.white : Colors.black87),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  
                  Row(
                    children: [
                      Icon(Icons.directions_walk, size: 20, color: Color(0xff98855A)),
                      SizedBox(width: 8),
                      Text(
                        distanceText,
                        style: TextStyle(fontSize: 14, color: context.isDarkMode ? Colors.white : Colors.black87),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          try {
                            final lat = placeData['posisi'].latitude;
                            final lng = placeData['posisi'].longitude;
                            _launchMapsUrl(lat, lng, placeName);
                          } catch (e) {
                            print('Error navigating: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Terjadi kesalahan saat membuka navigasi'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        icon: Icon(Icons.directions, size: 18),
                        label: Text("Navigasi"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Color(0xff98855A),
                          side: BorderSide(color: Color(0xff98855A)),
                        ),
                      ),
                      
                      ElevatedButton.icon(
                        onPressed: _navigateToDetailPlace,
                        icon: Icon(Icons.info_outline, size: 18),
                        label: Text("Lihat Detail"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xff98855A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
          'Peta Lokasi',
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
            onTap: (LatLng location) {
              setState(() {
                _showPlaceInfo = false;
              });
            },
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildSearchBar(),
          ),
          
          if (_searchResults.isNotEmpty)
            Positioned(
              top: 76, 
              left: 16,
              right: 16,
              child: Container(
                height: 250, 
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final place = _searchResults[index];
                    final placeData = place.data() as Map<String, dynamic>;
                    final placeName = placeData['nama'] ?? 'Tempat tanpa nama';
                    final placeAddress = placeData['alamat'] ?? 'Alamat tidak tersedia';
                    String? imageUrl;
                    
                    if (placeData.containsKey('imageUrl') && placeData['imageUrl'] != null) {
                      imageUrl = placeData['imageUrl'];
                    } else if (placeData.containsKey('images') && 
                               placeData['images'] != null && 
                               placeData['images'] is List && 
                               (placeData['images'] as List).isNotEmpty) {
                      imageUrl = (placeData['images'] as List).first;
                    }
                    
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Color(0xffF5F5F5),
                          image: imageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: imageUrl == null 
                            ? Icon(Icons.restaurant, color: Color(0xff98855A))
                            : null,
                      ),
                      title: Text(
                        placeName,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color:Colors.black87),
                      ),
                      subtitle: Text(
                        placeAddress,
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      onTap: () {
                        _addSearchResultToMap(place);
                        setState(() {
                          _searchResults = [];
                          _searchController.clear();
                        });
                      },
                    );
                  },
                ),
              ),
            ),
            
          Positioned(
            top: 76, 
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () async {
                          final GoogleMapController controller = await _controller.future;
                          controller.animateCamera(CameraUpdate.zoomIn());
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.add, color: Color(0xff98855A)),
                        ),
                      ),
                      Container(
                        height: 1,
                        color: Colors.grey[300],
                      ),
                      InkWell(
                        onTap: () async {
                          final GoogleMapController controller = await _controller.future;
                          controller.animateCamera(CameraUpdate.zoomOut());
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.remove, color: Color(0xff98855A)),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 12),
                
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: _getUserLocation,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.my_location, color: Color(0xff98855A)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xff98855A),
                ),
              ),
            ),
            
          if (_showPlaceInfo && _selectedPlace != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                transform: Matrix4.translationValues(0, 0, 0),
                child: _buildPlaceInfoCard(),
              ),
            ),
        ],
      ),
    );
  }
}