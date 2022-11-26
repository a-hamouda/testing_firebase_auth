import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'server_exception.dart';

class AuthRepo {
  const AuthRepo({
    required GoogleSignIn googleSignIn,
    required FirebaseAuth firebaseAuth,
  })  : _googleSignIn = googleSignIn,
        _firebaseAuth = firebaseAuth;

  final GoogleSignIn _googleSignIn;
  final FirebaseAuth _firebaseAuth;

  Future<void> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw const ServerException('Cancelled');
      } else {
        final googleAuthentication = await googleUser.authentication;

        final authCredential = GoogleAuthProvider.credential(
          idToken: googleAuthentication.idToken,
          accessToken: googleAuthentication.accessToken,
        );

        await _firebaseAuth.signInWithCredential(authCredential);
      }
    } on FirebaseAuthException catch (e) {
      throw ServerException(e.message!);
    }
  }
}
