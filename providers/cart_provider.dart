import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/product_model.dart';
import '../providers/auth_provider.dart' as app_auth;

class CartProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _items = [];
  String? _currentUserId;

  List<Map<String, dynamic>> get items => _items;

  int get itemCount => _items.length;

  // Set current user ID
  void setCurrentUser(String? userId) {
    _currentUserId = userId;
    if (userId != null) {
      loadCart(userId);
    }
  }

  // Load cart from persistent storage
  Future<void> loadCart(String userId) async {
    try {
      debugPrint('🔄 Loading cart for user: $userId');
      final prefs = await SharedPreferences.getInstance();
      final String? cartData = prefs.getString('cart_$userId');
      if (cartData != null) {
        final List<dynamic> decoded = json.decode(cartData);
        _items =
            decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        debugPrint('✅ Loaded ${_items.length} items from cart');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error loading cart: $e');
    }
  }

  // Save cart to persistent storage
  Future<void> _saveCart() async {
    if (_currentUserId == null) {
      debugPrint('⚠️ Cannot save cart: No user ID set');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final String cartData = json.encode(_items);
      await prefs.setString('cart_${_currentUserId!}', cartData);
      debugPrint('✅ Cart saved for user: $_currentUserId');
    } catch (e) {
      debugPrint('❌ Error saving cart: $e');
    }
  }

  // Get current user ID
  String? _getCurrentUserId() {
    return _currentUserId;
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
        'id': product.id, //  for backward compatibility

        // Product details
        'name': product.title,
        'title': product.title,
        'description': product.description,

        // Price fields (both string and numeric)
        'price': '₹${product.price.toStringAsFixed(0)}',
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

  void clearCart() {
    debugPrint('🧹 Clearing cart');
    _items.clear();
    _saveCart();
    notifyListeners();
  }

  // Helper method to get a specific item's productId
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
        // Parse from string like "₹888"
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
    return '₹50';
  }

  // Get delivery fee as double
  double get deliveryFeeAmount {
    return subtotal > 500 ? 0 : 50;
  }

  // Get grand total as formatted string
  String get grandTotal {
    double total = subtotal + deliveryFeeAmount;
    return '₹${total.toStringAsFixed(0)}';
  }

  // Get grand total as double
  double get grandTotalAmount {
    return subtotal + deliveryFeeAmount;
  }
}
