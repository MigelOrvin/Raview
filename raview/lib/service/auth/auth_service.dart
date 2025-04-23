import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:raview/service/model/createrequest.dart';
import 'package:raview/service/model/signinrequest.dart';

abstract class AuthFirebaseService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<Either> signUp(CreateRequest createRequest);
  Future<Either> signIn(SigninRequest signinRequest);
}

class AuthService extends AuthFirebaseService{
  @override
  Future<Either> signUp(CreateRequest createRequest) async{
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: createRequest.email,
        password: createRequest.password,
      );

      return const Right('Sign Up was Successful');
    }on FirebaseAuthException catch(e){
      String message = "";
      if (e.code == "weak-password") {
        message = "The password provided is too weak.";
      } else if(e.code == "email-already-in-use"){
        message = "The account already exists for that email.";
      } 
      return left(message);
    }
  }
  
  @override
  Future<Either> signIn(SigninRequest signinRequest) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: signinRequest.email,
        password: signinRequest.password,
      );
      return const Right('Sign In was Successful');
    } on FirebaseAuthException catch(e){
      String message = "";
      if (e.code == "user-not-found") {
        message = "No user found for that email.";
      } else if(e.code == "wrong-password"){
        message = "Wrong password provided for that user.";
      } else if(e.code == "invalid-email"){
        message = "The email address is badly formatted.";
      } else if(e.code == "user-disabled"){
        message = "User with this email has been disabled.";
      } else if(e.code == "operation-not-allowed"){
        message = "Signing in with Email and Password is not enabled.";
      } else {
        message = e.message.toString();
      }
      return left(message);
    }
  }

}