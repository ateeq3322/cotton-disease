import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = cred.user;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();         // ← send verification email
      }
      return user;
    } catch (e) {
      print("Signup Error: $e");
      return null;
    }
  }

  Future<User?> login(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = cred.user;
      if (user != null && !user.emailVerified) {
        // optional: logout user and prompt verification
        await _auth.signOut();
        throw FirebaseAuthException(
            code: 'email-not-verified',
            message: 'Please verify your email before login.');
      }
      return user;
    } catch (e) {
      print("Login Error: $e");
      return null;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print("Password Reset Error: $e");
      throw e;
    }
  }

  String? currentUserEmail() {
    return _auth.currentUser?.email;
  }
}
