import 'package:flutter/material.dart';
import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;

  int get itemCount => _items.length;

  void addToCart(ProductModel product, {int quantity = 1}) {
    // Check if item already exists in cart
    final existingItemIndex = _items.indexWhere((item) => item['id'] == product.id);

    if (existingItemIndex >= 0) {
      // Update quantity if item exists
      _items[existingItemIndex]['quantity'] = (_items[existingItemIndex]['quantity'] ?? 1) + quantity;
    } else {
      // Add new item with field names matching cart_screen expectations
      _items.add({
        'id': product.id,
        'name': product.title,
        'title': product.title,
        'price': '₹${product.price.toStringAsFixed(0)}',
        'priceValue': product.price,
        'image': product.imageUrls.isNotEmpty ? product.imageUrls.first : null,
        'imageUrl': product.imageUrls.isNotEmpty ? product.imageUrls.first : null,
        'quantity': quantity,
        'sellerId': product.sellerId,
        'sellerName': product.sellerName,
        'category': product.category,
      });
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _items.removeWhere((item) => item['id'] == productId);
    notifyListeners();
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void updateQuantity(String productId, int newQuantity) {
    final index = _items.indexWhere((item) => item['id'] == productId);
    if (index >= 0) {
      if (newQuantity <= 0) {
        removeFromCart(productId);
      } else {
        _items[index]['quantity'] = newQuantity;
        notifyListeners();
      }
    }
  }

  void incrementQuantity(int index) {
    if (index >= 0 && index < _items.length) {
      _items[index]['quantity'] = (_items[index]['quantity'] ?? 1) + 1;
      notifyListeners();
    }
  }

  void decrementQuantity(int index) {
    if (index >= 0 && index < _items.length) {
      int currentQty = _items[index]['quantity'] ?? 1;
      if (currentQty > 1) {
        _items[index]['quantity'] = currentQty - 1;
        notifyListeners();
      }
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  double get subtotal {
    double total = 0;
    for (var item in _items) {
      double price = item['priceValue']?.toDouble() ?? 0;
      int qty = item['quantity'] ?? 1;
      total += price * qty;
    }
    return total;
  }

  String get totalPrice {
    return '₹${subtotal.toStringAsFixed(0)}';
  }

  String get deliveryFee {
    if (subtotal > 500) {
      return 'Free';
    }
    return '₹50';
  }

  double get deliveryFeeAmount {
    return subtotal > 500 ? 0 : 50;
  }

  String get grandTotal {
    double total = subtotal + deliveryFeeAmount;
    return '₹${total.toStringAsFixed(0)}';
  }
}
