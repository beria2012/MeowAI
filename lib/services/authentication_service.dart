import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

import '../models/user.dart' as app_user;
import 'database_service.dart';

class AuthenticationService {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      'https://www.googleapis.com/auth/photoslibrary.readonly',
      'https://www.googleapis.com/auth/photoslibrary.appendonly',
    ],
  );
  
  final DatabaseService _databaseService = DatabaseService();
  
  // Current user stream
  Stream<app_user.User?> get userStream => _firebaseAuth.authStateChanges()
      .asyncMap((firebaseUser) => _convertFirebaseUser(firebaseUser));
  
  // Current user
  app_user.User? _currentUser;
  app_user.User? get currentUser => _currentUser;
  
  // Authentication state
  bool get isAuthenticated => _firebaseAuth.currentUser != null;
  bool get isAnonymous => _firebaseAuth.currentUser?.isAnonymous ?? false;
  
  // Singleton pattern
  static final AuthenticationService _instance = AuthenticationService._internal();
  factory AuthenticationService() => _instance;
  AuthenticationService._internal() {
    _initialize();
  }

  /// Initialize the authentication service
  Future<void> _initialize() async {
    // Listen to auth state changes
    _firebaseAuth.authStateChanges().listen((firebaseUser) async {
      _currentUser = await _convertFirebaseUser(firebaseUser);
      if (_currentUser != null) {
        await _databaseService.saveUser(_currentUser!);
      }
    });
    
    // Load current user from local storage
    _currentUser = await _databaseService.getCurrentUser();
  }

  /// Convert Firebase user to app user
  Future<app_user.User?> _convertFirebaseUser(firebase_auth.User? firebaseUser) async {
    if (firebaseUser == null) return null;
    
    try {
      // Get existing user preferences or create default ones
      final preferences = await _databaseService.getUserPreferences() 
          ?? app_user.UserPreferences.defaultPreferences();
      
      // Get or create user stats
      final stats = app_user.UserStats(); // This could be loaded from database
      
      return app_user.User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
        createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
        lastLoginAt: DateTime.now(),
        preferences: preferences,
        stats: stats,
        isAnonymous: firebaseUser.isAnonymous,
      );
    } catch (e) {
      print('Error converting Firebase user: $e');
      return null;
    }
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return AuthResult.cancelled();
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final firebase_auth.UserCredential userCredential = 
          await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user != null) {
        _currentUser = await _convertFirebaseUser(userCredential.user);
        await _databaseService.saveUser(_currentUser!);
        return AuthResult.success(_currentUser!);
      } else {
        return AuthResult.failure('Failed to sign in with Google');
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      return AuthResult.failure('Google sign-in failed: ${e.toString()}');
    }
  }

  /// Sign in anonymously
  Future<AuthResult> signInAnonymously() async {
    try {
      final firebase_auth.UserCredential userCredential = 
          await _firebaseAuth.signInAnonymously();

      if (userCredential.user != null) {
        _currentUser = await _convertFirebaseUser(userCredential.user);
        await _databaseService.saveUser(_currentUser!);
        return AuthResult.success(_currentUser!);
      } else {
        return AuthResult.failure('Failed to sign in anonymously');
      }
    } catch (e) {
      print('Error signing in anonymously: $e');
      return AuthResult.failure('Anonymous sign-in failed: ${e.toString()}');
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmailPassword(String email, String password) async {
    try {
      final firebase_auth.UserCredential userCredential = 
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        _currentUser = await _convertFirebaseUser(userCredential.user);
        await _databaseService.saveUser(_currentUser!);
        return AuthResult.success(_currentUser!);
      } else {
        return AuthResult.failure('Failed to sign in with email and password');
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e));
    } catch (e) {
      print('Error signing in with email/password: $e');
      return AuthResult.failure('Sign-in failed: ${e.toString()}');
    }
  }

  /// Create account with email and password
  Future<AuthResult> createAccountWithEmailPassword(
    String email, 
    String password, 
    String? displayName,
  ) async {
    try {
      final firebase_auth.UserCredential userCredential = 
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await userCredential.user?.updateDisplayName(displayName);
        await userCredential.user?.reload();
      }

      if (userCredential.user != null) {
        _currentUser = await _convertFirebaseUser(userCredential.user);
        await _databaseService.saveUser(_currentUser!);
        return AuthResult.success(_currentUser!);
      } else {
        return AuthResult.failure('Failed to create account');
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e));
    } catch (e) {
      print('Error creating account: $e');
      return AuthResult.failure('Account creation failed: ${e.toString()}');
    }
  }

  /// Send password reset email
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.success(null, message: 'Password reset email sent');
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e));
    } catch (e) {
      print('Error sending password reset email: $e');
      return AuthResult.failure('Failed to send password reset email: ${e.toString()}');
    }
  }

  /// Update user profile
  Future<AuthResult> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return AuthResult.failure('No user signed in');
      }

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      await user.reload();
      _currentUser = await _convertFirebaseUser(user);
      
      if (_currentUser != null) {
        await _databaseService.saveUser(_currentUser!);
      }

      return AuthResult.success(_currentUser, message: 'Profile updated successfully');
    } catch (e) {
      print('Error updating user profile: $e');
      return AuthResult.failure('Profile update failed: ${e.toString()}');
    }
  }

  /// Update user preferences
  Future<AuthResult> updateUserPreferences(app_user.UserPreferences preferences) async {
    try {
      if (_currentUser == null) {
        return AuthResult.failure('No user signed in');
      }

      // Update current user object
      _currentUser = _currentUser!.copyWith(preferences: preferences);
      
      // Save to database
      await _databaseService.saveUser(_currentUser!);
      await _databaseService.saveUserPreferences(preferences);

      return AuthResult.success(_currentUser, message: 'Preferences updated successfully');
    } catch (e) {
      print('Error updating user preferences: $e');
      return AuthResult.failure('Preferences update failed: ${e.toString()}');
    }
  }

  /// Update user stats
  Future<AuthResult> updateUserStats(app_user.UserStats stats) async {
    try {
      if (_currentUser == null) {
        return AuthResult.failure('No user signed in');
      }

      // Update current user object
      _currentUser = _currentUser!.copyWith(stats: stats);
      
      // Save to database
      await _databaseService.saveUser(_currentUser!);

      return AuthResult.success(_currentUser, message: 'Stats updated successfully');
    } catch (e) {
      print('Error updating user stats: $e');
      return AuthResult.failure('Stats update failed: ${e.toString()}');
    }
  }

  /// Link anonymous account with Google
  Future<AuthResult> linkAnonymousWithGoogle() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null || !user.isAnonymous) {
        return AuthResult.failure('No anonymous user to link');
      }

      // Get Google credentials
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult.cancelled();
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link the accounts
      final firebase_auth.UserCredential userCredential = 
          await user.linkWithCredential(credential);

      if (userCredential.user != null) {
        _currentUser = await _convertFirebaseUser(userCredential.user);
        await _databaseService.saveUser(_currentUser!);
        return AuthResult.success(_currentUser!, message: 'Account linked successfully');
      } else {
        return AuthResult.failure('Failed to link accounts');
      }
    } catch (e) {
      print('Error linking anonymous account: $e');
      return AuthResult.failure('Account linking failed: ${e.toString()}');
    }
  }

  /// Delete user account
  Future<AuthResult> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return AuthResult.failure('No user signed in');
      }

      // Clear local data first
      await _databaseService.clearAllData();
      
      // Delete Firebase user
      await user.delete();
      
      _currentUser = null;
      return AuthResult.success(null, message: 'Account deleted successfully');
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return AuthResult.failure('Please sign in again before deleting your account');
      }
      return AuthResult.failure(_getFirebaseErrorMessage(e));
    } catch (e) {
      print('Error deleting account: $e');
      return AuthResult.failure('Account deletion failed: ${e.toString()}');
    }
  }

  /// Reauthenticate user (required for sensitive operations)
  Future<AuthResult> reauthenticateWithGoogle() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return AuthResult.failure('No user signed in');
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult.cancelled();
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await user.reauthenticateWithCredential(credential);
      return AuthResult.success(_currentUser, message: 'Reauthentication successful');
    } catch (e) {
      print('Error reauthenticating: $e');
      return AuthResult.failure('Reauthentication failed: ${e.toString()}');
    }
  }

  /// Sign out
  Future<AuthResult> signOut() async {
    try {
      // Sign out from Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      
      // Sign out from Firebase
      await _firebaseAuth.signOut();
      
      _currentUser = null;
      return AuthResult.success(null, message: 'Signed out successfully');
    } catch (e) {
      print('Error signing out: $e');
      return AuthResult.failure('Sign out failed: ${e.toString()}');
    }
  }

  /// Get current Firebase user
  firebase_auth.User? get firebaseUser => _firebaseAuth.currentUser;

  /// Check if user has Google Photos access
  Future<bool> hasGooglePhotosAccess() async {
    try {
      final googleUser = await _googleSignIn.signInSilently();
      if (googleUser == null) return false;
      
      final auth = await googleUser.authentication;
      return auth.accessToken != null;
    } catch (e) {
      print('Error checking Google Photos access: $e');
      return false;
    }
  }

  /// Get Google access token
  Future<String?> getGoogleAccessToken() async {
    try {
      final googleUser = await _googleSignIn.signInSilently();
      if (googleUser == null) return null;
      
      final auth = await googleUser.authentication;
      return auth.accessToken;
    } catch (e) {
      print('Error getting Google access token: $e');
      return null;
    }
  }

  /// Convert Firebase error to user-friendly message
  String _getFirebaseErrorMessage(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'An unknown error occurred.';
    }
  }

  /// Get authentication status info
  Map<String, dynamic> getAuthInfo() {
    final firebaseUser = _firebaseAuth.currentUser;
    return {
      'is_authenticated': isAuthenticated,
      'is_anonymous': isAnonymous,
      'user_id': firebaseUser?.uid,
      'email': firebaseUser?.email,
      'display_name': firebaseUser?.displayName,
      'photo_url': firebaseUser?.photoURL,
      'email_verified': firebaseUser?.emailVerified,
      'creation_time': firebaseUser?.metadata.creationTime?.toIso8601String(),
      'last_sign_in': firebaseUser?.metadata.lastSignInTime?.toIso8601String(),
    };
  }

  /// Dispose resources
  void dispose() {
    // Clean up any resources if needed
  }
}

/// Authentication result wrapper
class AuthResult {
  final bool isSuccess;
  final app_user.User? user;
  final String? message;
  final String? error;

  const AuthResult._({
    required this.isSuccess,
    this.user,
    this.message,
    this.error,
  });

  factory AuthResult.success(app_user.User? user, {String? message}) {
    return AuthResult._(
      isSuccess: true,
      user: user,
      message: message,
    );
  }

  factory AuthResult.failure(String error) {
    return AuthResult._(
      isSuccess: false,
      error: error,
    );
  }

  factory AuthResult.cancelled() {
    return AuthResult._(
      isSuccess: false,
      error: 'Operation cancelled by user',
    );
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'AuthResult.success(user: ${user?.id}, message: $message)';
    } else {
      return 'AuthResult.failure(error: $error)';
    }
  }
}