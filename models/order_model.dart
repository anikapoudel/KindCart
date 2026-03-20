import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderModel {
  final String id;
  final String buyerId;
  final String buyerName;
  final String buyerEmail;
  final String buyerPhone;
  final String sellerId;
  final String sellerName;
  final String? sellerPhone;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String deliveryAddress;
  final String city;
  final String? postalCode;
  final String paymentMethod;
  final String orderStatus;
  final DateTime orderDate;
  final DateTime? expectedDeliveryDate;
  final String? notes;
  final String? trackingNumber;
  final bool isReviewed;
  final double? rating;
  final String? reviewText;
  final DateTime? deliveredDate;

  OrderModel({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.buyerEmail,
    required this.buyerPhone,
    required this.sellerId,
    required this.sellerName,
    this.sellerPhone,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.deliveryAddress,
    required this.city,
    this.postalCode,
    required this.paymentMethod,
    required this.orderStatus,
    required this.orderDate,
    this.expectedDeliveryDate,
    this.notes,
    this.trackingNumber,
    this.isReviewed = false,
    this.rating,
    this.reviewText,
    this.deliveredDate,
  });

  // Status helpers
  bool get isPending => orderStatus == 'pending';

  bool get isConfirmed => orderStatus == 'confirmed';

  bool get isProcessing => orderStatus == 'processing';

  bool get isShipped => orderStatus == 'shipped';

  bool get isDelivered => orderStatus == 'delivered';

  bool get isCancelled => orderStatus == 'cancelled';

  bool get isPendingContact => orderStatus == 'pending_contact';

  bool get isContacted => orderStatus == 'contacted';

  bool get isCompleted => orderStatus == 'completed';

  Color get statusColor {
    switch (orderStatus) {
      case 'pending':
      case 'pending_contact':
        return Colors.orange;
      case 'confirmed':
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String get statusText {
    switch (orderStatus) {
      case 'pending':
        return 'Pending Confirmation';
      case 'pending_contact':
        return 'Awaiting Contact';
      case 'confirmed':
        return 'Confirmed';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'contacted':
        return 'Contact Made';
      case 'completed':
        return 'Completed';
      default:
        return orderStatus;
    }
  }

  //  method:
  OrderModel copyWithStatus(String newStatus) {
    return OrderModel(
      id: this.id,
      buyerId: this.buyerId,
      buyerName: this.buyerName,
      buyerEmail: this.buyerEmail,
      buyerPhone: this.buyerPhone,
      sellerId: this.sellerId,
      sellerName: this.sellerName,
      items: this.items,
      subtotal: this.subtotal,
      deliveryFee: this.deliveryFee,
      total: this.total,
      orderStatus: newStatus,
      paymentMethod: this.paymentMethod,
      orderDate: this.orderDate,
      deliveryAddress: this.deliveryAddress,
      city: this.city,
      postalCode: this.postalCode,
      expectedDeliveryDate: this.expectedDeliveryDate,
      trackingNumber: this.trackingNumber,
      isReviewed: this.isReviewed,
    );
  }

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    return OrderModel(
      id: id,
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? '',
      buyerEmail: map['buyerEmail'] ?? '',
      buyerPhone: map['buyerPhone'] ?? '',
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      sellerPhone: map['sellerPhone'],
      items: (map['items'] as List? ?? [])
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      deliveryFee: (map['deliveryFee'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      deliveryAddress: map['deliveryAddress'] ?? '',
      city: map['city'] ?? '',
      postalCode: map['postalCode'],
      paymentMethod: map['paymentMethod'] ?? '',
      orderStatus: map['orderStatus'] ?? 'pending',
      orderDate: (map['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expectedDeliveryDate:
          (map['expectedDeliveryDate'] as Timestamp?)?.toDate(),
      notes: map['notes'],
      trackingNumber: map['trackingNumber'],
      isReviewed: map['isReviewed'] ?? false,
      rating: map['rating'] != null ? (map['rating'] as num).toDouble() : null,
      reviewText: map['reviewText'],
      deliveredDate: (map['deliveredDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerEmail': buyerEmail,
      'buyerPhone': buyerPhone,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerPhone': sellerPhone,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'total': total,
      'deliveryAddress': deliveryAddress,
      'city': city,
      'postalCode': postalCode,
      'paymentMethod': paymentMethod,
      'orderStatus': orderStatus,
      'orderDate': Timestamp.fromDate(orderDate),
      'expectedDeliveryDate': expectedDeliveryDate != null
          ? Timestamp.fromDate(expectedDeliveryDate!)
          : null,
      'notes': notes,
      'trackingNumber': trackingNumber,
      'isReviewed': isReviewed,
      'rating': rating,
      'reviewText': reviewText,
      'deliveredDate':
          deliveredDate != null ? Timestamp.fromDate(deliveredDate!) : null,
    };
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String? imageUrl;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
    };
  }
}
