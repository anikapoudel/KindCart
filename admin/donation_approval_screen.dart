import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/donation_provider.dart';
import '../models/donation_model.dart';

class DonationApprovalScreen extends StatelessWidget {
  const DonationApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Donations'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Consumer<DonationProvider>(
        builder: (context, provider, child) {
          if (provider.pendingDonations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 80, color: Colors.green),
                  SizedBox(height: 16),
                  Text('No pending donations!'),
                  Text('All caught up.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.pendingDonations.length,
            itemBuilder: (ctx, index) {
              final donation = provider.pendingDonations[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple.shade100,
                    child: Text(donation.quantity.toString()),
                  ),
                  title: Text(donation.title),
                  subtitle:
                      Text('${donation.category} • ${donation.condition}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                              'Donor',
                              donation.isAnonymous
                                  ? 'Anonymous'
                                  : donation.donorName),
                          _buildDetailRow('Description', donation.description),
                          _buildDetailRow('Location', donation.location),
                          _buildContactRow(
                              'Contact', donation.contact, context),
                          _buildDetailRow('Urgency', donation.urgency),

                          // Show donor images if available
                          if (donation.donorImageUrls.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text('Donor Images:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 80,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: donation.donorImageUrls.length,
                                itemBuilder: (imgCtx, imgIndex) {
                                  return GestureDetector(
                                    onTap: () => _showFullImage(context,
                                        donation.donorImageUrls[imgIndex]),
                                    child: Container(
                                      width: 80,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: NetworkImage(donation
                                              .donorImageUrls[imgIndex]),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _showCompleteDialog(context, donation),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Mark Completed'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _showRejectDialog(context, donation),
                                  icon: const Icon(Icons.close),
                                  label: const Text('Reject'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
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
            },
          );
        },
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
              width: 100,
              child: Text('$label:',
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildContactRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 100,
              child: Text('$label:',
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
            child: Row(
              children: [
                Expanded(child: Text(value)),
                IconButton(
                  icon: const Icon(Icons.phone, color: Colors.green, size: 20),
                  onPressed: () => _makePhoneCall(value, context),
                  tooltip: 'Call',
                ),
                IconButton(
                  icon: const Icon(Icons.message, color: Colors.blue, size: 20),
                  onPressed: () => _sendMessage(value, context),
                  tooltip: 'Message',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Phone call function
  Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    // Ensure the number has a tel: prefix
    final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch phone dialer for $phoneNumber'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Send message function
  Future<void> _sendMessage(String phoneNumber, BuildContext context) async {
    // Remove any spaces or special characters, keep only digits and plus sign
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    // Create SMS URI
    final Uri smsUri = Uri(scheme: 'sms', path: cleanNumber);

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open messaging app for $phoneNumber'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

                // Show donor images for reference
                if (donation.donorImageUrls.isNotEmpty) ...[
                  const Text(
                    'Donor Images:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: donation.donorImageUrls.length,
                      itemBuilder: (imgCtx, imgIndex) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            _showFullImage(
                                context, donation.donorImageUrls[imgIndex]);
                          },
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(
                                    donation.donorImageUrls[imgIndex]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

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

                // Option to use one of the donor images as proof
                if (donation.donorImageUrls.isNotEmpty) ...[
                  const Text(
                    'Use donor image as proof:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children:
                        donation.donorImageUrls.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final url = entry.value;
                      return ChoiceChip(
                        label: Text('Image ${idx + 1}'),
                        selected: imageController.text == url,
                        onSelected: (selected) {
                          setState(() {
                            imageController.text = selected ? url : '';
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                TextField(
                  controller: imageController,
                  decoration: InputDecoration(
                    labelText: 'Proof Image URL (optional)',
                    hintText: donation.donorImageUrls.isNotEmpty
                        ? 'Select from above or enter URL'
                        : 'Enter Firebase Storage URL',
                    border: const OutlineInputBorder(),
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

                      final provider =
                          Provider.of<DonationProvider>(context, listen: false);

                      // Use donor image as proof if none provided
                      String? proofUrl = imageController.text.isNotEmpty
                          ? imageController.text
                          : (donation.donorImageUrls.isNotEmpty
                              ? donation.donorImageUrls.first
                              : null);

                      await provider.completeDonation(
                        donationId: donation.id,
                        proofImageUrl: proofUrl,
                        recipientInfo: recipientController.text,
                      );
                      await provider.loadAllDonations();

                      if (ctx.mounted) Navigator.pop(ctx);

                      if (!context.mounted) return;

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
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
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

                      final provider =
                          Provider.of<DonationProvider>(context, listen: false);
                      await provider.rejectDonation(
                          donation.id, reasonController.text);
                      await provider.loadAllDonations();

                      if (ctx.mounted) Navigator.pop(ctx);

                      if (!context.mounted) return;

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
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Reject'),
            ),
          ],
        ),
      ),
    );
  }

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
}
