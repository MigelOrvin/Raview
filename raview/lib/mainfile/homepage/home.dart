import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:raview/designdata/auto/isdarkmode.dart';
import 'package:raview/mainfile/homepage/detailhomepage/explore.dart';
import 'package:raview/mainfile/homepage/detailhomepage/profile.dart';
import 'package:raview/mainfile/homepage/detailhomepage/wishlist.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selected = 0;
  late PageController _pageController;
  List<Widget> pages = [];

  double? latitude;
  double? longitude;
  String? locality;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    pages = [
      ExploreScreen(),
      wishlistScreen(),
      const ProfileScreen(latitude: null, longitude: null, locality: null),
    ];
    getLocation();
  }

  Future<void> getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 10));

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        setState(() {
          latitude = position.latitude;
          longitude = position.longitude;
          locality = placemarks[0].street;

          pages = [
            ExploreScreen(),
            wishlistScreen(),
            ProfileScreen(
              latitude: latitude,
              longitude: longitude,
              locality: locality,
            ),
          ];
        });
      }
    } catch (e) {
      setState(() {
        latitude = null;
        longitude = null;
        locality = null;

        pages = [
          ExploreScreen(),
          wishlistScreen(),
          ProfileScreen(
            latitude: latitude,
            longitude: longitude,
            locality: locality,
          ),
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent ,
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? const Color(0xff1E1E1E).withOpacity(0.9)
                : const Color(0xffFAFAFA).withOpacity(0.9),
            borderRadius: const BorderRadius.all(Radius.circular(60)),
            boxShadow: [
              BoxShadow(
                color: context.isDarkMode
                    ? const Color.fromARGB(255, 255, 255, 255).withOpacity(0.3)
                    : const Color.fromARGB(255, 0, 0, 0).withOpacity(0.2),
                blurRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: selected,
            onTap: (index) {
              setState(() {
                selected = index;
              });
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.search_rounded),
                label: 'Explore',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_outline_outlined),
                label: 'Wishlist',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_circle_outlined),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            selected = index;
          });
        },
        children: pages,
      ),
      
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
