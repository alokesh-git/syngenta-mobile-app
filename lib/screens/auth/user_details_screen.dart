import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_locale.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/user_store.dart';
import '../../router.dart';

class UserDetailsScreen extends StatefulWidget {
  /// When true, opens in edit mode (with back button + Save instead of redirect)
  final bool isEdit;
  const UserDetailsScreen({super.key, this.isEdit = false});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _whatsappController;
  late String _language;

  @override
  void initState() {
    super.initState();
    final store = UserStore.instance;
    _nameController = TextEditingController(text: store.name);
    _whatsappController = TextEditingController(
        text: store.whatsappNumber.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^91'), ''));
    _language = store.language.isEmpty ? 'English' : store.language;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    await UserStore.instance.saveProfile(
      name: _nameController.text,
      whatsappNumber: '+91 ${_whatsappController.text.trim()}',
      language: _language,
    );
    if (mounted) {
      await context.setLocale(AppLocale.fromName(_language));
    }

    if (!mounted) return;
    if (widget.isEdit) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('profile_updated'.tr()),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.homeScreen,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.isEdit;
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF7),
      body: Stack(
        children: [
          // Decorative blobs
          Positioned(
            top: -60,
            left: -60,
            child: _blob(220, AppTheme.primaryLight.withValues(alpha: 0.25)),
          ),
          Positioned(
            top: -40,
            right: -50,
            child: _blob(160, AppTheme.accentLight.withValues(alpha: 0.25)),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isEdit)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      )
                    else
                      const SizedBox(height: 20),

                    // Hero avatar with sparkles
                    Center(
                      child: SizedBox(
                        width: 200,
                        height: 160,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Sparkles
                            const Positioned(
                              top: 10, left: 20,
                              child: Icon(Icons.auto_awesome, size: 14, color: AppTheme.primary),
                            ),
                            Positioned(
                              top: 14, right: 28,
                              child: Icon(Icons.circle, size: 10, color: AppTheme.accent),
                            ),
                            const Positioned(
                              bottom: 30, left: 18,
                              child: Icon(Icons.circle, size: 8, color: AppTheme.primaryLight),
                            ),
                            const Positioned(
                              bottom: 16, right: 18,
                              child: Icon(Icons.auto_awesome, size: 12, color: AppTheme.primaryDark),
                            ),

                            // Avatar circle
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_outline,
                                  size: 56, color: AppTheme.primary),
                            ),

                            // Check badge
                            Positioned(
                              bottom: 24,
                              right: 38,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFF6FBF7), width: 3),
                                ),
                                child: const Icon(Icons.check, size: 14, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Center(
                      child: Text(
                        isEdit ? 'edit_profile_title'.tr() : 'complete_profile_title'.tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        'personalize_sub'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Form card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('full_name'.tr()),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration:
                                _decoration(Icons.person_outline, 'enter_full_name'.tr()),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'name_required'.tr()
                                : null,
                          ),

                          const SizedBox(height: 18),

                          _label('whatsapp_number'.tr()),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 14),
                                  child: Row(
                                    children: [
                                      const Text('+91',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                          )),
                                      const SizedBox(width: 4),
                                      Icon(Icons.keyboard_arrow_down,
                                          color: AppTheme.textSecondary, size: 20),
                                    ],
                                  ),
                                ),
                                Container(
                                    width: 1, height: 28, color: Colors.grey.shade300),
                                Expanded(
                                  child: TextFormField(
                                    controller: _whatsappController,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    decoration: InputDecoration(
                                      hintText: 'whatsapp_hint'.tr(),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      focusedErrorBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 16),
                                    ),
                                    style: const TextStyle(fontSize: 15),
                                    validator: (v) {
                                      if (v == null || v.trim().length != 10) {
                                        return 'whatsapp_invalid'.tr();
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          _label('preferred_language'.tr()),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButtonFormField<String>(
                                initialValue: _language,
                                icon: const Icon(Icons.keyboard_arrow_down),
                                decoration: const InputDecoration(
                                  prefixIcon:
                                      Icon(Icons.language, color: AppTheme.primary),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                                ),
                                items: AppConstants.languages.map((lang) {
                                  return DropdownMenuItem<String>(
                                    value: lang['name'],
                                    child: Row(
                                      children: [
                                        Text(lang['native']!,
                                            style: const TextStyle(fontSize: 16)),
                                        const SizedBox(width: 10),
                                        Text(lang['name']!,
                                            style: TextStyle(
                                                color: AppTheme.textSecondary)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) =>
                                    setState(() => _language = v ?? 'English'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Continue button with gradient
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.primaryLight],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            isEdit ? 'save_changes'.tr() : 'continue_btn'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_user_outlined,
                              size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'secure_private'.tr(),
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      );

  InputDecoration _decoration(IconData icon, String hint) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppTheme.primary),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
    );
  }
}
