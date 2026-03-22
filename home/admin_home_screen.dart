import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../providers/auth_provider.dart';
import '../providers/announcement_provider.dart';
import '../theme_provider.dart';
import '../admin/approval_screen.dart';
import '../admin/user_management_screen.dart';
import '../admin/donation_management_screen.dart';
import '../admin/product_moderation_screen.dart';
import '../screens/profile_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Dashboard stats
  int _totalUsers = 0;
  int _totalSellers = 0;
  int _totalDonors = 0;
  int _totalProducts = 0;
  int _pendingSellers = 0;
  int _totalDonations = 0;
  int _reportsCount = 0;
  double _totalRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _debugAdminAccess();
    _loadDashboardStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Debug method to check admin access
  Future<void> _debugAdminAccess() async {
    try {
      // Use the aliased FirebaseAuth
      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      print('🔍 Current user UID: ${currentUser?.uid}');

      if (currentUser != null) {
        // Check if user exists in Firestore
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
          print('  Please create a document with id: ${currentUser.uid}');
        }
      }

      // Try to read categories
      final categoriesSnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .limit(1)
          .get();
      print('✅ Categories read: ${categoriesSnapshot.docs.length} found');

      // Try to read users
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').limit(1).get();
      print('✅ Users read: ${usersSnapshot.docs.length} found');
    } catch (e) {
      print('❌ Debug error: $e');
    }
  }

  Future<void> _loadDashboardStats() async {
    setState(() => _isLoading = true);

    try {
      // Run all Firestore queries in parallel for better performance
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
        FirebaseFirestore.instance.collection('donations').get(),
        FirebaseFirestore.instance.collection('reports').get(),
        FirebaseFirestore.instance
            .collection('products')
            .where('isAvailable', isEqualTo: false)
            .get(),
      ]);

      setState(() {
        _totalUsers = results[0].docs.length;
        _totalSellers = results[1].docs.length;
        _totalDonors = results[2].docs.length;
        _pendingSellers = results[3].docs.length;
        _totalProducts = results[4].docs.length;
        _totalDonations = results[5].docs.length;
        _reportsCount = results[6].docs.length;

        // Calculate revenue
        _totalRevenue = 0;
        for (var doc in results[7].docs) {
          _totalRevenue +=
              (doc.data() as Map<String, dynamic>)['price']?.toDouble() ?? 0.0;
        }
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Verify admin access
    if (authProvider.userRole != 'Admin') {
      return _buildAccessDeniedScreen();
    }

    return Scaffold(
      backgroundColor:
          themeProvider.isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: _buildAppBar(authProvider, themeProvider),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                const UserManagementScreen(),
                const ProductModerationScreen(),
                const DonationManagementScreen(),
              ],
            ),
      drawer: _buildAdminDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuickActions(context),
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add_task, color: Colors.white),
        label:
            const Text('Quick Actions', style: TextStyle(color: Colors.white)),
      ),
    );
  }

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

  AppBar _buildAppBar(AuthProvider authProvider, ThemeProvider themeProvider) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Dashboard',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
      actions: [
        IconButton(
          icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
          onPressed: () => themeProvider.toggleTheme(),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadDashboardStats,
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Dashboard', icon: Icon(Icons.dashboard)),
          Tab(text: 'Users', icon: Icon(Icons.people)),
          Tab(text: 'Products', icon: Icon(Icons.inventory)),
          Tab(text: 'Donations', icon: Icon(Icons.volunteer_activism)),
        ],
      ),
    );
  }

  // DASHBOARD TAB
  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboardStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeBanner(),
            const SizedBox(height: 20),
            const Text('Key Metrics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildStatsGrid(),
            const SizedBox(height: 20),
            if (_pendingSellers > 0) _buildPendingActions(),
            const SizedBox(height: 20),
          ],
        ),
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
          const Text(
            'Platform Overview',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            _totalUsers.toString(),
            style: const TextStyle(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Total Users',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          icon: Icons.people,
          value: '$_totalUsers',
          label: 'Total Users',
          color: Colors.blue,
          onTap: () => _tabController.animateTo(1),
        ),
        _buildMetricCard(
          icon: Icons.store,
          value: '$_totalSellers',
          label: 'Sellers',
          color: Colors.orange,
          onTap: () => _tabController.animateTo(1),
        ),
        _buildMetricCard(
          icon: Icons.volunteer_activism,
          value: '$_totalDonors',
          label: 'Donors',
          color: Colors.purple,
          onTap: () => _tabController.animateTo(1),
        ),
        _buildMetricCard(
          icon: Icons.inventory,
          value: '$_totalProducts',
          label: 'Products',
          color: Colors.green,
          onTap: () => _tabController.animateTo(2),
        ),
        _buildMetricCard(
          icon: Icons.card_giftcard,
          value: '$_totalDonations',
          label: 'Donations',
          color: Colors.teal,
          onTap: () => _tabController.animateTo(3),
        ),
        _buildMetricCard(
          icon: Icons.pending_actions,
          value: '$_pendingSellers',
          label: 'Pending Sellers',
          color: Colors.orange,
          badge: _pendingSellers > 0,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const SellerApprovalScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    bool badge = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            if (badge)
              const Positioned(
                top: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 4,
                  backgroundColor: Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pending Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_pendingSellers > 0)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_add, color: Colors.orange),
                ),
                title: Text('$_pendingSellers seller approval requests'),
                subtitle: const Text('Review and approve new sellers'),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SellerApprovalScreen()),
                    );
                  },
                  child: const Text('Review'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Admin Drawer
  Drawer _buildAdminDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(),
          _buildDrawerItem(Icons.dashboard, 'Dashboard', () {
            Navigator.pop(context);
            _tabController.animateTo(0);
          }),
          _buildDrawerItem(Icons.people, 'User Management', () {
            Navigator.pop(context);
            _tabController.animateTo(1);
          }),
          _buildDrawerItem(Icons.inventory, 'Product Moderation', () {
            Navigator.pop(context);
            _tabController.animateTo(2);
          }),
          _buildDrawerItem(Icons.volunteer_activism, 'Donation Management', () {
            Navigator.pop(context);
            _tabController.animateTo(3);
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
              );
            },
            subtitle: _pendingSellers > 0 ? '$_pendingSellers pending' : null,
            badge: _pendingSellers > 0,
          ),
          _buildDrawerItem(
            Icons.category,
            'Categories',
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ProductModerationScreen()),
              );
            },
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

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const SellerApprovalScreen()),
                          );
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

  //  Functional announcement dialog with role selection
  void _showAnnouncementDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    List<String> selectedRoles = ['all']; // Default to all users
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
                    // Role selection chips
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

  // Helper Methods
  Color _getActivityColor(String? type) {
    switch (type) {
      case 'user_registered':
        return Colors.green;
      case 'seller_approved':
        return Colors.orange;
      case 'product_added':
        return Colors.blue;
      case 'donation_made':
        return Colors.purple;
      case 'report_filed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String? type) {
    switch (type) {
      case 'user_registered':
        return Icons.person_add;
      case 'seller_approved':
        return Icons.check_circle;
      case 'product_added':
        return Icons.inventory;
      case 'donation_made':
        return Icons.volunteer_activism;
      case 'report_filed':
        return Icons.flag;
      default:
        return Icons.info;
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
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    }
    return 'Unknown';
  }
}
