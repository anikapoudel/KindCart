import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/wishlist_provider.dart';
import 'providers/donation_provider.dart';
import 'providers/order_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/announcement_provider.dart';
import 'home/role_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => DonationProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => AnnouncementProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const AppWrapper(),
    ),
  );
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  String? _lastLoadedUid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final wishlistProvider =
          Provider.of<WishlistProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      authProvider.registerCartCallbacks(
        onSaveCartBeforeLogout: () async {
          await cartProvider.saveCartBeforeLogout();
          debugPrint('🛒 Cart saved before logout via callback');
        },
        onClearCartOnLogout: () async {
          debugPrint('🛒 Cart cleared on logout via callback');
        },
        onSetCartUserId: (userId) {
          cartProvider.setCurrentUser(userId);
          debugPrint('🛒 Cart user ID set to: $userId');
        },
      );

      authProvider.addListener(() async {
        if (authProvider.isAuthenticated && authProvider.user != null) {
          final uid = authProvider.user!.uid;
          if (_lastLoadedUid == uid) return;
          _lastLoadedUid = uid;

          debugPrint('🔄 Auth changed → loading wishlist for $uid');

          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            wishlistProvider.loadWishlist(uid);
          }
        } else {
          // User logged out
          _lastLoadedUid = null;
          debugPrint('🔄 Auth changed → clearing wishlist');
          wishlistProvider.clearLocalWishlist();
        }
      });

      if (authProvider.isAuthenticated && authProvider.user != null) {
        _lastLoadedUid = authProvider.user!.uid;

        cartProvider.setCurrentUser(authProvider.user!.uid);

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            wishlistProvider.loadWishlist(authProvider.user!.uid);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const MyApp();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'KindCart',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          centerTitle: false,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          foregroundColor: Colors.white,
          elevation: 1,
          centerTitle: false,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.grey[900],
          selectedItemColor: Colors.green[300],
          unselectedItemColor: Colors.grey[500],
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textTheme: TextTheme(
          displayLarge:
              const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          displayMedium:
              const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          titleLarge:
              const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.grey[300]),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.grey[400]),
        ),
        scaffoldBackgroundColor: Colors.grey[900],
        cardColor: Colors.grey[850],
        dividerColor: Colors.grey[800],
      ),
      home: const RoleRouter(),
    );
  }
}
