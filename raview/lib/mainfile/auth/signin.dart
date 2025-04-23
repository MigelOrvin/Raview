import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:raview/designdata/assets/vector/vectorlink.dart';
import 'package:raview/designdata/assets/widgets/AppBar.dart';
import 'package:raview/designdata/assets/widgets/BasicButton.dart';
import 'package:raview/designdata/auto/isdarkmode.dart';
import 'package:raview/mainfile/auth/signup.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _register(context),
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
              _signInText(),
              const SizedBox(height: 100),
              _emailField(context),
              const SizedBox(height: 20),
              _passField(context),
              const SizedBox(height: 50),
              BasicButton(onPressed: () {}, title: "Sign In",),
            ],
          ),
        ),
      ),
    );
  }


   Widget _register(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Not a Member?",
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          TextButton(onPressed: () {
             Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context)=>SignUpPage()));
                              
          }, child: const Text("Register Now", style: TextStyle(color: Color(0xff98855A)),))
        ],
      ),
    );
  }

   Widget _signInText() {
    return Text(
      'Sign In',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 27,
        color: context.isDarkMode ? Colors.white : Colors.black,
      ),
      textAlign: TextAlign.center,
    );
  }

    Widget _emailField(BuildContext context) {
    return TextField(
      cursorColor: context.isDarkMode ? Colors.white : Colors.black,
      controller: _email,
      decoration: const InputDecoration(hintText: "Enter your Email")
          .applyDefaults(Theme.of(context).inputDecorationTheme),
    );
  }

  Widget _passField(BuildContext context) {
    return TextField(
      cursorColor: context.isDarkMode ? Colors.white : Colors.black,
      controller: _pass,
      obscureText: _obscureText,
      decoration: InputDecoration(
        hintText: "Password",
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      ).applyDefaults(Theme.of(context).inputDecorationTheme),
    );
  }

} 