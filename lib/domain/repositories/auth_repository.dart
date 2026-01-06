import 'package:firebase_auth/firebase_auth.dart';

/// Authentication repository interface
abstract class AuthRepository {
  /// Get current user
  User? get currentUser;
  
  /// Stream of auth state changes
  Stream<User?> get authStateChanges;
  
  /// Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password);
  
  /// Sign in with Google
  Future<UserCredential> signInWithGoogle();
  
  /// Create user with email and password
  Future<UserCredential> createUserWithEmail(String email, String password);
  
  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email);
  
  /// Sign out
  Future<void> signOut();
  
  /// Update user profile
  Future<void> updateProfile({String? displayName, String? photoURL});
  
  /// Update password
  Future<void> updatePassword(String newPassword);
  
  /// Delete account
  Future<void> deleteAccount();
  
  /// Re-authenticate user (required before sensitive operations)
  Future<void> reauthenticate(String password);
}
