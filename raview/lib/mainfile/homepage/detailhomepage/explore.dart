import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:raview/designdata/auto/isdarkmode.dart';
import 'package:raview/mainfile/homepage/detailhomepage/explorewidget/displaylistplace.dart';
import 'package:raview/mainfile/homepage/detailhomepage/explorewidget/map.dart';
import 'package:raview/mainfile/homepage/detailhomepage/explorewidget/searchbarexplore.dart';

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

  @override
  void initState() {
    super.initState();
    selectedCategory = 'ALL';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
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
            catagoryList(size),
            Expanded(
              child: Displaylistplace(
                jenis: selectedCategory!,
                searchQuery: searchQuery,
              ),
            )
          ],
          
        ),
      ),
      floatingActionButtonLocation: isKeyboardVisible
        ? null
        : FloatingActionButtonLocation.centerDocked,
    floatingActionButton: isKeyboardVisible
        ? null
        : const MapInfo(),
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