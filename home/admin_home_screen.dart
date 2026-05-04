import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../providers/auth_provider.dart';
import '../providers/announcement_provider.dart';
import '../providers/donation_provider.dart';
import '../theme_provider.dart';
import '../admin/approval_screen.dart';
import '../admin/user_management_screen.dart';
import '../admin/donation_management_screen.dart';
import '../admin/product_moderation_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/profile_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;
  bool _isLoading = false;
  bool _hasLoadedOnce = false;

  // Dashboard stats
  int _totalUsers = 0;
  int _totalSellers = 0;
  int _totalDonors = 0;
  int _totalProducts = 0;
  int _pendingSellers = 0;
  int _totalDonations = 0;
  int _reportsCount = 0;
  double _totalRevenue = 0.0;

  // Additional metrics
  int _activeProducts = 0;
  int _completedDonations = 0;
  int _newUsersThisWeek = 0;
  double _revenueGrowth = 0.0;
  List<Map<String, dynamic>> _recentActivities = [];
  Map<String, int> _topCategories = {};
  int _activeSellersToday = 0;
  int _activeDonorsToday = 0;
  int _activeBuyersToday = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _debugAdminAccess();
    _debugCheckCollections();
    _loadDashboardStats();
    _loadRecentActivities();
  }

  Future<void> _debugCheckCollections() async {
    try {
      // Check products collection
      final products = await FirebaseFirestore.instance
          .collection('products')
          .limit(1)
          .get();

      if (products.docs.isNotEmpty) {
        print('📦 Products collection exists');
        print('📦 Sample product fields: ${products.docs.first.data().keys}');
        print('📦 Sample product data: ${products.docs.first.data()}');
      } else {
        print('⚠️ No products found in collection');
      }

      // Check donations collection
      final donations = await FirebaseFirestore.instance
          .collection('donations')
          .limit(1)
          .get();

      if (donations.docs.isNotEmpty) {
        print('🎁 Donations collection exists');
        print('🎁 Sample donation fields: ${donations.docs.first.data().keys}');
      } else {
        print('⚠️ No donations found in collection');
      }

      // Check users collection
      final users =
          await FirebaseFirestore.instance.collection('users').limit(1).get();

      if (users.docs.isNotEmpty) {
        print('👥 Users collection exists');
        print('👥 Sample user fields: ${users.docs.first.data().keys}');
      } else {
        print('⚠️ No users found in collection');
      }
    } catch (e) {
      print('❌ Debug error: $e');
    }
  }

  Future<void> _debugAdminAccess() async {
    try {
      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      print('🔍 Current user UID: ${currentUser?.uid}');

      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          print('✅ User document exists in Firestore');
          print('  - Role: ${userData?['role']}');
          print('  - Name: ${userData?['name']}');
          print('  - Is Admin: ${userData?['role'] == 'Admin'}');
        } else {
          print('❌ User document does NOT exist in Firestore!');
        }
      }
    } catch (e) {
      print('❌ Debug error: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentActivities() async {
    try {
      final activities = <Map<String, dynamic>>[];

      // Get recent users
      final recentUsers = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(30)
          .get();

      for (var doc in recentUsers.docs) {
        final userData = doc.data();
        activities.add({
          'type': 'user_registered',
          'title': 'New user registered',
          'subtitle': userData['name'] ?? userData['email'] ?? 'Unknown user',
          'timestamp': userData['createdAt'],
          'icon': Icons.person_add,
          'color': Colors.green,
        });
      }
      // Get recent donations
      final recentDonations = await FirebaseFirestore.instance
          .collection('donations')
          .orderBy('createdAt', descending: true)
          .limit(30)
          .get();

      for (var doc in recentDonations.docs) {
        final donationData = doc.data();
        activities.add({
          'type': 'donation_made',
          'title': 'New donation posted',
          'subtitle': donationData['title'] ??
              donationData['itemName'] ??
              donationData['name'] ??
              'Unknown item',
          'timestamp': donationData['createdAt'],
          'icon': Icons.volunteer_activism,
          'color': Colors.purple,
        });
      }

      // Get recent products
      final recentProducts = await FirebaseFirestore.instance
          .collection('products')
          .orderBy('createdAt', descending: true)
          .limit(30)
          .get();

      print('📦 Found ${recentProducts.docs.length} recent products');

      for (var doc in recentProducts.docs) {
        final productData = doc.data();
        String productName = productData['name'] ??
            productData['title'] ??
            productData['productName'] ??
            productData['itemName'] ??
            'Product';

        String sellerName = productData['sellerName'] ??
            productData['storeName'] ??
            productData['seller'] ??
            productData['vendor'] ??
            productData['addedBy'] ??
            'Someone';

        activities.add({
          'type': 'product_added',
          'title': 'New product added',
          'subtitle': '$productName by $sellerName',
          'timestamp': productData['createdAt'],
          'icon': Icons.inventory_2,
          'color': Colors.blue,
        });
      }

      // Get pending seller approvals
      final pendingSellers = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Seller')
          .where('sellerApprovalRequested', isEqualTo: true)
          .where('sellerApproved', isEqualTo: false)
          .limit(20)
          .get();

      for (var doc in pendingSellers.docs) {
        final sellerData = doc.data();
        activities.add({
          'type': 'seller_pending',
          'title': 'Seller approval pending',
          'subtitle':
              sellerData['name'] ?? sellerData['email'] ?? 'Unknown seller',
          'timestamp': sellerData['sellerApprovalRequestedAt'] ??
              sellerData['createdAt'],
          'icon': Icons.pending_actions,
          'color': Colors.orange,
        });
      }

      // Get recent reports
      final recentReports = await FirebaseFirestore.instance
          .collection('reports')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      for (var doc in recentReports.docs) {
        final reportData = doc.data();
        activities.add({
          'type': 'report_submitted',
          'title': 'New report submitted',
          'subtitle': reportData['reason'] ?? 'Content reported',
          'timestamp': reportData['createdAt'],
          'icon': Icons.flag,
          'color': Colors.red,
        });
      }

      // Sort all activities by timestamp (newest first)
      activities.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.toDate().compareTo(aTime.toDate());
      });

      print('📊 Total activities loaded: ${activities.length}');
      print('📊 Activity types: ${activities.map((a) => a['type']).toSet()}');

      setState(() {
        _recentActivities = activities.take(100).toList();
      });
    } catch (e) {
      debugPrint('Error loading recent activities: $e');
      setState(() {
        _recentActivities = [];
      });
    }
  }

  Future<void> _loadDashboardStats() async {
    setState(() => _isLoading = true);

    try {
      await _loadActiveUsersData();
      // Load donation provider data first
      final donationProvider =
          Provider.of<DonationProvider>(context, listen: false);
      await donationProvider.loadAllDonations();

      // Get completed donations count from the provider
      final completedDonationsCount =
          donationProvider.completedDonations.length;

      // Get reports count - query for pending reports
      final reportsQuery = await FirebaseFirestore.instance
          .collection('reports')
          .where('status', isEqualTo: 'pending')
          .get();

      final pendingReportsCount = reportsQuery.docs.length;

      // Run other Firestore queries in parallel
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('users').get(),
        FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'Seller')
            .get(),
        FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'Donor')
            .get(),
        FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'Seller')
            .where('sellerApprovalRequested', isEqualTo: true)
            .where('sellerApproved', isEqualTo: false)
            .get(),
        FirebaseFirestore.instance.collection('products').get(),
        FirebaseFirestore.instance
            .collection('products')
            .where('isAvailable', isEqualTo: true)
            .get(),
        FirebaseFirestore.instance.collection('donations').get(),
        FirebaseFirestore.instance.collection('reports').get(),
        FirebaseFirestore.instance
            .collection('products')
            .where('isAvailable', isEqualTo: false)
            .get(),
        FirebaseFirestore.instance
            .collection('users')
            .where('createdAt',
                isGreaterThan: Timestamp.fromDate(
                    DateTime.now().subtract(const Duration(days: 7))))
            .get(),
      ]);

      final totalProducts = results[4].docs.length;
      final soldProducts = results[8].docs;

      Map<String, int> categoryCount = {};
      for (var doc in results[4].docs) {
        String category = doc.data()['category'] ?? 'Other';
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }

      var sortedCategories = categoryCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Calculate revenue from sold products
      double revenue = 0;
      for (var doc in results[8].docs) {
        revenue +=
            (doc.data() as Map<String, dynamic>)['price']?.toDouble() ?? 0.0;
      }

      setState(() {
        _totalUsers = results[0].docs.length;
        _totalSellers = results[1].docs.length;
        _totalDonors = results[2].docs.length;
        _pendingSellers = results[3].docs.length;
        _totalProducts = totalProducts;
        _activeProducts = results[5].docs.length;
        _totalDonations = results[6].docs.length;
        _completedDonations = completedDonationsCount;
        _reportsCount = pendingReportsCount;
        _newUsersThisWeek = results[9].docs.length;
        _totalRevenue = revenue;
        _revenueGrowth = 15.5;
        _topCategories = Map.fromEntries(sortedCategories.take(5));
      });
    } catch (e) {
      debugPrint('Error loading dashboard stats: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading stats: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasLoadedOnce = true;
        });
      }
    }
  }

  Future<void> _loadActiveUsersData() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      final todayStartTimestamp = Timestamp.fromDate(todayStart);
      final todayEndTimestamp = Timestamp.fromDate(todayEnd);

      // Query users who logged in today
      final usersQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('lastLogin', isGreaterThanOrEqualTo: todayStartTimestamp)
          .where('lastLogin', isLessThan: todayEndTimestamp)
          .get();

      int sellers = 0;
      int donors = 0;
      int buyers = 0;

      for (var doc in usersQuery.docs) {
        final role = doc.data()['role'] as String?;
        switch (role) {
          case 'Seller':
            sellers++;
            break;
          case 'Donor':
            donors++;
            break;
          case 'Buyer':
            buyers++;
            break;
        }
      }

      setState(() {
        _activeSellersToday = sellers;
        _activeDonorsToday = donors;
        _activeBuyersToday = buyers;
      });
    } catch (e) {
      debugPrint('Error loading active users: $e');
      setState(() {
        _activeSellersToday = 0;
        _activeDonorsToday = 0;
        _activeBuyersToday = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWebLayout = screenWidth > 800;

    if (authProvider.userRole != 'Admin') {
      return _buildAccessDeniedScreen();
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          themeProvider.isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: _buildAppBar(authProvider, themeProvider, isWebLayout),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isWebLayout
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDashboardTab(),
                    const UserManagementScreen(),
                    const ProductModerationScreen(),
                    const DonationManagementScreen(),
                  ],
                )
              : IndexedStack(
                  index: _selectedIndex,
                  children: [
                    _buildDashboardTab(),
                    const UserManagementScreen(),
                    const ProductModerationScreen(),
                    const DonationManagementScreen(),
                  ],
                ),
      drawer: _buildDrawer(),
      bottomNavigationBar: !isWebLayout
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                  if (index == 0) {
                    _loadIfStale();
                  }
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.deepPurple,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white70,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),
              showUnselectedLabels: true,
              elevation: 8,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard, color: Colors.white),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people, color: Colors.white),
                  label: 'Users',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory, color: Colors.white),
                  label: 'Products',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.volunteer_activism, color: Colors.white),
                  label: 'Donations',
                ),
              ],
            )
          : null,
      floatingActionButton: !isWebLayout
          ? FloatingActionButton(
              onPressed: () => _showQuickActions(context),
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.add_task, color: Colors.white),
            )
          : FloatingActionButton.extended(
              onPressed: () => _showQuickActions(context),
              backgroundColor: Colors.deepPurple,
              icon: const Icon(Icons.add_task, color: Colors.white),
              label: const Text('Quick Actions',
                  style: TextStyle(color: Colors.white)),
            ),
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _buildAccessDeniedScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'Access Denied',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'You need admin privileges to access this page.',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(AuthProvider authProvider, ThemeProvider themeProvider,
      bool isWebLayout) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Dashboard',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            'Welcome back, ${authProvider.userData?['name'] ?? 'Admin'}',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      actions: [
        Tooltip(
          message: 'View Profile',
          child: IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ),
        Tooltip(
          message: themeProvider.isDarkMode
              ? 'Switch to Light Mode'
              : 'Switch to Dark Mode',
          child: IconButton(
            icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: Colors.white),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ),
        Tooltip(
          message: 'Refresh Data',
          child: IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _loadDashboardStats();
              _loadRecentActivities();
            },
          ),
        ),
      ],
      bottom: isWebLayout
          ? TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
              isScrollable: true,
              tabs: const [
                Tab(
                    text: 'Dashboard',
                    icon: Icon(Icons.dashboard, color: Colors.white)),
                Tab(
                    text: 'Users',
                    icon: Icon(Icons.people, color: Colors.white)),
                Tab(
                    text: 'Products',
                    icon: Icon(Icons.inventory, color: Colors.white)),
                Tab(
                    text: 'Donations',
                    icon: Icon(Icons.volunteer_activism, color: Colors.white)),
              ],
            )
          : null,
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(),
          _buildDrawerItem(Icons.dashboard, 'Dashboard', () {
            Navigator.pop(context);
            final screenWidth = MediaQuery.of(context).size.width;
            if (screenWidth > 800) {
              _tabController.animateTo(0);
            } else {
              setState(() => _selectedIndex = 0);
            }
          }),
          _buildDrawerItem(Icons.people, 'User Management', () {
            Navigator.pop(context);
            final screenWidth = MediaQuery.of(context).size.width;
            if (screenWidth > 800) {
              _tabController.animateTo(1);
            } else {
              setState(() => _selectedIndex = 1);
            }
          }),
          _buildDrawerItem(Icons.inventory, 'Product Moderation', () {
            Navigator.pop(context);
            final screenWidth = MediaQuery.of(context).size.width;
            if (screenWidth > 800) {
              _tabController.animateTo(2);
            } else {
              setState(() => _selectedIndex = 2);
            }
          }),
          _buildDrawerItem(Icons.volunteer_activism, 'Donation Management', () {
            Navigator.pop(context);
            final screenWidth = MediaQuery.of(context).size.width;
            if (screenWidth > 800) {
              _tabController.animateTo(3);
            } else {
              setState(() => _selectedIndex = 3);
            }
          }),
          const Divider(),
          _buildDrawerItem(
            Icons.pending_actions,
            'Seller Approvals',
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SellerApprovalScreen()),
              ).then((_) => _loadIfStale());
            },
            subtitle: _pendingSellers > 0 ? '$_pendingSellers pending' : null,
            badge: _pendingSellers > 0,
          ),
          _buildDrawerItem(
            Icons.flag,
            'Reports',
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportsScreen()),
              ).then((_) => _loadIfStale());
            },
            subtitle: _reportsCount > 0 ? '$_reportsCount pending' : null,
            badge: _reportsCount > 0,
          ),
          _buildDrawerItem(
            Icons.notifications_active,
            'Send Announcements',
            () {
              Navigator.pop(context);
              _showAnnouncementDialog();
            },
          ),
          const Divider(),
          _buildDrawerItem(
            Icons.person,
            'Profile',
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          _buildDrawerItem(
            Icons.logout,
            'Logout',
            () {
              Navigator.pop(context);
              _showLogoutDialog();
            },
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.admin_panel_settings,
                size: 30, color: Colors.deepPurple),
          ),
          const SizedBox(height: 10),
          const Text(
            'Admin Panel',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            'Manage your platform',
            style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap,
      {String? subtitle, bool badge = false, Color color = Colors.deepPurple}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: badge
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            )
          : null,
      onTap: onTap,
    );
  }

  // DASHBOARD TAB
  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadDashboardStats();
        await _loadRecentActivities();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeBanner(),
            const SizedBox(height: 20),
            _buildClickableMetricsGrid(),
            const SizedBox(height: 24),
            if (_pendingSellers > 0 || _reportsCount > 0)
              _buildPriorityActions(),
            if (_pendingSellers > 0 || _reportsCount > 0)
              const SizedBox(height: 24),
            _buildFinancialOverview(),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildTopCategories(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: _buildPlatformInsights(),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildTopCategories(),
                      const SizedBox(height: 24),
                      _buildPlatformInsights(),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 24),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  //  METRICS GRID
  Widget _buildClickableMetricsGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 800 ? 6 : 3;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: [
        _buildClickableMetricCard(
          icon: Icons.people,
          value: '$_totalUsers',
          label: 'Total Users',
          color: Colors.blue,
          subtitle: '+$_newUsersThisWeek new',
          onTap: () => _navigateToUsersTab(filter: null),
        ),
        _buildClickableMetricCard(
          icon: Icons.store,
          value: '$_totalSellers',
          label: 'Sellers',
          color: Colors.orange,
          subtitle:
              '${_totalSellers > 0 ? (_totalSellers / _totalUsers * 100).toStringAsFixed(0) : 0}% of users',
          onTap: () => _navigateToUsersTab(filter: 'Seller'),
        ),
        _buildClickableMetricCard(
          icon: Icons.volunteer_activism,
          value: '$_totalDonors',
          label: 'Donors',
          color: Colors.purple,
          subtitle:
              '${_totalDonors > 0 ? (_totalDonors / _totalUsers * 100).toStringAsFixed(0) : 0}% of users',
          onTap: () => _navigateToUsersTab(filter: 'Donor'),
        ),
        _buildClickableMetricCard(
          icon: Icons.inventory,
          value: '$_totalProducts',
          label: 'Total Products',
          color: Colors.green,
          subtitle: '$_activeProducts active',
          onTap: () => _navigateToTab(2),
        ),
        _buildClickableMetricCard(
          icon: Icons.pending_actions,
          value: '$_pendingSellers',
          label: 'Pending Approvals',
          color: Colors.red,
          subtitle: 'Seller requests',
          onTap: () => _navigateToSellerApprovals(),
        ),
        _buildClickableMetricCard(
          icon: Icons.flag,
          value: '$_reportsCount',
          label: 'Pending Reports',
          color: Colors.orange,
          subtitle: 'Need attention',
          onTap: () => _navigateToReports(),
        ),
      ],
    );
  }

  Widget _buildClickableMetricCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialOverview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withAlpha(30),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.shopping_basket,
                        color: Colors.white70, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      'NPR ${_totalRevenue.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Total Revenue',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withAlpha(50),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.white70, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      '$_completedDonations',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Completed Donations',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.priority_high,
                    color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Priority Actions Required',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_pendingSellers > 0)
            _buildActionItem(
              icon: Icons.person_add,
              title: 'Seller Approvals',
              subtitle:
                  '$_pendingSellers seller${_pendingSellers > 1 ? 's' : ''} waiting for approval',
              buttonText: 'Review',
              color: Colors.orange,
              onTap: () => _navigateToSellerApprovals(),
            ),
          if (_reportsCount > 0 && _pendingSellers > 0)
            const SizedBox(height: 12),
          if (_reportsCount > 0)
            _buildActionItem(
              icon: Icons.flag,
              title: 'Content Reports',
              subtitle:
                  '$_reportsCount report${_reportsCount > 1 ? 's' : ''} pending review',
              buttonText: 'Review',
              color: Colors.red,
              onTap: () => _navigateToReports(),
            ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(80, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(buttonText, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategories() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Categories',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (_topCategories.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('No data available')),
            )
          else
            ..._topCategories.entries.map((entry) {
              final total = _topCategories.values.reduce((a, b) => a + b);
              final percentage = (entry.value / total * 100).toStringAsFixed(1);
              return GestureDetector(
                onTap: () => _navigateToTab(2),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(fontSize: 13),
                          ),
                          Text(
                            '${entry.value} items ($percentage%)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: entry.value / total,
                        backgroundColor: Colors.grey[200],
                        color: Colors.deepPurple,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPlatformInsights() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Platform Insights',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _navigateToTab(2),
            child: _buildInsightItem(
              icon: Icons.rocket_launch,
              label: 'Conversion Rate',
              value:
                  '${_totalProducts > 0 ? ((_activeProducts / _totalProducts) * 100).toStringAsFixed(1) : 0}%',
              subtitle: 'Products active',
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _navigateToTab(3),
            child: _buildInsightItem(
              icon: Icons.volunteer_activism,
              label: 'Donation Success',
              value:
                  '${_totalDonations > 0 ? (_completedDonations / _totalDonations * 100).toStringAsFixed(1) : 0}%',
              subtitle: 'Completed donations',
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _navigateToUsersTab(filter: null),
            child: _buildInsightItem(
              icon: Icons.people,
              label: 'User Engagement',
              value:
                  '${((_totalSellers + _totalDonors) / (_totalUsers > 0 ? _totalUsers : 1) * 100).toStringAsFixed(1)}%',
              subtitle: 'Active contributors',
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Row(
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // RECENT ACTIVITY
  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, size: 20, color: Colors.deepPurple),
              const SizedBox(width: 8),
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_recentActivities.length} total',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_recentActivities.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No recent activity',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount:
                  _recentActivities.length > 10 ? 10 : _recentActivities.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final activity = _recentActivities[index];
                return GestureDetector(
                  onTap: () {
                    // Navigate based on activity type
                    switch (activity['type']) {
                      case 'product_added':
                        _navigateToTab(2);
                        break;
                      case 'donation_made':
                        _navigateToTab(3);
                        break;
                      case 'seller_pending':
                        _navigateToSellerApprovals();
                        break;
                      case 'report_submitted':
                        _navigateToReports();
                        break;
                      case 'user_registered':
                        _navigateToUsersTab(filter: null);
                        break;
                      default:
                        break;
                    }
                  },
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (activity['color'] as Color).withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        activity['icon'] as IconData,
                        color: activity['color'] as Color,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      activity['title'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      activity['subtitle'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      _formatTimestamp(activity['timestamp']),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              _showAllActivitiesDialog();
            },
            icon: const Icon(Icons.list_alt, size: 16),
            label: Text('View All ${_recentActivities.length} Activities'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.people_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Logged In Today',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _formatDateToday(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$_activeSellersToday',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.store, size: 14, color: Colors.white70),
                        SizedBox(width: 4),
                        Text(
                          'Sellers',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withAlpha(50),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$_activeDonorsToday',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.volunteer_activism,
                            size: 14, color: Colors.white70),
                        SizedBox(width: 4),
                        Text(
                          'Donors',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withAlpha(50),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$_activeBuyersToday',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart,
                            size: 14, color: Colors.white70),
                        SizedBox(width: 4),
                        Text(
                          'Buyers',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Navigation Helper Methods
  void _navigateToTab(int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 800) {
      _tabController.animateTo(index);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  String _formatDateToday() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  void _navigateToUsersTab({String? filter}) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > 800) {
      _tabController.animateTo(1);
    } else {
      setState(() {
        _selectedIndex = 1;
      });
    }

    if (filter != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Showing ${filter.toLowerCase()}s'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.deepPurple,
        ),
      );
    }
  }

  Future<void> _loadIfStale() async {
    if (!_hasLoadedOnce) {
      await _loadDashboardStats();
      await _loadRecentActivities();
    }
  }

  void _navigateToSellerApprovals() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SellerApprovalScreen()),
    ).then((_) => _loadIfStale());
  }

  void _navigateToReports() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReportsScreen()),
    ).then((_) => _loadIfStale());
  }

  void _showAllActivitiesDialog() {
    if (Theme.of(context).platform == TargetPlatform.android) {
      // Android
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _AllActivitiesFullScreen(
            recentActivities: _recentActivities,
          ),
        ),
      );
    } else {
      // Web
      _showAllActivitiesDialogWeb(context);
    }
  }

// Dialog version for web
  void _showAllActivitiesDialogWeb(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 700),
          child: _AllActivitiesContent(
            recentActivities: _recentActivities,
          ),
        ),
      ),
    );
  }

  String _getActivityTypeLabel(String type) {
    switch (type) {
      case 'user_registered':
        return 'User';
      case 'donation_made':
        return 'Donation';
      case 'product_added':
        return 'Product';
      case 'seller_pending':
        return 'Approval';
      case 'report_submitted':
        return 'Report';
      default:
        return 'Activity';
    }
  }

  void _showQuickActions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWebLayout = screenWidth > 800;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildQuickActionTile(
                        icon: Icons.person_add,
                        color: Colors.orange,
                        title: 'Review Seller Approvals',
                        subtitle: '$_pendingSellers pending',
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToSellerApprovals();
                        },
                      ),
                      _buildQuickActionTile(
                        icon: Icons.flag,
                        color: Colors.red,
                        title: 'Review Reports',
                        subtitle: '$_reportsCount pending',
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToReports();
                        },
                      ),
                      _buildQuickActionTile(
                        icon: Icons.notifications_active,
                        color: Colors.blue,
                        title: 'Send Announcement',
                        subtitle: 'Notify all users',
                        onTap: () {
                          Navigator.pop(context);
                          _showAnnouncementDialog();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  void _showAnnouncementDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    List<String> selectedRoles = ['all'];
    bool isSending = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Send Announcement'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., New Feature Update',
                      ),
                      enabled: !isSending,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        border: OutlineInputBorder(),
                        hintText: 'Enter your announcement here...',
                      ),
                      maxLines: 3,
                      enabled: !isSending,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Send to:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('All Users'),
                          selected: selectedRoles.contains('all'),
                          onSelected: isSending
                              ? null
                              : (selected) {
                                  setDialogState(() {
                                    if (selected) {
                                      selectedRoles = ['all'];
                                    } else {
                                      selectedRoles.remove('all');
                                      if (selectedRoles.isEmpty) {
                                        selectedRoles = ['all'];
                                      }
                                    }
                                  });
                                },
                        ),
                        FilterChip(
                          label: const Text('Buyers'),
                          selected: selectedRoles.contains('buyer'),
                          onSelected: isSending
                              ? null
                              : (selected) {
                                  setDialogState(() {
                                    if (selected) {
                                      selectedRoles.remove('all');
                                      selectedRoles.add('buyer');
                                    } else {
                                      selectedRoles.remove('buyer');
                                      if (selectedRoles.isEmpty) {
                                        selectedRoles = ['all'];
                                      }
                                    }
                                  });
                                },
                        ),
                        FilterChip(
                          label: const Text('Sellers'),
                          selected: selectedRoles.contains('seller'),
                          onSelected: isSending
                              ? null
                              : (selected) {
                                  setDialogState(() {
                                    if (selected) {
                                      selectedRoles.remove('all');
                                      selectedRoles.add('seller');
                                    } else {
                                      selectedRoles.remove('seller');
                                      if (selectedRoles.isEmpty) {
                                        selectedRoles = ['all'];
                                      }
                                    }
                                  });
                                },
                        ),
                        FilterChip(
                          label: const Text('Donors'),
                          selected: selectedRoles.contains('donor'),
                          onSelected: isSending
                              ? null
                              : (selected) {
                                  setDialogState(() {
                                    if (selected) {
                                      selectedRoles.remove('all');
                                      selectedRoles.add('donor');
                                    } else {
                                      selectedRoles.remove('donor');
                                      if (selectedRoles.isEmpty) {
                                        selectedRoles = ['all'];
                                      }
                                    }
                                  });
                                },
                        ),
                        FilterChip(
                          label: const Text('Admins'),
                          selected: selectedRoles.contains('admin'),
                          onSelected: isSending
                              ? null
                              : (selected) {
                                  setDialogState(() {
                                    if (selected) {
                                      selectedRoles.remove('all');
                                      selectedRoles.add('admin');
                                    } else {
                                      selectedRoles.remove('admin');
                                      if (selectedRoles.isEmpty) {
                                        selectedRoles = ['all'];
                                      }
                                    }
                                  });
                                },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSending ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          if (titleController.text.isNotEmpty &&
                              messageController.text.isNotEmpty) {
                            setDialogState(() => isSending = true);

                            final authProvider = Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            );

                            final announcementProvider =
                                Provider.of<AnnouncementProvider>(
                              context,
                              listen: false,
                            );

                            final success =
                                await announcementProvider.sendAnnouncement(
                              title: titleController.text,
                              message: messageController.text,
                              targetRoles: selectedRoles,
                              adminId: authProvider.user!.uid,
                              adminName:
                                  authProvider.userData?['name'] ?? 'Admin',
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Announcement sent successfully!'
                                        : 'Failed to send announcement',
                                  ),
                                  backgroundColor:
                                      success ? Colors.green : Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: isSending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Provider.of<AuthProvider>(context, listen: false).signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/auth');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} min ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    }
    return 'Unknown';
  }
}

// Full Screen Activities for Android
class _AllActivitiesFullScreen extends StatelessWidget {
  final List<Map<String, dynamic>> recentActivities;

  const _AllActivitiesFullScreen({required this.recentActivities});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Recent Activity',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${recentActivities.length} total',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: _AllActivitiesContent(
        recentActivities: recentActivities,
        isFullScreen: true,
      ),
    );
  }
}

// Shared content widget for both full screen and dialog
class _AllActivitiesContent extends StatelessWidget {
  final List<Map<String, dynamic>> recentActivities;
  final bool isFullScreen;

  const _AllActivitiesContent({
    required this.recentActivities,
    this.isFullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        if (!isFullScreen) ...[
          Row(
            children: [
              const Expanded(
                child: Text(
                  'All Recent Activity',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${recentActivities.length} total',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Showing latest ${recentActivities.length} activities',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: recentActivities.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No activities found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.all(isFullScreen ? 16 : 0),
                  itemCount: recentActivities.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final activity = recentActivities[index];
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (activity['color'] as Color).withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          activity['icon'] as IconData,
                          color: activity['color'] as Color,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        activity['title'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        activity['subtitle'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatTimestamp(activity['timestamp']),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: (activity['color'] as Color).withAlpha(30),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getActivityTypeLabel(activity['type'] as String),
                              style: TextStyle(
                                fontSize: 8,
                                color: activity['color'] as Color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        // Navigate based on activity type
                        switch (activity['type']) {
                          case 'product_added':
                            _navigateToTab(context, 2);
                            break;
                          case 'donation_made':
                            _navigateToTab(context, 3);
                            break;
                          case 'seller_pending':
                            _navigateToSellerApprovals(context);
                            break;
                          case 'report_submitted':
                            _navigateToReports(context);
                            break;
                          case 'user_registered':
                            _navigateToUsersTab(context, null);
                            break;
                          default:
                            break;
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _getActivityTypeLabel(String type) {
    switch (type) {
      case 'user_registered':
        return 'User';
      case 'donation_made':
        return 'Donation';
      case 'product_added':
        return 'Product';
      case 'seller_pending':
        return 'Approval';
      case 'report_submitted':
        return 'Report';
      default:
        return 'Activity';
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} min ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    }
    return 'Unknown';
  }

  void _navigateToTab(BuildContext context, int index) {
    Navigator.pop(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final adminHomeState =
        context.findAncestorStateOfType<_AdminHomeScreenState>();
    if (adminHomeState != null) {
      if (screenWidth > 800) {
        adminHomeState._tabController.animateTo(index);
      } else {
        adminHomeState.setState(() {
          adminHomeState._selectedIndex = index;
        });
      }
    }
  }

  void _navigateToSellerApprovals(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SellerApprovalScreen()),
    );
  }

  void _navigateToReports(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReportsScreen()),
    );
  }

  void _navigateToUsersTab(BuildContext context, String? filter) {
    Navigator.pop(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final adminHomeState =
        context.findAncestorStateOfType<_AdminHomeScreenState>();
    if (adminHomeState != null) {
      if (screenWidth > 800) {
        adminHomeState._tabController.animateTo(1);
      } else {
        adminHomeState.setState(() {
          adminHomeState._selectedIndex = 1;
        });
      }
    }
  }
}
