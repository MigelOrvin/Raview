import 'package:another_carousel_pro/another_carousel_pro.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Displaylistplace extends StatefulWidget {
  final String jenis;
  const Displaylistplace({super.key, required this.jenis});

  @override
  State<Displaylistplace> createState() => _DisplaylistplaceState();
}

class _DisplaylistplaceState extends State<Displaylistplace> {
  final CollectionReference placeCollection = FirebaseFirestore.instance.collection('allPlace');

  // Tambahkan variabel untuk menandai loading gambar
  bool _imagesPrecached = false;

  @override
  Widget build(BuildContext context) {
    final isAll = widget.jenis.toLowerCase() == 'all';
    final stream = isAll
        ? placeCollection.snapshots()
        : placeCollection.where('jenis', isEqualTo: widget.jenis).snapshots();

    return StreamBuilder(
      stream: stream,
      builder: (context, streamSnapshot) {
        if (streamSnapshot.hasData) {
          final docs = streamSnapshot.data!.docs;

          // Kumpulkan semua url gambar
          final allImages = <String>[];
          for (var doc in docs) {
            allImages.addAll(List<String>.from(doc['images']));
          }

          // Precache semua gambar hanya sekali
          if (!_imagesPrecached && allImages.isNotEmpty) {
            _imagesPrecached = true;
            Future.wait(
              allImages.map((url) => precacheImage(NetworkImage(url), context)),
            ).then((_) {
              if (mounted) setState(() {});
            });
            // Tampilkan loading saat proses precache
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final place = docs[index];
              final images = List<String>.from(place['images']);

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () {},
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: SizedBox(
                          height: 360,
                          width: double.infinity,
                          child: AnotherCarousel(
                            images: images.map((url) => NetworkImage(url)).toList(),
                            dotSize: 6,
                            animationCurve: Curves.easeInOut,
                            indicatorBgPadding: 5,
                            autoplayDuration: Duration(seconds: 5),
                            dotBgColor: Colors.transparent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
