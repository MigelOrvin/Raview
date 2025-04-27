
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:raview/designdata/assets/vector/vectorlink.dart';
import 'package:raview/designdata/assets/widgets/BasicButton.dart';
import 'package:raview/designdata/assets/widgets/snackbar.dart';
import 'package:raview/designdata/auto/isdarkmode.dart';
import 'package:raview/mainfile/auth/signin.dart';
import 'package:raview/mainfile/auth/signup.dart';

class SignupSigninScreen extends StatefulWidget {
  const SignupSigninScreen({super.key});

  @override
  State<SignupSigninScreen> createState() => _SignupSigninScreenState();
}

class _SignupSigninScreenState extends State<SignupSigninScreen> {

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 1), () {
    showSnackBar();
  });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: SvgPicture.asset(VectorLink.topUnion),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: SvgPicture.asset(VectorLink.bottomUnion),
          ),
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: SizedBox(
                      height: 150,
                      width: 250,
                      child: SvgPicture.asset(
                        VectorLink.logoSplash,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const Text(
                    "Rasa Review",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "Raview adalah layanan yang menyediakan rekomendasi tempat makan terbaik untuk anda",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: context.isDarkMode ? Colors.white : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: BasicButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (BuildContext context) => SignUpPage(),
                              ),
                            );
                          },
                          title: "Register",
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (BuildContext context) => SignInPage(),
                              ),
                            );
                          },
                          child: Text(
                            "Sign In",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color:
                                  context.isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> showSnackBar() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
       final snackbar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(title: "Warning!", message: "Location permission is required to proceed. Please enable it in your settings.", contentType: ContentType.warning, color: Color(0xff98855A),),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
    }
    
  }
}
