class CampaignInput {
  final String crop;
  final String region;
  final String growthStage;
  final String pestAlert;
  final String language;
  final String channel;

  const CampaignInput({
    required this.crop,
    required this.region,
    required this.growthStage,
    required this.pestAlert,
    required this.language,
    required this.channel,
  });
}

class CampaignOutput {
  final String headline;
  final String whatsappMessage;
  final String smsMessage;
  final String voiceScript;
  final String socialMediaCaption;
  final String recommendedProduct;
  final String productDose;
  final String productTiming;
  final String targetSegment;
  final String optimalSendTime;
  final int predictedEngagement;
  final UrgencyLevel urgencyLevel;
  final List<String> keyPoints;
  final String callToAction;
  final String language;
  final String channel;

  const CampaignOutput({
    required this.headline,
    required this.whatsappMessage,
    required this.smsMessage,
    required this.voiceScript,
    required this.socialMediaCaption,
    required this.recommendedProduct,
    required this.productDose,
    required this.productTiming,
    required this.targetSegment,
    required this.optimalSendTime,
    required this.predictedEngagement,
    required this.urgencyLevel,
    required this.keyPoints,
    required this.callToAction,
    required this.language,
    required this.channel,
  });

  String get activeMessage {
    switch (channel) {
      case 'whatsapp':
        return whatsappMessage;
      case 'sms':
        return smsMessage;
      case 'voice_call':
        return voiceScript;
      case 'social_media':
        return socialMediaCaption;
      default:
        return whatsappMessage;
    }
  }
}

enum UrgencyLevel { low, medium, high, critical }

extension UrgencyLevelExtension on UrgencyLevel {
  String get displayName {
    switch (this) {
      case UrgencyLevel.low:
        return 'LOW';
      case UrgencyLevel.medium:
        return 'MEDIUM';
      case UrgencyLevel.high:
        return 'HIGH';
      case UrgencyLevel.critical:
        return 'CRITICAL';
    }
  }

  int get colorValue {
    switch (this) {
      case UrgencyLevel.low:
        return 0xFF4CAF50;
      case UrgencyLevel.medium:
        return 0xFFFFA000;
      case UrgencyLevel.high:
        return 0xFFFF5722;
      case UrgencyLevel.critical:
        return 0xFFC62828;
    }
  }
}
