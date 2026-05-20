import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/campaign_model.dart';
import '../../services/ai_campaign_service.dart';

class AICampaignScreen extends StatefulWidget {
  const AICampaignScreen({super.key});

  @override
  State<AICampaignScreen> createState() => _AICampaignScreenState();
}

class _AICampaignScreenState extends State<AICampaignScreen> {
  String? _selectedCrop;
  String? _selectedRegion;
  String? _selectedStage;
  String? _selectedPest;
  String? _selectedLanguage = 'en';
  String? _selectedChannel = 'whatsapp';

  CampaignOutput? _result;
  bool _isGenerating = false;

  Future<void> _generateCampaign() async {
    if (_selectedCrop == null ||
        _selectedRegion == null ||
        _selectedStage == null ||
        _selectedPest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields to generate campaign'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _result = null;
    });

    // Simulate AI processing delay
    await Future.delayed(const Duration(milliseconds: 1800));

    final output = AICampaignService.generateCampaign(
      CampaignInput(
        crop: _selectedCrop!,
        region: _selectedRegion!,
        growthStage: _selectedStage!,
        pestAlert: _selectedPest!,
        language: _selectedLanguage!,
        channel: _selectedChannel!,
      ),
    );

    setState(() {
      _result = output;
      _isGenerating = false;
    });

    // Scroll to results
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('campaign_title'.tr(),
                style: const TextStyle(color: Colors.white, fontSize: 18)),
            Text('AI-Powered • 5 Languages • Real-time',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.8), fontSize: 11)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text('AI', style: TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryDark, AppTheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Campaign Generator',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Generate context-aware marketing content for any crop, region, and language',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Form
            _buildInputCard(),
            const SizedBox(height: 16),

            // Generate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateCampaign,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _isGenerating
                      ? 'generating'.tr()
                      : 'generate'.tr(),
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _isGenerating
                      ? AppTheme.primaryLight
                      : AppTheme.primary,
                ),
              ),
            ),

            // Result
            if (_result != null) ...[
              const SizedBox(height: 24),
              _CampaignResultCard(result: _result!),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Campaign Parameters',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 16),

          // Row 1: Crop + Region
          Row(
            children: [
              Expanded(
                child: _DropdownField(
                  label: 'select_crop'.tr(),
                  icon: Icons.grass,
                  value: _selectedCrop,
                  items: AppConstants.crops,
                  displayMap: {
                    for (var c in AppConstants.crops)
                      c: c[0].toUpperCase() + c.substring(1)
                  },
                  onChanged: (v) => setState(() => _selectedCrop = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DropdownField(
                  label: 'select_region'.tr(),
                  icon: Icons.location_on,
                  value: _selectedRegion,
                  items: AppConstants.regions,
                  displayMap: {for (var r in AppConstants.regions) r: r},
                  onChanged: (v) => setState(() => _selectedRegion = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Stage + Pest
          Row(
            children: [
              Expanded(
                child: _DropdownField(
                  label: 'select_stage'.tr(),
                  icon: Icons.timeline,
                  value: _selectedStage,
                  items: AppConstants.growthStages,
                  displayMap: {
                    'sowing': 'Sowing',
                    'vegetative': 'Vegetative',
                    'flowering': 'Flowering',
                    'fruiting': 'Grain Fill',
                    'maturity': 'Maturity',
                  },
                  onChanged: (v) => setState(() => _selectedStage = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DropdownField(
                  label: 'select_pest'.tr(),
                  icon: Icons.bug_report,
                  value: _selectedPest,
                  items: AppConstants.pestAlerts,
                  displayMap: AppConstants.pestDisplayNames,
                  onChanged: (v) => setState(() => _selectedPest = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Language selector
          const Text('Output Language',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AppConstants.languages.map((lang) {
                final isSelected = _selectedLanguage == lang['code'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedLanguage = lang['code']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : const Color(0xFFE0E0E0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            lang['native']!,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            lang['name']!,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.8)
                                  : AppTheme.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Channel selector
          const Text('Delivery Channel',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: AppConstants.channels.map((ch) {
              final isSelected = _selectedChannel == ch;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedChannel = ch),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : const Color(0xFFE0E0E0),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          AppConstants.channelIcons[ch]!,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ch == 'voice_call'
                              ? 'Voice'
                              : ch == 'social_media'
                                  ? 'Social'
                                  : ch.toUpperCase(),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final List<String> items;
  final Map<String, String> displayMap;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.displayMap,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppTheme.primary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      isExpanded: true,
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(
                  displayMap[item] ?? item,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _CampaignResultCard extends StatefulWidget {
  final CampaignOutput result;
  const _CampaignResultCard({required this.result});

  @override
  State<_CampaignResultCard> createState() => _CampaignResultCardState();
}

class _CampaignResultCardState extends State<_CampaignResultCard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final channelIndex = AppConstants.channels.indexOf(widget.result.channel);
    if (channelIndex >= 0) _tabController.animateTo(channelIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urgencyColor =
        Color(widget.result.urgencyLevel.colorValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metrics row
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Predicted\nEngagement',
                child: CircularPercentIndicator(
                  radius: 32,
                  lineWidth: 5,
                  percent: widget.result.predictedEngagement / 100,
                  center: Text(
                    '${widget.result.predictedEngagement}%',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  progressColor: AppTheme.primary,
                  backgroundColor: AppTheme.surface,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'Urgency\nLevel',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: urgencyColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.result.urgencyLevel.displayName,
                    style: TextStyle(
                      color: urgencyColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'Send\nTime',
                child: Text(
                  widget.result.optimalSendTime
                      .replaceAll(' (', '\n('),
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Product recommendation
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.science, color: AppTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'recommended_product'.tr(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.result.recommendedProduct,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
              ),
              Text('💊 ${widget.result.productDose}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13)),
              Text('⏰ ${widget.result.productTiming}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Target segment
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.people, color: AppTheme.accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('target_segment'.tr(),
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary)),
                    Text(
                      widget.result.targetSegment,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Campaign message tabs
        const Text(
          'Campaign Variants',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05), blurRadius: 8),
            ],
          ),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primary,
                tabs: const [
                  Tab(text: 'WhatsApp'),
                  Tab(text: 'SMS'),
                  Tab(text: 'Voice'),
                  Tab(text: 'Social'),
                ],
              ),
              SizedBox(
                height: 260,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _MessageTab(
                        message: widget.result.whatsappMessage,
                        channel: 'whatsapp'),
                    _MessageTab(
                        message: widget.result.smsMessage, channel: 'sms'),
                    _MessageTab(
                        message: widget.result.voiceScript,
                        channel: 'voice_call'),
                    _MessageTab(
                        message: widget.result.socialMediaCaption,
                        channel: 'social_media'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Key points
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('AI Insights',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              ...widget.result.keyPoints.map(
                (point) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle,
                          size: 14, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(point,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final Widget child;

  const _MetricCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 6),
        ],
      ),
      child: Column(
        children: [
          child,
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MessageTab extends StatelessWidget {
  final String message;
  final String channel;

  const _MessageTab({required this.message, required this.channel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: message));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message copied to clipboard!'),
                        backgroundColor: AppTheme.primary,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: Text('copy_message'.tr(),
                      style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Share.share(message),
                  icon: const Icon(Icons.share, size: 16),
                  label: Text(
                    channel == 'whatsapp'
                        ? 'share_whatsapp'.tr()
                        : 'Share',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
