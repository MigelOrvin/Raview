import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:raview/service/model/createrequest.dart';

abstract class AuthFirebaseService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<Either> signUp(CreateRequest createRequest);
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

}