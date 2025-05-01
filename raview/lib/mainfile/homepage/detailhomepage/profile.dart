import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
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
  String? _base64Image;
  final ImagePicker _picker = ImagePicker();
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          context.isDarkMode
              ? const Color(0xff292828)
              : const Color(0xffFAFAFA),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [_profileInfo(context)],
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
                  _buildStats(context),
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
          Container(
            alignment: Alignment.center,
            height: 104,
            width: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(
                  userData['profilePicture'] ??
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2c/Default_pfp.svg/2048px-Default_pfp.svg.png',
                ),
                fit: BoxFit.cover,
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
              text: _isEmailVisible ?  userData['email'] : _obfuscateEmail(userData['email']),
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
            Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
          },
          child: Icon(
            Icons.edit,
            color: context.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildStats(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "30",
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
        Text(
          "20",
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
    final obfuscatedUsername = username.length > 2
        ? '${username[0]}${'*' * (username.length - 2)}${username[username.length - 1]}'
        : '*' * username.length;
    return '$obfuscatedUsername@$domain';
  }

  Future<void> _compressAndEncodeImage() async {
    if (_image == null) return;
    final compressedImage = await FlutterImageCompress.compressWithFile(
      _image!.path,
      quality: 50,
    );
    if (compressedImage == null) return;
    setState(() {
      _base64Image = base64Encode(compressedImage);
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await _compressAndEncodeImage();
    }
  }

  
}
