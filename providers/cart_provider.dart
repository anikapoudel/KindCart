import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../providers/auth_provider.dart' as app_auth;

class CartProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _items = [];
  String? _currentUserId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> get items => _items;

  int get itemCount => _items.length;

  // Set current user ID
  void setCurrentUser(String? userId) {
    _currentUserId = userId;
    if (userId != null) {
      loadCart(userId);
    } else {
      _items.clear();
      notifyListeners();
      debugPrint('🛒 Cart cleared after logout');
    }
  }

  // Load cart from Firestore
  Future<void> loadCart(String userId) async {
    try {
      debugPrint('🔄 Loading cart for user: $userId');

      DocumentSnapshot doc =
          await _firestore.collection('carts').doc(userId).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<dynamic> items = data['items'] ?? [];
        _items = items.cast<Map<String, dynamic>>();
        debugPrint('✅ Loaded ${_items.length} items from Firestore');
        notifyListeners();
      } else {
        await _loadFromLocalStorage(userId);
      }
    } catch (e) {
      debugPrint('❌ Error loading cart from Firestore: $e');
      await _loadFromLocalStorage(userId);
    }
  }

  // Fallback to local storage
  Future<void> _loadFromLocalStorage(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cartData = prefs.getString('cart_$userId');
      if (cartData != null) {
        final List<dynamic> decoded = json.decode(cartData);
        _items =
            decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        debugPrint('✅ Loaded ${_items.length} items from local storage');

        // If user is logged in, migrate local cart to Firestore
        if (_currentUserId != null && _items.isNotEmpty) {
          await _saveToFirestore();
          // Clear local storage after migration
          await prefs.remove('cart_$userId');
          debugPrint('📤 Migrated local cart to Firestore');
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error loading from local storage: $e');
    }
  }

  // Save to Firestore only
  Future<void> _saveToFirestore() async {
    if (_currentUserId == null) return;

    try {
      await _firestore.collection('carts').doc(_currentUserId!).set({
        'userId': _currentUserId,
        'items': _items,
        'updatedAt': FieldValue.serverTimestamp(),
        'itemCount': _items.length,
      });
      debugPrint('✅ Cart saved to Firestore for user: $_currentUserId');
    } catch (e) {
      debugPrint('❌ Error saving to Firestore: $e');
      // If Firestore fails, save to local storage as backup
      await _saveToLocalStorage();
    }
  }

  // Backup to local storage
  Future<void> _saveToLocalStorage() async {
    if (_currentUserId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final String cartData = json.encode(_items);
      await prefs.setString('cart_${_currentUserId!}', cartData);
      debugPrint('💾 Cart saved to local storage (backup)');
    } catch (e) {
      debugPrint('❌ Error saving to local storage: $e');
    }
  }

  //  save method
  Future<void> _saveCart() async {
    if (_currentUserId == null) {
      debugPrint('⚠️ Cannot save cart: No user ID set');
      return;
    }

    // Save to Firestore
    await _saveToFirestore();

    //  local backup for offline support
    await _saveToLocalStorage();
  }

  // Modified clear cart
  void clearCart() async {
    debugPrint('🧹 Clearing cart');
    _items.clear();

    if (_currentUserId != null) {
      // Clear from Firestore
      try {
        await _firestore.collection('carts').doc(_currentUserId!).delete();
        debugPrint('🗑️ Cart cleared from Firestore');
      } catch (e) {
        debugPrint('❌ Error clearing Firestore cart: $e');
      }

      // Clear from local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cart_${_currentUserId!}');
    }

    notifyListeners();
  }

  //  method for logout - ensures cart is saved before logout
  Future<void> saveCartBeforeLogout() async {
    if (_currentUserId != null && _items.isNotEmpty) {
      await _saveToFirestore();
      debugPrint('💾 Cart preserved before logout');
    }
  }

  void addToCart(ProductModel product, {int quantity = 1}) {
    debugPrint('🛒 Adding to cart - Product ID: ${product.id}');
    debugPrint('   Product Title: ${product.title}');
    debugPrint('   Seller ID: ${product.sellerId}');
    debugPrint('   Seller Phone: ${product.sellerPhone}');

    // Check if item already exists in cart using productId
    final existingItemIndex = _items.indexWhere(
        (item) => item['productId'] == product.id || item['id'] == product.id);

    if (existingItemIndex >= 0) {
      // Update quantity if item exists
      _items[existingItemIndex]['quantity'] =
          (_items[existingItemIndex]['quantity'] ?? 1) + quantity;
      debugPrint(
          '✅ Updated existing item quantity to: ${_items[existingItemIndex]['quantity']}');
    } else {
      // Add new item with ALL field names that might be used across the app
      final newItem = {
        // Primary identifier
        'productId': product.id,
        'id': product.id, // for backward compatibility

        // Product details
        'name': product.title,
        'title': product.title,
        'description': product.description,

        // Price fields (both string and numeric)
        'price': 'NPR ${product.price.toStringAsFixed(0)}',
        'priceValue': product.price,

        // Image fields
        'image': product.imageUrls.isNotEmpty ? product.imageUrls.first : null,
        'imageUrl':
            product.imageUrls.isNotEmpty ? product.imageUrls.first : null,
        'imageUrls': product.imageUrls,

        // Quantity
        'quantity': quantity,

        // Seller information
        'sellerId': product.sellerId,
        'sellerName': product.sellerName,
        'sellerPhone': product.sellerPhone,

        // Product metadata
        'category': product.category,
        'condition': product.condition,
        'isAvailable': product.isAvailable,
      };

      _items.add(newItem);
      debugPrint('✅ Added new item to cart with productId: ${product.id}');
      debugPrint('   Cart now has ${_items.length} items');
    }

    _saveCart();
    notifyListeners();
  }

  void removeFromCart(String productId) {
    debugPrint('🗑️ Removing from cart - Product ID: $productId');
    _items.removeWhere(
        (item) => item['productId'] == productId || item['id'] == productId);
    _saveCart();
    notifyListeners();
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      debugPrint('🗑️ Removing item at index $index');
      _items.removeAt(index);
      _saveCart();
      notifyListeners();
    }
  }

  void updateQuantity(String productId, int newQuantity) {
    final index = _items.indexWhere(
        (item) => item['productId'] == productId || item['id'] == productId);

    if (index >= 0) {
      debugPrint('📦 Updating quantity for product $productId to $newQuantity');

      if (newQuantity <= 0) {
        removeFromCart(productId);
      } else {
        _items[index]['quantity'] = newQuantity;
        _saveCart();
        notifyListeners();
      }
    }
  }

  void incrementQuantity(int index) {
    if (index >= 0 && index < _items.length) {
      final currentQty = _items[index]['quantity'] ?? 1;
      _items[index]['quantity'] = currentQty + 1;
      debugPrint(
          '➕ Incremented quantity for item at index $index to ${_items[index]['quantity']}');
      _saveCart();
      notifyListeners();
    }
  }

  void decrementQuantity(int index) {
    if (index >= 0 && index < _items.length) {
      int currentQty = _items[index]['quantity'] ?? 1;
      if (currentQty > 1) {
        _items[index]['quantity'] = currentQty - 1;
        debugPrint(
            '➖ Decremented quantity for item at index $index to ${_items[index]['quantity']}');
        _saveCart();
        notifyListeners();
      }
    }
  }

  //  method to get a specific item's productId
  String? getProductIdAtIndex(int index) {
    if (index >= 0 && index < _items.length) {
      return _items[index]['productId'] ?? _items[index]['id'];
    }
    return null;
  }

  // Calculate subtotal as double
  double get subtotal {
    double total = 0;
    for (var item in _items) {
      // Try to get price from priceValue first, then parse from price string
      double price = 0;

      if (item['priceValue'] != null) {
        price = item['priceValue']?.toDouble() ?? 0;
      } else if (item['price'] != null) {
        // Parse from string like "NPR 888"
        String priceStr = item['price'].toString();
        price = double.parse(priceStr.replaceAll('₹', '').replaceAll(',', ''));
      }

      int qty = item['quantity'] ?? 1;
      total += price * qty;

      debugPrint(
          '💰 Item: ${item['name']}, Price: $price, Qty: $qty, Subtotal: $total');
    }
    return total;
  }

  // Get total price as formatted string
  String get totalPrice {
    return '₹${subtotal.toStringAsFixed(0)}';
  }

  // Get delivery fee as string
  String get deliveryFee {
    if (subtotal > 500) {
      return 'Free';
    }
    return 'NPR 50';
  }

  // Get delivery fee as double
  double get deliveryFeeAmount {
    return subtotal > 500 ? 0 : 50;
  }

  // Get grand total as formatted string
  String get grandTotal {
    double total = subtotal + deliveryFeeAmount;
    return 'NPR ${total.toStringAsFixed(0)}';
  }

  // Get grand total as double
  double get grandTotalAmount {
    return subtotal + deliveryFeeAmount;
  }
}
