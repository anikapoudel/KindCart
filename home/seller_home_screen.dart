import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/order_provider.dart';
import '../providers/chat_provider.dart';
import '../theme_provider.dart';
import '../screens/addproduct_screen.dart';
import '../screens/editproduct_screen.dart';
import '../screens/item_detail_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/chats_list_screen.dart';
import '../screens/order_detail_screen.dart';
import '../models/order_model.dart';
import '../models/chat_model.dart';
import '../screens/about_screen.dart';

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TabController _ordersTabController;
  bool _isLoading = false;
  String _selectedFilter = 'All';
  int _selectedIndex = 0;

  Stream<List<ChatModel>>? _chatsStream;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _ordersTabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _tabController.index == 0) {
        if (mounted) {
          setState(() {
            _selectedFilter = 'All';
          });
        }
      }
    });

    _loadSellerData();
    _initChatStream();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ordersTabController.dispose();
    super.dispose();
  }

  Future<void> _loadSellerData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      if (authProvider.isAuthenticated) {
        await productProvider.loadUserProducts(authProvider.user!.uid);
        await orderProvider.loadSellerOrders(authProvider.user!.uid);
      }
    } catch (e) {
      debugPrint('Error loading seller data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _initChatStream() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null && _currentUserId != userId) {
      _currentUserId = userId;
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      _chatsStream = chatProvider.getUserChatsStream(userId);
    }
  }

  int _getTotalUnreadCount(List<ChatModel> chats, String userId) {
    int totalUnread = 0;
    for (var chat in chats) {
      totalUnread += chat.unreadCountSeller;
    }
    return totalUnread;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###');
    return 'NPR ${formatter.format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWebLayout = screenWidth > 800;

    if (!authProvider.isSellerApproved) {
      return _buildApprovalPendingScreen(authProvider);
    }

    final soldProducts =
        productProvider.userProducts.where((p) => !p.isAvailable).toList();
    final totalEarnings =
        soldProducts.fold<double>(0.0, (sum, product) => sum + product.price);

    final pendingOrdersCount = orderProvider.sellerOrders
        .where((o) =>
            o.orderStatus == 'pending' || o.orderStatus == 'pending_contact')
        .length;

    final activeOrdersCount = orderProvider.sellerOrders
        .where((o) =>
            ['confirmed', 'processing', 'shipped'].contains(o.orderStatus))
        .length;

    final completedOrdersCount = orderProvider.sellerOrders
        .where((o) => ['delivered', 'completed'].contains(o.orderStatus))
        .length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seller Dashboard',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Welcome back, ${authProvider.userData?['name'] ?? 'Seller'}',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          Tooltip(
            message: themeProvider.isDarkMode
                ? 'Switch to Light Mode'
                : 'Switch to Dark Mode',
            child: IconButton(
              icon: Icon(themeProvider.isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode),
              onPressed: () => themeProvider.toggleTheme(),
            ),
          ),
          StreamBuilder<List<ChatModel>>(
            stream: _chatsStream,
            builder: (context, snapshot) {
              int unreadCount = 0;
              if (snapshot.hasData && _currentUserId != null) {
                unreadCount =
                    _getTotalUnreadCount(snapshot.data!, _currentUserId!);
              }
              return Stack(
                children: [
                  Tooltip(
                    message: 'Messages',
                    child: IconButton(
                      icon: const Icon(Icons.chat_outlined),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ChatsListScreen()),
                        );
                      },
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          Tooltip(
            message: 'Profile',
            child: IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()),
                );
              },
            ),
          ),
        ],
        //  TabBar for web layout
        bottom: isWebLayout
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: 'Dashboard', icon: Icon(Icons.dashboard)),
                  Tab(text: 'Products', icon: Icon(Icons.inventory)),
                  Tab(text: 'Orders', icon: Icon(Icons.shopping_bag)),
                ],
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isWebLayout
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDashboardTab(
                      productProvider.userProducts,
                      soldProducts,
                      totalEarnings,
                      pendingOrdersCount,
                      activeOrdersCount,
                      completedOrdersCount,
                      isWebLayout,
                    ),
                    _buildProductsTab(
                        productProvider.userProducts, authProvider),
                    _buildOrdersTab(orderProvider.sellerOrders),
                  ],
                )
              : IndexedStack(
                  index: _selectedIndex,
                  children: [
                    _buildDashboardTab(
                      productProvider.userProducts,
                      soldProducts,
                      totalEarnings,
                      pendingOrdersCount,
                      activeOrdersCount,
                      completedOrdersCount,
                      isWebLayout,
                    ),
                    _buildProductsTab(
                        productProvider.userProducts, authProvider),
                    _buildOrdersTab(orderProvider.sellerOrders),
                  ],
                ),
      //  bottom navigation bar for mobile
      bottomNavigationBar: !isWebLayout
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                  if (index == 1) {
                    _selectedFilter = 'All';
                  }
                });
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.orange,
              unselectedItemColor: Colors.grey,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory),
                  label: 'Products',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_bag),
                  label: 'Orders',
                ),
              ],
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
          if (result == true) {
            _loadSellerData();
          }
        },
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildCompactFooter(bool isDark, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.menu_book_rounded,
                      color: Color(0xFF2E7D32), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Our Mission - About Us',
                    style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(width: 80, height: 1, color: Colors.white.withAlpha(80)),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🌱',
                  style: TextStyle(
                      fontSize: 14, color: Colors.white.withAlpha(230))),
              const SizedBox(width: 8),
              Text(
                'One purchase at a time',
                style: TextStyle(
                    color: Colors.white.withAlpha(230),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(width: 80, height: 1, color: Colors.white.withAlpha(80)),
          const SizedBox(height: 12),
          Text(
            '© ${DateTime.now().year} KindCart',
            style: TextStyle(
                color: Colors.white.withAlpha(180),
                fontSize: 11,
                fontWeight: FontWeight.w400),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(
    List allProducts,
    List soldProducts,
    double totalEarnings,
    int pendingOrdersCount,
    int activeOrdersCount,
    int completedOrdersCount,
    bool isWebLayout,
  ) {
    final activeProducts = allProducts.where((p) => p.isAvailable).toList();
    final int crossAxisCount = isWebLayout ? 4 : 2;

    return RefreshIndicator(
      onRefresh: _loadSellerData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: isWebLayout ? 0 : kBottomNavigationBarHeight + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.orange, Colors.deepOrange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Earnings',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(
                          _formatCurrency(totalEarnings),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'From ${soldProducts.length} items sold',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Overview',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                    children: [
                      _buildClickableStatCard(
                        icon: Icons.inventory,
                        value: '${activeProducts.length}',
                        label: 'Active Listings',
                        color: Colors.green,
                        onTap: () {
                          if (isWebLayout) {
                            _tabController.animateTo(1);
                            setState(() {
                              _selectedFilter = 'Available';
                            });
                          } else {
                            setState(() {
                              _selectedIndex = 1;
                              _selectedFilter = 'Available';
                            });
                          }
                        },
                      ),
                      _buildClickableStatCard(
                        icon: Icons.sell,
                        value: '${soldProducts.length}',
                        label: 'Items Sold',
                        color: Colors.blue,
                        onTap: () {
                          if (isWebLayout) {
                            _tabController.animateTo(1);
                            setState(() {
                              _selectedFilter = 'Sold';
                            });
                          } else {
                            setState(() {
                              _selectedIndex = 1;
                              _selectedFilter = 'Sold';
                            });
                          }
                        },
                      ),
                      _buildClickableStatCard(
                        icon: Icons.pending,
                        value: '$pendingOrdersCount',
                        label: 'Pending Orders',
                        color: Colors.orange,
                        onTap: () {
                          if (isWebLayout) {
                            _tabController.animateTo(2);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (_ordersTabController.index != 0) {
                                _ordersTabController.animateTo(0);
                              }
                            });
                          } else {
                            setState(() {
                              _selectedIndex = 2;
                            });
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (_ordersTabController.index != 0) {
                                _ordersTabController.animateTo(0);
                              }
                            });
                          }
                        },
                      ),
                      _buildClickableStatCard(
                        icon: Icons.check_circle,
                        value: '$completedOrdersCount',
                        label: 'Completed Orders',
                        color: Colors.green,
                        onTap: () {
                          if (isWebLayout) {
                            _tabController.animateTo(2);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (_ordersTabController.index != 2) {
                                _ordersTabController.animateTo(2);
                              }
                            });
                          } else {
                            setState(() {
                              _selectedIndex = 2;
                            });
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (_ordersTabController.index != 2) {
                                _ordersTabController.animateTo(2);
                              }
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Quick Actions',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.add_photo_alternate,
                          label: 'Add Product',
                          color: Colors.green,
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const AddProductScreen()),
                            );
                            if (result == true) _loadSellerData();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.shopping_bag,
                          label: 'View Orders',
                          color: Colors.orange,
                          onTap: () {
                            if (isWebLayout) {
                              _tabController.animateTo(2);
                            } else {
                              setState(() => _selectedIndex = 2);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (soldProducts.isNotEmpty) ...[
                    const Text('Recently Sold',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount:
                            soldProducts.length > 3 ? 3 : soldProducts.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (_, index) {
                          final product = soldProducts[index];
                          return ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                image: product.imageUrls.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(
                                            product.imageUrls.first),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: product.imageUrls.isEmpty
                                  ? const Icon(Icons.image_not_supported,
                                      color: Colors.grey)
                                  : null,
                            ),
                            title: Text(product.title,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(_formatCurrency(product.price)),
                            trailing: const Icon(Icons.check_circle,
                                color: Colors.green),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isWebLayout)
              Container(
                margin: const EdgeInsets.only(top: 24),
                child: _buildCompactFooter(
                    Theme.of(context).brightness == Brightness.dark, context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClickableStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTab(List products, AuthProvider auth) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No products yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Start adding your products for sale',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddProductScreen()),
                );
                if (result == true) _loadSellerData();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    final filteredProducts = _getFilteredProducts(products);

    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'Sold'
                  ? 'No sold items yet'
                  : 'No active listings',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'Sold'
                  ? 'Items you sell will appear here'
                  : 'Your active products will appear here',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 800;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFilter,
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Products')),
                    DropdownMenuItem(
                        value: 'Available', child: Text('Available')),
                    DropdownMenuItem(value: 'Sold', child: Text('Sold')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedFilter = value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWebLayout ? 4 : 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return _buildProductCard(product);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersTab(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No orders yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'When customers place orders, they\'ll appear here',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final pendingOrders = orders
        .where((o) =>
            o.orderStatus == 'pending' || o.orderStatus == 'pending_contact')
        .toList();
    final processingOrders = orders
        .where((o) =>
            ['confirmed', 'processing', 'shipped'].contains(o.orderStatus))
        .toList();
    final completedOrders = orders
        .where((o) => ['delivered', 'completed'].contains(o.orderStatus))
        .toList();

    return Column(
      children: [
        Container(
          color: Colors.orange,
          child: TabBar(
            controller: _ordersTabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'Pending', icon: Icon(Icons.pending)),
              Tab(text: 'Processing', icon: Icon(Icons.autorenew)),
              Tab(text: 'Completed', icon: Icon(Icons.done_all)),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _ordersTabController,
            children: [
              _buildOrderList(pendingOrders, isPending: true),
              _buildOrderList(processingOrders, isProcessing: true),
              _buildOrderList(completedOrders, isCompleted: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderList(List<OrderModel> orders,
      {bool isPending = false,
      bool isProcessing = false,
      bool isCompleted = false}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No orders in this category',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSellerData,
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
    final isContactOrder = order.paymentMethod == 'Contact Seller';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  OrderDetailScreen(order: order, isSeller: true),
            ),
          ).then((_) => _loadSellerData());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.orderStatus).withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getStatusIcon(order.orderStatus),
                            size: 14,
                            color: _getStatusColor(order.orderStatus)),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(order.orderStatus),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(order.orderStatus)),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text('#${order.id.substring(0, 8)}',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.green.withAlpha(20),
                    child: Text(
                      order.buyerName.isNotEmpty
                          ? order.buyerName[0].toUpperCase()
                          : 'B',
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.buyerName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(
                            '${order.items.length} item(s) • ${_formatCurrency(order.total)}',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[600])),
                        Text(order.paymentMethod,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (firstItem != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                          image: firstItem.imageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(firstItem.imageUrl!),
                                  fit: BoxFit.cover)
                              : null,
                        ),
                        child: firstItem.imageUrl == null
                            ? const Icon(Icons.image_not_supported,
                                size: 20, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(firstItem.productName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text('Qty: ${firstItem.quantity}',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      Text(
                          _formatCurrency(firstItem.price * firstItem.quantity),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(_formatDate(order.orderDate),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  const Spacer(),
                  if (order.orderStatus == 'pending' ||
                      order.orderStatus == 'pending_contact')
                    TextButton.icon(
                      onPressed: () => _confirmOrder(order),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Confirm'),
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.green),
                    ),
                  if (order.orderStatus == 'confirmed' && !isContactOrder)
                    TextButton.icon(
                      onPressed: () => _markAsShipped(order),
                      icon: const Icon(Icons.local_shipping, size: 16),
                      label: const Text('Ship'),
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.purple),
                    ),
                  if (order.orderStatus == 'shipped' && !isContactOrder)
                    TextButton.icon(
                      onPressed: () => _markAsDelivered(order),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Deliver'),
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.green),
                    ),
                  if (order.orderStatus == 'confirmed' && isContactOrder)
                    TextButton.icon(
                      onPressed: () => _markAsDelivered(order),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Complete Order'),
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.green),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalPendingScreen(AuthProvider auth) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(20), shape: BoxShape.circle),
                child: const Icon(Icons.hourglass_empty,
                    size: 80, color: Colors.orange),
              ),
              const SizedBox(height: 32),
              const Text('Approval Pending',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(
                auth.sellerApprovalRequested
                    ? 'Your seller account is under review. You\'ll be able to start selling once approved by an admin.'
                    : 'Please request seller approval to start selling on KindCart.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              if (!auth.sellerApprovalRequested)
                ElevatedButton(
                  onPressed: () async {
                    await auth.requestSellerApproval();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Approval requested successfully!'),
                            backgroundColor: Colors.green),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Request Approval'),
                ),
              const SizedBox(height: 16),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ItemDetailScreen(item: product)),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                      image: product.imageUrls.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(product.imageUrls.first),
                              fit: BoxFit.cover)
                          : null,
                    ),
                    child: product.imageUrls.isEmpty
                        ? const Center(
                            child: Icon(Icons.image_not_supported,
                                color: Colors.grey))
                        : null,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: product.isAvailable ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(product.isAvailable ? 'Available' : 'Sold',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(_formatCurrency(product.price),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.orange)),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.visibility,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${product.viewCount}',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey)),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      EditProductScreen(product: product)),
                            );
                          },
                          child: const Icon(Icons.edit,
                              size: 16, color: Colors.orange),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List _getFilteredProducts(List products) {
    switch (_selectedFilter) {
      case 'Available':
        return products.where((p) => p.isAvailable).toList();
      case 'Sold':
        return products.where((p) => !p.isAvailable).toList();
      default:
        return products;
    }
  }

  void _confirmOrder(OrderModel order) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await orderProvider.updateOrderStatus(order.id, 'confirmed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Order confirmed'), backgroundColor: Colors.green),
        );
        await _loadSellerData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _markAsShipped(OrderModel order) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await orderProvider.updateOrderStatus(order.id, 'shipped');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Order marked as shipped'),
              backgroundColor: Colors.green),
        );
        await _loadSellerData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _markAsDelivered(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Delivered'),
        content: const Text('Marking this order as delivered will:\n'
            '• Update order status to delivered\n'
            '• Mark all items as sold\n'
            '• Update your earnings\n\n'
            'Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.green),
              child: const Text('Yes, Complete Order')),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;
    setState(() => _isLoading = true);

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    try {
      final success = await orderProvider.completeOrder(order.id, order.items);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Order completed successfully! Products marked as sold.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3)),
        );
        await _loadSellerData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to complete order. Please try again.'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error in markAsDelivered: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
      case 'pending_contact':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.lightBlue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'completed':
        return Colors.teal;
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
        return 'PENDING';
      case 'pending_contact':
        return 'AWAITING CONTACT';
      case 'confirmed':
        return 'CONFIRMED';
      case 'processing':
        return 'PROCESSING';
      case 'shipped':
        return 'SHIPPED';
      case 'delivered':
        return 'DELIVERED';
      case 'completed':
        return 'COMPLETED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return status.toUpperCase();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
