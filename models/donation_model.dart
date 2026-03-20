// lib/models/donation_model.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum DonationStatus {
  pending,    // Initial state after donor submits
  approved,   // Admin verified, waiting for completion
  completed,  // Donation actually done, will show in donate_screen
  rejected    // Admin rejected with reason
}

class DonationModel {
  final String id;
  final String donorId;
  final String donorName;
  final bool isAnonymous;

  // Item details
  final String category;
  final String title;
  final String description;
  final int quantity;
  final String condition;

  // Clothing-specific (optional)
  final String? brand;
  final String? size;
  final String? color;
  final String? gender;
  final String? material;

  // Donation details
  final String urgency;
  final String location;
  final String contact;
  final bool canPickup;
  final bool canDeliver;

  // Images
  final List<String> donorImageUrls;      // Images uploaded by donor
  final String? proofImageUrl;             // Proof image from admin (already exists)

  // Admin fields (only for completed)
  final String? recipientInfo;      // Where it went
  final DateTime? completedAt;      // When admin marked completed

  // Status
  final DonationStatus status;
  final String? rejectionReason;
  final DateTime createdAt;

  // Add this missing field
  final bool isAvailable;  // Controls visibility in public screens

  // Constructor
  DonationModel({
    required this.id,
    required this.donorId,
    required this.donorName,
    required this.isAnonymous,
    required this.category,
    required this.title,
    required this.description,
    required this.quantity,
    required this.condition,
    this.brand,
    this.size,
    this.color,
    this.gender,
    this.material,
    required this.urgency,
    required this.location,
    required this.contact,
    required this.canPickup,
    required this.canDeliver,
    required this.donorImageUrls,
    this.proofImageUrl,
    this.recipientInfo,
    this.completedAt,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    required this.isAvailable,  // Add this
  });

  // Convert to Firestore
  Map<String, dynamic> toMap() {
    return {
      'donorId': donorId,
      'donorName': donorName,
      'isAnonymous': isAnonymous,
      'category': category,
      'title': title,
      'description': description,
      'quantity': quantity,
      'condition': condition,
      'brand': brand,
      'size': size,
      'color': color,
      'gender': gender,
      'material': material,
      'urgency': urgency,
      'location': location,
      'contact': contact,
      'canPickup': canPickup,
      'canDeliver': canDeliver,
      'donorImageUrls': donorImageUrls,
      'proofImageUrl': proofImageUrl,
      'recipientInfo': recipientInfo,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'status': status.index,
      'rejectionReason': rejectionReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAvailable': isAvailable,  // Add this
    };
  }

  // Create from Firestore
  factory DonationModel.fromMap(String id, Map<String, dynamic> map) {
    return DonationModel(
      id: id,
      donorId: map['donorId'] ?? '',
      donorName: map['donorName'] ?? 'Anonymous',
      isAnonymous: map['isAnonymous'] ?? false,
      category: map['category'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      quantity: map['quantity'] ?? 1,
      condition: map['condition'] ?? '',
      brand: map['brand'],
      size: map['size'],
      color: map['color'],
      gender: map['gender'],
      material: map['material'],
      urgency: map['urgency'] ?? '',
      location: map['location'] ?? '',
      contact: map['contact'] ?? '',
      canPickup: map['canPickup'] ?? true,
      canDeliver: map['canDeliver'] ?? false,
      donorImageUrls: List<String>.from(map['donorImageUrls'] ?? []),
      proofImageUrl: map['proofImageUrl'],
      recipientInfo: map['recipientInfo'],
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      status: DonationStatus.values[map['status'] ?? 0],
      rejectionReason: map['rejectionReason'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isAvailable: map['isAvailable'] ?? true,  // Add this with default
    );
  }

  // Helper getters
  bool get shouldShowInDonateScreen => status == DonationStatus.completed;

  String get statusText {
    switch (status) {
      case DonationStatus.pending:
        return 'Pending Review';
      case DonationStatus.approved:
        return 'Approved';
      case DonationStatus.completed:
        return 'Completed';
      case DonationStatus.rejected:
        return 'Rejected';
    }
  }

  Color get statusColor {
    switch (status) {
      case DonationStatus.pending:
        return Colors.orange;
      case DonationStatus.approved:
        return Colors.blue;
      case DonationStatus.completed:
        return Colors.green;
      case DonationStatus.rejected:
        return Colors.red;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case DonationStatus.pending:
        return Icons.hourglass_empty;
      case DonationStatus.approved:
        return Icons.thumb_up;
      case DonationStatus.completed:
        return Icons.check_circle;
      case DonationStatus.rejected:
        return Icons.cancel;
    }
  }

  // Get main image to display (proof first, then donor images)
  String? get mainImageUrl {
    if (proofImageUrl != null) return proofImageUrl;
    if (donorImageUrls.isNotEmpty) return donorImageUrls.first;
    return null;
  }
}