import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Private variables
  Map<String, dynamic>? _userData;
  User? _user;
  String? _userRole;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isEmailVerified = false;
  bool _isProfileComplete = false;
  bool _isSellerApproved = false;
  bool _sellerApprovalRequested = false;
  StreamSubscription? _userDocSubscription;

  // Verification listener
  StreamSubscription? _verificationListener;
  bool _isCheckingVerification = false;

  // Getters
  Map<String, dynamic>? get userData => _userData;

  User? get user => _user;

  String? get userRole => _userRole;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _user != null;

  bool get isEmailVerified => _isEmailVerified;

  //  getters
  bool get isProfileComplete => _isProfileComplete;

  bool get isSellerApproved => _isSellerApproved;

  bool get sellerApprovalRequested => _sellerApprovalRequested;

  // Combined getters for business logic
  bool get canAccessSellerFeatures =>
      _userRole == 'Seller' && _isEmailVerified && _isSellerApproved;

  bool get canAccessDonorFeatures => _userRole == 'Donor' && _isEmailVerified;

  bool get canAccessBuyerFeatures => _userRole == 'Buyer' && _isEmailVerified;

  AuthProvider() {
    _setPersistence();
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _userDocSubscription?.cancel();
    _verificationListener?.cancel();
    super.dispose();
  }

  // Setter for userData (only used internally)
  void _updateUserData(Map<String, dynamic>? data) {
    _userData = data;
    notifyListeners();
  }

  // session persistence
  Future<void> _setPersistence() async {
    try {
      await _auth.setPersistence(Persistence.LOCAL);
      debugPrint('✅ Auth persistence set to LOCAL');
    } catch (e) {
      debugPrint('❌ Error setting persistence: $e');
    }
  }

  Future<void> _onAuthStateChanged(User? user) async {
    debugPrint('🔄 Auth state changed: ${user?.email ?? 'No user'}');
    _user = user;

    if (user != null) {
      try {
        // Cancel previous subscriptions if any
        await _userDocSubscription?.cancel();

        // Cancel any existing verification listener first
        _verificationListener?.cancel();
        _isCheckingVerification = false;

        // Check email verification status
        await user.reload();
        final freshUser = _auth.currentUser;
        _isEmailVerified = freshUser?.emailVerified ?? false;
        debugPrint('📧 Email verified: $_isEmailVerified');

        // Only start listening if email is NOT verified AND user still exists
        if (!_isEmailVerified && _user != null) {
          debugPrint('🔍 Starting email verification listener...');
          _listenToVerificationStatus();
        } else if (_isEmailVerified) {
          debugPrint('✅ Email already verified, no listener needed');
        }

        // Load user role and listen to changes
        await _loadUserRole(user.uid);
        _listenToUserData(user.uid);
      } catch (e) {
        debugPrint('❌ Error in auth state change: $e');
      }
    } else {
      // User is null - clean up everything
      _userRole = null;
      _isEmailVerified = false;
      _isProfileComplete = false;
      _isSellerApproved = false;
      _sellerApprovalRequested = false;
      _updateUserData(null); // Clear userData on logout

      // Cancel all listeners
      _verificationListener?.cancel();
      _isCheckingVerification = false;
      await _userDocSubscription?.cancel();

      debugPrint('🧹 Cleaned up all listeners on logout');
    }
    notifyListeners();
  }

  // Add email verification listener
  void _listenToVerificationStatus() {
    // Don't start if already checking or user is null
    if (_isCheckingVerification || _user == null) {
      debugPrint(
          '⚠️ Not starting verification listener: already checking or user null');
      return;
    }

    _isCheckingVerification = true;

    // Cancel any existing listener first
    _verificationListener?.cancel();

    debugPrint('🔍 Starting email verification polling...');

    _verificationListener = Stream.periodic(const Duration(seconds: 3))
        .take(20) // Check for up to 60 seconds
        .listen((_) async {
      // Check if user still exists
      if (_user == null || !_isCheckingVerification) {
        debugPrint('🛑 Stopping verification listener: user null or cancelled');
        _verificationListener?.cancel();
        _isCheckingVerification = false;
        return;
      }

      try {
        debugPrint('🔍 Checking email verification status...');
        await _user!.reload();
        final currentUser = _auth.currentUser;
        final isVerified = currentUser?.emailVerified ?? false;

        if (isVerified != _isEmailVerified) {
          _isEmailVerified = isVerified;
          debugPrint(
              '✅ Email verification status changed to: $_isEmailVerified');

          if (isVerified) {
            debugPrint('✅ Email verified! Updating Firestore...');
            try {
              await _firestore.collection('users').doc(_user!.uid).update({
                'emailVerified': true,
              });
            } catch (e) {
              debugPrint('❌ Error updating email verified status: $e');
            }

            // Cancel the listener once verified
            _verificationListener?.cancel();
            _isCheckingVerification = false;
          }

          notifyListeners();
        }
      } catch (e) {
        debugPrint('❌ Error checking verification: $e');
        // If error is due to user not found, cancel listener
        if (e.toString().contains('user-not-found') ||
            e.toString().contains('No such user') ||
            e.toString().contains('network')) {
          _verificationListener?.cancel();
          _isCheckingVerification = false;
        }
      }
    }, onDone: () {
      _isCheckingVerification = false;
      debugPrint(
          '⏱️ Email verification check completed (max attempts reached)');
    });
  }

  // Listen to real-time user data updates
  void _listenToUserData(String uid) {
    _userDocSubscription =
        _firestore.collection('users').doc(uid).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        _updateUserData(data); // Update _userData when Firestore changes
        _userRole = data['role'];
        _isProfileComplete = data['profileComplete'] ?? false;
        _isSellerApproved = data['sellerApproved'] ?? false;
        _sellerApprovalRequested = data['sellerApprovalRequested'] ?? false;

        debugPrint('📡 Real-time user data updated:');
        debugPrint('  - Role: $_userRole');
        debugPrint('  - Profile Complete: $_isProfileComplete');
        debugPrint('  - Seller Approved: $_isSellerApproved');

        notifyListeners();
      }
    }, onError: (error) {
      debugPrint('❌ Error listening to user data: $error');
    });
  }

  // Load user role from Firestore
  Future<void> _loadUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _updateUserData(data); // Store the data
        _userRole = data['role'];
        _isProfileComplete = data['profileComplete'] ?? false;
        _isSellerApproved = data['sellerApproved'] ?? false;
        _sellerApprovalRequested = data['sellerApprovalRequested'] ?? false;
        debugPrint('✅ User data loaded: $_userRole');
      } else {
        debugPrint('⚠️ User document does not exist in Firestore');
        // Try to create the document if it doesn't exist
        await _createUserDocument(uid);
      }
    } catch (e) {
      debugPrint('❌ Error loading user role: $e');
    }
  }

  // Helper method to create user document
  Future<void> _createUserDocument(String uid) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final Map<String, dynamic> userData = {
          'uid': uid,
          'email': user.email,
          'name': user.displayName ?? user.email?.split('@')[0] ?? 'User',
          'phone': '',
          'role': 'Buyer', // Default role
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'isActive': true,
          'profileComplete': false,
          'emailVerified': user.emailVerified,
          'sellerApproved': false,
          'sellerApprovalRequested': false,
        };

        await _firestore.collection('users').doc(uid).set(userData);
        _updateUserData(userData); // Set _userData after creation
        debugPrint('✅ Created missing user document in Firestore');
      }
    } catch (e) {
      debugPrint('❌ Failed to create missing user document: $e');
    }
  }

  // Sign Up with Email & Password
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('📝 Attempting to create user: $email');

      // Create user in Firebase Auth
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final User? user = userCredential.user;

      if (user != null) {
        debugPrint('✅ User created in Auth: ${user.uid}');

        // Set display name
        await user.updateDisplayName(name);
        await user.reload();

        // Send email verification
        await user.sendEmailVerification();
        debugPrint('📧 Verification email sent');

        // Create user document in Firestore with retry logic
        bool firestoreSuccess = false;
        int retryCount = 0;

        while (!firestoreSuccess && retryCount < 3) {
          try {
            Map<String, dynamic> userData = {
              'uid': user.uid,
              'email': email.trim(),
              'name': name.trim(),
              'phone': phone.trim(),
              'role': role,
              'createdAt': FieldValue.serverTimestamp(),
              'lastLogin': FieldValue.serverTimestamp(),
              'isActive': true,
              'profileComplete': true,
              'emailVerified': false,
              'sellerApproved': false,
              'sellerApprovalRequested': false,
            };

            // Add seller-specific fields
            if (role == 'Seller') {
              userData['sellerApprovalRequested'] = true;
              userData['sellerApprovalRequestedAt'] =
                  FieldValue.serverTimestamp();
              userData['sellerApproved'] = false;
            }

            await _firestore.collection('users').doc(user.uid).set(userData);
            _updateUserData(
                userData); // Set _userData after successful creation
            firestoreSuccess = true;
            debugPrint('✅ User document created in Firestore');
          } catch (e) {
            retryCount++;
            debugPrint(
                '❌ Error creating Firestore document (attempt $retryCount): $e');
            if (retryCount >= 3) {
              debugPrint(
                  '❌ Failed to create Firestore document after 3 attempts');
            } else {
              // Wait a bit before retrying
              await Future.delayed(const Duration(seconds: 1));
            }
          }
        }

        _userRole = role;
        if (role == 'Seller') {
          _sellerApprovalRequested = true;
        }

        // Start listening for verification
        _listenToVerificationStatus();

        _setLoading(false);
        return true;
      }

      _setLoading(false);
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint(
          '🔥 FirebaseAuthException in signUp: ${e.code} - ${e.message}');
      _handleAuthError(e);
      _setLoading(false);
      return false;
    } catch (e, stackTrace) {
      debugPrint('🔥 Unexpected error in signUp: $e');
      debugPrint('🔥 Stack trace: $stackTrace');
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  // Login with Email & Password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('📝 Attempting to sign in: $email');

      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final User? user = userCredential.user;

      if (user != null) {
        // Reload user to get latest email verification status
        await user.reload();
        final freshUser = _auth.currentUser;
        final isVerified = freshUser?.emailVerified ?? false;

        debugPrint('📧 Email verified status: $isVerified');

        if (!isVerified) {
          _errorMessage = 'Please verify your email before logging in. '
              'Check your inbox for the verification link. '
              'Click "Resend Verification" if needed.';
          _setLoading(false);
          return false;
        }

        // Update last login and verification status in Firestore
        try {
          // Check if document exists first
          final doc = await _firestore.collection('users').doc(user.uid).get();

          if (doc.exists) {
            await _firestore.collection('users').doc(user.uid).update({
              'lastLogin': FieldValue.serverTimestamp(),
              'emailVerified': true,
            });

            // Update _userData with latest data
            final updatedDoc =
                await _firestore.collection('users').doc(user.uid).get();
            if (updatedDoc.exists) {
              _updateUserData(updatedDoc.data());
            }
          } else {
            // Create document if it doesn't exist
            await _createUserDocument(user.uid);
          }
          debugPrint('✅ Updated last login in Firestore');
        } catch (e) {
          debugPrint('⚠️ Error updating last login: $e');
          // Don't fail the login if this fails
        }

        await _loadUserRole(user.uid);
        _isEmailVerified = true;
        _setLoading(false);
        return true;
      }

      _setLoading(false);
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint(
          '🔥 FirebaseAuthException in signIn: ${e.code} - ${e.message}');
      _handleAuthError(e);
      _setLoading(false);
      return false;
    } catch (e, stackTrace) {
      debugPrint('🔥 Unexpected error in signIn: $e');
      debugPrint('🔥 Stack trace: $stackTrace');
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _userDocSubscription?.cancel();
      await _verificationListener?.cancel();
      await _auth.signOut();
      _userRole = null;
      _isEmailVerified = false;
      _isProfileComplete = false;
      _isSellerApproved = false;
      _sellerApprovalRequested = false;
      _updateUserData(null); // Clear userData on sign out
      _isCheckingVerification = false;
      _setLoading(false);
      debugPrint('✅ User signed out');
    } catch (e) {
      debugPrint('❌ Error signing out: $e');
      _errorMessage = 'Error signing out';
      _setLoading(false);
    }
  }

  // Send Password Reset Email
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      debugPrint('📧 Password reset email sent');
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint(
          '🔥 FirebaseAuthException in resetPassword: ${e.code} - ${e.message}');
      _handleAuthError(e);
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('❌ Error in resetPassword: $e');
      _errorMessage = 'Failed to send reset email';
      _setLoading(false);
      return false;
    }
  }

  // Send Verification Email
  Future<bool> sendVerificationEmail() async {
    _setLoading(true);
    _clearError();

    try {
      await _user?.sendEmailVerification();
      debugPrint('📧 Verification email sent');

      // Start listening for verification if not already
      if (!_isCheckingVerification && _user != null) {
        _listenToVerificationStatus();
      }

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint(
          '🔥 FirebaseAuthException in sendVerificationEmail: ${e.code} - ${e.message}');
      _handleAuthError(e);
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('❌ Error in sendVerificationEmail: $e');
      _errorMessage = 'Failed to send verification email';
      _setLoading(false);
      return false;
    }
  }

  // Check verification status
  Future<bool> checkEmailVerification() async {
    if (_user == null) return false;

    try {
      await _user!.reload();
      _user = _auth.currentUser;
      _isEmailVerified = _user?.emailVerified ?? false;

      if (_isEmailVerified) {
        // Update Firestore
        try {
          await _firestore.collection('users').doc(_user!.uid).update({
            'emailVerified': true,
          });

          // Update _userData
          final updatedDoc =
              await _firestore.collection('users').doc(_user!.uid).get();
          if (updatedDoc.exists) {
            _updateUserData(updatedDoc.data());
          }
        } catch (e) {
          debugPrint('❌ Error updating email verified status: $e');
        }
      }

      notifyListeners();
      debugPrint('📧 Email verification check: $_isEmailVerified');
      return _isEmailVerified;
    } catch (e) {
      debugPrint('❌ Error checking email verification: $e');
      return false;
    }
  }

  // Request seller approval
  Future<bool> requestSellerApproval() async {
    if (_user == null || _userRole != 'Seller') return false;

    _setLoading(true);
    try {
      await _firestore.collection('users').doc(_user!.uid).update({
        'sellerApprovalRequested': true,
        'sellerApprovalRequestedAt': FieldValue.serverTimestamp(),
      });
      _sellerApprovalRequested = true;

      // Update _userData
      final updatedDoc =
          await _firestore.collection('users').doc(_user!.uid).get();
      if (updatedDoc.exists) {
        _updateUserData(updatedDoc.data());
      }

      _setLoading(false);
      debugPrint('✅ Seller approval requested');
      return true;
    } catch (e) {
      debugPrint('❌ Error requesting seller approval: $e');
      _errorMessage = 'Failed to request seller approval';
      _setLoading(false);
      return false;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    String? name,
    String? phone,
    String? role,
  }) async {
    if (_user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (role != null) updates['role'] = role;

      if (updates.isNotEmpty) {
        // Check if document exists first
        final doc = await _firestore.collection('users').doc(_user!.uid).get();

        if (!doc.exists) {
          // Create the document if it doesn't exist
          final Map<String, dynamic> userData = {
            'uid': _user!.uid,
            'email': _user!.email,
            'name': name ??
                _user!.displayName ??
                _user!.email?.split('@')[0] ??
                'User',
            'phone': phone ?? '',
            'role': role ?? 'Buyer',
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
            'isActive': true,
            'profileComplete': true,
            'emailVerified': _user!.emailVerified,
            'sellerApproved': false,
            'sellerApprovalRequested': false,
          };

          await _firestore.collection('users').doc(_user!.uid).set(userData);
          _updateUserData(userData);
          debugPrint('✅ Created user document during profile update');
        } else {
          // Update existing document
          await _firestore.collection('users').doc(_user!.uid).update(updates);

          // Update _userData with changes
          final updatedDoc =
              await _firestore.collection('users').doc(_user!.uid).get();
          if (updatedDoc.exists) {
            _updateUserData(updatedDoc.data());
          }

          debugPrint('✅ Profile updated: $updates');
        }

        // Update display name in Firebase Auth if name changed
        if (name != null) {
          await _user!.updateDisplayName(name);
          await _user!.reload();
          _user = _auth.currentUser;
        }

        if (role != null) _userRole = role;

        // If role changed to Seller, automatically request approval
        if (role == 'Seller' && _userRole != 'Seller') {
          await requestSellerApproval();
        }
      }

      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('❌ Error updating profile: $e');
      _errorMessage = 'Failed to update profile: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    if (_user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();

      if (doc.exists) {
        _updateUserData(doc.data()); // Update _userData
        debugPrint('✅ User data retrieved from Firestore');
        return doc.data();
      } else {
        debugPrint('⚠️ User document does not exist in Firestore');

        // Try to create the document if it doesn't exist
        try {
          await _createUserDocument(_user!.uid);
          // Try to get it again
          final newDoc =
              await _firestore.collection('users').doc(_user!.uid).get();
          if (newDoc.exists) {
            _updateUserData(newDoc.data());
            return newDoc.data();
          }
          return null;
        } catch (e) {
          debugPrint('❌ Failed to create missing user document: $e');
          return null;
        }
      }
    } catch (e) {
      debugPrint('❌ Error getting user data: $e');
      return null;
    }
  }

  // Check if user has specific role
  bool hasRole(String role) {
    return _userRole == role;
  }

  // Check if user has any of the allowed roles
  bool hasAnyRole(List<String> roles) {
    return _userRole != null && roles.contains(_userRole);
  }

  // Refresh user token
  Future<void> refreshUser() async {
    try {
      await _user?.reload();
      _user = _auth.currentUser;

      // Refresh user data from Firestore
      if (_user != null) {
        final doc = await _firestore.collection('users').doc(_user!.uid).get();
        if (doc.exists) {
          _updateUserData(doc.data());
        }
      }

      notifyListeners();
      debugPrint('🔄 User data refreshed');
    } catch (e) {
      debugPrint('❌ Error refreshing user: $e');
    }
  }

  // Helper Methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        _errorMessage = 'This email is already registered';
        break;
      case 'invalid-email':
        _errorMessage = 'Invalid email address';
        break;
      case 'weak-password':
        _errorMessage = 'Password is too weak';
        break;
      case 'user-not-found':
        _errorMessage = 'No user found with this email';
        break;
      case 'wrong-password':
        _errorMessage = 'Incorrect password';
        break;
      case 'user-disabled':
        _errorMessage = 'This account has been disabled';
        break;
      case 'too-many-requests':
        _errorMessage = 'Too many attempts. Please try again later';
        break;
      case 'network-request-failed':
        _errorMessage = 'Network error. Check your connection';
        break;
      default:
        _errorMessage = 'Authentication failed: ${e.message}';
    }
    notifyListeners();
  }

  // Add account deletion method
  Future<bool> deleteAccount() async {
    _setLoading(true);
    _clearError();

    try {
      if (_user == null) return false;

      // Delete user data from Firestore first
      await _firestore.collection('users').doc(_user!.uid).delete();

      // Delete the user account
      await _user!.delete();

      // Sign out
      await signOut();

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _errorMessage =
            'Please log out and log in again before deleting your account';
      } else {
        _handleAuthError(e);
      }
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('❌ Error deleting account: $e');
      _errorMessage = 'Failed to delete account';
      _setLoading(false);
      return false;
    }
  }

  // Fetch user data method (used in add_donation_screen)
  Future<void> fetchUserData() async {
    try {
      if (_user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .get();

        if (doc.exists) {
          _updateUserData(doc.data());
          notifyListeners();
          debugPrint('✅ User data fetched successfully');
        } else {
          // Create document if it doesn't exist
          await _createUserDocument(_user!.uid);
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching user data: $e');
    }
  }

  // Check persisted auth state
  Future<bool> checkPersistedAuth() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        _user = _auth.currentUser;
        if (_user != null) {
          await _loadUserRole(_user!.uid);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error checking persisted auth: $e');
      return false;
    }
  }
}
