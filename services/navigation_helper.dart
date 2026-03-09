// lib/services/navigation_helper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/role_guard.dart';
import '../screens/addproduct_screen.dart';
import '../screens/adddonation_screen.dart';
import '../screens/shop_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/wishlist_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/search_screen.dart';  // ← ADD THIS IMPORT

class NavigationHelper {
  // Navigate to Seller Screen (only for sellers)
  static void goToSellScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoleGuard(
          allowedRoles: ['Seller'],
          requireVerified: true,
          requireSellerApproved: true,
          child: const AddProductScreen(),
          fallback: const AuthScreen(),
        ),
      ),
    );
  }

  // Navigate to Donation Screen (only for donors)
  static void goToDonateScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoleGuard(
          allowedRoles: ['Donor'],
          requireVerified: true,
          child: const AddDonationScreen(),
          fallback: const AuthScreen(),
        ),
      ),
    );
  }

  // Navigate to Shop Screen (anyone can view)
  static void goToShopScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ShopScreen(),
      ),
    );
  }

  // Navigate to Search Screen (anyone can search)
  static void goToSearchScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchScreen(),
      ),
    );
  }

  // Navigate to Cart Screen (requires authentication)
  static void goToCartScreen(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      _showLoginRequiredDialog(context);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CartScreen(),
      ),
    );
  }

  // Navigate to Wishlist Screen (requires authentication)
  static void goToWishlistScreen(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      _showLoginRequiredDialog(context);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WishlistScreen(),
      ),
    );
  }

  // Navigate to Profile Screen
  static void goToProfileScreen(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    }
  }

  // Navigate to About Screen
  static void goToAboutScreen(BuildContext context) {
    Navigator.pushNamed(context, '/about');
  }

  // Navigate to Chat/AI Help Screen
  static void goToChatScreen(BuildContext context) {
    Navigator.pushNamed(context, '/chat');
  }

  // Show bottom sheet with role-based options
  static void showAddOptions(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
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
                'What would you like to add?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Show login option if not authenticated
              if (!auth.isAuthenticated) ...[
                _buildOptionTile(
                  icon: Icons.login,
                  iconColor: Colors.blue,
                  title: 'Login Required',
                  subtitle: 'Please login to sell or donate items',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AuthScreen()),
                    );
                  },
                ),
              ] else ...[
                // Seller options
                if (auth.userRole == 'Seller') ...[
                  if (auth.isSellerApproved)
                    _buildOptionTile(
                      icon: Icons.sell,
                      iconColor: Colors.green,
                      title: 'Sell an Item',
                      subtitle: 'List your pre-loved items for sale',
                      onTap: () {
                        Navigator.pop(context);
                        goToSellScreen(context);
                      },
                    )
                  else
                    _buildOptionTile(
                      icon: Icons.hourglass_empty,
                      iconColor: Colors.orange,
                      title: 'Seller Approval Pending',
                      subtitle: 'Your seller account is being reviewed',
                      onTap: () {
                        Navigator.pop(context);
                        _showApprovalPendingDialog(context);
                      },
                    ),
                ],

                // Donor options
                if (auth.userRole == 'Donor')
                  _buildOptionTile(
                    icon: Icons.volunteer_activism,
                    iconColor: Colors.orange,
                    title: 'Donate Items',
                    subtitle: 'Give items to those in need',
                    onTap: () {
                      Navigator.pop(context);
                      goToDonateScreen(context);
                    },
                  ),

                // Buyer options (or if user has no special role)
                if (auth.userRole == 'Buyer')
                  _buildOptionTile(
                    icon: Icons.shopping_bag,
                    iconColor: Colors.purple,
                    title: 'Browse Items',
                    subtitle: 'Shop for sustainable products',
                    onTap: () {
                      Navigator.pop(context);
                      goToShopScreen(context);
                    },
                  ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Helper method to build option tiles
  static Widget _buildOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withAlpha(25),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  // Show login required dialog
  static void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please login to access this feature'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  // Show approval pending dialog
  static void _showApprovalPendingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approval Pending'),
        content: const Text(
            'Your seller account is awaiting admin approval. '
                'You will be able to list items once approved.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}