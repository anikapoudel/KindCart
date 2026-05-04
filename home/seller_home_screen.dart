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
import 'package:url_launcher/url_launcher.dart';

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
  late PageController _pageController;

  Stream<List<ChatModel>>? _chatsStream;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _ordersTabController = TabController(length: 3, vsync: this);
    _pageController = PageController();

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
    _pageController.dispose();
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

  Widget _buildGradientAppBar(
    BuildContext context,
    AuthProvider authProvider,
    ThemeProvider themeProvider,
    bool isWebLayout,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2E7D32),
            Color(0xFF4CAF50),
            Color(0xFFE91E63),
            Color(0xFFF06292),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 12,
            offset: const Offset(0, 3),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Title + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.white, Colors.white70],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Text(
                            'Seller Dashboard',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isWebLayout ? 22 : 20,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withAlpha(50),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.store_rounded,
                                size: isWebLayout ? 14 : 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Welcome back, ${authProvider.userData?['name']?.split(' ')[0] ?? 'Seller'}',
                                  style: TextStyle(
                                    fontSize: isWebLayout ? 11 : 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Theme toggle
                  _appBarIconButton(
                    icon: isDark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    onPressed: () => themeProvider.toggleTheme(),
                  ),
                  // Chat button with badge
                  StreamBuilder<List<ChatModel>>(
                    stream: _chatsStream,
                    builder: (context, snapshot) {
                      int unreadCount = 0;
                      if (snapshot.hasData && _currentUserId != null) {
                        unreadCount = _getTotalUnreadCount(
                            snapshot.data!, _currentUserId!);
                      }
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _appBarIconButton(
                              icon: Icons.chat_outlined,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ChatsListScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: 2,
                              top: 2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                    minWidth: 16, minHeight: 16),
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
                  // Profile button
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _appBarIconButton(
                      icon: Icons.person_outline,
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
              ),
              // Web-only tab bar
              if (isWebLayout)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    tabs: const [
                      Tab(text: 'Dashboard', icon: Icon(Icons.dashboard)),
                      Tab(text: 'Products', icon: Icon(Icons.inventory)),
                      Tab(text: 'Orders', icon: Icon(Icons.shopping_bag)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appBarIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: onPressed,
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWebLayout = screenWidth > 800;
    final bool isMobileLayout = screenWidth < 600;
    final bool isTabletLayout = screenWidth >= 600 && screenWidth < 900;
    final bool isDark = themeProvider.isDarkMode;

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
      resizeToAvoidBottomInset: true,
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      body: Column(
        children: [
          _buildGradientAppBar(
            context,
            authProvider,
            themeProvider,
            isWebLayout,
            isDark,
          ),
          Expanded(
            child: _isLoading
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
                            isMobileLayout,
                            isTabletLayout,
                          ),
                          _buildProductsTab(
                              productProvider.userProducts, authProvider),
                          _buildOrdersTab(orderProvider.sellerOrders),
                        ],
                      )
                    : PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        children: [
                          _buildDashboardTab(
                            productProvider.userProducts,
                            soldProducts,
                            totalEarnings,
                            pendingOrdersCount,
                            activeOrdersCount,
                            completedOrdersCount,
                            isWebLayout,
                            isMobileLayout,
                            isTabletLayout,
                          ),
                          _buildProductsTab(
                              productProvider.userProducts, authProvider),
                          _buildOrdersTab(orderProvider.sellerOrders),
                        ],
                      ),
          ),
        ],
      ),
      bottomNavigationBar: !isWebLayout
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                  _pageController.jumpToPage(index);
                  if (index == 1) {
                    _selectedFilter = 'All';
                  }
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              selectedItemColor: const Color(0xFFE91E63),
              unselectedItemColor: isDark ? Colors.grey[500] : Colors.grey,
              elevation: 8,
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
        backgroundColor: const Color(0xFFE91E63),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // Dashboard Tab
  Widget _buildDashboardTab(
    List allProducts,
    List soldProducts,
    double totalEarnings,
    int pendingOrdersCount,
    int activeOrdersCount,
    int completedOrdersCount,
    bool isWebLayout,
    bool isMobileLayout,
    bool isTabletLayout,
  ) {
    final activeProducts = allProducts.where((p) => p.isAvailable).toList();
    final int crossAxisCount = isWebLayout ? 4 : 2;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return RefreshIndicator(
      onRefresh: _loadSellerData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                        colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
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
                  Text('Overview',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87)),
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
                        color: const Color(0xFF4CAF50),
                        onTap: () {
                          if (isWebLayout) {
                            _tabController.animateTo(1);
                            setState(() {
                              _selectedFilter = 'Available';
                            });
                          } else {
                            setState(() {
                              _selectedIndex = 1;
                              _pageController.jumpToPage(1);
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
                              _pageController.jumpToPage(1);
                              _selectedFilter = 'Sold';
                            });
                          }
                        },
                      ),
                      _buildClickableStatCard(
                        icon: Icons.pending,
                        value: '$pendingOrdersCount',
                        label: 'Pending Orders',
                        color: const Color(0xFFE91E63),
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
                              _pageController.jumpToPage(2);
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
                        color: const Color(0xFF2E7D32),
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
                              _pageController.jumpToPage(2);
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
                  Text('Quick Actions',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.add_photo_alternate,
                          label: 'Add Product',
                          color: const Color(0xFF4CAF50),
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
                          color: const Color(0xFFE91E63),
                          onTap: () {
                            if (isWebLayout) {
                              _tabController.animateTo(2);
                            } else {
                              setState(() {
                                _selectedIndex = 2;
                                _pageController.jumpToPage(2);
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (soldProducts.isNotEmpty) ...[
                    Text('Recently Sold',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 12),
                    Card(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87)),
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
            // Footer
            if (isWebLayout)
              _buildCompactFooter(
                  context, isMobileLayout, isTabletLayout, isDark),
            if (!isWebLayout)
              const SizedBox(height: kBottomNavigationBarHeight + 10),
          ],
        ),
      ),
    );
  }

  //  FOOTER SECTION
  Widget _buildCompactFooter(BuildContext context, bool isMobileLayout,
      bool isTabletLayout, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobileLayout ? 20 : 40,
        vertical: 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [
            Color(0xFF1B5E20),
            Color(0xFF2E7D32),
            Color(0xFF388E3C),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main Footer Content
          LayoutBuilder(
            builder: (context, constraints) {
              if (isMobileLayout) {
                return _buildFooterMobileLayout(context);
              } else if (isTabletLayout) {
                return _buildFooterTabletLayout(context);
              } else {
                return _buildFooterDesktopLayout(context);
              }
            },
          ),
          const SizedBox(height: 20),
          // Divider Line
          Container(
            height: 1,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withAlpha(0),
                  Colors.white.withAlpha(100),
                  Colors.white.withAlpha(0),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Bottom Bar
          _buildFooterBottomBar(context, isMobileLayout),
        ],
      ),
    );
  }

  Widget _buildFooterDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: _buildFooterLogoSection(context),
        ),
        Expanded(
          flex: 1,
          child: Center(
            child: _buildFooterContactSection(context),
          ),
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.only(left: 40),
            child: _buildFooterSocialSection(context),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterTabletLayout(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildFooterLogoSection(context)),
            const SizedBox(width: 40),
            Expanded(child: _buildFooterContactSection(context)),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _buildFooterSocialSection(context)),
          ],
        ),
      ],
    );
  }

  Widget _buildFooterMobileLayout(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFooterLogoSection(context),
        const SizedBox(height: 24),
        _buildFooterContactSection(context),
        const SizedBox(height: 24),
        _buildFooterSocialSection(context),
      ],
    );
  }

  Widget _buildFooterLogoSection(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Colors.white, Colors.white70],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withAlpha(80),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/Logo.png',
                  width: 45,
                  height: 45,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.green.withAlpha(30),
                      child: const Icon(
                        Icons.eco,
                        color: Colors.white,
                        size: 26,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'KindCart',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxWidth: 280),
          child: const Text(
            'Sustainable second-hand marketplace connecting buyers, sellers, and donors for a greener future.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(40)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_rounded, color: Colors.white, size: 12),
              SizedBox(width: 4),
              Text(
                'Eco-Friendly',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooterContactSection(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'CONTACT US',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        _buildFooterContactItem(
          icon: Icons.phone_rounded,
          text: '+977 9847098514',
          onTap: () => _makePhoneCall('+9779847098514'),
        ),
        const SizedBox(height: 8),
        _buildFooterContactItem(
          icon: Icons.phone_rounded,
          text: '+977 9857059514',
          onTap: () => _makePhoneCall('+9779857059514'),
        ),
        const SizedBox(height: 8),
        _buildFooterContactItem(
          icon: Icons.email_rounded,
          text: 'support@kindcart.com',
          onTap: () => _sendEmail('support@kindcart.com'),
          isEmail: true,
        ),
        const SizedBox(height: 8),
        _buildFooterContactItem(
          icon: Icons.access_time_rounded,
          text: 'Mon-Fri: 9AM - 6PM',
          onTap: null,
        ),
      ],
    );
  }

  Widget _buildFooterContactItem({
    required IconData icon,
    required String text,
    VoidCallback? onTap,
    bool isEmail = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor:
            onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white70, size: 16),
                const SizedBox(width: 10),
                Text(
                  text,
                  style: TextStyle(
                    color: onTap != null ? Colors.white : Colors.white60,
                    fontSize: 12,
                    decoration: onTap != null ? TextDecoration.underline : null,
                    decorationColor: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterSocialSection(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CONNECT WITH US',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildFooterSocialIcon(
              iconData: Icons.camera_alt_rounded,
              label: 'Instagram',
              url: 'https://www.instagram.com',
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFEDA77),
                  Color(0xFFF58529),
                  Color(0xFFDD2A7B),
                  Color(0xFF8134AF),
                  Color(0xFF515BD4),
                ],
                stops: [0.0, 0.2, 0.5, 0.8, 1.0],
              ),
            ),
            const SizedBox(width: 16),
            _buildFooterSocialIcon(
              iconData: Icons.facebook_rounded,
              label: 'Facebook',
              url: 'https://www.facebook.com',
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1877F2), Color(0xFF0C63D4)],
              ),
            ),
            const SizedBox(width: 16),
            _buildFooterSocialIcon(
              iconData: Icons.chat_bubble_rounded,
              label: 'Twitter',
              url: 'https://www.twitter.com',
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1DA1F2), Color(0xFF0D8BD9)],
              ),
            ),
            const SizedBox(width: 16),
            _buildFooterSocialIcon(
              iconData: Icons.play_circle_filled_rounded,
              label: 'YouTube',
              url: 'https://www.youtube.com',
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF0000), Color(0xFFCC0000)],
              ),
            ),
            const SizedBox(width: 16),
            _buildFooterSocialIcon(
              iconData: Icons.work_rounded,
              label: 'LinkedIn',
              url: 'https://www.linkedin.com',
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A66C2), Color(0xFF004182)],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooterSocialIcon({
    required IconData iconData,
    required String label,
    required String url,
    required Gradient gradient,
  }) {
    return Tooltip(
      message: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _openSocialUrl(url),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              iconData,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterBottomBar(BuildContext context, bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFooterBottomLink('📍 About Us', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AboutScreen()),
          );
        }),
        const SizedBox(height: 12),
        Text(
          '© ${DateTime.now().year} KindCart. All rights reserved.',
          style: TextStyle(
            color: Colors.white.withAlpha(180),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFooterBottomLink(String text, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white54,
            ),
          ),
        ),
      ),
    );
  }

  // Helper Methods for Footer Actions
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showErrorDialog(context, 'Could not make phone call');
      }
    } catch (e) {
      _showErrorDialog(context, 'Phone call not supported on this device');
    }
  }

  Future<void> _sendEmail(String emailAddress) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        _showErrorDialog(context, 'Could not open email app');
      }
    } catch (e) {
      _showErrorDialog(context, 'Email not supported on this device');
    }
  }

  Future<void> _openSocialUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showErrorDialog(context, 'Could not open link');
      }
    } catch (e) {
      _showErrorDialog(context, 'Cannot open this link');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? color.withAlpha(30) : color.withAlpha(20),
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
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600])),
          ],
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? color.withAlpha(30) : color.withAlpha(20),
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

  Widget _buildProductsTab(List products, AuthProvider auth) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWebLayout = screenWidth > 800;

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No products yet',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 8),
            Text('Start adding your products for sale',
                style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600])),
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
                backgroundColor: const Color(0xFFE91E63),
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
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'Sold'
                  ? 'Items you sell will appear here'
                  : 'Your active products will appear here',
              style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ],
        ),
      );
    }

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
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  ),
                  dropdownColor:
                      isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  style:
                      TextStyle(color: isDark ? Colors.white : Colors.black87),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWebLayout = screenWidth > 800;

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No orders yet',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 8),
            Text(
              'When customers place orders, they\'ll appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600]),
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
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE91E63), Color(0xFFF06292)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No orders in this category',
                style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600])),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF4CAF50).withAlpha(20),
                    child: Text(
                      order.buyerName.isNotEmpty
                          ? order.buyerName[0].toUpperCase()
                          : 'B',
                      style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.buyerName,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: isDark ? Colors.white : Colors.black87)),
                        const SizedBox(height: 4),
                        Text(
                            '${order.items.length} item(s) • ${_formatCurrency(order.total)}',
                            style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600])),
                        Text(order.paymentMethod,
                            style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[500])),
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
                      color: isDark ? Colors.grey[900] : Colors.grey[50],
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
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    color:
                                        isDark ? Colors.white : Colors.black87),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text('Qty: ${firstItem.quantity}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600])),
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
                  Icon(Icons.calendar_today,
                      size: 12,
                      color: isDark ? Colors.grey[500] : Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(_formatDate(order.orderDate),
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[500])),
                  const Spacer(),
                  if (order.orderStatus == 'pending' ||
                      order.orderStatus == 'pending_contact')
                    TextButton.icon(
                      onPressed: () => _confirmOrder(order),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Confirm'),
                      style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2E7D32)),
                    ),
                  if (order.orderStatus == 'confirmed' && !isContactOrder)
                    TextButton.icon(
                      onPressed: () => _markAsShipped(order),
                      icon: const Icon(Icons.local_shipping, size: 16),
                      label: const Text('Ship'),
                      style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFF06292)),
                    ),
                  if (order.orderStatus == 'shipped' && !isContactOrder)
                    TextButton.icon(
                      onPressed: () => _markAsDelivered(order),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Deliver'),
                      style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2E7D32)),
                    ),
                  if (order.orderStatus == 'confirmed' && isContactOrder)
                    TextButton.icon(
                      onPressed: () => _markAsDelivered(order),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Complete Order'),
                      style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2E7D32)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(product) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

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
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
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
                        color: product.isAvailable
                            ? const Color(0xFF4CAF50)
                            : Colors.red,
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
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(_formatCurrency(product.price),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE91E63))),
                    const Spacer(),
                    Row(
                      children: [
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
                              size: 16, color: Color(0xFFE91E63)),
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

  Widget _buildApprovalPendingScreen(AuthProvider auth) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF2E7D32),
                  Color(0xFF4CAF50),
                  Color(0xFFE91E63),
                  Color(0xFFF06292)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.white, Colors.white70],
                        ).createShader(bounds),
                        child: const Text(
                          'Approval Pending',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.white),
                        ),
                      ),
                    ),
                    _appBarIconButton(
                      icon: isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      onPressed: () => themeProvider.toggleTheme(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          color: const Color(0xFFE91E63).withAlpha(20),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.hourglass_empty,
                          size: 80, color: Color(0xFFE91E63)),
                    ),
                    const SizedBox(height: 32),
                    Text('Approval Pending',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 16),
                    Text(
                      auth.sellerApprovalRequested
                          ? 'Your seller account is under review. You\'ll be able to start selling once approved by an admin.'
                          : 'Please request seller approval to start selling on KindCart.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),
                    if (!auth.sellerApprovalRequested)
                      ElevatedButton(
                        onPressed: () async {
                          await auth.requestSellerApproval();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Approval requested successfully!'),
                                  backgroundColor: Colors.green),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                        ),
                        child: const Text('Request Approval'),
                      ),
                    const SizedBox(height: 16),
                    TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ProfileScreen()),
                          );
                        },
                        child: const Text('Go Back to Profile')),
                  ],
                ),
              ),
            ),
          ),
        ],
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
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32)),
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
        return const Color(0xFFE91E63);
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.lightBlue;
      case 'shipped':
        return const Color(0xFFF06292);
      case 'delivered':
        return const Color(0xFF4CAF50);
      case 'completed':
        return const Color(0xFF2E7D32);
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
