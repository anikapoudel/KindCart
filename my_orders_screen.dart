import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import 'order_detail_screen.dart';
import 'user_chat_screen.dart';
import '../models/order_model.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    debugPrint('🔍 Loading orders for buyer: ${authProvider.user?.uid}');

    if (authProvider.isAuthenticated) {
      await orderProvider.loadBuyerOrders(authProvider.user!.uid);
      debugPrint(
          '📦 Orders loaded: ${orderProvider.buyerOrders.length} orders found');

      // Print each order for debugging
      for (var order in orderProvider.buyerOrders) {
        debugPrint(
            '  - Order ID: ${order.id}, Status: ${order.orderStatus}, Total: ₹${order.total}');
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    debugPrint(
        '🏠 Building MyOrdersScreen, orders count: ${orderProvider.buyerOrders.length}');

    // Filter orders by status
    final pendingOrders = orderProvider.buyerOrders
        .where((o) =>
            o.orderStatus == 'pending' || o.orderStatus == 'pending_contact')
        .toList();
    final activeOrders = orderProvider.buyerOrders
        .where((o) =>
            ['confirmed', 'processing', 'shipped'].contains(o.orderStatus))
        .toList();
    final completedOrders = orderProvider.buyerOrders
        .where((o) =>
            ['delivered', 'completed', 'cancelled'].contains(o.orderStatus))
        .toList();

    debugPrint(
        '📊 Order counts - Pending: ${pendingOrders.length}, Active: ${activeOrders.length}, Completed: ${completedOrders.length}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Pending', icon: Icon(Icons.pending)),
            Tab(text: 'Active', icon: Icon(Icons.local_shipping)),
            Tab(text: 'Completed', icon: Icon(Icons.check_circle)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : orderProvider.buyerOrders.isEmpty
              ? _buildEmptyState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOrderList(pendingOrders),
                    _buildOrderList(activeOrders),
                    _buildOrderList(completedOrders),
                  ],
                ),
    );
  }

  Widget _buildOrderList(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No orders in this category',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final firstItem = order.items.isNotEmpty ? order.items.first : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(order: order),
            ),
          ).then((_) => _loadOrders()); // Refresh when coming back
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Order ID and Status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.orderStatus).withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(order.orderStatus),
                          size: 14,
                          color: _getStatusColor(order.orderStatus),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(order.orderStatus),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(order.orderStatus),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '#${order.id.substring(0, 8)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Items preview
              if (firstItem != null) ...[
                Row(
                  children: [
                    // Item image
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        image: firstItem.imageUrl != null &&
                                firstItem.imageUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(firstItem.imageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: firstItem.imageUrl == null ||
                              firstItem.imageUrl!.isEmpty
                          ? const Icon(Icons.image_not_supported,
                              color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 12),

                    // Item details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            firstItem.productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Quantity: ${firstItem.quantity}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (order.items.length > 1)
                            Text(
                              '+${order.items.length - 1} more item(s)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Total amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${order.total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.paymentMethod,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Seller info and date
              Row(
                children: [
                  Icon(Icons.store, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.sellerName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatDate(order.orderDate),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),

              // Action buttons for pending orders
              if (order.orderStatus == 'pending' ||
                  order.orderStatus == 'pending_contact')
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      if (order.paymentMethod == 'Contact Seller')
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _contactSeller(order);
                            },
                            icon: const Icon(Icons.chat, size: 16),
                            label: const Text('Contact Seller'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              side: const BorderSide(color: Colors.orange),
                            ),
                          ),
                        ),
                      if (order.paymentMethod == 'Contact Seller')
                        const SizedBox(width: 8),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => _cancelOrder(order),
                          icon: const Icon(Icons.cancel, size: 16),
                          label: const Text('Cancel'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          const Text(
            'No orders yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Start shopping to see your orders here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(String status) {
    switch (status) {
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
      case 'pending_contact':
        return Icons.hourglass_empty;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'processing':
        return Icons.autorenew;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'completed':
        return Icons.star;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
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
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  //  Contact Seller method with chat navigation
  void _contactSeller(OrderModel order) async {
    debugPrint('💬 Contacting seller for order: ${order.id}');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // Get the first item's product ID for the chat
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final productId = firstItem?.productId ?? '';
    final productTitle = firstItem?.productName ?? 'Product';
    final productImage = firstItem?.imageUrl;

    // Generate a consistent chat ID
    final chatId = _generateChatId(
      authProvider.user!.uid,
      order.sellerId,
      productId,
    );

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Get or create chat
      final existingChatId = await chatProvider.getExistingChatId(
        buyerId: authProvider.user!.uid,
        sellerId: order.sellerId,
        productId: productId,
      );

      String finalChatId;

      if (existingChatId != null) {
        finalChatId = existingChatId;
        debugPrint('✅ Using existing chat: $finalChatId');
      } else {
        finalChatId = await chatProvider.getOrCreateChat(
          chatId: chatId,
          buyerId: authProvider.user!.uid,
          buyerName: authProvider.userData?['name'] ??
              authProvider.user!.displayName ??
              'Buyer',
          sellerId: order.sellerId,
          sellerName: order.sellerName,
          productId: productId,
          productTitle: productTitle,
          productImage: productImage,
        );
        debugPrint('✅ Created new chat: $finalChatId');
      }

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        // Send a message about this order
        String orderMessage = '';
        orderMessage +=
            '📦 **Regarding Order #${order.id.substring(0, 8)}**\n\n';
        orderMessage += 'I would like to discuss my order:\n';
        orderMessage += '• **Items:** ${order.items.length} item(s)\n';
        orderMessage += '• **Total:** ₹${order.total.toStringAsFixed(0)}\n';
        orderMessage += '• **Payment:** ${order.paymentMethod}\n\n';
        orderMessage +=
            'Please let me know about the delivery/pickup arrangements.';

        await chatProvider.sendMessage(
          chatId: finalChatId,
          senderId: authProvider.user!.uid,
          senderName: authProvider.userData?['name'] ??
              authProvider.user!.displayName ??
              'Buyer',
          content: orderMessage,
        );

        // Navigate to chat screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserChatScreen(
              chatId: finalChatId,
              otherUserName: order.sellerName,
              productTitle: productTitle,
              otherUserId: order.sellerId,
              productId: productId,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error contacting seller: $e');
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper method to generate consistent chat ID
  String _generateChatId(String userId1, String userId2, String productId) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}_$productId';
  }

  void _cancelOrder(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Text(
            'Are you sure you want to cancel order #${order.id.substring(0, 8)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Show loading in the specific card instead of whole screen
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      try {
        final success =
            await orderProvider.cancelOrder(order.id, authProvider.user!.uid);

        if (success && mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Order cancelled successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          await _loadOrders();
        } else if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Failed to cancel order. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ Error in cancel UI: $e');
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
}
