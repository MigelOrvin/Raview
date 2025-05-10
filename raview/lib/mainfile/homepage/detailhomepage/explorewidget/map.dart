import 'package:flutter/material.dart';
import 'package:raview/designdata/auto/isdarkmode.dart';

class MapInfo extends StatefulWidget {
  const MapInfo({super.key});

  @override
  State<MapInfo> createState() => _MapInfoState();
}

class _MapInfoState extends State<MapInfo> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return FloatingActionButton.extended(
      backgroundColor: Colors.transparent,
      extendedPadding: EdgeInsets.only(bottom: 250),
      elevation: 0,
      onPressed: () {},
      label: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? const Color(0xffFAFAFA).withOpacity(0.9)
              : const Color(0xff1E1E1E).withOpacity(0.9),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 5),
            Text(
              'Map',
              style: TextStyle(
                color: context.isDarkMode ? Colors.black : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 5),
            Icon(Icons.map_outlined, color: context.isDarkMode ? Colors.black : Colors.white),
            SizedBox(width: 5),
          ],
        ),
      ),
    );
  }
}
