import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistProvider extends ChangeNotifier {
  List<ProductModel> _items = [];
  bool _isLoading = false;

  List<ProductModel> get items => _items;

  int get itemCount => _items.length;

  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> loadWishlist(String userId) async {
    if (userId.isEmpty) return;

    _setLoading(true);
    try {
      await FirebaseAuth.instance.currentUser?.getIdToken();

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .get();

      final List<ProductModel> wishlistItems = [];
      for (var doc in snapshot.docs) {
        final productId = doc['productId'];
        final productDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();
        if (productDoc.exists) {
          wishlistItems.add(
            ProductModel.fromMap(productDoc.id, productDoc.data()!),
          );
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

  void clearLocalWishlist() {
    _items = [];
    _isLoading = false;
    notifyListeners();
  }

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

  Future<bool> addToWishlist(String userId, ProductModel product) async {
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

      try {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(product.id)
            .update({'wishlistCount': FieldValue.increment(1)});
      } catch (e) {
        debugPrint('⚠️ Could not update product wishlist count: $e');
      }

      if (!_items.any((item) => item.id == product.id)) {
        _items.add(product);
      }

      notifyListeners();
      return true;
    } on FirebaseException catch (e) {
      debugPrint(
          '❌ Firebase error adding to wishlist: ${e.code} - ${e.message}');
      return false;
    }
  }

  Future<bool> removeFromWishlist(String userId, String productId,
      {bool showSnackbar = true}) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(productId)
          .delete();

      try {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .update({'wishlistCount': FieldValue.increment(-1)});
      } catch (e) {
        debugPrint('⚠️ Could not update product wishlist count: $e');
      }

      _items.removeWhere((item) => item.id == productId);
      notifyListeners();
      return true;
    } on FirebaseException catch (e) {
      debugPrint(
          '❌ Firebase error removing from wishlist: ${e.code} - ${e.message}');
      return false;
    }
  }

  Future<void> toggleWishlist(String userId, ProductModel product) async {
    final isInList = await isInWishlist(userId, product.id);
    if (isInList) {
      await removeFromWishlist(userId, product.id);
    } else {
      await addToWishlist(userId, product);
    }
  }

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
}
