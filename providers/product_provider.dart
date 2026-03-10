// lib/providers/product_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../models/product_model.dart';

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
  bool _sortByNewest = true;  // Make this public via getter

  // Getters
  List<ProductModel> get products => _products;
  List<ProductModel> get userProducts => _userProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get sortByNewest => _sortByNewest;  // ✅ Add this getter

  // Filtered products based on current filters
  List<ProductModel> get filteredProducts {
    return _products.where((product) {
      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!product.title.toLowerCase().contains(query) &&
            !product.description.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Category filter
      if (_selectedCategory != 'All' && product.category != _selectedCategory) {
        return false;
      }

      // Condition filter
      if (_selectedCondition != 'All' && product.condition != _selectedCondition) {
        return false;
      }

      // Price filter
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

  // Add new product
  Future<bool> addProduct({
    required String title,
    required String description,
    required double price,
    required String category,
    required String condition,
    required List<File> images,
    Map<String, dynamic>? specifications,
    String? location,
    required String sellerId,
    required String sellerName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Upload images to Firebase Storage
      List<String> imageUrls = [];
      for (int i = 0; i < images.length; i++) {
        final file = images[i];
        final fileName = '${sellerId}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final ref = _storage.ref().child('product_images').child(fileName);

        await ref.putFile(file);
        final url = await ref.getDownloadURL();
        imageUrls.add(url);

        debugPrint('✅ Uploaded image $i: $url');
      }

      // Create product in Firestore
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
        'isAvailable': true,
        'isActive': true,
        'isHidden': false,
        'specifications': specifications ?? {},
        'location': location ?? 'Not specified',
        'viewCount': 0,
        'wishlistCount': 0,
      };

      final docRef = await _firestore.collection('products').add(productData);

      debugPrint('✅ Product added with ID: ${docRef.id}');

      // Reload products
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

      await _firestore.collection('products').doc(productId).update(updates);

      debugPrint('✅ Product updated: $productId');

      // Reload products
      await loadProducts();

      _setLoading(false);
      return true;

    } catch (e) {
      debugPrint('❌ Error updating product: $e');
      _errorMessage = 'Failed to update product';
      _setLoading(false);
      return false;
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

  // Permanently delete product (use with caution!)
  Future<bool> permanentlyDeleteProduct(String productId, List<String> imageUrls) async {
    _setLoading(true);
    _clearError();

    try {
      // Delete images from storage
      for (String imageUrl in imageUrls) {
        try {
          final ref = _storage.refFromURL(imageUrl);
          await ref.delete();
        } catch (e) {
          debugPrint('⚠️ Error deleting image: $e');
        }
      }

      // Delete from Firestore
      await _firestore.collection('products').doc(productId).delete();

      debugPrint('✅ Product permanently deleted: $productId');

      // Reload products
      await loadProducts();

      _setLoading(false);
      return true;

    } catch (e) {
      debugPrint('❌ Error permanently deleting product: $e');
      _errorMessage = 'Failed to delete product';
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
      return null;
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