import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'guest_home_screen.dart';
import 'buyer_home_screen.dart';
import 'seller_home_screen.dart';
import 'donor_home_screen.dart';
import 'admin_home_screen.dart';
import 'buyer_home_screen.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // If not logged in, show guest home (your existing screen)
    if (!authProvider.isAuthenticated) {
      return const HomeScreen();
    }

    // Get user role - based on your AuthProvider, roles are strings
    final role = authProvider.userRole;

    debugPrint('📍 Current user role: $role');

    // Return role-specific home screen
    switch (role) {
      case 'Seller':
        return const SellerHomeScreen();
      case 'Buyer':
        return const BuyerHomeScreen();
      case 'Donor':
        return const DonorHomeScreen();
      case 'Admin':
        return const AdminHomeScreen();
      default:
        // If role is not set, default to guest
        return const HomeScreen();
    }
  }
}
