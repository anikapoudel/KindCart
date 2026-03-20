import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/donation_provider.dart';
import '../models/donation_model.dart';

class DonationManagementScreen extends StatefulWidget {
  const DonationManagementScreen({Key? key}) : super(key: key);

  @override
  State<DonationManagementScreen> createState() => _DonationManagementScreenState();
}

class _DonationManagementScreenState extends State<DonationManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  // Filter controllers
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _categoryFilter;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllDonations();
    });
  }

  Future<void> _loadAllDonations() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<DonationProvider>(context, listen: false);
    await provider.loadAllDonations();
    if (mounted) {
      setState(() => _isLoading = false);
    }
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
        title: const Text(
          'Donation Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.hourglass_empty), text: 'Pending'),
            Tab(icon: Icon(Icons.thumb_up), text: 'Approved'),
            Tab(icon: Icon(Icons.check_circle), text: 'Completed'),
            Tab(icon: Icon(Icons.cancel), text: 'Rejected'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAll,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _forceSync,
            tooltip: 'Force Sync',
          ),
        ],
      ),

      body: Column(
        children: [
          // Search and Filter Bar
          _buildSearchFilterBar(),

          // Stats Summary
          _buildStatsSummary(),

          // Loading indicator
          if (_isLoading)
            const LinearProgressIndicator(
              backgroundColor: Colors.deepPurple,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPendingTab(),
                _buildApprovedTab(),
                _buildCompletedTab(),
                _buildRejectedTab(),
              ],
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQuickStats,
        icon: const Icon(Icons.analytics),
        label: const Text('Stats'),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }

  // SEARCH & FILTER BAR
  Widget _buildSearchFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by title, donor, location...',
              prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value.toLowerCase());
            },
          ),

          const SizedBox(height: 12),

          Container(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                FilterChip(
                  label: const Text('All Categories'),
                  selected: _categoryFilter == null,
                  onSelected: (_) {
                    setState(() => _categoryFilter = null);
                  },
                  backgroundColor: Colors.white,
                  selectedColor: Colors.deepPurple.shade100,
                  checkmarkColor: Colors.deepPurple,
                ),
                const SizedBox(width: 8),
                ...['Clothing', 'Books', 'Toys', 'Kitchenware', 'Electronics', 'Furniture', 'Food', 'Other']
                    .map((category) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: _categoryFilter == category,
                    onSelected: (selected) {
                      setState(() => _categoryFilter = selected ? category : null);
                    },
                    backgroundColor: Colors.white,
                    selectedColor: Colors.deepPurple.shade100,
                    checkmarkColor: Colors.deepPurple,
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //  STATS SUMMARY
  Widget _buildStatsSummary() {
    return Consumer<DonationProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          color: Colors.deepPurple.shade50,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip(
                  label: 'Pending',
                  count: provider.pendingDonations.length,
                  icon: Icons.hourglass_empty,
                  color: Colors.orange,
                  isSelected: _selectedIndex == 0,
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  label: 'Approved',
                  count: provider.approvedDonations.length,
                  icon: Icons.thumb_up,
                  color: Colors.blue,
                  isSelected: _selectedIndex == 1,
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  label: 'Completed',
                  count: provider.completedDonations.length,
                  icon: Icons.check_circle,
                  color: Colors.green,
                  isSelected: _selectedIndex == 2,
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  label: 'Rejected',
                  count: provider.rejectedDonations.length,
                  icon: Icons.cancel,
                  color: Colors.red,
                  isSelected: _selectedIndex == 3,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatChip({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? color.withAlpha(26) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? color : Colors.transparent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: $count',
            style: TextStyle(
              color: isSelected ? color : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  //  PENDING TAB
  Widget _buildPendingTab() {
    return Consumer<DonationProvider>(
      builder: (context, provider, child) {
        final pending = provider.pendingDonations;

        if (pending.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline,
            title: 'No Pending Donations',
            message: 'All donations have been reviewed',
            color: Colors.orange,
          );
        }

        final filtered = _filterDonations(pending);

        return RefreshIndicator(
          onRefresh: _loadAllDonations,
          color: Colors.deepPurple,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (ctx, index) {
              final donation = filtered[index];
              return _buildDonationCard(
                donation: donation,
                statusColor: Colors.orange,
                statusIcon: Icons.hourglass_empty,
                actions: [
                  ElevatedButton.icon(
                    onPressed: () => _showDonorDetailsDialog(context, donation),
                    icon: const Icon(Icons.person, size: 16),
                    label: const Text('View Donor'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(100, 36),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showQuickApproveDialog(context, donation),
                    icon: const Icon(Icons.thumb_up, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(100, 36),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(context, donation),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      minimumSize: const Size(100, 36),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  //  APPROVED TAB
  Widget _buildApprovedTab() {
    return Consumer<DonationProvider>(
      builder: (context, provider, child) {
        final approved = provider.approvedDonations;

        if (approved.isEmpty) {
          return _buildEmptyState(
            icon: Icons.thumb_up,
            title: 'No Approved Donations',
            message: 'Approved donations waiting to be completed will appear here',
            color: Colors.blue,
          );
        }

        final filtered = _filterDonations(approved);

        return RefreshIndicator(
          onRefresh: _loadAllDonations,
          color: Colors.deepPurple,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (ctx, index) {
              final donation = filtered[index];
              return _buildDonationCard(
                donation: donation,
                statusColor: Colors.blue,
                statusIcon: Icons.thumb_up,
                actions: [
                  ElevatedButton.icon(
                    onPressed: () => _showDonorDetailsDialog(context, donation),
                    icon: const Icon(Icons.person, size: 16),
                    label: const Text('Donor'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, 36),
                    ),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton.icon(
                    onPressed: () => _showCompleteDialog(context, donation),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(100, 36),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  //  COMPLETED TAB
  Widget _buildCompletedTab() {
    return Consumer<DonationProvider>(
      builder: (context, provider, child) {
        final completed = provider.completedDonations;

        if (completed.isEmpty) {
          return _buildEmptyState(
            icon: Icons.emoji_events,
            title: 'No Completed Donations',
            message: 'Completed donations will appear here',
            color: Colors.green,
          );
        }

        final filtered = _filterDonations(completed);

        return RefreshIndicator(
          onRefresh: _loadAllDonations,
          color: Colors.deepPurple,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (ctx, index) {
              final donation = filtered[index];
              return _buildDonationCard(
                donation: donation,
                statusColor: Colors.green,
                statusIcon: Icons.check_circle,
                showProof: true,
                actions: [
                  OutlinedButton.icon(
                    onPressed: () => _viewImpactStory(context, donation),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Story'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                      minimumSize: const Size(120, 36),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  //  REJECTED TAB
  Widget _buildRejectedTab() {
    return Consumer<DonationProvider>(
      builder: (context, provider, child) {
        final rejected = provider.rejectedDonations;

        if (rejected.isEmpty) {
          return _buildEmptyState(
            icon: Icons.cancel,
            title: 'No Rejected Donations',
            message: 'Rejected donations will appear here with reasons',
            color: Colors.red,
          );
        }

        final filtered = _filterDonations(rejected);

        return RefreshIndicator(
          onRefresh: _loadAllDonations,
          color: Colors.deepPurple,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (ctx, index) {
              final donation = filtered[index];
              return _buildDonationCard(
                donation: donation,
                statusColor: Colors.red,
                statusIcon: Icons.cancel,
                actions: const [],
              );
            },
          ),
        );
      },
    );
  }

  //  DONATION CARD
  Widget _buildDonationCard({
    required DonationModel donation,
    required Color statusColor,
    required IconData statusIcon,
    List<Widget>? actions,
    bool showProof = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showDonorDetailsDialog(context, donation),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Donor images preview
                  if (donation.donorImageUrls.isNotEmpty)
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(donation.donorImageUrls.first),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) {},
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCategoryIcon(donation.category),
                        color: statusColor,
                        size: 24,
                      ),
                    ),
                  const SizedBox(width: 12),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                donation.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withAlpha(26),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, size: 10, color: statusColor),
                                  const SizedBox(width: 2),
                                  Text(
                                    donation.status.toString().split('.').last,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Donor info
                        Row(
                          children: [
                            Icon(Icons.person, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                donation.isAnonymous ? 'Anonymous Donor' : donation.donorName,
                                style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),

                        // Category & Quantity
                        Row(
                          children: [
                            Icon(Icons.category, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                '${donation.category} • ${donation.quantity} items • ${donation.condition}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),

                        // Location
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                donation.location,
                                style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        // Urgency indicator
                        Row(
                          children: [
                            Icon(
                              _getUrgencyIcon(donation.urgency),
                              size: 12,
                              color: _getUrgencyColor(donation.urgency),
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                donation.urgency,
                                style: TextStyle(
                                  color: _getUrgencyColor(donation.urgency),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        // Image count indicator
                        if (donation.donorImageUrls.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                Icon(Icons.image, size: 10, color: Colors.deepPurple[300]),
                                const SizedBox(width: 2),
                                Text(
                                  '${donation.donorImageUrls.length} image${donation.donorImageUrls.length > 1 ? 's' : ''}',
                                  style: TextStyle(color: Colors.deepPurple[300], fontSize: 9),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons
            if (actions != null && actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  //  DONOR DETAILS DIALOG
  void _showDonorDetailsDialog(BuildContext context, DonationModel donation) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        donation.donorName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            donation.isAnonymous ? 'Anonymous Donor' : donation.donorName,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Donor ID: ${donation.donorId.substring(0, 8)}...',
                            style: TextStyle(color: Colors.white.withAlpha(179), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
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
                      // Donor Images Section
                      if (donation.donorImageUrls.isNotEmpty) ...[
                        const Text(
                          'Donation Images',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 150,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: donation.donorImageUrls.length,
                            itemBuilder: (imgCtx, imgIndex) {
                              return GestureDetector(
                                onTap: () => _showFullImage(context, donation.donorImageUrls[imgIndex]),
                                child: Container(
                                  width: 120,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: NetworkImage(donation.donorImageUrls[imgIndex]),
                                      fit: BoxFit.cover,
                                      onError: (exception, stackTrace) {},
                                    ),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.black12,
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.image, color: Colors.white54, size: 30),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                      ],

                      // Contact Information
                      const Text(
                        'Contact Information',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoTile(
                        icon: Icons.person_outline,
                        label: 'Donor Name',
                        value: donation.isAnonymous ? 'Anonymous' : donation.donorName,
                      ),
                      _buildInfoTile(
                        icon: Icons.phone,
                        label: 'Contact Number',
                        value: donation.contact,
                        isContact: true,
                      ),
                      _buildInfoTile(
                        icon: Icons.location_on,
                        label: 'Location',
                        value: donation.location,
                      ),

                      const SizedBox(height: 16),
                      const Divider(),

                      // Donation Details
                      const Text(
                        'Donation Details',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoTile(
                        icon: Icons.category,
                        label: 'Category',
                        value: donation.category,
                      ),
                      _buildInfoTile(
                        icon: Icons.label,
                        label: 'Title',
                        value: donation.title,
                      ),
                      _buildInfoTile(
                        icon: Icons.description,
                        label: 'Description',
                        value: donation.description,
                      ),
                      _buildInfoTile(
                        icon: Icons.production_quantity_limits,
                        label: 'Quantity',
                        value: '${donation.quantity} items',
                      ),
                      _buildInfoTile(
                        icon: Icons.assignment,
                        label: 'Condition',
                        value: donation.condition,
                      ),

                      const SizedBox(height: 16),
                      const Divider(),

                      // Additional Details
                      const Text(
                        'Additional Information',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoTile(
                        icon: Icons.access_time,
                        label: 'Urgency',
                        value: donation.urgency,
                        valueColor: _getUrgencyColor(donation.urgency),
                      ),
                      _buildInfoTile(
                        icon: Icons.calendar_today,
                        label: 'Submitted On',
                        value: _formatDateTime(donation.createdAt),
                      ),
                      _buildInfoTile(
                        icon: donation.canPickup ? Icons.check_circle : Icons.cancel,
                        label: 'Can Pickup',
                        value: donation.canPickup ? 'Yes' : 'No',
                        valueColor: donation.canPickup ? Colors.green : Colors.red,
                      ),
                      _buildInfoTile(
                        icon: donation.canDeliver ? Icons.check_circle : Icons.cancel,
                        label: 'Can Deliver',
                        value: donation.canDeliver ? 'Yes' : 'No',
                        valueColor: donation.canDeliver ? Colors.green : Colors.red,
                      ),

                      // Clothing specific details
                      if (donation.category == 'Clothing') ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const Text(
                          'Clothing Details',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (donation.brand != null)
                          _buildInfoTile(
                            icon: Icons.branding_watermark,
                            label: 'Brand',
                            value: donation.brand!,
                          ),
                        if (donation.size != null)
                          _buildInfoTile(
                            icon: Icons.straighten,
                            label: 'Size',
                            value: donation.size!,
                          ),
                        if (donation.color != null)
                          _buildInfoTile(
                            icon: Icons.color_lens,
                            label: 'Color',
                            value: donation.color!,
                          ),
                        if (donation.gender != null)
                          _buildInfoTile(
                            icon: Icons.people,
                            label: 'Gender',
                            value: donation.gender!,
                          ),
                      ],

                      // Rejection reason if any
                      if (donation.rejectionReason != null) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Rejection Reason',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                donation.rejectionReason!,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Admin actions
                      const SizedBox(height: 20),
                      if (donation.status == DonationStatus.pending)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _showQuickApproveDialog(context, donation);
                                },
                                icon: const Icon(Icons.thumb_up),
                                label: const Text('Approve'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _showRejectDialog(context, donation);
                                },
                                icon: const Icon(Icons.close),
                                label: const Text('Reject'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for info tiles
  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isContact = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.deepPurple[300]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isContact ? FontWeight.bold : FontWeight.normal,
                          color: valueColor ?? (isContact ? Colors.blue : Colors.black87),
                        ),
                      ),
                    ),
                    if (isContact)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.phone, size: 18, color: Colors.green),
                            onPressed: () => _makePhoneCall(value),
                            tooltip: 'Call',
                          ),
                          IconButton(
                            icon: const Icon(Icons.message, size: 18, color: Colors.blue),
                            onPressed: () => _sendMessage(value),
                            tooltip: 'Message',
                          ),
                        ],
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

  // Show full image
  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.error, color: Colors.white, size: 50),
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
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //  EMPTY STATE
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: color.withAlpha(77)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                message,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //  DIALOGS

  void _showQuickApproveDialog(BuildContext context, DonationModel donation) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Donation'),
        content: Text('Approve "${donation.title}" from ${donation.donorName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = Provider.of<DonationProvider>(context, listen: false);
              await provider.approveDonation(donation.id);
              await provider.loadAllDonations();

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${donation.title} approved'),
                  backgroundColor: Colors.green,
                ),
              );

              _showContactInfo(context, donation);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showContactInfo(BuildContext context, DonationModel donation) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Contact Donor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact ${donation.isAnonymous ? 'Anonymous Donor' : donation.donorName}:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text('Phone'),
              subtitle: Text(donation.contact),
              onTap: () {
                Navigator.pop(ctx);
                _makePhoneCall(donation.contact);
              },
            ),
            ListTile(
              leading: const Icon(Icons.message, color: Colors.blue),
              title: const Text('Message'),
              subtitle: Text(donation.contact),
              onTap: () {
                Navigator.pop(ctx);
                _sendMessage(donation.contact);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(BuildContext context, DonationModel donation) {
    final imageController = TextEditingController();
    final recipientController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Complete Donation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Mark "${donation.title}" as completed'),
                const SizedBox(height: 16),
                TextField(
                  controller: recipientController,
                  decoration: const InputDecoration(
                    labelText: 'Recipient Info *',
                    hintText: 'e.g., Donated to Children\'s Home, Mumbai',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: imageController,
                  decoration: const InputDecoration(
                    labelText: 'Photo URL',
                    hintText: 'Firebase Storage URL (optional)',
                    border: OutlineInputBorder(),
                  ),
                  enabled: !isLoading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                if (recipientController.text.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter recipient info'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                setState(() => isLoading = true);

                final provider = Provider.of<DonationProvider>(context, listen: false);
                await provider.completeDonation(
                  donationId: donation.id,
                  proofImageUrl: imageController.text,
                  recipientInfo: recipientController.text,
                );
                await provider.loadAllDonations();

                if (ctx.mounted) Navigator.pop(ctx);

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${donation.title} marked completed!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Text('Complete'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, DonationModel donation) {
    final reasonController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Reject Donation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Reject "${donation.title}" from ${donation.donorName}?'),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason for rejection *',
                    hintText: 'e.g., Items not in good condition',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  enabled: !isLoading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                if (reasonController.text.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Please provide a reason'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                setState(() => isLoading = true);

                final provider = Provider.of<DonationProvider>(context, listen: false);
                await provider.rejectDonation(donation.id, reasonController.text);
                await provider.loadAllDonations();

                if (ctx.mounted) Navigator.pop(ctx);

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${donation.title} rejected'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Text('Reject'),
            ),
          ],
        ),
      ),
    );
  }

  void _viewImpactStory(BuildContext context, DonationModel donation) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (donation.proofImageUrl != null && donation.proofImageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  donation.proofImageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: Colors.deepPurple[100],
                    child: const Center(child: Icon(Icons.image, size: 40, color: Colors.deepPurple)),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    donation.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow('Donor', donation.isAnonymous ? 'Anonymous' : donation.donorName),
                  _buildDetailRow('Category', donation.category),
                  _buildDetailRow('Quantity', '${donation.quantity} items'),
                  _buildDetailRow('Location', donation.location),
                  const Divider(height: 16),
                  const Text('Impact:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(donation.recipientInfo ?? 'N/A'),
                  const SizedBox(height: 4),
                  Text(
                    'Completed on: ${_formatDateTime(donation.completedAt ?? donation.createdAt)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Close'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickStats() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Donation Statistics'),
        content: Consumer<DonationProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatRow('Pending', provider.pendingDonations.length, Colors.orange),
                  _buildStatRow('Approved', provider.approvedDonations.length, Colors.blue),
                  _buildStatRow('Completed', provider.completedDonations.length, Colors.green),
                  _buildStatRow('Rejected', provider.rejectedDonations.length, Colors.red),
                  const Divider(height: 16),
                  const Text('Categories:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildStatRow('Clothing', _countByCategory(provider, 'Clothing'), Colors.purple),
                  _buildStatRow('Books', _countByCategory(provider, 'Books'), Colors.blue),
                  _buildStatRow('Toys', _countByCategory(provider, 'Toys'), Colors.orange),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Force Sync
  Future<void> _forceSync() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<DonationProvider>(context, listen: false);
    await provider.loadAllDonations();
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data synced successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Refresh all data
  Future<void> _refreshAll() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<DonationProvider>(context, listen: false);
    await provider.loadAllDonations();

    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Donations refreshed'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }

  //  HELPER FUNCTIONS

  List<DonationModel> _filterDonations(List<DonationModel> donations) {
    return donations.where((d) {
      final matchesSearch = _searchQuery.isEmpty ||
          d.title.toLowerCase().contains(_searchQuery) ||
          d.donorName.toLowerCase().contains(_searchQuery) ||
          d.location.toLowerCase().contains(_searchQuery) ||
          (d.recipientInfo?.toLowerCase().contains(_searchQuery) ?? false);

      final matchesCategory = _categoryFilter == null || d.category == _categoryFilter;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  int _countByCategory(DonationProvider provider, String category) {
    int count = 0;
    count += provider.pendingDonations.where((d) => d.category == category).length;
    count += provider.approvedDonations.where((d) => d.category == category).length;
    count += provider.completedDonations.where((d) => d.category == category).length;
    count += provider.rejectedDonations.where((d) => d.category == category).length;
    return count;
  }

  Widget _buildStatRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 13)),
            ],
          ),
          Text(
            '$count',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 65,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
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

  Color _getUrgencyColor(String urgency) {
    if (urgency.contains('Immediate')) return Colors.red;
    if (urgency.contains('Urgent')) return Colors.orange;
    if (urgency.contains('Normal')) return Colors.blue;
    return Colors.green;
  }

  IconData _getUrgencyIcon(String urgency) {
    if (urgency.contains('Immediate')) return Icons.warning;
    if (urgency.contains('Urgent')) return Icons.access_time;
    if (urgency.contains('Normal')) return Icons.event;
    return Icons.event_available;
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Phone call function
  void _makePhoneCall(String phoneNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $phoneNumber...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Send message function
  void _sendMessage(String phoneNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening messenger for $phoneNumber...'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}