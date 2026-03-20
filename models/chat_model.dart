import 'package:cloud_firestore/cloud_firestore.dart';
class ChatModel {
  final String id;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;
  final String productId;
  final String productTitle;
  final String? productImage;
  final DateTime lastMessageTime;
  final String lastMessage;
  final bool lastMessageIsFromBuyer;
  final int unreadCountBuyer;
  final int unreadCountSeller;
  final String? orderId; // Link to order if placed

  ChatModel({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.productId,
    required this.productTitle,
    this.productImage,
    required this.lastMessageTime,
    required this.lastMessage,
    required this.lastMessageIsFromBuyer,
    this.unreadCountBuyer = 0,
    this.unreadCountSeller = 0,
    this.orderId,
  });

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'buyerName': buyerName,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'productId': productId,
      'productTitle': productTitle,
      'productImage': productImage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessage': lastMessage,
      'lastMessageIsFromBuyer': lastMessageIsFromBuyer,
      'unreadCountBuyer': unreadCountBuyer,
      'unreadCountSeller': unreadCountSeller,
      'orderId': orderId,
    };
  }

  factory ChatModel.fromMap(String id, Map<String, dynamic> map) {
    return ChatModel(
      id: id,
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? '',
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      productId: map['productId'] ?? '',
      productTitle: map['productTitle'] ?? '',
      productImage: map['productImage'],
      lastMessageTime: (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageIsFromBuyer: map['lastMessageIsFromBuyer'] ?? false,
      unreadCountBuyer: map['unreadCountBuyer'] ?? 0,
      unreadCountSeller: map['unreadCountSeller'] ?? 0,
      orderId: map['orderId'],
    );
  }
}

// models/message_model.dart
class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'type': type.index,
    };
  }

  factory MessageModel.fromMap(String id, Map<String, dynamic> map) {
    return MessageModel(
      id: id,
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      content: map['content'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      type: MessageType.values[map['type'] ?? 0],
    );
  }
}

enum MessageType { text, image, system }