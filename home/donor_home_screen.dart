import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/donation_provider.dart';
import '../theme_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import '../models/donation_model.dart';
import '../screens/adddonation_screen.dart';
import '../screens/donate_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/about_screen.dart';

class DonorHomeScreen extends StatefulWidget {
  const DonorHomeScreen({Key? key}) : super(key: key);

  @override
  State<DonorHomeScreen> createState() => _DonorHomeScreenState();
}

class _DonorHomeScreenState extends State<DonorHomeScreen> {
  // Animation controllers for stats cards
  final Map<String, GlobalKey> _statCardKeys = {
    'total': GlobalKey(),
    'completed': GlobalKey(),
    'pending': GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    _loadDonorData();
  }

  Future<void> _loadDonorData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final donationProvider =
          Provider.of<DonationProvider>(context, listen: false);

      if (authProvider.isAuthenticated) {
        await donationProvider.loadUserDonations(authProvider.user!.uid);
        await donationProvider.loadCompletedDonations();
      }
    } catch (e) {
      debugPrint('Error loading donor data: $e');
    }
  }

  bool _shouldUseFullScreenDialog(BuildContext context) {
    final isAndroid = !kIsWeb && Platform.isAndroid;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return isAndroid || isSmallScreen;
  }

  // Reusable adaptive dialog method
  void _showAdaptiveDialog({
    required BuildContext context,
    required String title,
    required WidgetBuilder builder,
  }) {
    final useFullScreen = _shouldUseFullScreenDialog(context);
    final theme = Theme.of(context);

    if (useFullScreen) {
      // For Android
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              title: Text(title),
              centerTitle: true,
              backgroundColor: theme.colorScheme.surface,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            body: builder(ctx),
          ),
        ),
      );
    } else {
      // For Web
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: theme.dialogBackgroundColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(child: builder(ctx)),
              ],
            ),
          ),
        ),
      );
    }
  }

  // Function to show full-screen image
  void _showFullImage(BuildContext context, String imageUrl) {
    final useFullScreen = _shouldUseFullScreenDialog(context);

    if (useFullScreen) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            body: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.white, size: 50),
                        SizedBox(height: 16),
                        Text('Failed to load image',
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(0),
          child: Stack(
            children: [
              InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.white, size: 50),
                        SizedBox(height: 16),
                        Text('Failed to load image',
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(153),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // Image gallery widget for multiple donor images
  Widget _buildImageGallery(List<String> imageUrls, BuildContext context) {
    final theme = Theme.of(context);
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 60,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        itemBuilder: (ctx, index) {
          return GestureDetector(
            onTap: () => _showFullImage(context, imageUrls[index]),
            child: Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.primary),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.broken_image,
                        size: 20, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final donationProvider = Provider.of<DonationProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 800;
    final isDark = themeProvider.isDarkMode;
    final isMobileLayout = screenWidth < 600;
    final isTabletLayout = screenWidth >= 600 && screenWidth < 900;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await donationProvider.loadUserDonations(authProvider.user!.uid);
          await donationProvider.loadCompletedDonations();
        },
        color: theme.colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with donor info
              _buildHeader(authProvider, themeProvider, isWebLayout),

              // Stats cards
              _buildStatsCards(donationProvider),

              const SizedBox(height: 24),

              // Quick actions
              _buildQuickActions(context),

              const SizedBox(height: 24),

              // Recent donations by donor
              _buildRecentDonations(context, donationProvider),

              const SizedBox(height: 24),

              // Impact stories (recent completed donations)
              _buildImpactStories(context, donationProvider),

              const SizedBox(height: 30),

              // Footer
              if (isWebLayout)
                _buildCompactFooter(context, isMobileLayout, isTabletLayout),
            ],
          ),
        ),
      ),
      // Bottom Navigation Bar for Android
      bottomNavigationBar: !isWebLayout
          ? Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withAlpha(51),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: BottomAppBar(
                color: theme.cardColor,
                elevation: 0,
                shape: const CircularNotchedRectangle(),
                notchMargin: 6.0,
                padding: EdgeInsets.zero,
                child: SizedBox(
                  height: 56,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Home Button
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('You are already on Home'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.home_outlined,
                                color: const Color(0xFFE91E63),
                                size: 22,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Home',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: const Color(0xFFE91E63),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Donation Button
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AddDonationScreen()),
                            );
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF2E7D32),
                                      Color(0xFF4CAF50)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          const Color(0xFF4CAF50).withAlpha(77),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Donate',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Profile Button
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ProfileScreen()),
                            );
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_outline,
                                color: theme.colorScheme.onSurfaceVariant,
                                size: 22,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Profile',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(
      AuthProvider auth, ThemeProvider themeProvider, bool isWebLayout) {
    final userName =
        auth.userData?['name'] ?? auth.user?.displayName ?? 'Donor';
    final isDark = themeProvider.isDarkMode;
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, isAndroid ? 8 : 12, 20, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E7D32),
            Color(0xFF4CAF50),
            Color(0xFFE91E63),
            Color(0xFFF06292),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withAlpha(51),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: isSmallScreen ? 28 : 32,
                    backgroundColor: Colors.white.withAlpha(51),
                    backgroundImage: auth.user?.photoURL != null
                        ? NetworkImage(auth.user!.photoURL!)
                        : null,
                    child: auth.user?.photoURL == null
                        ? Text(
                            userName[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 24 : 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                // Name + welcome
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                      ),
                      Text(
                        userName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 18 : 22,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // DONOR badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 12,
                    vertical: isSmallScreen ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(26),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withAlpha(51),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.volunteer_activism,
                        color: Colors.white,
                        size: isSmallScreen ? 14 : 16,
                      ),
                      SizedBox(width: isSmallScreen ? 4 : 6),
                      Text(
                        'DONOR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 10 : 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // action buttons on Web
                if (!isAndroid) ...[
                  const SizedBox(width: 12),
                  // Dark Mode Toggle
                  Tooltip(
                    message:
                        isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: IconButton(
                        icon: Icon(
                          isDark ? Icons.light_mode : Icons.dark_mode,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          themeProvider.toggleTheme();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isDark
                                  ? 'Light Mode Activated'
                                  : 'Dark Mode Activated'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ),
                  // Profile Button
                  Tooltip(
                    message: 'View Profile',
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.person_outline,
                            color: Colors.white, size: 20),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ProfileScreen()),
                          );
                        },
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ),
                  // Add Donation Button
                  Tooltip(
                    message: 'Add New Donation',
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add_circle,
                            color: Colors.white, size: 22),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AddDonationScreen()),
                          );
                        },
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            // Motto line
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Your kindness changes lives',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Stats cards
  Widget _buildStatsCards(DonationProvider donationProvider) {
    final theme = Theme.of(context);
    final userDonations = donationProvider.userDonations;

    final totalDonated = userDonations.length;
    final pendingCount =
        userDonations.where((d) => d.status == DonationStatus.pending).length;
    final completedCount =
        userDonations.where((d) => d.status == DonationStatus.completed).length;
    final approvedCount =
        userDonations.where((d) => d.status == DonationStatus.approved).length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.analytics,
                    color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Your Impact Dashboard',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  key: _statCardKeys['total']!,
                  value: '$totalDonated',
                  label: 'Total Donations',
                  icon: Icons.favorite,
                  color: theme.colorScheme.primary,
                  onTap: () =>
                      _showDonationsByStatus(context, userDonations, 'all'),
                  description: 'All donations you\'ve made',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  key: _statCardKeys['completed']!,
                  value: '$completedCount',
                  label: 'Completed',
                  icon: Icons.check_circle,
                  color: Colors.green,
                  onTap: () => _showDonationsByStatus(
                      context, userDonations, 'completed'),
                  description: 'Successfully delivered donations',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  key: _statCardKeys['pending']!,
                  value: '$pendingCount',
                  label: 'Pending',
                  icon: Icons.hourglass_empty,
                  color: Colors.orange,
                  onTap: () =>
                      _showDonationsByStatus(context, userDonations, 'pending'),
                  description: 'Awaiting approval',
                ),
              ),
            ],
          ),
          if (approvedCount > 0) ...[
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.info_outline,
                        color: theme.colorScheme.onPrimary, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$approvedCount donation${approvedCount > 1 ? 's are' : ' is'} approved and being processed',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required Key key,
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String description,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withAlpha(40),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: color.withAlpha(51),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Quick actions
  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.flash_on,
                    color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.add_circle,
                  label: 'New Donation',
                  color: theme.colorScheme.primary,
                  subtitle: 'Start giving',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AddDonationScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.history,
                  label: 'My Donations',
                  color: Colors.blue,
                  subtitle: 'Track status',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Scroll down to see your donations'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.volunteer_activism,
                  label: 'See Impact',
                  color: Colors.orange,
                  subtitle: 'View stories',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DonateScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withAlpha(30),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Recent donations by the donor
  Widget _buildRecentDonations(
      BuildContext context, DonationProvider provider) {
    final theme = Theme.of(context);
    final userDonations = provider.userDonations;

    if (userDonations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.card_giftcard,
                      color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Your Donations',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withAlpha(20),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.card_giftcard,
                        size: 50, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No donations yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start your first donation today',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddDonationScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Start Donating'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.card_giftcard,
                        color: theme.colorScheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Your Donations',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  _showAllDonationsDialog(context, userDonations);
                },
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: userDonations.length > 3 ? 3 : userDonations.length,
            itemBuilder: (ctx, index) {
              final donation = userDonations[index];
              return _buildDonationTile(donation);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDonationTile(DonationModel donation) {
    final theme = Theme.of(context);
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (donation.status) {
      case DonationStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Pending Review';
        break;
      case DonationStatus.approved:
        statusColor = Colors.blue;
        statusIcon = Icons.thumb_up;
        statusText = 'Approved';
        break;
      case DonationStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
        break;
      case DonationStatus.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showDonationDetailsDialog(context, donation);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(donation.category),
                    color: statusColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donation.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${donation.quantity} items • ${donation.location}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Impact stories with enhanced image handling
  Widget _buildImpactStories(BuildContext context, DonationProvider provider) {
    final theme = Theme.of(context);
    final completedDonations = provider.completedDonations;

    if (completedDonations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.emoji_emotions,
                        color: theme.colorScheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Recent Impact Stories',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DonateScreen()),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount:
                  completedDonations.length > 5 ? 5 : completedDonations.length,
              itemBuilder: (ctx, index) {
                final donation = completedDonations[index];
                return _buildImpactStoryCard(donation);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactStoryCard(DonationModel donation) {
    final theme = Theme.of(context);
    String? mainImageToShow;
    bool isAdminProof = false;

    if (donation.proofImageUrl != null && donation.proofImageUrl!.isNotEmpty) {
      mainImageToShow = donation.proofImageUrl;
      isAdminProof = true;
    } else if (donation.donorImageUrls.isNotEmpty) {
      mainImageToShow = donation.donorImageUrls.first;
    }

    return GestureDetector(
      onTap: () {
        _showImpactStoryDialog(context, donation);
      },
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 16),
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 3,
          color: theme.cardColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main Image Section
              SizedBox(
                height: 160,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (mainImageToShow != null)
                      GestureDetector(
                        onTap: () => _showFullImage(context, mainImageToShow!),
                        child: Stack(
                          children: [
                            Image.network(
                              mainImageToShow,
                              width: double.infinity,
                              height: 160,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: theme.colorScheme.primaryContainer,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFE91E63),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => Container(
                                color: theme.colorScheme.primaryContainer,
                                child: Center(
                                  child: Icon(Icons.image_not_supported,
                                      color: theme.colorScheme.primary,
                                      size: 40),
                                ),
                              ),
                            ),
                            // Zoom indicator
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(153),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.zoom_in,
                                        size: 10, color: Colors.white),
                                    SizedBox(width: 3),
                                    Text(
                                      'Zoom',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        height: 160,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.primaryContainer,
                              theme.colorScheme.primaryContainer.withAlpha(128),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(Icons.volunteer_activism,
                              size: 50, color: theme.colorScheme.primary),
                        ),
                      ),
                    // Category Badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(179),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getCategoryIcon(donation.category),
                                size: 8, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(
                              donation.category,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Image type badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isAdminProof
                              ? const Color(0xFF2E7D32).withAlpha(204)
                              : const Color(0xFFE91E63).withAlpha(204),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isAdminProof ? Icons.verified : Icons.person,
                              size: 8,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              isAdminProof ? 'Proof' : 'Donor',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content Section
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      donation.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.people_alt,
                            size: 10,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            donation.recipientInfo ?? 'Those in need',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 9, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            donation.location,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.inventory,
                            size: 9, color: theme.colorScheme.primary),
                        const SizedBox(width: 3),
                        Text(
                          '${donation.quantity} items',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    //  bottom row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          flex: 2,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.favorite,
                                  size: 9, color: theme.colorScheme.primary),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  _formatDate(donation.completedAt ??
                                      donation.createdAt),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (donation.donorImageUrls.length > 1)
                          Flexible(
                            flex: 1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.photo_library,
                                      size: 7,
                                      color: theme.colorScheme.primary),
                                  const SizedBox(width: 2),
                                  Text(
                                    '+${donation.donorImageUrls.length}',
                                    style: TextStyle(
                                      fontSize: 7,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Flexible(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Story',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
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

  void _showImpactStoryDialog(BuildContext context, DonationModel donation) {
    final theme = Theme.of(context);
    final useFullScreen = _shouldUseFullScreenDialog(context);

    // Determine main image
    String? mainImageToShow;
    if (donation.proofImageUrl != null && donation.proofImageUrl!.isNotEmpty) {
      mainImageToShow = donation.proofImageUrl;
    } else if (donation.donorImageUrls.isNotEmpty) {
      mainImageToShow = donation.donorImageUrls.first;
    }

    // Collect all images for gallery
    List<String> allImages = [];
    if (donation.proofImageUrl != null && donation.proofImageUrl!.isNotEmpty) {
      allImages.add(donation.proofImageUrl!);
    }
    allImages.addAll(donation.donorImageUrls);

    Widget dialogContent(BuildContext ctx) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(useFullScreen ? 24 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!useFullScreen && mainImageToShow != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GestureDetector(
                  onTap: () => _showFullImage(context, mainImageToShow!),
                  child: Image.network(
                    mainImageToShow,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        color: theme.colorScheme.primaryContainer,
                        child: const Center(
                            child:
                                CircularProgressIndicator(color: Colors.green)),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: theme.colorScheme.primaryContainer,
                      child: Center(
                          child: Icon(Icons.image,
                              size: 60, color: theme.colorScheme.primary)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    donation.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    donation.category,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🌟 Impact Made',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.people_alt,
                          size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          donation.recipientInfo ?? 'Those in need',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 18, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Text(
                        donation.location,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 18, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Text(
                        _formatDate(donation.completedAt ?? donation.createdAt),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.volunteer_activism,
                          size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Text(
                        '${donation.quantity} items donated',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Image Gallery Section
            if (allImages.length > 1) ...[
              const SizedBox(height: 12),
              Text(
                '📸 Gallery',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: allImages.length,
                  itemBuilder: (ctx, index) {
                    return GestureDetector(
                      onTap: () => _showFullImage(context, allImages[index]),
                      child: Container(
                        width: 70,
                        height: 70,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            allImages[index],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Icon(Icons.broken_image, size: 25),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Thank you for being part of this impact! Your generosity changes lives.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      );
    }

    if (useFullScreen) {
      //  Android
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              title: const Text('Impact Story'),
              centerTitle: true,
              backgroundColor: theme.colorScheme.surface,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
              actions: [
                if (mainImageToShow != null)
                  IconButton(
                    icon: const Icon(Icons.fullscreen),
                    onPressed: () => _showFullImage(context, mainImageToShow!),
                  ),
              ],
            ),
            body: dialogContent(ctx),
          ),
        ),
      );
    } else {
      // web
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: theme.dialogBackgroundColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
              maxWidth: 600,
            ),
            child: dialogContent(ctx),
          ),
        ),
      );
    }
  }

  //  Donation Details Dialog
  void _showDonationDetailsDialog(BuildContext context, DonationModel donation,
      [BuildContext? parentContext]) {
    final theme = Theme.of(context);

    _showAdaptiveDialog(
      context: parentContext ?? context,
      title: 'Donation Details',
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(_getCategoryIcon(donation.category),
                      color: theme.colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    donation.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Category', donation.category),
            _buildDetailRow('Quantity', '${donation.quantity} items'),
            _buildDetailRow('Condition', donation.condition),
            _buildDetailRow('Location', donation.location),
            _buildDetailRow(
                'Status', donation.status.toString().split('.').last),
            if (donation.rejectionReason != null) ...[
              const Divider(),
              const Text('Rejection Reason:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.error)),
                child: Text(donation.rejectionReason!),
              ),
            ],
            if (donation.recipientInfo != null) ...[
              const Divider(),
              const Text('Impact Made:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.emoji_emotions,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(donation.recipientInfo!,
                            style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
            ],
            if (donation.donorImageUrls.isNotEmpty) ...[
              const Divider(),
              const Text('Images:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildImageGallery(donation.donorImageUrls, ctx),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

//  Donations By Status Dialog
  void _showDonationsByStatus(
      BuildContext context, List<DonationModel> donations, String status) {
    final theme = Theme.of(context);
    final filteredDonations = status == 'all'
        ? donations
        : donations.where((d) {
            if (status == 'completed')
              return d.status == DonationStatus.completed;
            if (status == 'pending') return d.status == DonationStatus.pending;
            return true;
          }).toList();

    String title = status == 'all'
        ? 'All Donations'
        : status == 'completed'
            ? 'Completed Donations'
            : 'Pending Donations';

    _showAdaptiveDialog(
      context: context,
      title: title,
      builder: (ctx) => filteredDonations.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline,
                      size: 50, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text('No $status donations found',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: filteredDonations.length,
              itemBuilder: (ctx, index) {
                final donation = filteredDonations[index];
                return ListTile(
                  leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(_getCategoryIcon(donation.category),
                          color: theme.colorScheme.primary)),
                  title: Text(donation.title),
                  subtitle:
                      Text('${donation.quantity} items • ${donation.location}'),
                  onTap: () {
                    _showDonationDetailsDialog(ctx, donation);
                  },
                );
              },
            ),
    );
  }

  void _showAllDonationsDialog(
      BuildContext context, List<DonationModel> donations) {
    final theme = Theme.of(context);

    _showAdaptiveDialog(
      context: context,
      title: 'All Your Donations',
      builder: (ctx) => ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: donations.length,
        itemBuilder: (ctx, index) {
          final donation = donations[index];
          return ListTile(
            leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(_getCategoryIcon(donation.category),
                    color: theme.colorScheme.primary)),
            title: Text(donation.title),
            subtitle:
                Text('${donation.quantity} items • ${donation.statusText}'),
            trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: _getStatusColor(donation.status).withAlpha(26),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(donation.statusText,
                    style: TextStyle(
                        color: _getStatusColor(donation.status),
                        fontSize: 10,
                        fontWeight: FontWeight.bold))),
            onTap: () {
              _showDonationDetailsDialog(ctx, donation);
            },
          );
        },
      ),
    );
  }

  //Footer

  Widget _buildCompactFooter(
      BuildContext context, bool isMobileLayout, bool isTabletLayout) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobileLayout ? 20 : 40,
        vertical: 24,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
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
          _buildFooterBottomBar(context, isMobileLayout),
        ],
      ),
    );
  }

  Widget _buildFooterDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 1, child: _buildFooterLogoSection(context)),
        Expanded(
            flex: 1, child: Center(child: _buildFooterContactSection(context))),
        Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(left: 40),
              child: _buildFooterSocialSection(context),
            )),
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
        Row(children: [Expanded(child: _buildFooterSocialSection(context))]),
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AboutScreen()),
        );
      },
      child: Column(
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
                        child: const Icon(Icons.eco,
                            color: Colors.white, size: 26),
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
              style:
                  TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
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
                Text('Eco-Friendly',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterContactSection(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('CONTACT US',
            style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
        const SizedBox(height: 12),
        _buildFooterContactItem(
            icon: Icons.phone_rounded,
            text: '+977 9847098514',
            onTap: () => _makePhoneCall('+9779847098514')),
        const SizedBox(height: 8),
        _buildFooterContactItem(
            icon: Icons.phone_rounded,
            text: '+977 9857059514',
            onTap: () => _makePhoneCall('+9779857059514')),
        const SizedBox(height: 8),
        _buildFooterContactItem(
            icon: Icons.email_rounded,
            text: 'support@kindcart.com',
            onTap: () => _sendEmail('support@kindcart.com'),
            isEmail: true),
        const SizedBox(height: 8),
        _buildFooterContactItem(
            icon: Icons.access_time_rounded,
            text: 'Mon-Fri: 9AM - 6PM',
            onTap: null),
      ],
    );
  }

  Widget _buildFooterContactItem(
      {required IconData icon,
      required String text,
      VoidCallback? onTap,
      bool isEmail = false}) {
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
        const Text('CONNECT WITH US',
            style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
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
                      Color(0xFF515BD4)
                    ],
                    stops: [
                      0.0,
                      0.2,
                      0.5,
                      0.8,
                      1.0
                    ])),
            const SizedBox(width: 16),
            _buildFooterSocialIcon(
                iconData: Icons.facebook_rounded,
                label: 'Facebook',
                url: 'https://www.facebook.com',
                gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1877F2), Color(0xFF0C63D4)])),
            const SizedBox(width: 16),
            _buildFooterSocialIcon(
                iconData: Icons.chat_bubble_rounded,
                label: 'Twitter',
                url: 'https://www.twitter.com',
                gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1DA1F2), Color(0xFF0D8BD9)])),
            const SizedBox(width: 16),
            _buildFooterSocialIcon(
                iconData: Icons.play_circle_filled_rounded,
                label: 'YouTube',
                url: 'https://www.youtube.com',
                gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF0000), Color(0xFFCC0000)])),
            const SizedBox(width: 16),
            _buildFooterSocialIcon(
                iconData: Icons.work_rounded,
                label: 'LinkedIn',
                url: 'https://www.linkedin.com',
                gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A66C2), Color(0xFF004182)])),
          ],
        ),
      ],
    );
  }

  Widget _buildFooterSocialIcon(
      {required IconData iconData,
      required String label,
      required String url,
      required Gradient gradient}) {
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
                    offset: const Offset(0, 2))
              ],
            ),
            child: Icon(iconData, color: Colors.white, size: 22),
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
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const AboutScreen()));
        }),
        const SizedBox(height: 12),
        Text('© ${DateTime.now().year} KindCart. All rights reserved.',
            style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 11),
            textAlign: TextAlign.center),
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
          child: Text(text,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white54)),
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
    final Uri emailUri = Uri(scheme: 'mailto', path: emailAddress);
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
          duration: const Duration(seconds: 2)),
    );
  }

  // Helper Methods
  Color _getStatusColor(DonationStatus status) {
    switch (status) {
      case DonationStatus.pending:
        return Colors.orange;
      case DonationStatus.approved:
        return Colors.blue;
      case DonationStatus.completed:
        return Colors.green;
      case DonationStatus.rejected:
        return Colors.red;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'clothing':
        return Icons.checkroom;
      case 'books':
        return Icons.menu_book;
      case 'toys':
        return Icons.toys;
      case 'kitchenware':
        return Icons.kitchen;
      case 'electronics':
        return Icons.electrical_services;
      case 'furniture':
        return Icons.chair;
      case 'food':
        return Icons.fastfood;
      default:
        return Icons.card_giftcard;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 90,
              child: Text('$label:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ))),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    if (difference < 30) return '${(difference / 7).floor()} weeks ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
