import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProductModerationScreen extends StatefulWidget {
  const ProductModerationScreen({super.key});

  @override
  State<ProductModerationScreen> createState() => _ProductModerationScreenState();
}

class _ProductModerationScreenState extends State<ProductModerationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  // Add a GlobalKey to manage the Scaffold state
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('categories').get();
      if (mounted) {
        setState(() {
          _categories = ['All', ...snapshot.docs.map((doc) => doc['name'] as String)];
        });
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use the scaffold key for better snackbar management
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Product Moderation'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Products', icon: Icon(Icons.inventory)),
            Tab(text: 'Reported', icon: Icon(Icons.flag)),
            Tab(text: 'Categories', icon: Icon(Icons.category)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                          : null,
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    underline: const SizedBox(),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllProductsTab(),
                _buildReportedProductsTab(),
                _buildCategoriesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllProductsTab() {
    Query query = FirebaseFirestore.instance.collection('products').orderBy('createdAt', descending: true);

    if (_selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var products = snapshot.data!.docs;

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          products = products.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = (data['title'] ?? '').toString().toLowerCase();
            final description = (data['description'] ?? '').toString().toLowerCase();
            final query = _searchQuery.toLowerCase();
            return title.contains(query) || description.contains(query);
          }).toList();
        }

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No products found',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final data = product.data() as Map<String, dynamic>;
            return _buildProductCard(context, product.id, data);
          },
        );
      },
    );
  }

  Widget _buildReportedProductsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reports = snapshot.data!.docs;

        if (reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.flag_outlined, size: 80, color: Colors.green[200]),
                const SizedBox(height: 16),
                Text(
                  'No pending reports',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            final data = report.data() as Map<String, dynamic>;
            return _buildReportCard(context, report.id, data);
          },
        );
      },
    );
  }

  Widget _buildCategoriesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').orderBy('name').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final categories = snapshot.data!.docs;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => _showAddCategoryDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add New Category'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final data = category.data() as Map<String, dynamic>;
                  return _buildCategoryCard(context, category.id, data);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductCard(BuildContext context, String productId, Map<String, dynamic> data) {
    final isAvailable = data['isAvailable'] ?? true;
    final price = data['price'] ?? 0;
    final condition = data['condition'] ?? 'Not specified';

    Color conditionColor;
    switch (condition) {
      case 'New':
        conditionColor = Colors.green;
        break;
      case 'Like New':
        conditionColor = Colors.blue;
        break;
      case 'Good':
        conditionColor = Colors.orange;
        break;
      case 'Fair':
        conditionColor = Colors.purple;
        break;
      default:
        conditionColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 60,
            height: 60,
            color: Colors.grey[200],
            child: data['imageUrls'] != null && (data['imageUrls'] as List).isNotEmpty
                ? Image.network(
              data['imageUrls'][0],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
            )
                : const Icon(Icons.image, color: Colors.grey),
          ),
        ),
        title: Text(
          data['title'] ?? 'No Title',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seller: ${data['sellerName'] ?? 'Unknown'}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: conditionColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    condition,
                    style: TextStyle(color: conditionColor, fontSize: 10),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '₹${price.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isAvailable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Sold',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            IconButton(
              icon: Icon(
                isAvailable ? Icons.visibility : Icons.visibility_off,
                color: isAvailable ? Colors.green : Colors.grey,
              ),
              onPressed: () => _toggleProductVisibility(context, productId, isAvailable, data['title'] ?? 'Product'),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (String value) {
                // Handle menu selection immediately without trying to pop
                switch (value) {
                  case 'view':
                    _showProductDetails(context, productId, data);
                    break;
                  case 'edit':
                    _showEditProductDialog(context, productId, data);
                    break;
                  case 'delete':
                    _showDeleteProductDialog(context, productId, data['title'] ?? 'Product');
                    break;
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem<String>(
                    value: 'view',
                    child: ListTile(
                      leading: Icon(Icons.visibility),
                      title: Text('View Details'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit Product'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Delete Product'),
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, String reportId, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.red.withAlpha(20),
                    child: const Icon(Icons.flag, color: Colors.red),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reported by: ${data['reporterName'] ?? 'Unknown'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Product: ${data['productTitle'] ?? 'Unknown'}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    data['createdAt'] != null
                        ? DateFormat('dd/MM/yy').format((data['createdAt'] as Timestamp).toDate())
                        : 'Unknown',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(
                'Reason: ${data['reason'] ?? 'Not specified'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (data['description'] != null && data['description'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(data['description']),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleReport(context, reportId, data['productId'], 'approved'),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Keep Product'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleReport(context, reportId, data['productId'], 'rejected'),
                      icon: const Icon(Icons.remove_circle),
                      label: const Text('Remove Product'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String categoryId, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.withAlpha(20),
          child: Icon(
            data['icon'] != null
                ? IconData(int.tryParse(data['icon'].toString()) ?? 0xe2c7, fontFamily: 'MaterialIcons')
                : Icons.category,
            color: Colors.deepPurple,
          ),
        ),
        title: Text(data['name'] ?? 'No Name'),
        subtitle: Text('${data['productCount'] ?? 0} products'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showEditCategoryDialog(context, categoryId, data),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteCategoryDialog(context, categoryId, data['name'] ?? 'Category'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleProductVisibility(BuildContext context, String productId, bool currentStatus, String productName) async {
    try {
      await FirebaseFirestore.instance.collection('products').doc(productId).update({
        'isAvailable': !currentStatus,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${!currentStatus ? 'Shown' : 'Hidden'} $productName'),
            backgroundColor: !currentStatus ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleReport(BuildContext context, String reportId, String? productId, String action) async {
    try {
      // Update report status
      await FirebaseFirestore.instance.collection('reports').doc(reportId).update({
        'status': action == 'approved' ? 'dismissed' : 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolvedBy': 'admin',
      });

      // If action is 'rejected', remove or hide the product
      if (action == 'rejected' && productId != null) {
        await FirebaseFirestore.instance.collection('products').doc(productId).update({
          'isAvailable': false,
          'removedByAdmin': true,
          'removedReason': 'Reported content',
          'removedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'approved' ? 'Report dismissed' : 'Product removed'),
            backgroundColor: action == 'approved' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProductDetails(BuildContext context, String productId, Map<String, dynamic> data) {
    // Store the data in local variables to avoid context issues
    final String title = data['title'] ?? 'Product Details';
    final String description = data['description'] ?? 'No description';
    final double price = data['price'] ?? 0;
    final String condition = data['condition'] ?? 'Not specified';
    final String category = data['category'] ?? 'Not specified';
    final String sellerName = data['sellerName'] ?? 'Unknown';
    final String location = data['location'] ?? 'Not specified';
    final String postedDate = data['createdAt'] != null
        ? DateFormat('dd MMM yyyy').format((data['createdAt'] as Timestamp).toDate())
        : 'Unknown';
    final List<String> imageUrls = data['imageUrls'] != null
        ? List<String>.from(data['imageUrls'])
        : [];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Images
                        if (imageUrls.isNotEmpty)
                          Container(
                            height: 200,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: imageUrls.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      imageUrls[index],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Icon(Icons.broken_image, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                        // Details
                        _buildDetailRow('Description', description),
                        const SizedBox(height: 8),
                        _buildDetailRow('Price', '₹$price'),
                        const SizedBox(height: 8),
                        _buildDetailRow('Condition', condition),
                        const SizedBox(height: 8),
                        _buildDetailRow('Category', category),
                        const SizedBox(height: 8),
                        _buildDetailRow('Seller', sellerName),
                        const SizedBox(height: 8),
                        _buildDetailRow('Location', location),
                        const SizedBox(height: 8),
                        _buildDetailRow('Posted', postedDate),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance.collection('categories').add({
                      'name': nameController.text,
                      'description': descriptionController.text,
                      'productCount': 0,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    if (mounted) {
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Category added successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditCategoryDialog(BuildContext context, String categoryId, Map<String, dynamic> data) {
    final nameController = TextEditingController(text: data['name'] ?? '');
    final descriptionController = TextEditingController(text: data['description'] ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Edit Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance.collection('categories').doc(categoryId).update({
                    'name': nameController.text,
                    'description': descriptionController.text,
                  });

                  if (mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Category updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteCategoryDialog(BuildContext context, String categoryId, String categoryName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: Text('Are you sure you want to delete "$categoryName"? Products in this category will need to be recategorized.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance.collection('categories').doc(categoryId).delete();

                  if (mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Deleted $categoryName'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showEditProductDialog(BuildContext context, String productId, Map<String, dynamic> data) {
    final titleController = TextEditingController(text: data['title'] ?? '');
    final priceController = TextEditingController(text: data['price']?.toString() ?? '');
    final descriptionController = TextEditingController(text: data['description'] ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Close the edit dialog first
                Navigator.of(dialogContext).pop();

                // Show loading indicator in a separate dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (loadingContext) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                );

                try {
                  await FirebaseFirestore.instance.collection('products').doc(productId).update({
                    'title': titleController.text,
                    'price': double.tryParse(priceController.text) ?? 0,
                    'description': descriptionController.text,
                  });

                  if (mounted) {
                    // Close loading dialog
                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Product updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    // Close loading dialog
                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteProductDialog(BuildContext context, String productId, String productName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text('Are you sure you want to delete "$productName"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Close the delete dialog first
                Navigator.of(dialogContext).pop();

                // Show loading indicator in a separate dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (loadingContext) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                );

                try {
                  await FirebaseFirestore.instance.collection('products').doc(productId).delete();

                  if (mounted) {
                    // Close loading dialog
                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Deleted $productName'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    // Close loading dialog
                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}