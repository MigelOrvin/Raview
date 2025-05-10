import 'package:another_carousel_pro/another_carousel_pro.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:raview/designdata/assets/vector/vectorlink.dart';
import 'package:raview/designdata/assets/widgets/snackbar.dart';
import 'package:raview/designdata/auto/isdarkmode.dart';
import 'package:raview/mainfile/homepage/detailplace/detailplace.dart';

class wishlistScreen extends StatefulWidget {
  const wishlistScreen({super.key});

  @override
  State<wishlistScreen> createState() => _wishlistScreenState();
}

class _wishlistScreenState extends State<wishlistScreen> {
  final Map<String, DocumentSnapshot> _placeCache = {};

  Future<void> removeFromWishlist(
    String wishlistDocId,
    String placeName,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('wishlist')
          .doc(wishlistDocId)
          .delete();

      final snackbar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: "Success",
          message: '$placeName deleted from wishlist',
          contentType: ContentType.success,
          color: Color(0xff98855A),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(),
              child: Center(
                child: SvgPicture.asset(
                  VectorLink.logoSplash,
                  height: 113,
                  width: 113,
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('wishlist')
                    .where(
                      'userId',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                    )
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'Wishlist kamu akan tampil di sini',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: context.isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    );
                  }

                  final wishlistDocs = snapshot.data!.docs;

                  return Padding(
                    padding: const EdgeInsets.only(left: 15, right: 15),
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.only(bottom: 170, left: 16, right: 16, top: 16),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 25,
                              mainAxisSpacing: 25,
                              childAspectRatio: 0.8,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final wishlistDoc = wishlistDocs[index];
                                final placeId = wishlistDoc['placeId'];
                                final wishlistId = wishlistDoc.id;

                                return FutureBuilder<DocumentSnapshot>(
                                  future: _getPlaceSnapshot(placeId),
                                  builder: (context, placeSnapshot) {
                                    if (!placeSnapshot.hasData) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }

                                    final place = placeSnapshot.data!;
                                    if (!place.exists) {
                                      return Container();
                                    }

                                    final imagesList = List<String>.from(
                                      place['images'],
                                    );
                                    final placeName = place['nama'];

                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PlaceDetailScreen(place: place),
                                          ),
                                        );
                                      },
                                      child: Stack(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: context.isDarkMode
                                                      ? const Color.fromARGB(255, 255, 255, 255)
                                                          .withOpacity(0.3)
                                                      : const Color.fromARGB(255, 0, 0, 0)
                                                          .withOpacity(0.5),
                                                  blurRadius: 6,
                                                  spreadRadius: 5,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(20),
                                              child: Stack(
                                                children: [
                                                  SizedBox(
                                                    height: double.infinity,
                                                    width: double.infinity,
                                                    child: Hero(
                                                      tag: placeId,
                                                      child: AnotherCarousel(
                                                        images: imagesList
                                                            .map(
                                                              (url) => FadeInImage.assetNetwork(
                                                                placeholder: 'assets/placeholder.png',
                                                                image: url,
                                                                fit: BoxFit.cover,
                                                              ),
                                                            )
                                                            .toList(),
                                                        dotSize: 4,
                                                        indicatorBgPadding: 5,
                                                        dotBgColor: Colors.transparent,
                                                        borderRadius: true,
                                                        moveIndicatorFromBottom: 5,
                                                        noRadiusForIndicator: true,
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    bottom: 0,
                                                    left: 0,
                                                    right: 0,
                                                    child: Container(
                                                      height: 60,
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          begin: Alignment.topCenter,
                                                          end: Alignment.bottomCenter,
                                                          colors: [
                                                            Colors.transparent,
                                                            Colors.black.withOpacity(0.8),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    bottom: 10,
                                                    left: 10,
                                                    right: 50,
                                                    child: Text(
                                                      placeName,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 8,
                                            right: 8,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.4),
                                                shape: BoxShape.circle,
                                              ),
                                              child: IconButton(
                                                iconSize: 22,
                                                padding: EdgeInsets.zero,
                                                constraints: BoxConstraints(
                                                  minHeight: 32,
                                                  minWidth: 32,
                                                ),
                                                icon: Icon(
                                                  Icons.favorite,
                                                  color: Colors.red,
                                                  size: 22,
                                                ),
                                                onPressed: () => removeFromWishlist(
                                                  wishlistId,
                                                  placeName,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              childCount: wishlistDocs.length,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<DocumentSnapshot> _getPlaceSnapshot(String placeId) async {
    if (_placeCache.containsKey(placeId)) {
      return _placeCache[placeId]!;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('allPlace')
        .doc(placeId)
        .get();

    if (snapshot.exists) {
      _placeCache[placeId] = snapshot;
    }

    return snapshot;
  }
}
