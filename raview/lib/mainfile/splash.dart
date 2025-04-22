import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:raview/designdata/assets/vector/vectorlink.dart';
import 'package:raview/mainfile/auth/signup_signin.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    redirect();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
      child: SvgPicture.asset(
         VectorLink.logoSplash
      ),
    ),
    );
  }

  Future<void> redirect() async{
    await Future.delayed(const Duration(seconds: 2));
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => const SignupSigninScreen()));
  }
}