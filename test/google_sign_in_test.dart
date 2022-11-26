import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:testing_firebase_auth/auth_repo.dart';
import 'package:testing_firebase_auth/server_exception.dart';

import 'google_sign_in_test.mocks.dart';

@GenerateMocks([
  GoogleSignIn,
  FirebaseAuth,
  GoogleSignInAccount,
  GoogleSignInAuthentication,
  UserCredential,
  FirebaseAuthException,
])
void main() {
  group('Google sign in', () {
    late final GoogleSignIn mockGoogleSignIn;
    late final MockFirebaseAuth mockFirebaseAuth;
    late final AuthRepo sut;

    setUpAll(() {
      mockGoogleSignIn = MockGoogleSignIn();
      mockFirebaseAuth = MockFirebaseAuth();
      sut = AuthRepo(
        googleSignIn: mockGoogleSignIn,
        firebaseAuth: mockFirebaseAuth,
      );
    });

    tearDown(() {
      reset(mockGoogleSignIn);
      reset(mockFirebaseAuth);
    });

    test('should return normally on successful sign in', () {
      // arrange
      const fakeIdToken = 'fakeIdToken';
      const fakeAccessToken = 'fakeAccessToken';
      final googleAccount = MockGoogleSignInAccount();
      final googleSignInAuth = MockGoogleSignInAuthentication();
      final userCredential = MockUserCredential();

      // stub
      when(mockGoogleSignIn.signIn())
          .thenAnswer((_) => Future.value(googleAccount));
      when(googleAccount.authentication)
          .thenAnswer((_) => Future.value(googleSignInAuth));
      when(googleSignInAuth.idToken).thenReturn(fakeIdToken);
      when(googleSignInAuth.accessToken).thenReturn(fakeAccessToken);
      when(mockFirebaseAuth.signInWithCredential(any))
          .thenAnswer((_) => Future.value(userCredential));

      // assert
      expect(() async => sut.signInWithGoogle(), returnsNormally);
    });

    test(
        'should throw $ServerException with message "Canceled" if user '
        'dismissed sign in popup', () {
      // stub
      when(mockGoogleSignIn.signIn()).thenAnswer((_) => Future.value());

      // assert
      expect(
        () async => sut.signInWithGoogle(),
        throwsA(isA<ServerException>()
            .having((e) => e.message, 'message', equals('Cancelled'))),
      );
    });

    test(
        'should throw $ServerException with message from '
        '$FirebaseAuthException when signing with google credential fails', () {
      // arrange
      const fakeExceptionMessage = 'Fake message coming from Firebase Auth';
      const fakeIdToken = 'fakeIdToken';
      const fakeAccessToken = 'fakeAccessToken';
      final googleAccount = MockGoogleSignInAccount();
      final googleSignInAuth = MockGoogleSignInAuthentication();
      final firebaseAuthException = MockFirebaseAuthException();

      // stub
      when(mockGoogleSignIn.signIn())
          .thenAnswer((_) => Future.value(googleAccount));
      when(googleAccount.authentication)
          .thenAnswer((_) => Future.value(googleSignInAuth));
      when(googleSignInAuth.idToken).thenReturn(fakeIdToken);
      when(googleSignInAuth.accessToken).thenReturn(fakeAccessToken);
      when(mockFirebaseAuth.signInWithCredential(any))
          .thenThrow(firebaseAuthException);
      when(firebaseAuthException.message).thenReturn(fakeExceptionMessage);

      // assert
      expect(
          () async => sut.signInWithGoogle(),
          throwsA(isA<ServerException>()
              .having((e) => e.message, 'message', fakeExceptionMessage)));
    });
  });
}
