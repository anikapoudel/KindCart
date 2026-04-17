import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product_model.dart';
import 'item_detail_screen.dart';
import 'addproduct_screen.dart';
import 'editproduct_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProducts();
    });
  }

  Future<void> _loadUserProducts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);

    if (authProvider.isAuthenticated) {
      await productProvider.loadUserProducts(authProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isWebLayout = screenWidth > 800;

    // number of columns based on screen size
    final int crossAxisCount = isWebLayout ? 4 : 2;

    // card height based on screen size for mobile
    final double cardHeight = isWebLayout ? 280 : screenHeight * 0.28;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddProductScreen()),
              ).then((_) => _loadUserProducts());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserProducts,
        child: productProvider.isLoading && productProvider.userProducts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : productProvider.userProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No listings yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start selling by adding your first product',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const AddProductScreen()),
                            ).then((_) => _loadUserProducts());
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Your First Product'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: isWebLayout ? 300 : 200,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: isWebLayout ? 0.85 : 0.65,
                    ),
                    itemCount: productProvider.userProducts.length,
                    itemBuilder: (context, index) {
                      final product = productProvider.userProducts[index];
                      return _buildProductCard(product, isWebLayout);
                    },
                  ),
      ),
    );
  }

  Widget _buildProductCard(ProductModel product, bool isWebLayout) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image section with tap to view details
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemDetailScreen(item: product),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  image: product.imageUrls.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(product.imageUrls.first),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: product.imageUrls.isEmpty
                    ? const Center(
                        child: Icon(Icons.image_not_supported,
                            size: 30, color: Colors.grey),
                      )
                    : null,
              ),
            ),
          ),

          // Details section
          Padding(
            padding: EdgeInsets.all(isWebLayout ? 8 : 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  product.title,
                  style: TextStyle(
                    fontSize: isWebLayout ? 14 : 11,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: isWebLayout ? 4 : 2),

                // Price
                Text(
                  'NPR ${product.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: isWebLayout ? 16 : 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),

                SizedBox(height: isWebLayout ? 4 : 2),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: product.isAvailable
                        ? Colors.green.withAlpha(20)
                        : Colors.red.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              product.isAvailable ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        product.isAvailable ? 'Active' : 'Sold',
                        style: TextStyle(
                          fontSize: isWebLayout ? 10 : 8,
                          color:
                              product.isAvailable ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isWebLayout ? 8 : 6),

                // Edit and Delete buttons row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProductScreen(
                                product: product,
                              ),
                            ),
                          ).then((result) {
                            if (result == true) {
                              _loadUserProducts();
                            }
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orange),
                          foregroundColor: Colors.orange,
                          padding: EdgeInsets.symmetric(
                              vertical: isWebLayout ? 8 : 4),
                          minimumSize: const Size(0, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit, size: isWebLayout ? 16 : 12),
                            SizedBox(width: isWebLayout ? 4 : 2),
                            Text(
                              'Edit',
                              style: TextStyle(fontSize: isWebLayout ? 12 : 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _confirmDelete(product);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(
                              vertical: isWebLayout ? 8 : 4),
                          minimumSize: const Size(0, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete, size: isWebLayout ? 16 : 12),
                            SizedBox(width: isWebLayout ? 4 : 2),
                            Text(
                              'Delete',
                              style: TextStyle(fontSize: isWebLayout ? 12 : 10),
                            ),
                          ],
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
    );
  }

  Future<void> _confirmDelete(ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
            'Are you sure you want to delete "${product.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final success = await productProvider.deleteProduct(product.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadUserProducts();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete product'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
