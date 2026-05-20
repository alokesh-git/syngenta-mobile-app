class AppConstants {
  static const String appName = 'KisanConnect';

  static const List<String> crops = [
    'rice', 'wheat', 'cotton', 'sugarcane', 'maize',
    'soybean', 'tomato', 'chili', 'groundnut',
  ];

  static const List<String> regions = [
    'Punjab', 'Haryana', 'Uttar Pradesh', 'Madhya Pradesh',
    'Maharashtra', 'Andhra Pradesh', 'Telangana', 'Tamil Nadu',
    'Karnataka', 'Gujarat', 'Bihar', 'Rajasthan', 'Odisha',
    'West Bengal', 'Chhattisgarh',
  ];

  static const List<String> growthStages = [
    'sowing', 'vegetative', 'flowering', 'fruiting', 'maturity',
  ];

  static const List<String> pestAlerts = [
    'no_alert', 'blast', 'bph', 'stem_borer', 'bollworm',
    'aphids', 'whitefly', 'rust', 'downy_mildew', 'blight',
    'helicoverpa', 'thrips',
  ];

  static const Map<String, String> pestDisplayNames = {
    'no_alert': 'No Alert',
    'blast': 'Rice Blast',
    'bph': 'Brown Plant Hopper',
    'stem_borer': 'Stem Borer',
    'bollworm': 'Bollworm',
    'aphids': 'Aphids',
    'whitefly': 'Whitefly',
    'rust': 'Rust Disease',
    'downy_mildew': 'Downy Mildew',
    'blight': 'Leaf Blight',
    'helicoverpa': 'Helicoverpa',
    'thrips': 'Thrips',
  };

  static const List<Map<String, String>> languages = [
    {'code': 'en', 'name': 'English', 'native': 'English'},
    {'code': 'hi', 'name': 'Hindi', 'native': 'हिंदी'},
    {'code': 'ta', 'name': 'Tamil', 'native': 'தமிழ்'},
    {'code': 'te', 'name': 'Telugu', 'native': 'తెలుగు'},
    {'code': 'mr', 'name': 'Marathi', 'native': 'मराठी'},
  ];

  static const List<String> channels = [
    'whatsapp', 'sms', 'voice_call', 'social_media',
  ];

  static const Map<String, String> channelIcons = {
    'whatsapp': '💬',
    'sms': '📱',
    'voice_call': '📞',
    'social_media': '📢',
  };

  // Syngenta products mapped to pest+crop combinations
  static const Map<String, Map<String, String>> productRecommendations = {
    'blast': {
      'product': 'SCORE® (Difenoconazole 25% EC)',
      'dose': '0.5 ml/L water',
      'timing': 'At first sign of disease, spray 2-3 times at 10-day interval',
    },
    'bph': {
      'product': 'ACTARA® (Thiamethoxam 25% WG)',
      'dose': '100g/acre',
      'timing': 'Apply at tillering stage when pest count exceeds threshold',
    },
    'stem_borer': {
      'product': 'KARATE® (Lambda-cyhalothrin 5% EC)',
      'dose': '1 ml/L water',
      'timing': 'Apply at vegetative stage, repeat after 15 days if needed',
    },
    'bollworm': {
      'product': 'KARATE® ZEON (Lambda-cyhalothrin 5% CS)',
      'dose': '200 ml/acre',
      'timing': 'Apply at flowering stage, monitor weekly',
    },
    'aphids': {
      'product': 'ACTARA® (Thiamethoxam 25% WG)',
      'dose': '80g/acre',
      'timing': 'Apply when aphid colonies appear on tender shoots',
    },
    'whitefly': {
      'product': 'ACTARA® (Thiamethoxam 25% WG)',
      'dose': '100g/acre',
      'timing': 'Apply at first infestation, repeat after 15 days',
    },
    'rust': {
      'product': 'AMISTAR® Top (Azoxystrobin + Difenoconazole)',
      'dose': '200 ml/acre',
      'timing': 'Preventive spray at flag leaf stage',
    },
    'downy_mildew': {
      'product': 'RIDOMIL GOLD® (Metalaxyl-M + Mancozeb)',
      'dose': '2g/L water',
      'timing': 'Apply at first symptom, repeat every 7-10 days',
    },
    'blight': {
      'product': 'AMISTAR® (Azoxystrobin 23% SC)',
      'dose': '200 ml/acre',
      'timing': 'Apply at disease onset, 2 sprays at 14-day interval',
    },
    'no_alert': {
      'product': 'AMISTAR® Top (Preventive)',
      'dose': '200 ml/acre',
      'timing': 'Preventive spray at crop canopy formation',
    },
  };
}
