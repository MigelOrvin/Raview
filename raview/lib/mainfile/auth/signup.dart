
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:raview/designdata/assets/vector/vectorlink.dart';
import 'package:raview/designdata/assets/widgets/AppBar.dart';
import 'package:raview/designdata/assets/widgets/BasicButton.dart';
import 'package:raview/designdata/auto/isdarkmode.dart';
import 'package:raview/mainfile/auth/signin.dart';
import 'package:raview/mainfile/homepage/home.dart';
import 'package:raview/service/auth/auth_service.dart';
import 'package:raview/service/model/createrequest.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  bool _obscureText = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _login(context),
      appBar: AppbarCommon(
        title: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: SvgPicture.asset(
            VectorLink.logoSplash,
            height: 113,
            width: 113,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 30),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _registerText(),
              const SizedBox(height: 100),
              _fullNameField(context),
              const SizedBox(height: 20),
              _emailField(context),
              const SizedBox(height: 20),
              _passField(context),
              const SizedBox(height: 20),
              BasicButton(
                onPressed: () async {
                  AuthService authService = AuthService();
                  var x = authService.signUp(
                    CreateRequest(
                      fullName: _fullName.text.toString(),
                      email: _email.text.toString(),
                      password: _pass.text.toString(),
                    ),
                  );

                  x.then((value) {
                    value.fold(
                      (l) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l.toString()),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      (r) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (BuildContext context) => const HomePage(),
                          ), (route) => false
                        );
                      },
                    );
                  });
                  

                  
                },
                title: "Make an Account",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _login(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Do you have an Account?",
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => const SignInPage(),
                ),
              );
            },
            child: Text("Sign In", style: TextStyle(color: Color(0xff98855A))),
          ),
        ],
      ),
    );
  }

  Widget _registerText() {
    return Text(
      'Register',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 27,
        color: context.isDarkMode ? Colors.white : Colors.black,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _fullNameField(BuildContext context) {
    return TextField(
      cursorColor: context.isDarkMode ? Colors.white : Colors.black,
      controller: _fullName,
      decoration: const InputDecoration(
        hintText: "Full Name",
      ).applyDefaults(Theme.of(context).inputDecorationTheme),
    );
  }

  Widget _emailField(BuildContext context) {
    return TextField(
      cursorColor: context.isDarkMode ? Colors.white : Colors.black,
      controller: _email,
      decoration: const InputDecoration(
        hintText: "Your Email",
      ).applyDefaults(Theme.of(context).inputDecorationTheme),
    );
  }

  Widget _passField(BuildContext context) {
    return TextField(
      cursorColor: context.isDarkMode ? Colors.white : Colors.black,
      controller: _pass,
      obscureText: _obscureText,
      decoration: InputDecoration(
        hintText: "Password",
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 25.0),
          child: IconButton(
            icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
          ),
        ),
      ).applyDefaults(Theme.of(context).inputDecorationTheme),
    );
  }
}
