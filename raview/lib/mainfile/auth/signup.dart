import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:raview/designdata/assets/vector/vectorlink.dart';
import 'package:raview/designdata/assets/widgets/AppBar.dart';
import 'package:raview/designdata/assets/widgets/BasicButton.dart';
import 'package:raview/designdata/assets/widgets/snackbar.dart';
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
  final _formKey = GlobalKey<FormState>();
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
          child: Form(
            key: _formKey,
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
                    if (_formKey.currentState!.validate()) {
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
                            final snackbar = SnackBar(
                              elevation: 0,
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.transparent,
                              content: AwesomeSnackbarContent(
                                title: "Warning!",
                                message: l.toString(),
                                contentType: ContentType.warning,
                                color: Color(0xff98855A),
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(snackbar);
                          },
                          (r) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (BuildContext context) => const HomePage(),
                              ),
                              (route) => false,
                            );
                          },
                        );
                      });
                    }
                  },
                  title: "Make an Account",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fullNameField(BuildContext context) {
    return TextFormField(
      cursorColor: context.isDarkMode ? Colors.white : Colors.black,
      controller: _fullName,
      decoration: const InputDecoration(
        hintText: "Full Name",
      ).applyDefaults(Theme.of(context).inputDecorationTheme),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Full Name is required";
        }
        return null;
      },
    );
  }

  Widget _emailField(BuildContext context) {
    return TextFormField(
      cursorColor: context.isDarkMode ? Colors.white : Colors.black,
      controller: _email,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        hintText: "Your Email",
      ).applyDefaults(Theme.of(context).inputDecorationTheme),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Email is required";
        }
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return "Enter a valid email";
        }
        return null;
      },
    );
  }

  Widget _passField(BuildContext context) {
    return TextFormField(
      cursorColor: context.isDarkMode ? Colors.white : Colors.black,
      controller: _pass,
      obscureText: _obscureText,
      decoration: InputDecoration(
        hintText: "Password",
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 20.0),
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Password is required";
        }
        if (value.length < 6) {
          return "Password must be at least 6 characters";
        }
        return null;
      },
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
}
