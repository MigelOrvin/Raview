import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:raview/designdata/assets/widgets/snackbar.dart';
import 'package:raview/designdata/auto/isdarkmode.dart';
import 'package:raview/mainfile/homepage/detailplace/detailplace.dart';
import 'package:shimmer/shimmer.dart';

class Displaylistplace extends StatefulWidget {
  final String jenis;
  final String searchQuery;
  const Displaylistplace({
    super.key,
    required this.jenis,
    this.searchQuery = '',
  });

  @override
  State<Displaylistplace> createState() => _DisplaylistplaceState();
}

class _DisplaylistplaceState extends State<Displaylistplace> {
  final CollectionReference placeCollection = FirebaseFirestore.instance
      .collection('allPlace');

  final int _limit = 5;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoading = false;
  List<DocumentSnapshot> _places = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchPlaces();
      }
    });
  }

  @override
  void didUpdateWidget(covariant Displaylistplace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jenis != widget.jenis ||
        oldWidget.searchQuery != widget.searchQuery) {
      setState(() {
        _places.clear();
        _lastDoc = null;
        _hasMore = true;
        _isLoading = false;
      });
      _fetchPlaces();
    }
  }

  Future<void> _fetchPlaces() async {
    if (_isLoading) return;

    if (_lastDoc == null) {
      _places.clear();
    }

    setState(() => _isLoading = true);

    Query query;
    if (widget.searchQuery.isNotEmpty) {
      if (widget.jenis.toLowerCase() == 'all') {
        query = placeCollection.orderBy('nama_lower');
      } else {
        query = placeCollection
            .where('jenis', isEqualTo: widget.jenis)
            .orderBy('nama_lower');
      }
      final snapshot = await query.get();
      _places = snapshot.docs;
      setState(() {
        _isLoading = false;
        _hasMore = false;
      });
      return;
    }

    if (!_hasMore) return;
    query =
        widget.jenis.toLowerCase() == 'all'
            ? placeCollection.orderBy('rating', descending: true)
            : placeCollection
                .where('jenis', isEqualTo: widget.jenis)
                .orderBy('rating', descending: true);

    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }

    final snapshot = await query.limit(_limit).get();
    if (snapshot.docs.isNotEmpty) {
      _lastDoc = snapshot.docs.last;
      _places.addAll(snapshot.docs);
    }
    if (snapshot.docs.length < _limit) _hasMore = false;
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Stream<List<String>> getUserWishlistIds() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);
    return FirebaseFirestore.instance
        .collection('wishlist')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => doc['placeId'] as String).toList(),
        );
  }

  Future<void> toggleFavorite(
    String placeId,
    String placeName,
    bool isFav,
    BuildContext context,
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

  @override
  Widget build(BuildContext context) {
    if (_places.isEmpty && _isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  height: 360,
                  width: double.infinity,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Container(height: 20, width: 120, color: Colors.white),
              const SizedBox(height: 8),
              Container(height: 16, width: 200, color: Colors.white),
            ],
          ),
        ),
      );
    }

    List<DocumentSnapshot> filteredPlaces = _places;
    if (widget.searchQuery.isNotEmpty) {
      final lowerQuery = widget.searchQuery.toLowerCase();
      filteredPlaces =
          _places.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final namaLower =
                data.containsKey('nama_lower')
                    ? data['nama_lower']
                    : (data['nama'] ?? '').toString().toLowerCase();
            return namaLower.contains(lowerQuery);
          }).toList();
    }

    if (widget.searchQuery.isNotEmpty &&
        filteredPlaces.isEmpty &&
        !_isLoading) {
      return Center(
        child: Text(
          'Tidak ada hasil untuk "${widget.searchQuery}"',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: context.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      );
    }

    return StreamBuilder<List<String>>(
      stream: getUserWishlistIds(),
      builder: (context, wishlistSnapshot) {
        final wishlistIds = wishlistSnapshot.data ?? [];
        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.only(bottom: 100),
          itemCount:
              filteredPlaces.length +
              (_hasMore && widget.searchQuery.isEmpty ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == filteredPlaces.length) {
              if (_hasMore && widget.searchQuery.isEmpty) {
                return Center(child: CircularProgressIndicator());
              } else {
                return const SizedBox.shrink();
              }
            }
            final place = filteredPlaces[index];
            final data = place.data() as Map<String, dynamic>;
            final images = List<String>.from(data['images']);
            final placeId = place.id;
            final placeName = data['nama'] ?? '';

            final thumbnailUrl = images.isNotEmpty ? images[0] : '';

            final isFav = wishlistIds.contains(placeId);

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlaceDetailScreen(place: place),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: SizedBox(
                            height: 220,
                            width: double.infinity,
                            child: Hero(
                              tag: place.id,
                              child: FadeInImage.assetNetwork(
                                placeholder: 'assets/placeholder.png',
                                image: thumbnailUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  context.isDarkMode
                                      ? const Color(0xff1E1E1E).withOpacity(0.9)
                                      : const Color(
                                        0xffFAFAFA,
                                      ).withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color:
                                    isFav
                                        ? Colors.red
                                        : (context.isDarkMode
                                            ? Colors.white
                                            : Colors.black),
                              ),
                              onPressed: () async {
                                await toggleFavorite(
                                  placeId,
                                  placeName,
                                  isFav,
                                  context,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            data['nama'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.isDarkMode ? Colors.white : Colors.black,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              color: context.isDarkMode ? Colors.white : Colors.black,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Text(
                                data['rating'].toString(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: context.isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.timelapse_rounded,
                          color: Color(0xff98855A),
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          data['jambuka'].toString(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:
                                context.isDarkMode
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                        Text(" - "),
                        Text(
                          data['jamtutup'].toString(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:
                                context.isDarkMode
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
