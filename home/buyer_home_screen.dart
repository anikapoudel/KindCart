import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/about_screen.dart';
import '../screens/shop_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/search_screen.dart';
import '../screens/wishlist_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/item_detail_screen.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../theme_provider.dart';
import '../../services/navigation_helper.dart';
import '../../models/product_model.dart';
import '../screens/chats_list_screen.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;
  int _currentSlide = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': '🛍️ Sustainable Fashion',
      'subtitle': 'Discover pre-loved treasures at amazing prices',
      'image': '👗',
      'color': const Color(0xFF7B2D8B),
      'buttonText': 'Shop Now',
      'type': 'shop',
    },
    {
      'title': '✨ Quality Thrift Items',
      'subtitle': 'Every item tells a story - find yours today',
      'image': '🌟',
      'color': const Color(0xFF00695C),
      'buttonText': 'Explore',
      'type': 'shop',
    },
    {
      'title': '💰 Save Big, Live Green',
      'subtitle': 'Good items at good price',
      'image': '💚',
      'color': const Color(0xFF2E7D32),
      'buttonText': 'Start Shopping',
      'type': 'shop',
    },
  ];

  final List<Map<String, dynamic>> impactStats = [
    {
      'value': 'Join Us',
      'icon': Icons.people_outline,
      'color': Colors.green,
      'label': 'Growing Community'
    },
    {
      'value': 'Be First',
      'icon': Icons.eco_outlined,
      'color': Colors.blue,
      'label': 'Start the Movement'
    },
    {
      'value': 'You Can',
      'icon': Icons.favorite_outline,
      'color': Colors.orange,
      'label': 'Make a Difference'
    },
    {
      'value': 'Start Now',
      'icon': Icons.rocket_launch_outlined,
      'color': Colors.purple,
      'label': 'First Donation'
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
      _startAutoSlide();
    });
  }

  void _startAutoSlide() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _autoSlide();
    });
  }

  void _autoSlide() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 3));
      if (_pageController.hasClients) {
        int nextPage = _currentSlide + 1;
        if (nextPage >= _slides.length) nextPage = 0;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<ProductModel> _getFeaturedProducts(List<ProductModel> products) =>
      products.take(6).toList();

  List<ProductModel> _getDonationItems(List<ProductModel> products) =>
      products.where((p) => p.price == 0).take(5).toList();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);

    final isDark = themeProvider.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F7F5);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final surfaceColor =
        isDark ? const Color(0xFF252525) : const Color(0xFFF0F4F0);

    String displayName = 'Buyer';
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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black12,
        toolbarHeight: 64,
        title: GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => const AboutScreen())),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.green.withAlpha(80),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/Logo.png',
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.green.withAlpha(30),
                        child: Icon(
                          Icons.eco,
                          color: isDark ? Colors.green[300] : Colors.green,
                          size: 24,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'KindCart',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    'Welcome back, $displayName! 👋',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.green[300] : Colors.green[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          _AppBarIconButton(
            icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: isDark ? Colors.amber : Colors.grey[600]!,
            onTap: () => themeProvider.toggleTheme(),
            isDark: isDark,
            tooltip: isDark ? 'Light Mode' : 'Dark Mode',
          ),
          _AppBarIconButton(
            icon: Icons.chat_bubble_outline_rounded,
            color: isDark ? Colors.white70 : Colors.grey[700]!,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ChatsListScreen())),
            isDark: isDark,
            tooltip: 'Messages',
          ),
          _AppBarIconButton(
            icon: Icons.search_rounded,
            color: isDark ? Colors.white70 : Colors.grey[700]!,
            onTap: () => NavigationHelper.goToSearchScreen(context),
            isDark: isDark,
            tooltip: 'Search',
          ),
          Consumer<WishlistProvider>(
            builder: (context, wishlistProvider, child) {
              return _BadgeIconButton(
                icon: Icons.favorite_border_rounded,
                badgeCount: wishlistProvider.items.length,
                badgeColor: Colors.red,
                iconColor: isDark ? Colors.white70 : Colors.grey[700]!,
                isDark: isDark,
                onTap: () => NavigationHelper.goToWishlistScreen(context),
                tooltip: 'Wishlist',
              );
            },
          ),
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              return _BadgeIconButton(
                icon: Icons.shopping_bag_outlined,
                badgeCount: cartProvider.items.length,
                badgeColor: Colors.green,
                iconColor: isDark ? Colors.white70 : Colors.grey[700]!,
                isDark: isDark,
                onTap: () => NavigationHelper.goToCartScreen(context),
                tooltip: 'Shopping Cart',
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.green,
        onRefresh: () => productProvider.loadProducts(),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Slideshow
              SizedBox(
                height: 230,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) =>
                          setState(() => _currentSlide = index),
                      itemCount: _slides.length,
                      itemBuilder: (context, index) {
                        final slide = _slides[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                slide['color'] as Color,
                                (slide['color'] as Color).withAlpha(200),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (slide['color'] as Color).withAlpha(70),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -10,
                                bottom: -10,
                                child: Text(
                                  slide['image'] as String,
                                  style: const TextStyle(
                                      fontSize: 110, color: Colors.white10),
                                ),
                              ),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withAlpha(30),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '✨ KindCart ✨',
                                          style: TextStyle(
                                            color: Colors.white.withAlpha(220),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        slide['title'] as String,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        slide['subtitle'] as String,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white.withAlpha(210),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      GestureDetector(
                                        onTap: () =>
                                            NavigationHelper.goToShopScreen(
                                                context),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 22, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    Colors.black.withAlpha(30),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                slide['buttonText'] as String,
                                                style: TextStyle(
                                                  color:
                                                      slide['color'] as Color,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Icon(
                                                Icons.arrow_forward_rounded,
                                                size: 16,
                                                color: slide['color'] as Color,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    // Slide indicator dots
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _slides.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: _currentSlide == index ? 20 : 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                color: _currentSlide == index
                                    ? Colors.white
                                    : Colors.white.withAlpha(100),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Featured Items
              _SectionHeader(
                title: 'Featured Items',
                actionLabel: 'See All',
                onAction: () => NavigationHelper.goToShopScreen(context),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.62,
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

              //  Free Donations
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

              // Our Impact
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withAlpha(60),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.eco_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Our Impact',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: impactStats.map((stat) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(stat['icon'] as IconData,
                                    color: Colors.white, size: 24),
                                const SizedBox(height: 6),
                                Text(
                                  stat['value'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  stat['label'] as String,
                                  style: const TextStyle(
                                      color: Colors.white60, fontSize: 9),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AboutScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Learn More About Our Mission',
                              style: TextStyle(
                                color: Color(0xFF1B5E20),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded,
                                color: Color(0xFF1B5E20), size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
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
                NavigationHelper.goToSearchScreen(context);
                break;
              case 2:
                NavigationHelper.goToCartScreen(context);
                break;
              case 3:
                NavigationHelper.goToWishlistScreen(context);
                break;
              case 4:
                NavigationHelper.goToProfileScreen(context);
                break;
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          selectedItemColor: Colors.green,
          unselectedItemColor: isDark ? Colors.grey[600] : Colors.grey[400],
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.search_outlined),
                activeIcon: Icon(Icons.search_rounded),
                label: 'Search'),
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
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatScreen()),
        ),
        backgroundColor: const Color(0xFF7B2D8B),
        elevation: 4,
        icon: const Icon(Icons.auto_awesome_rounded,
            color: Colors.white, size: 20),
        label: const Text(
          'AI Help',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  //  Product card
  Widget _buildProductCard(ProductModel product, bool isDark, Color cardColor) {
    return GestureDetector(
      onTap: () {
        print('Product tapped: ${product.title}'); // Debug print
        Navigator.pushNamed(context, '/item-detail', arguments: product);
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
                              : '₹${product.price.toStringAsFixed(0)}',
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
                    Text(
                      product.sellerName,
                      style: TextStyle(
                          fontSize: 9,
                          color: isDark ? Colors.grey[500] : Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildDonationCard(ProductModel item, bool isDark, Color cardColor) {
    final firstImage = item.imageUrls.isNotEmpty ? item.imageUrls.first : null;

    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/item-detail', arguments: item),
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

// Reusable AppBar icon button with Tooltip
class _AppBarIconButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;
  final String tooltip;

  const _AppBarIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isDark,
    required this.tooltip,
  });

  @override
  State<_AppBarIconButton> createState() => _AppBarIconButtonState();
}

class _AppBarIconButtonState extends State<_AppBarIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      preferBelow: false,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      child: MouseRegion(
        onEnter: (_) => _controller.forward(),
        onExit: (_) => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      widget.color.withAlpha(30),
                      widget.color.withAlpha(60),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: IconButton(
                  icon: Icon(widget.icon, color: widget.color, size: 22),
                  onPressed: widget.onTap,
                  splashRadius: 22,
                  splashColor: widget.color.withAlpha(50),
                  highlightColor: widget.color.withAlpha(30),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Reusable badge icon button with Tooltip
class _BadgeIconButton extends StatefulWidget {
  final IconData icon;
  final int badgeCount;
  final Color badgeColor;
  final Color iconColor;
  final bool isDark;
  final VoidCallback onTap;
  final String tooltip;

  const _BadgeIconButton({
    required this.icon,
    required this.badgeCount,
    required this.badgeColor,
    required this.iconColor,
    required this.isDark,
    required this.onTap,
    required this.tooltip,
  });

  @override
  State<_BadgeIconButton> createState() => _BadgeIconButtonState();
}

class _BadgeIconButtonState extends State<_BadgeIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      preferBelow: false,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      child: MouseRegion(
        onEnter: (_) => _controller.forward(),
        onExit: (_) => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          widget.iconColor.withAlpha(30),
                          widget.iconColor.withAlpha(60),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: IconButton(
                      icon:
                          Icon(widget.icon, color: widget.iconColor, size: 22),
                      onPressed: widget.onTap,
                      splashRadius: 22,
                      splashColor: widget.iconColor.withAlpha(50),
                      highlightColor: widget.iconColor.withAlpha(30),
                    ),
                  ),
                  if (widget.badgeCount > 0)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                            color: widget.badgeColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: widget.badgeColor.withAlpha(100),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ]),
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '${widget.badgeCount}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// Reusable section header
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
                    color: (iconColor ?? Colors.green).withAlpha(25),
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
              foregroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              children: [
                Text(actionLabel,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
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
