import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>(
  (ref) => FirebaseAuthService(),
);

class FirebaseAuthIdentity {
  const FirebaseAuthIdentity({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.isAdmin,
  });

  final String uid;
  final String email;
  final String? displayName;
  final bool isAdmin;

  String get username {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return email.split('@').first;
  }
}

/// Thin Firebase Authentication adapter. When Firebase is not configured for
/// the current platform, the controller can continue using its local adapter.
class FirebaseAuthService {
  bool get isAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<FirebaseAuthIdentity?> currentIdentity() async {
    if (!isAvailable) return null;
    final user = FirebaseAuth.instance.currentUser;
    return user == null ? null : await _identity(user);
  }

  Future<FirebaseAuthIdentity> signIn({
    required String email,
    required String password,
  }) async {
    if (!isAvailable) {
      throw Exception('Firebase is not configured on this platform.');
    }
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) throw Exception('Sign-in did not return a user.');
      return _identity(user);
    } on FirebaseAuthException catch (error) {
      throw Exception(_messageFor(error));
    }
  }

  Future<FirebaseAuthIdentity> createAccount({
    required String email,
    required String password,
  }) async {
    if (!isAvailable) {
      throw Exception('Firebase is not configured on this platform.');
    }
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      final user = credential.user;
      if (user == null) throw Exception('Account creation did not complete.');
      return _identity(user);
    } on FirebaseAuthException catch (error) {
      throw Exception(_messageFor(error));
    }
  }

  Future<void> signOut() async {
    if (isAvailable) {
      await FirebaseAuth.instance.signOut();
    }
  }

  Future<FirebaseAuthIdentity> _identity(User user) async {
    final claims = (await user.getIdTokenResult()).claims ?? const {};
    return FirebaseAuthIdentity(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      isAdmin: claims['admin'] == true || claims['role'] == 'admin',
    );
  }

  String _messageFor(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-not-found':
      case 'invalid-credential':
        return 'No account matches those sign-in details.';
      case 'wrong-password':
        return 'The password is incorrect.';
      case 'email-already-in-use':
        return 'That email already has an account. Try signing in.';
      case 'weak-password':
        return 'Choose a stronger password with at least 8 characters.';
      case 'network-request-failed':
        return 'No internet connection. Please reconnect and try again.';
      default:
        return 'We could not complete that request. Please try again.';
    }
  }
}
