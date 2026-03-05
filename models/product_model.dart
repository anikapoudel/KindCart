// lib/models/product_model.dart
class ProductModel {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final double price;
  final double? originalPrice;
  final String category;
  final String condition;
  final List<String> imageUrls;
  final String location;
  final bool isNegotiable;
  final bool canShip;
  final Map<String, dynamic>? attributes; // For category-specific fields
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isAvailable;
  final int views;
  final List<String>? savedBy; // Users who favorited

  ProductModel({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.category,
    required this.condition,
    required this.imageUrls,
    required this.location,
    this.isNegotiable = false,
    this.canShip = false,
    this.attributes,
    required this.createdAt,
    required this.updatedAt,
    this.isAvailable = true,
    this.views = 0,
    this.savedBy,
  });

// Add toMap() and fromMap() methods
}