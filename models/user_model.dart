import 'package:cloud_firestore/cloud_firestore.dart';
class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String role; // 'buyer', 'seller', 'donor', 'admin'
  final bool isVerified;
  final DateTime createdAt;
  final String? profileImageUrl;
  final Map<String, dynamic>? preferences;
  final int donationPoints; // For donor rewards
  final int sellerRating; // For sellers

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.role,
    this.isVerified = false,
    required this.createdAt,
    this.profileImageUrl,
    this.preferences,
    this.donationPoints = 0,
    this.sellerRating = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'role': role,
      'isVerified': isVerified,
      'createdAt': createdAt,
      'profileImageUrl': profileImageUrl,
      'preferences': preferences,
      'donationPoints': donationPoints,
      'sellerRating': sellerRating,
    };
  }

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'],
      role: map['role'] ?? 'buyer',
      isVerified: map['isVerified'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      profileImageUrl: map['profileImageUrl'],
      preferences: map['preferences'],
      donationPoints: map['donationPoints'] ?? 0,
      sellerRating: map['sellerRating'] ?? 0,
    );
  }
}