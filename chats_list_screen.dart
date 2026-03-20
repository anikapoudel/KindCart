import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../models/chat_model.dart';
import 'user_chat_screen.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
          backgroundColor: Colors.green,
        ),
        body: const Center(
          child: Text('Please login to view messages'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: chatProvider.getUserChatsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!;

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No messages yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When you contact a seller, your chats will appear here',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];

              // Determine other user's info
              final isBuyer = chat.buyerId == userId;
              final otherUserId = isBuyer ? chat.sellerId : chat.buyerId;
              final otherUserName = isBuyer ? chat.sellerName : chat.buyerName;

              // Determine unread count for current user
              final unreadCount =
                  isBuyer ? chat.unreadCountBuyer : chat.unreadCountSeller;

              // Determine if last message is from other user
              final isFromOther = (isBuyer && !chat.lastMessageIsFromBuyer) ||
                  (!isBuyer && chat.lastMessageIsFromBuyer);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        child: Text(
                          otherUserName.isNotEmpty
                              ? otherUserName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                      if (unreadCount > 0 && isFromOther)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    otherUserName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chat.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: unreadCount > 0 && isFromOther
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        chat.productTitle,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  trailing: Text(
                    _formatTime(chat.lastMessageTime),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontWeight: unreadCount > 0 && isFromOther
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserChatScreen(
                          chatId: chat.id,
                          otherUserName: otherUserName,
                          productTitle: chat.productTitle,
                          otherUserId: otherUserId,
                          productId: chat.productId,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}
