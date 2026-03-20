import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product_model.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _locationController;

  late String _selectedCategory;
  late String _selectedCondition;
  late bool _isAvailable;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _titleController = TextEditingController(text: widget.product.title);
    _descriptionController =
        TextEditingController(text: widget.product.description);
    _priceController =
        TextEditingController(text: widget.product.price.toString());
    _locationController =
        TextEditingController(text: widget.product.location ?? '');

    _selectedCategory = widget.product.category;
    _selectedCondition = widget.product.condition;
    _isAvailable = widget.product.isAvailable;

    debugPrint(
        '📝 EditProductScreen initialized for product: ${widget.product.id}');
    debugPrint('   Title: ${widget.product.title}');
    debugPrint('   Seller ID: ${widget.product.sellerId}');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Verify ownership
      if (authProvider.user?.uid != widget.product.sellerId) {
        throw Exception('You can only edit your own products');
      }

      debugPrint('📝 Updating product: ${widget.product.id}');

      final success = await productProvider.updateProduct(
        productId: widget.product.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        category: _selectedCategory,
        condition: _selectedCondition,
        location: _locationController.text.trim(),
        isAvailable: _isAvailable,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Product updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Wait a moment for the user to see the success message
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        throw Exception(productProvider.errorMessage ?? 'Update failed');
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint('❌ Error in _updateProduct: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating product: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  //  delete method with options
  Future<void> _showDeleteOptions() async {
    final deleteOption = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text(
          'How would you like to remove this product?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel'),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, 'soft'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Soft Delete (Hide)'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, 'permanent'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Permanently Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (deleteOption == 'cancel' || deleteOption == null || !mounted) return;

    if (deleteOption == 'permanent') {
      // Show extra warning for permanent delete
      final confirmPermanent = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ Permanent Deletion'),
          content: const Text(
              'This will permanently delete the product and all its images. '
              'This action CANNOT be undone.\n\n'
              'Are you absolutely sure?'),
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
              child: const Text('Yes, Delete Forever'),
            ),
          ],
        ),
      );

      if (confirmPermanent != true) return;
      await _permanentlyDeleteProduct();
    } else {
      await _softDeleteProduct();
    }
  }

  // Soft delete (hide the product)
  Future<void> _softDeleteProduct() async {
    setState(() => _isSubmitting = true);

    try {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);

      // Use updateProduct to mark as hidden/unavailable
      final success = await productProvider.updateProduct(
        productId: widget.product.id,
        isAvailable: false,
        isHidden: true,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Product hidden successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to previous screen
        Navigator.pop(context, true);
      } else {
        throw Exception(productProvider.errorMessage ?? 'Soft delete failed');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // Permanent delete
  Future<void> _permanentlyDeleteProduct() async {
    setState(() => _isSubmitting = true);

    try {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Check if user is admin
      final isAdmin = authProvider.userRole == 'Admin';

      debugPrint(
          '🗑️ Attempting permanent delete for product: ${widget.product.id}');
      debugPrint('   Is Admin: $isAdmin');

      // Call permanent delete method
      final success = await productProvider.permanentlyDeleteProduct(
        widget.product.id,
        widget.product.imageUrls,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Product permanently deleted'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate all the way back to my listings
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        throw Exception(
            productProvider.errorMessage ?? 'Permanent delete failed');
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint('❌ Error in _permanentlyDeleteProduct: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isOwner = authProvider.user?.uid == widget.product.sellerId;
    final isAdmin = authProvider.userRole == 'Admin';

    if (!isOwner && !isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'You can only edit your own products',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
        actions: [
          // Delete button with options
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteOptions();
              } else if (value == 'mark_sold') {
                _softDeleteProduct();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_sold',
                child: Row(
                  children: [
                    Icon(Icons.sell, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Mark as Sold'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Options...'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),

          // Save button
          TextButton(
            onPressed: _isSubmitting ? null : _updateProduct,
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'SAVE',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                if (value.length < 10) {
                  return 'Title must be at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: ProductModel.categoryOptions.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a category';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Condition
            DropdownButtonFormField<String>(
              value: _selectedCondition,
              decoration: const InputDecoration(
                labelText: 'Condition',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info_outline),
              ),
              items: ProductModel.conditionOptions.map((condition) {
                return DropdownMenuItem(
                  value: condition,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getConditionColor(condition),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(condition),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCondition = value!;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select condition';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Price
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price (₹)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter price';
                }
                final price = double.tryParse(value);
                if (price == null) {
                  return 'Please enter a valid number';
                }
                if (price <= 0) {
                  return 'Price must be greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter location';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.description),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter description';
                }
                if (value.length < 20) {
                  return 'Description must be at least 20 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Availability Switch
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Available for sale',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _isAvailable ? 'Item is visible to buyers' : 'Item is hidden',
                  style: TextStyle(
                    color: _isAvailable ? Colors.green : Colors.red,
                  ),
                ),
                value: _isAvailable,
                onChanged: (value) {
                  setState(() {
                    _isAvailable = value;
                  });
                },
                secondary: Icon(
                  _isAvailable ? Icons.check_circle : Icons.cancel,
                  color: _isAvailable ? Colors.green : Colors.red,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Delete Options Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delete Options',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const Divider(height: 20),
                    ListTile(
                      leading: const Icon(Icons.visibility_off,
                          color: Colors.orange),
                      title: const Text('Soft Delete (Hide)'),
                      subtitle:
                          const Text('Hide product from buyers, but keep data'),
                      onTap: _isSubmitting ? null : _softDeleteProduct,
                    ),
                    ListTile(
                      leading:
                          const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text('Permanently Delete'),
                      subtitle:
                          const Text('Completely remove product and images'),
                      onTap: _isSubmitting
                          ? null
                          : () => _permanentlyDeleteProduct(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Product Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Product Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 20),
                    _buildInfoRow('Product ID', widget.product.id),
                    _buildInfoRow(
                        'Created', _formatDate(widget.product.createdAt)),
                    _buildInfoRow('Views', '${widget.product.viewCount}'),
                    _buildInfoRow(
                        'Wishlist', '${widget.product.wishlistCount}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getConditionColor(String condition) {
    switch (condition) {
      case 'Brand New':
      case 'Like New':
        return Colors.green;
      case 'Excellent':
      case 'Very Good':
        return Colors.teal;
      case 'Good':
        return Colors.blue;
      case 'Fair':
        return Colors.orange;
      case 'For Parts/Not Working':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
