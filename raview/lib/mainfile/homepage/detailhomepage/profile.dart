import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:raview/designdata/assets/widgets/AppBar.dart';
import 'package:raview/designdata/auto/isdarkmode.dart';
import 'package:raview/mainfile/auth/signup_signin.dart';

class profileScreen extends StatelessWidget {
  const profileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppbarCommon(
        backgroundColor: context.isDarkMode ? Colors.black : Colors.white,
        hideBack: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _profileInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _profileInfo(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height / 3.5,
      decoration: BoxDecoration(
        color: context.isDarkMode ? Colors.black : Colors.white,
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(50),
          bottomLeft: Radius.circular(50),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2, 
            blurRadius: 10, 
            offset: const Offset(0, 5), 
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                "${FirebaseAuth.instance.currentUser!.photoURL}",
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            "${FirebaseAuth.instance.currentUser!.displayName}",
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "${FirebaseAuth.instance.currentUser!.email}",
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 10),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.center, 
          //   children: [
          //     GestureDetector(
          //       onTap: () {
          //         FirebaseAuth.instance.signOut();
          //         Navigator.pushAndRemoveUntil(
          //           context,
          //           MaterialPageRoute(
          //             builder: (BuildContext context) => const SignupSigninScreen(),
          //           ),
          //           (route) => false,
          //         );
          //       },
          //       child: Column(
          //         children: [
          //           const Icon(
          //             Icons.logout,
          //             color: Colors.red,
          //             size: 30,
          //           ),
          //         ],
          //       ),
          //     ),
          //     const SizedBox(width: 20), // Add spacing between buttons
          //     GestureDetector(
          //       onTap: () {
          //         // Add edit functionality here
          //       },
          //       child: Column(
          //         children: [
          //           const Icon(
          //             Icons.edit,
          //             color: Colors.blue,
          //             size: 30,
          //           ),
          //           const SizedBox(height: 5),
          //           const Text(
          //             "Edit",
          //             style: TextStyle(
          //               color: Colors.blue,
          //               fontSize: 14,
          //               fontWeight: FontWeight.bold,
          //             ),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
}
