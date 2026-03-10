// lib/providers/wishlist_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import 'auth_provider.dart';

class WishlistProvider extends ChangeNotifier {
  List<ProductModel> _items = [];
  bool _isLoading = false;

  List<ProductModel> get items => _items;
  int get itemCount => _items.length;
  bool get isLoading => _isLoading;

  // Load wishlist from Firestore
  Future<void> loadWishlist(String userId) async {
    _setLoading(true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .get();

      final List<ProductModel> wishlistItems = [];

      for (var doc in snapshot.docs) {
        final productId = doc.data()['productId'] as String;

        // Fetch product details
        final productDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();

        if (productDoc.exists) {
          final product = ProductModel.fromMap(productDoc.id, productDoc.data()!);
          wishlistItems.add(product);
        }
      }

      _items = wishlistItems;
      debugPrint('✅ Loaded ${_items.length} wishlist items');
    } catch (e) {
      debugPrint('❌ Error loading wishlist: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Check if product is in wishlist
  Future<bool> isInWishlist(String userId, String productId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(productId)
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('❌ Error checking wishlist: $e');
      return false;
    }
  }

  // Add to wishlist
  Future<void> addToWishlist(String userId, ProductModel product) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(product.id)
          .set({
        'productId': product.id,
        'addedAt': FieldValue.serverTimestamp(),
      });

      // Update product wishlist count
      await FirebaseFirestore.instance
          .collection('products')
          .doc(product.id)
          .update({
        'wishlistCount': FieldValue.increment(1),
      });

      // Add to local list if not already present
      if (!_items.any((item) => item.id == product.id)) {
        _items.add(product);
      }

      notifyListeners();
      debugPrint('✅ Added to wishlist: ${product.id}');
    } catch (e) {
      debugPrint('❌ Error adding to wishlist: $e');
      rethrow;
    }
  }

  // Remove from wishlist
  Future<void> removeFromWishlist(String userId, String productId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(productId)
          .delete();

      // Update product wishlist count
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .update({
        'wishlistCount': FieldValue.increment(-1),
      });

      // Remove from local list
      _items.removeWhere((item) => item.id == productId);

      notifyListeners();
      debugPrint('✅ Removed from wishlist: $productId');
    } catch (e) {
      debugPrint('❌ Error removing from wishlist: $e');
      rethrow;
    }
  }

  // Toggle wishlist (add if not exists, remove if exists)
  Future<void> toggleWishlist(String userId, ProductModel product) async {
    final isInList = await isInWishlist(userId, product.id);

    if (isInList) {
      await removeFromWishlist(userId, product.id);
    } else {
      await addToWishlist(userId, product);
    }
  }

  // Clear wishlist
  Future<void> clearWishlist(String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      _items.clear();
      notifyListeners();
      debugPrint('✅ Cleared wishlist');
    } catch (e) {
      debugPrint('❌ Error clearing wishlist: $e');
    }
  }
  void sortItems(String sortBy) {
    switch (sortBy) {
      case 'newest':
        _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'price_low':
        _items.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        _items.sort((a, b) => b.price.compareTo(a.price));
        break;
    }
    notifyListeners();
  }
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}