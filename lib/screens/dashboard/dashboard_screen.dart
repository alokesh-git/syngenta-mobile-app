import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/farmer_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FarmerProvider>().loadNearbyFarmers();
    });
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'good_morning'.tr();
    if (hour < 17) return 'good_afternoon'.tr();
    return 'good_evening'.tr();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final farmerProvider = context.watch<FarmerProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryDark, AppTheme.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _greeting(),
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 14),
                    ),
                    Text(
                      authProvider.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.language, color: Colors.white),
                onPressed: () => _showLanguagePicker(context),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Row
                  Row(
                    children: [
                      _StatCard(
                        label: 'nearby_farmers'.tr(),
                        value: '${farmerProvider.nearbyCount}',
                        icon: Icons.people,
                        color: AppTheme.primary,
                        onTap: () => context.read<AppProvider>().setTab(1),
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'active_alerts'.tr(),
                        value: '3',
                        icon: Icons.warning_amber,
                        color: AppTheme.warning,
                        onTap: () {},
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'ai_insight'.tr(),
                        value: 'New',
                        icon: Icons.auto_awesome,
                        color: AppTheme.accent,
                        onTap: () => context.read<AppProvider>().setTab(3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Crop Alerts
                  _SectionHeader(
                    title: 'active_alerts'.tr(),
                    onSeeAll: () {},
                  ),
                  const SizedBox(height: 12),
                  _CropAlertCard(
                    crop: 'Rice',
                    region: 'Punjab & UP',
                    alert: 'Blast Disease',
                    urgency: 'CRITICAL',
                    urgencyColor: AppTheme.critical,
                    product: 'SCORE® (Difenoconazole)',
                    icon: '🌾',
                  ),
                  const SizedBox(height: 8),
                  _CropAlertCard(
                    crop: 'Cotton',
                    region: 'Maharashtra & AP',
                    alert: 'Bollworm Infestation',
                    urgency: 'HIGH',
                    urgencyColor: AppTheme.warning,
                    product: 'KARATE® ZEON',
                    icon: '🌿',
                  ),
                  const SizedBox(height: 8),
                  _CropAlertCard(
                    crop: 'Wheat',
                    region: 'Haryana',
                    alert: 'Rust Disease',
                    urgency: 'MEDIUM',
                    urgencyColor: AppTheme.accent,
                    product: 'AMISTAR® Top',
                    icon: '🌱',
                  ),
                  const SizedBox(height: 20),

                  // Quick Actions
                  _SectionHeader(title: 'quick_campaign'.tr(), onSeeAll: null),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.auto_awesome,
                          label: 'Generate\nCampaign',
                          color: AppTheme.primary,
                          onTap: () =>
                              context.read<AppProvider>().setTab(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.people,
                          label: 'Find\nFarmers',
                          color: AppTheme.accent,
                          onTap: () =>
                              context.read<AppProvider>().setTab(1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.chat_bubble,
                          label: 'Start\nChat',
                          color: const Color(0xFF1565C0),
                          onTap: () =>
                              context.read<AppProvider>().setTab(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.cloud,
                          label: 'Weather\nUpdate',
                          color: const Color(0xFF00838F),
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Nearby Farmers Preview
                  _SectionHeader(
                    title: 'nearby_farmers'.tr(),
                    onSeeAll: () => context.read<AppProvider>().setTab(1),
                  ),
                  const SizedBox(height: 12),
                  if (farmerProvider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    SizedBox(
                      height: 160,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: farmerProvider.farmers.take(5).length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final farmer =
                              farmerProvider.farmers.take(5).toList()[i];
                          return _FarmerMiniCard(farmer: farmer);
                        },
                      ),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _LanguagePicker(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
                padding: EdgeInsets.zero, minimumSize: Size.zero),
            child: Text('see_all'.tr(),
                style: const TextStyle(color: AppTheme.primary)),
          ),
      ],
    );
  }
}

class _CropAlertCard extends StatelessWidget {
  final String crop;
  final String region;
  final String alert;
  final String urgency;
  final Color urgencyColor;
  final String product;
  final String icon;

  const _CropAlertCard({
    required this.crop,
    required this.region,
    required this.alert,
    required this.urgency,
    required this.urgencyColor,
    required this.product,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: urgencyColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$crop — $alert',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: urgencyColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        urgency,
                        style: TextStyle(
                            color: urgencyColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(region,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
                Text(
                  '💊 $product',
                  style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmerMiniCard extends StatelessWidget {
  final dynamic farmer;
  const _FarmerMiniCard({required this.farmer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                radius: 18,
                backgroundColor: AppTheme.primary.withOpacity(0.15),
                child: Text(
                  farmer.name[0].toUpperCase(),
                  style: const TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              if (farmer.isOnline)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.success,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            farmer.name,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            farmer.state,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 11),
          ),
          const Spacer(),
          Text(
            farmer.distanceKm != null
                ? '${farmer.distanceKm!.toStringAsFixed(1)} km'
                : '',
            style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker();

  @override
  Widget build(BuildContext context) {
    final languages = [
      {'code': 'en', 'name': 'English', 'native': 'English'},
      {'code': 'hi', 'name': 'Hindi', 'native': 'हिंदी'},
      {'code': 'ta', 'name': 'Tamil', 'native': 'தமிழ்'},
      {'code': 'te', 'name': 'Telugu', 'native': 'తెలుగు'},
      {'code': 'mr', 'name': 'Marathi', 'native': 'मराठी'},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Language',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...languages.map(
            (lang) => ListTile(
              leading: Text(
                lang['native']!,
                style: const TextStyle(fontSize: 18),
              ),
              title: Text(lang['name']!),
              onTap: () async {
                await context
                    .read<AppProvider>()
                    .setLanguage(context, lang['code']!);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
