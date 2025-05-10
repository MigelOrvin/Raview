import 'package:another_carousel_pro/another_carousel_pro.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:raview/designdata/assets/widgets/BasicButton.dart';
import 'package:raview/designdata/assets/widgets/snackbar.dart';
import 'package:raview/designdata/auto/isdarkmode.dart';
import 'package:flutter/scheduler.dart';
import 'package:raview/mainfile/homepage/postreview.dart/postreview.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:ui';

class PlaceDetailScreen extends StatefulWidget {
  final DocumentSnapshot<Object?> place;
  const PlaceDetailScreen({super.key, required this.place});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  int currentIndex = 0;
  bool _showFullDescription = false;
  final Duration _animationDuration = Duration(milliseconds: 300);

  Future<QuerySnapshot>? _reviewsFuture;
  Map<String, dynamic>? _updatedPlaceData;
  @override
  void initState() {
    super.initState();
    final placeId = widget.place.id;
    _reviewsFuture =
        FirebaseFirestore.instance
            .collection('reviews')
            .where('placeId', isEqualTo: placeId)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();
  }

  Stream<bool> isFavorited(String placeId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(false);

    return FirebaseFirestore.instance
        .collection('wishlist')
        .where('userId', isEqualTo: user.uid)
        .where('placeId', isEqualTo: placeId)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  Future<void> toggleFavorite(
    String placeId,
    String placeName,
    bool isFav,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final wishlistRef = FirebaseFirestore.instance.collection('wishlist');
    try {
      if (!isFav) {
        await wishlistRef.add({'userId': user.uid, 'placeId': placeId});
        final snackbar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: "Success",
            message: '$placeName added to wishlist',
            contentType: ContentType.success,
            color: Color(0xff98855A),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackbar);
      } else {
        final snapshot =
            await wishlistRef
                .where('userId', isEqualTo: user.uid)
                .where('placeId', isEqualTo: placeId)
                .get();
        for (var doc in snapshot.docs) {
          await wishlistRef.doc(doc.id).delete();
        }
        final snackbar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: "Success",
            message: '$placeName removed from wishlist',
            contentType: ContentType.success,
            color: Color(0xff98855A),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackbar);
      }
    } catch (e) {
      final errorSnackbar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: "Error",
          message: 'Failed to update wishlist: $e',
          contentType: ContentType.failure,
          color: Colors.red,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar);
    }
  }

  void _refreshData() {
    setState(() {
      final placeId = widget.place.id;
      _reviewsFuture =
          FirebaseFirestore.instance
              .collection('reviews')
              .where('placeId', isEqualTo: placeId)
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

      FirebaseFirestore.instance.collection('allPlace').doc(placeId).get().then(
        (doc) {
          if (doc.exists && mounted) {
            setState(() {
              _updatedPlaceData = doc.data() as Map<String, dynamic>;
            });
          }
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final placeId = widget.place.id;
    final placeName = widget.place['nama'] ?? '';
    final deskripsi = widget.place['deskripsi'] ?? '';

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            detailImage(size, context, placeId, placeName),
            Padding(
              padding: EdgeInsets.only(
                left: 25,
                right: 25,
                bottom: 50,
                top: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.place['nama'],
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 20,
                      height: 1.2,
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis,
                      color: context.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.timelapse_rounded,
                        color: Color(0xff98855A),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.place['jambuka'].toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color:
                              context.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(" - "),
                      Text(
                        widget.place['jamtutup'].toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color:
                              context.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedSize(
                        duration: _animationDuration,
                        curve: Curves.easeInOut,
                        child: Container(
                          constraints: BoxConstraints(
                            maxHeight:
                                _showFullDescription ? double.infinity : 105,
                          ),
                          child: Text(
                            deskripsi,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color:
                                  context.isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                            ),
                            textAlign: TextAlign.justify,
                            overflow:
                                _showFullDescription
                                    ? TextOverflow.visible
                                    : TextOverflow.fade,
                          ),
                        ),
                      ),

                      if (deskripsi.length > 150)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showFullDescription = !_showFullDescription;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                Text(
                                  _showFullDescription
                                      ? "Show less"
                                      : "Show more",
                                  style: TextStyle(
                                    color: Color(0xff98855A),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Icon(
                                  _showFullDescription
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Color(0xff98855A),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),

                  AnimatedContainer(
                    duration: _animationDuration,
                    height: 20,
                    curve: Curves.easeInOut,
                  ),

                  AnimatedContainer(
                    duration: _animationDuration,
                    curve: Curves.easeInOut,
                    transform: Matrix4.translationValues(
                      0,
                      _showFullDescription ? 0 : -10,
                      0,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          color:
                              context.isDarkMode ? Colors.white : Colors.black,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Text(
                            _updatedPlaceData != null
                                ? _updatedPlaceData!['rating'].toString()
                                : widget.place['rating'].toString(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color:
                                  context.isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                            ),
                          ),
                        ),
                        Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            _updatedPlaceData != null
                                ? _updatedPlaceData!['review'].toString()
                                : widget.place['review'].toString(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color:
                                  context.isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                            ),
                          ),
                        ),
                        Text(
                          "reviews",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color:
                                context.isDarkMode
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  _buildLatestReview(placeId),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: BasicButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Postreview(place: widget.place),
                  ),
                );

                if (result == true) {
                  _refreshData();
                }
              },
              title: "Add Review",
            ),
          ),
        ),
      ),
    );
  }

  Stack detailImage(
    Size size,
    BuildContext context,
    String placeId,
    String placeName,
  ) {
    return Stack(
      children: [
        SizedBox(
          height: size.height * 0.35,
          child: Hero(
            tag: placeId,
            child: AnotherCarousel(
              images:
                  widget.place['images']
                      .map(
                        (url) => FadeInImage.assetNetwork(
                          placeholder: 'assets/placeholder.png',
                          image: url,
                          fit: BoxFit.cover,
                        ),
                      )
                      .toList(),
              showIndicator: false,
              dotBgColor: Colors.transparent,
              boxFit: BoxFit.cover,
              onImageChange: (p0, p1) {
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    currentIndex = p1;
                  });
                });
              },
              autoplay: true,
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          right: 20,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.black.withOpacity(0.8),
            ),
            child: Text(
              '${currentIndex + 1} / ${widget.place['images'].length}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          left: 0,
          top: 25,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: size.width * 0.66),
                StreamBuilder<bool>(
                  stream: isFavorited(placeId),
                  builder: (context, snapshot) {
                    final isFav = snapshot.data ?? false;
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: InkWell(
                        onTap: () => toggleFavorite(placeId, placeName, isFav),
                        child: Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.red : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLatestReview(String placeId) {
    return FutureBuilder<QuerySnapshot>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xff98855A)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: context.isDarkMode ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "No reviews yet. Be the first to review!",
              style: TextStyle(
                color: context.isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          );
        }

        final reviewData =
            snapshot.data!.docs[0].data() as Map<String, dynamic>;
        final comment = reviewData['comment'] ?? '';
        final username = reviewData['username'] ?? 'Anonymous';
        final profilePic = reviewData['profilePicture'] ?? '';
        final timestamp = (reviewData['timestamp'] as Timestamp?)?.toDate();
        final timeAgo =
            timestamp != null
                ? timeago.format(timestamp, locale: 'en_short')
                : 'recent';

        final List<dynamic> imageUrls = reviewData['imageUrls'] ?? [];

        return Container(
          margin: EdgeInsets.only(bottom: 20),
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: context.isDarkMode ? Colors.grey[800] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Latest Review",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xff98855A),
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 10),

              if (imageUrls.isNotEmpty)
                Container(
                  height: 120,
                  margin: EdgeInsets.only(bottom: 15),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          _showFullImageDialog(imageUrls[index]);
                        },
                        child: Container(
                          width: 120,
                          margin: EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: NetworkImage(imageUrls[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              Text(
                comment,
                style: TextStyle(
                  color: context.isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 15),

              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showFullImageDialog(profilePic),
                    child: CircleAvatar(
                      radius: 15,
                      backgroundImage:
                          profilePic.isNotEmpty
                              ? NetworkImage(profilePic)
                              : null,
                      child:
                          profilePic.isEmpty
                              ? Icon(Icons.person, size: 20, color: Colors.grey)
                              : null,
                    ),
                  ),
                  SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                context.isDarkMode
                                    ? Colors.white
                                    : Colors.black,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        Text(
                          timeAgo,
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      "See All",
                      style: TextStyle(
                        color: Color(0xff98855A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFullImageDialog(String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
            ),
            Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.all(10),
              child: GestureDetector(
                onTap: () {},
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(imageUrl, fit: BoxFit.contain),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
