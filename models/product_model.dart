import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String sellerId;
  final String sellerName;
  final String? sellerPhone;
  final String title;
  final String description;
  final double price;
  final String category;
  final String condition;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isAvailable;
  final bool isActive;
  final Map<String, dynamic>? specifications;

  final String? location;
  final double? latitude;
  final double? longitude;

  // Statistics
  final int viewCount;
  final int wishlistCount;

  // For soft delete/hide
  final bool isHidden;

  ProductModel({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    required this.imageUrls,
    required this.createdAt,
    this.updatedAt,
    this.sellerPhone,
    this.isAvailable = true,
    this.isActive = true,
    this.specifications,
    this.location,
    this.latitude,
    this.longitude,
    this.viewCount = 0,
    this.wishlistCount = 0,
    this.isHidden = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerPhone': sellerPhone,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'condition': condition,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isAvailable': isAvailable,
      'isActive': isActive,
      'specifications': specifications,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'viewCount': viewCount,
      'wishlistCount': wishlistCount,
      'isHidden': isHidden,
    };
  }

  factory ProductModel.fromMap(String id, Map<String, dynamic> map) {
    return ProductModel(
      id: id,
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? 'Unknown Seller',
      sellerPhone: map['sellerPhone'] ?? 'Not provided',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      category: map['category'] ?? 'Uncategorized',
      condition: map['condition'] ?? 'Not Specified',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      isAvailable: map['isAvailable'] ?? true,
      isActive: map['isActive'] ?? true,
      specifications: map['specifications'],
      location: map['location'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      viewCount: map['viewCount'] ?? 0,
      wishlistCount: map['wishlistCount'] ?? 0,
      isHidden: map['isHidden'] ?? false,
    );
  }

  //  a copy with updated fields
  ProductModel copyWith({
    String? id,
    String? sellerId,
    String? sellerName,
    String? sellerPhone,
    String? title,
    String? description,
    double? price,
    String? category,
    String? condition,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isAvailable,
    bool? isActive,
    Map<String, dynamic>? specifications,
    String? location,
    double? latitude,
    double? longitude,
    int? viewCount,
    int? wishlistCount,
    bool? isHidden,
  }) {
    return ProductModel(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isAvailable: isAvailable ?? this.isAvailable,
      isActive: isActive ?? this.isActive,
      specifications: specifications ?? this.specifications,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      viewCount: viewCount ?? this.viewCount,
      wishlistCount: wishlistCount ?? this.wishlistCount,
      isHidden: isHidden ?? this.isHidden,
    );
  }

  // Condition options for dropdown
  static const List<String> conditionOptions = [
    'Brand New',
    'Like New',
    'Very Good',
    'Good',
    'Fair',
    'For Parts/Not Working',
  ];

  // Categories
  static const List<String> categoryOptions = [
    'Electronics',
    'Clothing',
    'Furniture',
    'Books',
    'Sports',
    'Toys',
    'Home & Garden',
    'Tools',
    'Vehicles',
    'Other',
  ];
}
