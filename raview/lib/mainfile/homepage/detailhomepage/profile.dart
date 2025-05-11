import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:raview/designdata/auto/change_mode_theme_provider.dart';
import 'package:raview/designdata/auto/isdarkmode.dart';
import 'package:raview/mainfile/auth/signin.dart';
import 'package:raview/service/auth/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String? locality;

  const ProfileScreen({
    super.key,
    this.latitude,
    this.longitude,
    required this.locality,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEmailVisible = false;
  File? _image;
  final ImagePicker _picker = ImagePicker();
  int _wishlistCount = 0;
  bool _isLoadingWishlist = true;

  @override
  void initState() {
    super.initState();
    _fetchWishlistCount();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          context.isDarkMode
              ? const Color(0xff292828)
              : const Color(0xffFAFAFA),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _profileInfo(context),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 25),
            child: Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: context.isDarkMode ? const Color(0xff1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: context.isDarkMode
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        context.isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
                        color: context.isDarkMode ? Colors.white : Colors.black,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Dark Mode",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: context.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      width: 50,
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: context.isDarkMode 
                            ? Color(0xff98855A) 
                            : Colors.grey.shade300,
                      ),
                      child: Stack(
                        children: [
                          AnimatedPositioned(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            left: context.isDarkMode ? 22 : 0,
                            right: context.isDarkMode ? 0 : 22,
                            top: 2,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  )
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  context.isDarkMode 
                                      ? Icons.nightlight_round 
                                      : Icons.wb_sunny,
                                  size: 14,
                                  color: context.isDarkMode 
                                      ? Color(0xff98855A) 
                                      : Colors.orange,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileInfo(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('Users')
              .doc(userId)
              .snapshots(),
      builder: (context, snapshot) {
        Widget child;

        if (snapshot.connectionState == ConnectionState.waiting) {
          child = const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          child = Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || !snapshot.data!.exists) {
          child = const Center(child: Text('User not found'));
        } else {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          child = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildUserInfo(context, userData),
                  _buildActions(context),
                  _buildStats(context, userData),
                  const SizedBox(width: 1),
                ],
              ),
            ],
          );
        }

        return Container(
          width: double.infinity,
          height: 307,
          decoration: BoxDecoration(
            color: context.isDarkMode ? const Color(0xff1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(50),
              bottomRight: Radius.circular(50),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    context.isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                spreadRadius: 5,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }

  Widget _buildUserInfo(BuildContext context, Map<String, dynamic> userData) {
    return Container(
      width: 250,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          InkResponse(
            onTap: () {
              _showFullImageDialog(
                userData['profilePicture'] ??
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2c/Default_pfp.svg/2048px-Default_pfp.svg.png',
              );
            },
            onDoubleTap: () {
              _showImageSourceDialog();
            },
            child: Container(
              alignment: Alignment.center,
              height: 104,
              width: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      context.isDarkMode
                          ? const Color.fromARGB(255, 255, 255, 255)
                          : const Color.fromARGB(255, 77, 77, 77),
                  width: 2,
                ),
                image: DecorationImage(
                  image: NetworkImage(
                    userData['profilePicture'] ??
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2c/Default_pfp.svg/2048px-Default_pfp.svg.png',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          Text(
            userData['name'] != null && userData['name'].length > 10
                ? '${userData['name'].substring(0, 10)}...'
                : userData['name'] ?? 'User Name',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: context.isDarkMode ? Colors.white : Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text.rich(
            TextSpan(
              text:
                  _isEmailVisible
                      ? userData['email']
                      : _obfuscateEmail(userData['email']),
              style: TextStyle(
                fontSize: 14,
                color: context.isDarkMode ? Colors.white : Colors.black,
              ),
              children: [
                WidgetSpan(
                  child: GestureDetector(
                    child: Icon(
                      _isEmailVisible ? Icons.visibility_off : Icons.visibility,
                      size: 14,
                      color: context.isDarkMode ? Colors.white : Colors.black,
                    ),
                    onTap: () {
                      setState(() {
                        _isEmailVisible = !_isEmailVisible;
                      });
                    },
                  ),
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          widget.locality == null
              ? const CircularProgressIndicator()
              : Text.rich(
                TextSpan(
                  text: "Lokasi anda: ",
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        context.isDarkMode
                            ? const Color.fromARGB(232, 255, 255, 255)
                            : const Color.fromARGB(255, 77, 77, 77),
                  ),
                  children: [
                    TextSpan(
                      text: widget.locality,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: context.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                overflow: TextOverflow.visible,
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
        ],
      ),
    );
  }
  Widget _buildActions(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            AuthService().signOut();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => const SignInPage(),
              ),
              (route) => false,
            );
          },
          child: const Icon(Icons.logout, color: Colors.red),
        ),
        const SizedBox(height: 100),
        GestureDetector(
          onTap: () {
            _showEditUsernameDialog(context);
          },
          child: Icon(
            Icons.edit,
            color: context.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildStats(BuildContext context, Map<String, dynamic> userData) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        userData['reviews'] != null
            ? userData['reviews'].toString()
            : '0',
        style: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.bold,
          color: context.isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      Text(
        "Reviews",
        style: TextStyle(
          fontSize: 14,
          color: context.isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      const Text("________"),
      _isLoadingWishlist
          ? SizedBox(
              height: 25,
              width: 25,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  context.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            )
          : Text(
              _wishlistCount.toString(),
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: context.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
      Text(
        "Wishlist",
        style: TextStyle(
          fontSize: 14,
          color: context.isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    ],
  );
}

  String _obfuscateEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final username = parts[0];
    final domain = parts[1];
    final obfuscatedUsername =
        username.length > 2
            ? '${username[0]}${'*' * (username.length - 2)}${username[username.length - 1]}'
            : '*' * username.length;
    return '$obfuscatedUsername@$domain';
  }

  Future<void> _fetchWishlistCount() async {
    setState(() {
      _isLoadingWishlist = true;
    });
    
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final querySnapshot = await FirebaseFirestore.instance
          .collection('wishlist')
          .where('userId', isEqualTo: userId)
          .get();
      
      setState(() {
        _wishlistCount = querySnapshot.docs.length;
        _isLoadingWishlist = false;
      });
    } catch (e) {
      print('Error fetching wishlist count: $e');
      setState(() {
        _isLoadingWishlist = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
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

        final userId = FirebaseAuth.instance.currentUser!.uid;
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profilePictures')
            .child('$userId.jpg');

        try {
          await storageRef.putFile(compressedFile);
          final downloadUrl = await storageRef.getDownloadURL();
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(userId)
              .update({'profilePicture': downloadUrl});

          setState(() {
            _image = compressedFile;
          });
        } catch (e) {
          print('Error uploading image: $e');
        }
      }
    }
  }

  Future<String?> getImage() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profilePictures')
          .child('$userId.jpg');
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error fetching image URL: $e');
      return null;
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor:
                context.isDarkMode ? const Color(0xff292828) : Colors.white,
            title: Text("Choose Image Source"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
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
                  _pickImage(ImageSource.gallery);
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
                child: Container(
                  color: Colors.black.withOpacity(0.5), 
                ),
              ),
            ),
             Dialog(
                backgroundColor: Colors.transparent, 
                insetPadding: EdgeInsets.all(10), 
                child: GestureDetector(
                  onTap: () {}, 
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showEditUsernameDialog(BuildContext context) {
    final TextEditingController _usernameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.isDarkMode ? const Color(0xff292828) : Colors.white,
        title: Text(
          "Edit Username",
          style: TextStyle(
            color: context.isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _usernameController,
              style: TextStyle(
                color: context.isDarkMode ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: "Enter new username",
                hintStyle: TextStyle(
                  color: context.isDarkMode ? Colors.white70 : Colors.black54,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: Color(0xff98855A),
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: Color(0xff98855A),
                    width: 2,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Dark Mode",
                  style: TextStyle(
                    color: context.isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    width: 50,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: context.isDarkMode 
                          ? Color(0xff98855A) 
                          : Colors.grey.shade300,
                    ),
                    child: Stack(
                      children: [
                        AnimatedPositioned(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          left: context.isDarkMode ? 22 : 0,
                          right: context.isDarkMode ? 0 : 22,
                          top: 2,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                )
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                context.isDarkMode 
                                    ? Icons.nightlight_round 
                                    : Icons.wb_sunny,
                                size: 16,
                                color: context.isDarkMode 
                                    ? Color(0xff98855A) 
                                    : Colors.orange,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: Color(0xff98855A),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (_usernameController.text.isNotEmpty) {
                final userId = FirebaseAuth.instance.currentUser!.uid;
                await FirebaseFirestore.instance
                    .collection('Users')
                    .doc(userId)
                    .update({'name': _usernameController.text});
                Navigator.pop(context);
              }
            },
            child: Text(
              "Save",
              style: TextStyle(
                color: Color(0xff98855A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
