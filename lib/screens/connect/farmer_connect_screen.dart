import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/farmer_model.dart';
import '../../providers/farmer_provider.dart';
import '../../providers/auth_provider.dart';

import '../chat/chat_screen.dart';

class FarmerConnectScreen extends StatefulWidget {
  const FarmerConnectScreen({super.key});

  @override
  State<FarmerConnectScreen> createState() => _FarmerConnectScreenState();
}

class _FarmerConnectScreenState extends State<FarmerConnectScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FarmerProvider>().loadNearbyFarmers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final farmerProvider = context.watch<FarmerProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('farmer_connect_title'.tr(),
                style: const TextStyle(color: Colors.white, fontSize: 18)),
            Text('farmer_connect_sub'.tr(),
                style: TextStyle(
                    color: Colors.white.withOpacity(0.8), fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () =>
                context.read<FarmerProvider>().loadNearbyFarmers(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Crop filter chips
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CropChip(
                    label: 'all_crops'.tr(),
                    isSelected: farmerProvider.selectedCrop == null,
                    onTap: () =>
                        context.read<FarmerProvider>().filterByCrop(null),
                  ),
                  const SizedBox(width: 8),
                  ...AppConstants.crops.map((crop) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _CropChip(
                          label: crop.tr(),
                          isSelected:
                              farmerProvider.selectedCrop == crop,
                          onTap: () => context
                              .read<FarmerProvider>()
                              .filterByCrop(crop),
                        ),
                      )),
                ],
              ),
            ),
          ),

          // Farmer count
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.location_on,
                    size: 16, color: AppTheme.primary),
                const SizedBox(width: 4),
                Text(
                  '${farmerProvider.farmers.length} ${'farmer'.tr()}s nearby',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),

          // Farmer list
          Expanded(
            child: farmerProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : farmerProvider.farmers.isEmpty
                    ? Center(
                        child: Text('no_farmers_found'.tr(),
                            style: const TextStyle(
                                color: AppTheme.textSecondary)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        itemCount: farmerProvider.farmers.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          return _FarmerCard(
                            farmer: farmerProvider.farmers[i],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _CropChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CropChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFE0E0E0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _FarmerCard extends StatelessWidget {
  final FarmerModel farmer;
  const _FarmerCard({required this.farmer});

  @override
  Widget build(BuildContext context) {
    final myUid = context.read<AuthProvider>().user?.uid ?? 'demo_user';
    final myName = context.read<AuthProvider>().displayName;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primary.withOpacity(0.15),
                child: Text(
                  farmer.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          farmer.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: farmer.isOnline
                                ? AppTheme.success
                                : Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${farmer.region}, ${farmer.state}',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (farmer.distanceKm != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Icon(Icons.location_on,
                        size: 14, color: AppTheme.primary),
                    Text(
                      '${farmer.distanceKm!.toStringAsFixed(1)} km',
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Crops
          if (farmer.crops.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: farmer.crops
                  .map((c) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  AppTheme.primaryLight.withOpacity(0.5)),
                        ),
                        child: Text(
                          c.tr(),
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],

          // Farm size
          if (farmer.farmSize > 0)
            Text(
              '🌾 Farm: ${farmer.farmSize.toStringAsFixed(1)} acres',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12),
            ),
          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _sendHelpRequest(context, farmer),
                  icon: const Icon(Icons.handshake_outlined, size: 16),
                  label: Text('help_request'.tr(),
                      style: const TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openChat(context, farmer, myUid, myName),
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: Text('send_message'.tr(),
                      style: const TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sendHelpRequest(BuildContext context, FarmerModel farmer) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Help Request'),
        content: Text(
            'Send a help request to ${farmer.name}?\n\nThis will notify them that you need assistance.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Help request sent to ${farmer.name}!'),
                backgroundColor: AppTheme.primary,
              ));
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _openChat(BuildContext context, FarmerModel farmer,
      String myUid, String myName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatRoomId: '${myUid}_${farmer.uid}',
          otherFarmer: farmer,
        ),
      ),
    );
  }
}
