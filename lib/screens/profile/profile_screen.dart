import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/farmer_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _farmSizeController = TextEditingController();
  String? _selectedRegion;
  List<String> _selectedCrops = [];
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().farmerProfile;
    if (profile != null) {
      _nameController.text = profile.name;
      _farmSizeController.text = profile.farmSize.toString();
      _selectedRegion = profile.region.isNotEmpty ? profile.region : null;
      _selectedCrops = List.from(profile.crops);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _farmSizeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.user?.uid ?? 'demo_user';

    final profile = FarmerModel(
      uid: uid,
      name: _nameController.text.trim().isEmpty
          ? 'Farmer'
          : _nameController.text.trim(),
      region: _selectedRegion ?? '',
      crops: _selectedCrops,
      farmSize: double.tryParse(_farmSizeController.text) ?? 0,
      language: context.read<AppProvider>().selectedLanguageCode,
      createdAt: DateTime.now(),
    );

    await authProvider.updateProfile(profile);
    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile saved!'),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final appProvider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text('profile_title'.tr(),
            style: const TextStyle(color: Colors.white)),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text('save',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppTheme.primary.withOpacity(0.15),
                        child: Text(
                          authProvider.displayName[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_isEditing)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 16),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    authProvider.displayName,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (authProvider.isAnonymous)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Guest Mode',
                        style: TextStyle(
                            color: Colors.orange, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Farm details
            _SectionCard(
              title: 'my_farm'.tr(),
              child: Column(
                children: [
                  _EditableField(
                    label: 'Name',
                    controller: _nameController,
                    isEditing: _isEditing,
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 12),
                  _EditableField(
                    label: 'Farm Size (acres)',
                    controller: _farmSizeController,
                    isEditing: _isEditing,
                    icon: Icons.landscape,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  if (_isEditing)
                    DropdownButtonFormField<String>(
                      value: _selectedRegion,
                      decoration: const InputDecoration(
                        labelText: 'Region',
                        prefixIcon: Icon(Icons.location_on,
                            color: AppTheme.primary, size: 18),
                      ),
                      items: AppConstants.regions
                          .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(r),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedRegion = v),
                    )
                  else
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on,
                          color: AppTheme.primary),
                      title: const Text('Region',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary)),
                      subtitle: Text(
                          _selectedRegion ?? 'Not set',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Crops
            _SectionCard(
              title: 'Crops I Grow',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.crops.map((crop) {
                      final selected = _selectedCrops.contains(crop);
                      return GestureDetector(
                        onTap: _isEditing
                            ? () {
                                setState(() {
                                  if (selected) {
                                    _selectedCrops.remove(crop);
                                  } else {
                                    _selectedCrops.add(crop);
                                  }
                                });
                              }
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppTheme.primary
                                  : const Color(0xFFE0E0E0),
                            ),
                          ),
                          child: Text(
                            crop.tr(),
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Language
            _SectionCard(
              title: 'language_pref'.tr(),
              child: Column(
                children: AppConstants.languages
                    .map(
                      (lang) => RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${lang['native']} (${lang['name']})'),
                        value: lang['code']!,
                        groupValue: appProvider.selectedLanguageCode,
                        activeColor: AppTheme.primary,
                        onChanged: (v) {
                          if (v != null) {
                            appProvider.setLanguage(context, v);
                          }
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Settings
            _SectionCard(
              title: 'Settings',
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('notifications'.tr()),
                    subtitle: const Text('Crop alerts & messages'),
                    value: appProvider.notificationsEnabled,
                    activeColor: AppTheme.primary,
                    onChanged: appProvider.toggleNotifications,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await context.read<AuthProvider>().signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout, color: AppTheme.error),
                label: Text('logout'.tr(),
                    style: const TextStyle(color: AppTheme.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _EditableField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isEditing;
  final IconData icon;
  final TextInputType? keyboardType;

  const _EditableField({
    required this.label,
    required this.controller,
    required this.isEditing,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    if (isEditing) {
      return TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 18),
        ),
      );
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(label,
          style: const TextStyle(
              fontSize: 12, color: AppTheme.textSecondary)),
      subtitle: Text(
          controller.text.isEmpty ? 'Not set' : controller.text,
          style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
