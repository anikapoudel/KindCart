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
          final product =
              ProductModel.fromMap(productDoc.id, productDoc.data()!);
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
  Future<bool> addToWishlist(String userId, ProductModel product) async {
    try {
      debugPrint('➕ Adding to wishlist:');
      debugPrint('  - User ID: $userId');
      debugPrint('  - Product ID: ${product.id}');

      // First, add to wishlist subcollection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(product.id)
          .set({
        'productId': product.id,
        'addedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Successfully added to wishlist in Firestore');

      // update product wishlist count
      try {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(product.id)
            .update({
          'wishlistCount': FieldValue.increment(1),
        });
        debugPrint('✅ Updated product wishlist count');
      } catch (e) {
        // Log but don't fail
        debugPrint('⚠️ Could not update product wishlist count: $e');
      }

      // Add to local list
      if (!_items.any((item) => item.id == product.id)) {
        _items.add(product);
      }

      notifyListeners();
      return true;
    } on FirebaseException catch (e) {
      debugPrint('❌ Firebase error adding to wishlist:');
      debugPrint('  - Code: ${e.code}');
      debugPrint('  - Message: ${e.message}');
      return false;
    }
  }

  Future<bool> removeFromWishlist(String userId, String productId,
      {bool showSnackbar = true}) async {
    try {
      debugPrint('➖ Removing from wishlist: $productId');

      // Remove from wishlist subcollection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(productId)
          .delete();

      // update product wishlist count
      try {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .update({
          'wishlistCount': FieldValue.increment(-1),
        });
      } catch (e) {
        debugPrint('⚠️ Could not update product wishlist count: $e');
      }

      // Remove from local list
      _items.removeWhere((item) => item.id == productId);

      notifyListeners();
      return true;
    } on FirebaseException catch (e) {
      debugPrint(
          '❌ Firebase error removing from wishlist: ${e.code} - ${e.message}');
      return false;
    }
  }

  // Toggle wishlist
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
