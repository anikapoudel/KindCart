import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import 'auth_provider.dart';

// Global navigator key for accessing context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<ProductModel> _products = [];
  List<ProductModel> _userProducts = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filters and search
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedCondition = 'All';
  double _maxPrice = 100000;
  bool _sortByNewest = true;

  // Getters
  List<ProductModel> get products => _products;
  List<ProductModel> get userProducts => _userProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get sortByNewest => _sortByNewest;

  // Filtered products based on current filters
  List<ProductModel> get filteredProducts {
    return _products.where((product) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!product.title.toLowerCase().contains(query) &&
            !product.description.toLowerCase().contains(query)) {
          return false;
        }
      }

      if (_selectedCategory != 'All' && product.category != _selectedCategory) {
        return false;
      }

      if (_selectedCondition != 'All' && product.condition != _selectedCondition) {
        return false;
      }

      if (product.price > _maxPrice) {
        return false;
      }

      return product.isAvailable && product.isActive && !product.isHidden;
    }).toList()
      ..sort((a, b) {
        if (_sortByNewest) {
          return b.createdAt.compareTo(a.createdAt);
        } else {
          return a.price.compareTo(b.price);
        }
      });
  }

  // Load all products
  Future<void> loadProducts() async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('📦 Loading all products...');
      final snapshot = await _firestore
          .collection('products')
          .where('isAvailable', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('isHidden', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      _products = snapshot.docs.map((doc) {
        return ProductModel.fromMap(doc.id, doc.data());
      }).toList();

      debugPrint('✅ Loaded ${_products.length} products');
    } catch (e) {
      debugPrint('❌ Error loading products: $e');
      _errorMessage = 'Failed to load products';
    } finally {
      _setLoading(false);
    }
  }

  // Load user's products (for seller)
  Future<void> loadUserProducts(String sellerId) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('📦 Loading products for seller: $sellerId');
      final snapshot = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .get();

      _userProducts = snapshot.docs.map((doc) {
        return ProductModel.fromMap(doc.id, doc.data());
      }).toList();

      debugPrint('✅ Loaded ${_userProducts.length} products for user');
    } catch (e) {
      debugPrint('❌ Error loading user products: $e');
      _errorMessage = 'Failed to load your products';
    } finally {
      _setLoading(false);
    }
  }

  // Platform-specific file reading
  Future<Uint8List> _readFileAsBytes(dynamic file) async {
    debugPrint('🔍 Reading file on ${kIsWeb ? "Web" : "Mobile"}');

    if (kIsWeb) {
      try {
        if (file is XFile) {
          debugPrint('📸 Reading XFile on web');
          final bytes = await file.readAsBytes();
          return bytes;
        } else {
          debugPrint('❌ Unknown file type on web: ${file.runtimeType}');
          throw Exception('Unsupported file type on web');
        }
      } catch (e) {
        debugPrint('❌ Web file reading error: $e');
        rethrow;
      }
    } else {
      try {
        if (file is XFile) {
          debugPrint('📸 Reading XFile on mobile');
          final bytes = await file.readAsBytes();
          return bytes;
        } else if (file is File) {
          debugPrint('📸 Reading File on mobile');
          final bytes = await file.readAsBytes();
          return bytes;
        } else {
          debugPrint('❌ Unknown file type on mobile: ${file.runtimeType}');
          throw Exception('Unsupported file type on mobile');
        }
      } catch (e) {
        debugPrint('❌ Mobile file reading error: $e');
        rethrow;
      }
    }
  }

  // Add new product
  Future<bool> addProduct({
    required String title,
    required String description,
    required double price,
    required String category,
    required String condition,
    required List<XFile> images,
    Map<String, dynamic>? specifications,
    String? location,
    required String sellerId,
    required String sellerName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('📝 Starting addProduct with ${images.length} images');

      // Upload images to Firebase Storage
      List<String> imageUrls = [];

      for (int i = 0; i < images.length; i++) {
        try {
          final imageFile = images[i];
          debugPrint('\n--- Processing image $i ---');

          final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final ref = _storage.ref().child('product_images').child(sellerId).child(fileName);
          debugPrint('📁 Storage path: ${ref.fullPath}');

          final Uint8List bytes = await _readFileAsBytes(imageFile);
          debugPrint('📸 Image $i size: ${bytes.length} bytes');

          if (bytes.isEmpty) {
            debugPrint('❌ ERROR: Bytes are empty for image $i');
            continue;
          }

          final metadata = SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'uploadedBy': sellerId,
              'uploadedAt': DateTime.now().toIso8601String(),
            },
          );

          debugPrint('📤 Uploading image $i to Firebase Storage...');
          await ref.putData(bytes, metadata);
          debugPrint('📤 Upload completed for image $i');

          final url = await ref.getDownloadURL();
          debugPrint('✅ Image $i uploaded successfully');
          imageUrls.add(url);

        } catch (e, stack) {
          debugPrint('❌ Error uploading image $i: $e');
          debugPrint('📚 Stack trace: $stack');
          continue;
        }
      }

      if (imageUrls.isEmpty) {
        debugPrint('⚠️ No images uploaded successfully, using placeholder');
        imageUrls = [
          'https://via.placeholder.com/400x400?text=No+Image',
        ];
      }

      // Create product in Firestore
      debugPrint('📝 Creating product in Firestore...');
      final productData = {
        'sellerId': sellerId,
        'sellerName': sellerName,
        'title': title,
        'description': description,
        'price': price,
        'category': category,
        'condition': condition,
        'imageUrls': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isAvailable': true,
        'isActive': true,
        'isHidden': false,
        'specifications': specifications ?? {},
        'location': location ?? 'Not specified',
        'viewCount': 0,
        'wishlistCount': 0,
        'chatCount': 0,
        'shareCount': 0,
      };

      final docRef = await _firestore.collection('products').add(productData);
      debugPrint('✅ Product added with ID: ${docRef.id}');

      await loadProducts();
      await loadUserProducts(sellerId);

      _setLoading(false);
      return true;

    } catch (e) {
      debugPrint('❌ Error adding product: $e');
      _errorMessage = 'Failed to add product: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  // Update product
  Future<bool> updateProduct({
    required String productId,
    String? title,
    String? description,
    double? price,
    String? category,
    String? condition,
    bool? isAvailable,
    bool? isHidden,
    Map<String, dynamic>? specifications,
    String? location,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('📝 Attempting to update product: $productId');

      Map<String, dynamic> updates = {};

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (price != null) updates['price'] = price;
      if (category != null) updates['category'] = category;
      if (condition != null) updates['condition'] = condition;
      if (isAvailable != null) updates['isAvailable'] = isAvailable;
      if (isHidden != null) updates['isHidden'] = isHidden;
      if (specifications != null) updates['specifications'] = specifications;
      if (location != null) updates['location'] = location;

      updates['updatedAt'] = FieldValue.serverTimestamp();

      debugPrint('📦 Update data: $updates');

      // First, verify the product exists
      final productDoc = await _firestore.collection('products').doc(productId).get();
      if (!productDoc.exists) {
        debugPrint('❌ Product not found: $productId');
        _errorMessage = 'Product not found';
        _setLoading(false);
        return false;
      }

      // Check if user is the owner 
      final productData = productDoc.data();

      // Get current user ID safely
      String? currentUserId;
      try {
        final authProvider = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false);
        currentUserId = authProvider.user?.uid;
      } catch (e) {
        debugPrint('⚠️ Could not get auth context for ownership check');
      }

      if (currentUserId != null && productData?['sellerId'] != currentUserId) {
        debugPrint('❌ User is not the owner of this product');
        _errorMessage = 'You can only edit your own products';
        _setLoading(false);
        return false;
      }

      // Perform the update
      await _firestore.collection('products').doc(productId).update(updates);
      debugPrint('✅ Product updated successfully in Firestore: $productId');

      // Update local lists
      await _refreshLocalProduct(productId);

      notifyListeners();
      _setLoading(false);
      return true;

    } catch (e) {
      debugPrint('❌ Error updating product: $e');
      debugPrint('📚 Stack trace: ${StackTrace.current}');
      _errorMessage = 'Failed to update product: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  // Helper method to refresh a single product
  Future<void> _refreshLocalProduct(String productId) async {
    try {
      final updatedDoc = await _firestore.collection('products').doc(productId).get();
      if (updatedDoc.exists) {
        final updatedProduct = ProductModel.fromMap(productId, updatedDoc.data()!);

        final productIndex = _products.indexWhere((p) => p.id == productId);
        if (productIndex != -1) {
          _products[productIndex] = updatedProduct;
          debugPrint('✅ Updated product in _products list');
        }

        final userProductIndex = _userProducts.indexWhere((p) => p.id == productId);
        if (userProductIndex != -1) {
          _userProducts[userProductIndex] = updatedProduct;
          debugPrint('✅ Updated product in _userProducts list');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error refreshing local product: $e');
    }
  }

  // Delete product (soft delete by hiding)
  Future<bool> deleteProduct(String productId) async {
    return updateProduct(
      productId: productId,
      isHidden: true,
      isAvailable: false,
    );
  }

  // Permanently delete product
  Future<bool> permanentlyDeleteProduct(String productId, List<String> imageUrls) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('🗑️ Starting permanent deletion for product: $productId');

      // Delete images from storage
      for (String imageUrl in imageUrls) {
        if (imageUrl.contains('via.placeholder.com') ||
            imageUrl.contains('placehold.co') ||
            imageUrl.contains('dummyimage')) {
          debugPrint('⚠️ Skipping placeholder image: $imageUrl');
          continue;
        }

        try {
          final ref = _storage.refFromURL(imageUrl);
          await ref.delete();
          debugPrint('✅ Deleted image: $imageUrl');
        } catch (e) {
          debugPrint('⚠️ Error deleting image (continuing anyway): $e');
        }
      }

      // Delete from Firestore
      await _firestore.collection('products').doc(productId).delete();
      debugPrint('✅ Product document deleted from Firestore: $productId');

      _products.removeWhere((p) => p.id == productId);
      _userProducts.removeWhere((p) => p.id == productId);

      notifyListeners();
      _setLoading(false);
      return true;

    } catch (e) {
      debugPrint('❌ Error permanently deleting product: $e');
      _errorMessage = 'Failed to delete product: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  // Increment view count
  Future<void> incrementViewCount(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'viewCount': FieldValue.increment(1),
      });

      final productIndex = _products.indexWhere((p) => p.id == productId);
      if (productIndex != -1) {
        final updatedProduct = ProductModel.fromMap(productId, {
          ..._products[productIndex].toMap(),
          'viewCount': _products[productIndex].viewCount + 1,
        });
        _products[productIndex] = updatedProduct;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error incrementing view count: $e');
    }
  }

  // Search and filter methods
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setCondition(String condition) {
    _selectedCondition = condition;
    notifyListeners();
  }

  void setMaxPrice(double price) {
    _maxPrice = price;
    notifyListeners();
  }

  void setSortByNewest(bool newest) {
    _sortByNewest = newest;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    _selectedCondition = 'All';
    _maxPrice = 100000;
    _sortByNewest = true;
    notifyListeners();
  }

  // Get product by ID
  ProductModel? getProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      try {
        return _userProducts.firstWhere((product) => product.id == id);
      } catch (e) {
        return null;
      }
    }
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
