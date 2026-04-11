import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui' as ui;
import '../screens/addproduct_screen.dart';
import '../screens/shop_screen.dart';
import '../screens/adddonation_screen.dart';
import '../screens/about_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/search_screen.dart';
import '../screens/wishlist_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/item_detail_screen.dart';
import '../screens/chats_list_screen.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../theme_provider.dart';
import '../services/navigation_helper.dart';
import '../../models/product_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;
  int _currentSlide = 0;

  final GlobalKey _fabKey = GlobalKey();

  // Sample data for slider
  final List<Map<String, dynamic>> _slides = [
    {
      'title': '🌱 Sustainable Shopping',
      'subtitle': 'Give items a second life',
      'image': '🌍',
      'color': Colors.green,
      'buttonText': 'Shop Now',
      'destination': const ShopScreen(),
      'type': 'shop',
    },
    {
      'title': '🤝 Donate with Heart',
      'subtitle': 'Help those in need today',
      'image': '💝',
      'color': Colors.orange,
      'buttonText': 'Donate Now',
      'destination': const AddDonationScreen(),
      'type': 'donate',
    },
    {
      'title': '💰 Earn While Saving',
      'subtitle': 'Sell your pre-loved items',
      'image': '💰',
      'color': Colors.blue,
      'buttonText': 'Start Selling',
      'destination': const AddProductScreen(),
      'type': 'sell',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Auto slide for carousel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoSlide();
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
      // Boost image cache
      PaintingBinding.instance.imageCache.maximumSize = 100;
      PaintingBinding.instance.imageCache.maximumSizeBytes =
          100 << 20; // 100 MB

      final ImageProvider provider = const AssetImage('assets/screen1.gif');
      provider.resolve(createLocalImageConfiguration(context));
    });
  }

  void _startAutoSlide() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _autoSlide();
      }
    });
  }

  void _autoSlide() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 3));
      if (_pageController.hasClients) {
        int nextPage = _currentSlide + 1;
        if (nextPage >= _slides.length) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  // Helper method to check if user is logged in and show dialog if not
  bool _checkAuthAndNavigate(BuildContext context, VoidCallback action) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) {
      _showLoginRequiredDialog(context);
      return false;
    }
    action();
    return true;
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please login to access this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              NavigationHelper.goToProfileScreen(context);
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  List<ProductModel> _getFeaturedProducts(List<ProductModel> products) =>
      products.take(6).toList();

  List<ProductModel> _getDonationItems(List<ProductModel> products) =>
      products.where((p) => p.price == 0).take(5).toList();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);

    final isDark = themeProvider.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F7F5);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final screenWidth = MediaQuery.of(context).size.width;

    String displayName = 'Guest';
    if (authProvider.userData != null &&
        authProvider.userData!['name'] != null) {
      displayName = authProvider.userData!['name'].toString().split(' ')[0];
    } else if (authProvider.user?.displayName != null) {
      displayName = authProvider.user!.displayName!.split(' ')[0];
    } else if (authProvider.user?.email != null) {
      displayName = authProvider.user!.email!.split('@')[0];
    }

    final featuredProducts = _getFeaturedProducts(productProvider.products);
    final donationItems = _getDonationItems(productProvider.products);

    // Detect if running on web (using screen width as indicator)
    final bool isWebLayout = screenWidth > 800;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(88),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF1A1A2E),
                      const Color(0xFF1B2F3B),
                      const Color(0xFF1A1A2E),
                    ]
                  : [
                      const Color(0xFFE8F5E9),
                      const Color(0xFFF3E5F5),
                      const Color(0xFFE8F5E9),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.5, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withAlpha(40)
                    : Colors.black.withAlpha(12),
                blurRadius: 12,
                offset: const Offset(0, 3),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      // Logo and Brand Section
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AboutScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      Colors.green.shade300,
                                      Colors.purple.shade300
                                    ]
                                  : [
                                      Colors.green.shade400,
                                      Colors.purple.shade400
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isDark
                                        ? Colors.green.shade800
                                        : Colors.green.shade200)
                                    .withAlpha(80),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Container(
                            width: isWebLayout ? 46 : 40,
                            height: isWebLayout ? 46 : 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/Logo.png',
                                width: isWebLayout ? 46 : 40,
                                height: isWebLayout ? 46 : 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.green.withAlpha(30),
                                    child: Icon(
                                      Icons.eco,
                                      color: isDark
                                          ? Colors.green[300]
                                          : Colors.green[700],
                                      size: isWebLayout ? 26 : 22,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Brand and Welcome Section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: isDark
                                    ? [
                                        Colors.green.shade300,
                                        Colors.purple.shade300
                                      ]
                                    : [
                                        const Color(0xFF2E7D32),
                                        const Color(0xFF7B1FA2)
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: Text(
                                'KindCart',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isWebLayout ? 22 : 19,
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
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [
                                          Colors.green.shade900.withAlpha(60),
                                          Colors.purple.shade900.withAlpha(60)
                                        ]
                                      : [
                                          Colors.green.shade50,
                                          Colors.purple.shade50
                                        ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.grey[800]!
                                      : Colors.grey[200]!,
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.waving_hand_rounded,
                                    size: isWebLayout ? 14 : 12,
                                    color: isDark
                                        ? Colors.green[300]
                                        : Colors.green[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      authProvider.user != null
                                          ? 'Welcome back, $displayName'
                                          : 'Welcome, User',
                                      style: TextStyle(
                                        fontSize: isWebLayout ? 11 : 10,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? Colors.grey[300]
                                            : Colors.grey[700],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    authProvider.user != null ? '✨' : '👋',
                                    style: TextStyle(
                                        fontSize: isWebLayout ? 12 : 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Action Buttons
                      if (isWebLayout)
                        _buildWebActionButtons(
                            themeProvider, isDark, authProvider)
                      else
                        _buildAndroidActionButtons(
                            themeProvider, isDark, authProvider),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: Colors.green,
        onRefresh: () => productProvider.loadProducts(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Slider Section
              SizedBox(
                height: 220,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentSlide = index;
                        });
                      },
                      itemCount: _slides.length,
                      itemBuilder: (context, index) {
                        final slide = _slides[index];
                        return Container(
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                slide['color'] as Color,
                                (slide['color'] as Color).withAlpha(180),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (slide['color'] as Color).withAlpha(77),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -20,
                                bottom: -20,
                                child: Text(
                                  slide['image'] as String,
                                  style: const TextStyle(
                                      fontSize: 120, color: Colors.white12),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        slide['title'] as String,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        slide['subtitle'] as String,
                                        style: TextStyle(
                                          color: Colors.white.withAlpha(230),
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      ElevatedButton(
                                        onPressed: () {
                                          // Use type-based navigation
                                          final type = slide['type'] as String;
                                          switch (type) {
                                            case 'shop':
                                              NavigationHelper.goToShopScreen(
                                                  context);
                                              break;
                                            case 'donate':
                                              _checkAuthAndNavigate(context,
                                                  () {
                                                NavigationHelper
                                                    .goToDonateScreen(context);
                                              });
                                              break;
                                            case 'sell':
                                              _checkAuthAndNavigate(context,
                                                  () {
                                                NavigationHelper.goToSellScreen(
                                                    context);
                                              });
                                              break;
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor:
                                              slide['color'] as Color,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 10),
                                        ),
                                        child:
                                            Text(slide['buttonText'] as String),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _slides.length,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentSlide == index
                                  ? Colors.green
                                  : Colors.grey.withAlpha(128),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Featured Items
              _SectionHeader(
                title: 'Featured Items',
                actionLabel: 'See All',
                onAction: () => NavigationHelper.goToShopScreen(context),
              ),

              const SizedBox(height: 12),

              // grid with proper sizing
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: isWebLayout ? 0.6 : 0.35,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount:
                      productProvider.isLoading ? 6 : featuredProducts.length,
                  itemBuilder: (context, index) {
                    if (productProvider.isLoading) {
                      return _buildShimmerCard(isDark);
                    }
                    if (index >= featuredProducts.length) {
                      return const SizedBox();
                    }
                    return _buildProductCard(
                        featuredProducts[index], isDark, cardColor);
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Free Donations
              if (donationItems.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Free Donations',
                  actionLabel: 'View All',
                  onAction: () => NavigationHelper.goToDonateScreen(context),
                  leadingIcon: Icons.volunteer_activism_rounded,
                  iconColor: Colors.green,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 185,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: donationItems.length,
                    itemBuilder: (context, index) => _buildDonationCard(
                        donationItems[index], isDark, cardColor),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const SizedBox(height: 30),

              // Compact Footer
              _buildCompactFooter(isDark, context),
            ],
          ),
        ),
      ),

      // Bottom Navigation for Android
      bottomNavigationBar:
          isWebLayout ? null : _buildAndroidBottomNav(isDark, authProvider),

      // Floating action button
      floatingActionButton: Container(
        key: _fabKey,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7B2D8B), Color(0xFF9B4D96)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B2D8B).withAlpha(80),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            // Help feature
            debugPrint('Help button pressed');
            ChatScreen.showAnchored(
              context: context,
              anchorKey: _fabKey,
              height: 600.0,
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.auto_awesome_rounded,
              color: Colors.white, size: 20),
          label: const Text(
            'Help',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  // Compact Footer Widget
  Widget _buildCompactFooter(bool isDark, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
              : [const Color(0xFF1B5E20), const Color(0xFF0D47A1)],
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
          // Our Mission Button
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
                  Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFF1B5E20),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Our Mission - About Us',
                    style: TextStyle(
                      color: Color(0xFF1B5E20),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Divider
          Container(
            width: 80,
            height: 1,
            color: Colors.white.withAlpha(80),
          ),
          const SizedBox(height: 12),

          // Quotation
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🌱',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withAlpha(230),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'One purchase at a time',
                style: TextStyle(
                  color: Colors.white.withAlpha(230),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Divider
          Container(
            width: 80,
            height: 1,
            color: Colors.white.withAlpha(80),
          ),
          const SizedBox(height: 12),

          // Copyright Info
          Text(
            '© ${DateTime.now().year} KindCart',
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Web-specific action buttons
  Widget _buildWebActionButtons(
      ThemeProvider themeProvider, bool isDark, AuthProvider authProvider) {
    return Row(
      children: [
        _ElegantIconButton(
          icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          onTap: () => themeProvider.toggleTheme(),
          tooltip: isDark ? 'Light Mode' : 'Dark Mode',
          isDark: isDark,
        ),
        _ElegantIconButton(
          icon: Icons.search_rounded,
          onTap: () => NavigationHelper.goToSearchScreen(context),
          tooltip: 'Search',
          isDark: isDark,
        ),
        Consumer<WishlistProvider>(
          builder: (context, wishlistProvider, child) {
            return _ElegantBadgeButton(
              icon: Icons.favorite_border_rounded,
              badgeCount: wishlistProvider.items.length,
              onTap: () {
                _checkAuthAndNavigate(context, () {
                  NavigationHelper.goToWishlistScreen(context);
                });
              },
              tooltip: 'Wishlist',
              isDark: isDark,
            );
          },
        ),
        Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            return _ElegantBadgeButton(
              icon: Icons.shopping_bag_outlined,
              badgeCount: cartProvider.items.length,
              onTap: () {
                _checkAuthAndNavigate(context, () {
                  NavigationHelper.goToCartScreen(context);
                });
              },
              tooltip: 'Shopping Cart',
              isDark: isDark,
            );
          },
        ),
        _ElegantIconButton(
          icon: Icons.person_outline_rounded,
          onTap: () => NavigationHelper.goToProfileScreen(context),
          tooltip: 'Profile',
          isDark: isDark,
        ),
      ],
    );
  }

  // Android-specific action buttons
  Widget _buildAndroidActionButtons(
      ThemeProvider themeProvider, bool isDark, AuthProvider authProvider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ElegantIconButton(
          icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          onTap: () => themeProvider.toggleTheme(),
          tooltip: isDark ? 'Light Mode' : 'Dark Mode',
          isDark: isDark,
          iconSize: 18,
        ),
        _ElegantIconButton(
          icon: Icons.search_rounded,
          onTap: () => NavigationHelper.goToSearchScreen(context),
          tooltip: 'Search',
          isDark: isDark,
          iconSize: 18,
        ),
      ],
    );
  }

  // Android bottom navigation bar
  Widget _buildAndroidBottomNav(bool isDark, AuthProvider authProvider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A1A1A), const Color(0xFF2D1B2D)]
              : [Colors.white, const Color(0xFFFFF0F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          switch (index) {
            case 0:
              break;
            case 1:
              _checkAuthAndNavigate(context, () {
                NavigationHelper.goToCartScreen(context);
              });
              break;
            case 2:
              _checkAuthAndNavigate(context, () {
                NavigationHelper.goToWishlistScreen(context);
              });
              break;
            case 3:
              NavigationHelper.goToProfileScreen(context);
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFF7B2D8B),
        unselectedItemColor: isDark ? Colors.grey[600] : Colors.grey[400],
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              activeIcon: Icon(Icons.shopping_bag_rounded),
              label: 'Cart'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border_rounded),
              activeIcon: Icon(Icons.favorite_rounded),
              label: 'Wishlist'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel product, bool isDark, Color cardColor) {
    return GestureDetector(
      onTap: () {
        _checkAuthAndNavigate(context, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailScreen(item: product),
            ),
          );
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 40 : 12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
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
                      color:
                          isDark ? Colors.grey[800] : const Color(0xFFF0F4F0),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: product.imageUrls.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
                            child: Image.network(
                              product.imageUrls.first,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(Icons.broken_image,
                                    size: 24, color: Colors.grey[400]),
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(Icons.image_not_supported,
                                size: 28, color: Colors.grey[400]),
                          ),
                  ),
                  if (product.condition.isNotEmpty)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.condition,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(7, 7, 7, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      product.category,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.green,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: isDark ? Colors.white : Colors.grey[900]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product.price == 0
                              ? 'FREE'
                              : 'NPR ${product.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: product.price == 0
                                ? Colors.green[600]
                                : Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getConditionColor(product.condition),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            product.condition,
                            style: TextStyle(
                                fontSize: 9,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[500]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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

  Color _getConditionColor(String condition) {
    switch (condition) {
      case 'Like New':
        return Colors.green;
      case 'Excellent':
        return Colors.teal;
      case 'Good':
        return Colors.blue;
      case 'Fair':
        return Colors.orange;
      case 'Needs Repair':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDonationCard(ProductModel item, bool isDark, Color cardColor) {
    final firstImage = item.imageUrls.isNotEmpty ? item.imageUrls.first : null;

    return GestureDetector(
      onTap: () {
        _checkAuthAndNavigate(context, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailScreen(item: item),
            ),
          );
        });
      },
      child: Container(
        width: 145,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 40 : 12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
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
                      color:
                          isDark ? Colors.grey[800] : const Color(0xFFF0F4F0),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    child: firstImage != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(14)),
                            child: Image.network(
                              firstImage,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(Icons.broken_image,
                                    size: 24, color: Colors.grey[400]),
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(Icons.image_not_supported,
                                size: 28, color: Colors.grey[400]),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('FREE',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isDark ? Colors.white : Colors.grey[900]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Free to claim',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[600]),
                    ),
                    const SizedBox(height: 2),
                    Text(item.condition,
                        style: TextStyle(
                            fontSize: 9,
                            color:
                                isDark ? Colors.grey[500] : Colors.grey[500])),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 50,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//  Icon Button
class _ElegantIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool isDark;
  final double iconSize;

  const _ElegantIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    required this.isDark,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    Colors.grey[800]!.withAlpha(200),
                    Colors.grey[900]!.withAlpha(200)
                  ]
                : [
                    Colors.white.withAlpha(220),
                    Colors.grey[50]!.withAlpha(220)
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withAlpha(30)
                  : Colors.grey.withAlpha(20),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: IconButton(
          padding: const EdgeInsets.all(8),
          constraints: BoxConstraints(
            minWidth: iconSize + 14,
            minHeight: iconSize + 14,
          ),
          icon: Icon(
            icon,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
            size: iconSize,
          ),
          onPressed: onTap,
          splashRadius: iconSize + 6,
          splashColor:
              isDark ? Colors.white.withAlpha(20) : Colors.green.withAlpha(30),
          highlightColor: Colors.transparent,
        ),
      ),
    );
  }
}

//  Badge Button
class _ElegantBadgeButton extends StatelessWidget {
  final IconData icon;
  final int badgeCount;
  final VoidCallback onTap;
  final String tooltip;
  final bool isDark;
  final double iconSize;

  const _ElegantBadgeButton({
    required this.icon,
    required this.badgeCount,
    required this.onTap,
    required this.tooltip,
    required this.isDark,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        Colors.grey[800]!.withAlpha(200),
                        Colors.grey[900]!.withAlpha(200)
                      ]
                    : [
                        Colors.white.withAlpha(220),
                        Colors.grey[50]!.withAlpha(220)
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withAlpha(30)
                      : Colors.grey.withAlpha(20),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: IconButton(
              padding: const EdgeInsets.all(8),
              constraints: BoxConstraints(
                minWidth: iconSize + 14,
                minHeight: iconSize + 14,
              ),
              icon: Icon(
                icon,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                size: iconSize,
              ),
              onPressed: onTap,
              splashRadius: iconSize + 6,
              splashColor: isDark
                  ? Colors.white.withAlpha(20)
                  : Colors.green.withAlpha(30),
              highlightColor: Colors.transparent,
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Colors.red[400]!, Colors.red[600]!]
                        : [Colors.red[500]!, Colors.red[700]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.grey[900]! : Colors.white,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withAlpha(50),
                      blurRadius: 4,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

//  section header
class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData? leadingIcon;
  final Color? iconColor;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.leadingIcon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (leadingIcon != null) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (iconColor ?? Colors.green).withAlpha(25),
                        (iconColor ?? Colors.green).withAlpha(50),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(leadingIcon,
                      color: iconColor ?? Colors.green, size: 16),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF7B2D8B),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              children: [
                Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
