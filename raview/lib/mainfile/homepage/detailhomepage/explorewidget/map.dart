import 'package:flutter/material.dart';
import 'package:raview/designdata/auto/isdarkmode.dart';
import 'package:raview/mainfile/homepage/map/mappage.dart';

class MapInfo extends StatelessWidget {
  const MapInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 130),
      child: FloatingActionButton.extended(
        backgroundColor: context.isDarkMode
            ? const Color(0xffFAFAFA).withOpacity(0.9)
            : const Color(0xff1E1E1E).withOpacity(0.9),
        elevation: 3,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MapPage()),
          );
        },
        icon: Icon(
          Icons.map_outlined, 
          color: context.isDarkMode ? Colors.black : Colors.white
        ),
        label: Text(
          'Map View',
          style: TextStyle(
            color: context.isDarkMode ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
