import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRole = 'All';
  final List<String> _roles = ['All', 'Buyer', 'Seller', 'Donor', 'Admin'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Users', icon: Icon(Icons.people)),
            Tab(text: 'Pending Approvals', icon: Icon(Icons.pending_actions)),
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
                      hintText: 'Search users by name or email...',
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
                    value: _selectedRole,
                    hint: const Text('Filter by role'),
                    underline: const SizedBox(),
                    items: _roles.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedRole = value!),
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
                _buildAllUsersTab(),
                _buildPendingApprovalsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllUsersTab() {
    Query query = FirebaseFirestore.instance.collection('users');

    // Apply role filter
    if (_selectedRole != 'All') {
      query = query.where('role', isEqualTo: _selectedRole);
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

        var users = snapshot.data!.docs;

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          users = users.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final email = (data['email'] ?? '').toString().toLowerCase();
            final query = _searchQuery.toLowerCase();
            return name.contains(query) || email.contains(query);
          }).toList();
        }

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No users found',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final data = user.data() as Map<String, dynamic>;
            return _buildUserCard(context, user.id, data);
          },
        );
      },
    );
  }

  Widget _buildPendingApprovalsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Seller')
          .where('sellerApprovalRequested', isEqualTo: true)
          .where('sellerApproved', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final pendingUsers = snapshot.data!.docs;

        if (pendingUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 80, color: Colors.green[200]),
                const SizedBox(height: 16),
                Text(
                  'No pending approvals',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingUsers.length,
          itemBuilder: (context, index) {
            final user = pendingUsers[index];
            final data = user.data() as Map<String, dynamic>;
            return _buildPendingApprovalCard(context, user.id, data);
          },
        );
      },
    );
  }

  Widget _buildUserCard(BuildContext context, String userId, Map<String, dynamic> data) {
    final role = data['role'] ?? 'Buyer';
    final isActive = data['isActive'] ?? true;
    final isSellerApproved = data['sellerApproved'] ?? false;

    Color roleColor;
    switch (role) {
      case 'Admin':
        roleColor = Colors.red;
        break;
      case 'Seller':
        roleColor = isSellerApproved ? Colors.orange : Colors.grey;
        break;
      case 'Donor':
        roleColor = Colors.purple;
        break;
      default:
        roleColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: roleColor.withAlpha(20),
          child: Icon(
            role == 'Seller' ? Icons.store :
            role == 'Donor' ? Icons.volunteer_activism :
            role == 'Admin' ? Icons.admin_panel_settings : Icons.person,
            color: roleColor,
          ),
        ),
        title: Text(data['name'] ?? 'No Name'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['email'] ?? 'No Email'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: roleColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    role,
                    style: TextStyle(color: roleColor, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                if (!isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Inactive',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                if (role == 'Seller' && !isSellerApproved && data['sellerApprovalRequested'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Pending',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isActive ? Icons.block : Icons.check_circle,
                color: isActive ? Colors.red : Colors.green,
              ),
              onPressed: () => _toggleUserStatus(context, userId, isActive, data['name'] ?? 'User'),
            ),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit User'),
                  ),
                ),
                if (role == 'Seller' && data['sellerApprovalRequested'] == true && !isSellerApproved)
                  const PopupMenuItem(
                    value: 'approve',
                    child: ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text('Approve as Seller'),
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete User'),
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditUserDialog(context, userId, data);
                } else if (value == 'approve') {
                  _approveSeller(context, userId, data['name'] ?? 'Seller');
                } else if (value == 'delete') {
                  _showDeleteUserDialog(context, userId, data['name'] ?? 'User');
                }
              },
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.phone, 'Phone', data['phone'] ?? 'Not provided'),
                _buildInfoRow(Icons.location_on, 'Location', data['location'] ?? 'Not provided'),
                _buildInfoRow(Icons.calendar_today, 'Joined',
                    data['createdAt'] != null
                        ? DateFormat('dd MMM yyyy').format((data['createdAt'] as Timestamp).toDate())
                        : 'Unknown'),
                if (role == 'Seller') ...[
                  const Divider(),
                  _buildInfoRow(Icons.inventory, 'Total Products', '${data['totalProducts'] ?? 0}'),
                  _buildInfoRow(Icons.attach_money, 'Total Sales', '₹${data['totalSales'] ?? 0}'),
                ],
                if (role == 'Donor') ...[
                  const Divider(),
                  _buildInfoRow(Icons.card_giftcard, 'Total Donations', '${data['totalDonations'] ?? 0}'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingApprovalCard(BuildContext context, String userId, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange, width: 2),
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
                    backgroundColor: Colors.orange.withAlpha(20),
                    child: const Icon(Icons.store, color: Colors.orange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'] ?? 'No Name',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(data['email'] ?? 'No Email'),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildInfoRow(Icons.phone, 'Phone', data['phone'] ?? 'Not provided'),
              _buildInfoRow(Icons.location_on, 'Location', data['location'] ?? 'Not provided'),
              _buildInfoRow(Icons.business, 'Business Name', data['businessName'] ?? 'Not provided'),
              _buildInfoRow(Icons.description, 'Business Description',
                  data['businessDescription'] ?? 'Not provided', maxLines: 2),
              if (data['requestDate'] != null)
                _buildInfoRow(Icons.calendar_today, 'Requested on',
                    DateFormat('dd MMM yyyy').format((data['requestDate'] as Timestamp).toDate())),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveSeller(context, userId, data['name'] ?? 'Seller'),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectSeller(context, userId, data['name'] ?? 'Seller'),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Reject'),
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

  Widget _buildInfoRow(IconData icon, String label, String value, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleUserStatus(BuildContext context, String userId, bool currentStatus, String userName) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isActive': !currentStatus,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${!currentStatus ? 'Activated' : 'Deactivated'} $userName'),
            backgroundColor: !currentStatus ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _approveSeller(BuildContext context, String userId, String sellerName) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'sellerApproved': true,
        'sellerApprovalRequested': false,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': 'admin',
      });

      // Add to activity log
      await FirebaseFirestore.instance.collection('activity_logs').add({
        'type': 'seller_approved',
        'description': 'Seller $sellerName has been approved',
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approved $sellerName as seller'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectSeller(BuildContext context, String userId, String sellerName) async {
    // Show rejection reason dialog
    final reasonController = TextEditingController();

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Seller'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject $sellerName as seller?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('users').doc(userId).update({
                  'sellerApprovalRequested': false,
                  'sellerApprovalRejected': true,
                  'sellerRejectionReason': reasonController.text,
                  'rejectedAt': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Rejected $sellerName'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(dialogContext);
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
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, String userId, Map<String, dynamic> currentData) {
    final nameController = TextEditingController(text: currentData['name'] ?? '');
    final phoneController = TextEditingController(text: currentData['phone'] ?? '');
    final locationController = TextEditingController(text: currentData['location'] ?? '');
    String selectedRole = currentData['role'] ?? 'Buyer';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'Buyer', child: Text('Buyer')),
                  DropdownMenuItem(value: 'Seller', child: Text('Seller')),
                  DropdownMenuItem(value: 'Donor', child: Text('Donor')),
                  DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                ],
                onChanged: (value) => selectedRole = value!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('users').doc(userId).update({
                  'name': nameController.text,
                  'phone': phoneController.text,
                  'location': locationController.text,
                  'role': selectedRole,
                });

                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(dialogContext);
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
      ),
    );
  }

  void _showDeleteUserDialog(BuildContext context, String userId, String userName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete $userName? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('users').doc(userId).delete();

                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Deleted $userName'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(dialogContext);
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
      ),
    );
  }
}