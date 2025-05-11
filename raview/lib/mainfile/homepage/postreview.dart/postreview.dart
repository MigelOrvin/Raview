import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:raview/designdata/assets/widgets/BasicButton.dart';
import 'package:raview/designdata/assets/widgets/snackbar.dart';
import 'package:raview/designdata/auto/isdarkmode.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Postreview extends StatefulWidget {
  final DocumentSnapshot place;
  final DocumentSnapshot? existingReview;
  
  const Postreview({
    super.key, 
    required this.place, 
    this.existingReview,
  });

  @override
  State<Postreview> createState() => _PostreviewState();
}

class _PostreviewState extends State<Postreview> {
  final TextEditingController _commentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<File> _images = [];
  bool _isUploading = false;
  int _rating = 0; 

  @override
  void initState() {
    super.initState();
    
    // Load Komen
    if (widget.existingReview != null) {
      final data = widget.existingReview!.data() as Map<String, dynamic>;
      _commentController.text = data['comment'] ?? '';
      _rating = data['rating'] ?? 0;
      
      // Load existing image URLs
      final List<dynamic> existingImageUrls = data['imageUrls'] ?? [];
      _existingImageUrls = List<String>.from(existingImageUrls);
    }
  }
  
  // Simpan Image
  List<String> _existingImageUrls = [];

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            context.isDarkMode ? const Color(0xff292828) : Colors.white,
        title: Text("Choose Image Source"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImages(ImageSource.camera);
            },
            child: Text(
              "Camera",
              style: TextStyle(
                color: context.isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImages(ImageSource.gallery);
            },
            child: Text(
              "Gallery",
              style: TextStyle(
                color: context.isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages(ImageSource source) async {
    if (_images.length >= 3) return;
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      final compressedImage = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        quality: 60,
      );
      if (compressedImage != null) {
        final compressedFile = File('${imageFile.path}_compressed');
        await compressedFile.writeAsBytes(compressedImage);
        setState(() {
          if (_images.length < 3) {
            _images.add(compressedFile);
          }
        });
      }
    }
  }

  Future<List<String>> _uploadImages() async {
    List<String> urls = [];
    for (var image in _images) {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('reviewImages')
          .child(
              '$userId-${DateTime.now().millisecondsSinceEpoch}-${_images.indexOf(image)}.jpg');
      await storageRef.putFile(image);
      final url = await storageRef.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }
  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      final errorSnackbar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: "Error",
          message: 'Please write a review comment',
          contentType: ContentType.failure,
          color: Colors.red,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar);
      return;
    }
    
    if (_rating == 0) {
      final errorSnackbar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: "Error",
          message: 'Please Add a Rating',
          contentType: ContentType.failure,
          color: Colors.red,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar);
      return;
    }

    setState(() => _isUploading = true);

    try {
      List<String> imageUrls = [];
      if (_images.isNotEmpty) {
        imageUrls = await _uploadImages();
      }
      
      // Gabungin image yg di firebase sm yg di upload
      final allImageUrls = [..._existingImageUrls, ...imageUrls];
      
      final user = FirebaseAuth.instance.currentUser;
      
      
      final bool isEditing = widget.existingReview != null;
      
      // mbil rating sebelumnya kalo diedit
      int previousRating = 0;
      if (isEditing) {
        final reviewData = widget.existingReview!.data() as Map<String, dynamic>;
        previousRating = reviewData['rating'] ?? 0;
      }

      // Buat/edit review
      if (isEditing) {
        await FirebaseFirestore.instance
            .collection('reviews')
            .doc(widget.existingReview!.id)
            .update({
          'comment': _commentController.text.trim(),
          'imageUrls': allImageUrls,
          'rating': _rating,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseFirestore.instance.collection('reviews').add({
          'placeId': widget.place.id,
          'userId': user!.uid,
          'comment': _commentController.text.trim(),
          'imageUrls': allImageUrls,
          'rating': _rating,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      final placeRef = FirebaseFirestore.instance
          .collection('allPlace')
          .doc(widget.place.id);
      
      final docSnapshot = await placeRef.get();
      if (!docSnapshot.exists) {
        throw Exception("Document tidak ditemukan. ID: ${widget.place.id}");
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final placeSnapshot = await transaction.get(placeRef);
        
        final placeData = placeSnapshot.data() as Map<String, dynamic>;
        final currentReviewCount = placeData['review'] ?? 0;
        final currentRating = placeData['rating'] ?? 0.0;

        final double currentRatingDouble = currentRating is int 
            ? currentRating.toDouble() 
            : currentRating;

        if (isEditing) {
          // Updatee FIREBASEEEAAAAAAAAAAAAAAA
          final totalRating = (currentRatingDouble * currentReviewCount) - previousRating + _rating;
          final newRating = totalRating / currentReviewCount;
          
          transaction.update(placeRef, {
            'rating': double.parse(newRating.toStringAsFixed(1)),
          });
        } else {
          // Add a new review
          final newReviewCount = currentReviewCount + 1;
          final totalRating = (currentRatingDouble * currentReviewCount) + _rating;
          final newRating = totalRating / newReviewCount;

          transaction.update(placeRef, {
            'review': newReviewCount,
            'rating': double.parse(newRating.toStringAsFixed(1)),
          });
          
          // Nmbhin review kalo baru pertm kali review
          await FirebaseFirestore.instance
            .collection('Users')
            .doc(user!.uid)
            .update({
              'reviews': FieldValue.increment(1)
            });
        }
      });

      setState(() {
        _commentController.clear();
        _images.clear();
        _existingImageUrls.clear();
        _rating = 0;
        _isUploading = false;
      });

      final successSnackbar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: "Success",
          message: isEditing 
              ? "Review successfully updated!" 
              : "Review successfully submitted!",
          contentType: ContentType.success,
          color: Color(0xff98855A),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(successSnackbar);

      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isUploading = false);
      
      final errorSnackbar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: "Error",
          message: e.toString(),
          contentType: ContentType.failure,
          color: Colors.red,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar);
    }
  }
  Widget _imagePickerRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_existingImageUrls.isNotEmpty) ...[
          Text(
            "Existing Images",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: context.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              ..._existingImageUrls.map((url) => Stack(
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: 8),
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: context.isDarkMode
                              ? Colors.grey[800]
                              : Colors.grey[300],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(url, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _existingImageUrls.remove(url);
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.close, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  )),
            ],
          ),
          SizedBox(height: 16),
        ],
        Text(
          _existingImageUrls.isNotEmpty ? "New Images" : "Add Images",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: context.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            ..._images.map((img) => Stack(
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: 8),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: context.isDarkMode
                            ? Colors.grey[800]
                            : Colors.grey[300],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(img, fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _images.remove(img);
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                )),
            if (_images.length < 3)
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: context.isDarkMode ? Colors.grey[800] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.add_a_photo, size: 32, color: Colors.grey),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _ratingStars() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Rating",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: context.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _rating = index + 1;
                });
              },
              child: Icon(
                index < _rating ? Icons.star : Icons.star_border,
                color: index < _rating
                    ? Color(0xff98855A)
                    : Colors.grey,
                size: 36,
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: BasicButton(
                  onPressed: _submitReview,
                  title: widget.existingReview != null ? "Update Review" : "Post Review",
                ),
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.only(
              top: 40,
              bottom: 20,
              right: 25,
              left: 25,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[200],
                          ),
                          child: Icon(Icons.close, color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 20),                      Expanded(
                        child: Text(
                          widget.existingReview != null ? 'Edit Review' : 'Post Review',
                          style: TextStyle(
                            color: context.isDarkMode ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 36),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  _imagePickerRow(),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _commentController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: "Write your review here...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                const SizedBox(height: 30),
                _ratingStars(),
              ],
            ),
          ),
        ),
      ),
      if (_isUploading)
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: Colors.black.withOpacity(0.2),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.isDarkMode 
                        ? Colors.grey[800] 
                        : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xff98855A)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
  }
}
