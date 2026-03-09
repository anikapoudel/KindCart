import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../widgets/role_guard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SellerApprovalScreen extends StatefulWidget {
  const SellerApprovalScreen({super.key});

  @override
  State<SellerApprovalScreen> createState() => _SellerApprovalScreenState();
}

class _SellerApprovalScreenState extends State<SellerApprovalScreen> {
  List<Map<String, dynamic>> _pendingSellers = [];
  bool _isLoading = true;
  bool _isActionInProgress = false;
  String? _selectedSellerId;

  @override
  void initState() {
    super.initState();
    _loadPendingSellers();
  }

  Future<void> _loadPendingSellers() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Seller')
          .where('sellerApprovalRequested', isEqualTo: true)
          .where('sellerApproved', isEqualTo: false)
          .orderBy('sellerApprovalRequestedAt', descending: true)
          .get();

      setState(() {
        _pendingSellers = snapshot.docs.map((doc) {
          return {'id': doc.id, ...doc.data()};
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading pending sellers: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading sellers: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _verifyAdminStatus() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      final adminDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final isAdmin = adminDoc.data()?['role'] == 'Admin';

      if (!isAdmin && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unauthorized: Admin access required'),
            backgroundColor: Colors.red,
          ),
        );
      }

      return isAdmin;
    } catch (e) {
      debugPrint('Error verifying admin status: $e');
      return false;
    }
  }

  Future<void> _approveSeller(String sellerId) async {
    // Verify admin status first
    final isAdmin = await _verifyAdminStatus();
    if (!isAdmin) return;

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Approval'),
        content: const Text('Are you sure you want to approve this seller?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isActionInProgress = true;
      _selectedSellerId = sellerId;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(sellerId)
          .update({
        'sellerApproved': true,
        'sellerApprovedAt': FieldValue.serverTimestamp(),
        'approvedBy': currentUser?.uid,
        'approvedByEmail': currentUser?.email,
        'sellerApprovalRequested': false, // Clear the request flag
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send notification to seller
      await _sendApprovalNotification(sellerId, approved: true);

      await _loadPendingSellers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seller approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error approving seller: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving seller: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isActionInProgress = false;
          _selectedSellerId = null;
        });
      }
    }
  }

  Future<void> _rejectSeller(String sellerId) async {
    // Verify admin status first
    final isAdmin = await _verifyAdminStatus();
    if (!isAdmin) return;

    final reasonController = TextEditingController();
    bool isRejecting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Reject Seller'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please provide a reason for rejection:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Incomplete information, verification failed',
                    helperText: 'This reason will be shown to the seller',
                  ),
                  maxLines: 3,
                  enabled: !isRejecting,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isRejecting ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isRejecting
                    ? null
                    : () async {
                  if (reasonController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Please provide a rejection reason'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  setDialogState(() {
                    isRejecting = true;
                  });

                  try {
                    final currentUser = FirebaseAuth.instance.currentUser;

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(sellerId)
                        .update({
                      'sellerApprovalRequested': false,
                      'sellerApproved': false,
                      'sellerRejectionReason': reasonController.text.trim(),
                      'sellerRejectedAt': FieldValue.serverTimestamp(),
                      'rejectedBy': currentUser?.uid,
                      'rejectedByEmail': currentUser?.email,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                    // Send rejection notification
                    await _sendApprovalNotification(sellerId, approved: false, reason: reasonController.text.trim());

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }

                    await _loadPendingSellers();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Seller rejected successfully'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('Error rejecting seller: $e');
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    setDialogState(() {
                      isRejecting = false;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: isRejecting
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text('Reject'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _sendApprovalNotification(String sellerId, {required bool approved, String? reason}) async {
    try {
      // Create notification in Firestore for in-app notifications
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': sellerId,
        'type': 'seller_approval',
        'title': approved ? 'Seller Account Approved' : 'Seller Account Rejected',
        'body': approved
            ? 'Congratulations! Your seller account has been approved. You can now start listing items.'
            : 'Your seller account request was rejected. Reason: $reason',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // TODO: Implement Firebase Cloud Messaging for push notifications
      // This will be added when you implement FCM

      debugPrint('✅ Notification created for seller: $sellerId');
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
      // Don't throw - notification failure shouldn't break the approval flow
    }
  }

  Future<void> _viewSellerDetails(Map<String, dynamic> seller) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Seller Details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildDetailCard(
                        icon: Icons.person,
                        title: 'Basic Information',
                        children: [
                          _buildDetailRow('Name', seller['name'] ?? 'N/A'),
                          _buildDetailRow('Email', seller['email'] ?? 'N/A'),
                          _buildDetailRow('Phone', seller['phone'] ?? 'N/A'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDetailCard(
                        icon: Icons.assignment,
                        title: 'Application Details',
                        children: [
                          _buildDetailRow('Requested On',
                              _formatDateTime(seller['sellerApprovalRequestedAt'])),
                          _buildDetailRow('Account Created',
                              _formatDateTime(seller['createdAt'])),
                          _buildDetailRow('Email Verified',
                              seller['emailVerified'] == true ? 'Yes' : 'No'),
                        ],
                      ),
                      if (seller['sellerNotes'] != null) ...[
                        const SizedBox(height: 16),
                        _buildDetailCard(
                          icon: Icons.note,
                          title: 'Seller Notes',
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(seller['sellerNotes']),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _approveSeller(seller['id']);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text('Approve'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _rejectSeller(seller['id']);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailCard({required IconData icon, required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: ['Admin'],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Seller Approvals'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isActionInProgress ? null : _loadPendingSellers,
            ),
            Text(
              '${_pendingSellers.length} pending',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _pendingSellers.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.green[200],
              ),
              const SizedBox(height: 16),
              const Text(
                'No pending seller approvals',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'All caught up! Check back later.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        )
            : ListView.builder(
          itemCount: _pendingSellers.length,
          itemBuilder: (context, index) {
            final seller = _pendingSellers[index];
            final isSelected = _selectedSellerId == seller['id'];

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () => _viewSellerDetails(seller),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Avatar with initial
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.green[100],
                            child: Text(
                              seller['name']?[0]?.toUpperCase() ?? 'S',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Seller info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  seller['name'] ?? 'Unknown Seller',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  seller['email'] ?? 'No email',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withAlpha(20),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Requested: ${_formatDate(seller['sellerApprovalRequestedAt'])}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Action buttons
                          Column(
                            children: [
                              if (isSelected && _isActionInProgress)
                                const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              else ...[
                                IconButton(
                                  icon: const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                  onPressed: _isActionInProgress
                                      ? null
                                      : () => _approveSeller(seller['id']),
                                  tooltip: 'Approve',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                  ),
                                  onPressed: _isActionInProgress
                                      ? null
                                      : () => _rejectSeller(seller['id']),
                                  tooltip: 'Reject',
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      if (seller['phone'] != null) ...[
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              seller['phone'],
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value ?? 'Not provided'),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Unknown';
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return 'Unknown';
  }
}