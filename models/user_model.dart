import 'package:cloud_firestore/cloud_firestore.dart';
class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? phone;
  final String role;
  final bool isVerified;
  final DateTime createdAt;
  final String? profileImageUrl;
  final Map<String, dynamic>? preferences;

  // Seller-specific fields
  final bool sellerApproved;
  final bool sellerApprovalRequested;
  final DateTime? sellerApprovedAt;
  final String? approvedBy;
  final String? sellerRejectionReason;

  // Donor-specific fields
  final int donationPoints;

  // Buyer/Seller fields
  final int sellerRating;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    this.isVerified = false,
    required this.createdAt,
    this.profileImageUrl,
    this.preferences,
    this.sellerApproved = false,
    this.sellerApprovalRequested = false,
    this.sellerApprovedAt,
    this.approvedBy,
    this.sellerRejectionReason,
    this.donationPoints = 0,
    this.sellerRating = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'isVerified': isVerified,
      'createdAt': createdAt,
      'profileImageUrl': profileImageUrl,
      'preferences': preferences,
      'sellerApproved': sellerApproved,
      'sellerApprovalRequested': sellerApprovalRequested,
      'sellerApprovedAt': sellerApprovedAt,
      'approvedBy': approvedBy,
      'sellerRejectionReason': sellerRejectionReason,
      'donationPoints': donationPoints,
      'sellerRating': sellerRating,
    };
  }

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'],
      role: map['role'] ?? 'Buyer',
      isVerified: map['isVerified'] ?? map['emailVerified'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      profileImageUrl: map['profileImageUrl'],
      preferences: map['preferences'],
      sellerApproved: map['sellerApproved'] ?? false,
      sellerApprovalRequested: map['sellerApprovalRequested'] ?? false,
      sellerApprovedAt: map['sellerApprovedAt'] != null
          ? (map['sellerApprovedAt'] as Timestamp).toDate()
          : null,
      approvedBy: map['approvedBy'],
      sellerRejectionReason: map['sellerRejectionReason'],
      donationPoints: map['donationPoints'] ?? 0,
      sellerRating: map['sellerRating'] ?? 0,
    );
  }
}
