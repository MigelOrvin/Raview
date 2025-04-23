import 'package:flutter/material.dart';
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
  late final List<Widget> pages;

  @override
  void initState() {
    pages = [
      exploreScreen(),
      wishlistScreen(),
      profileScreen(),
    ];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selected,
        onTap: (index){
          setState(() {
            selected = index;
          });
        },
        items: [
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
      body: pages[selected],
    );
  }
}