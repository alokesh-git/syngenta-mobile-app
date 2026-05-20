import '../core/constants.dart';
import '../models/campaign_model.dart';

/// Simulates an LLM-based campaign generator.
/// In production: replace generateCampaign() body with an API call to
/// Claude/GPT with structured prompt containing crop, region, weather,
/// pest alerts, and historical engagement data.
class AICampaignService {
  static CampaignOutput generateCampaign(CampaignInput input) {
    final product = _getProduct(input.pestAlert);
    final urgency = _calculateUrgency(input.pestAlert, input.growthStage);
    final engagement = _predictEngagement(input);
    final content = _generateContent(input, product);

    return CampaignOutput(
      headline: content['headline']!,
      whatsappMessage: content['whatsapp']!,
      smsMessage: content['sms']!,
      voiceScript: content['voice']!,
      socialMediaCaption: content['social']!,
      recommendedProduct: product['product']!,
      productDose: product['dose']!,
      productTiming: product['timing']!,
      targetSegment: _getTargetSegment(input),
      optimalSendTime: _getOptimalTime(input),
      predictedEngagement: engagement,
      urgencyLevel: urgency,
      keyPoints: _getKeyPoints(input, product),
      callToAction: _getCTA(input.channel),
      language: input.language,
      channel: input.channel,
    );
  }

  static Map<String, String> _getProduct(String pestAlert) {
    return AppConstants.productRecommendations[pestAlert] ??
        AppConstants.productRecommendations['no_alert']!;
  }

  static UrgencyLevel _calculateUrgency(String pest, String stage) {
    const criticalPests = ['blast', 'bollworm', 'bph'];
    const highPests = ['stem_borer', 'blight', 'downy_mildew', 'helicoverpa'];
    const criticalStages = ['flowering', 'fruiting'];

    if (criticalPests.contains(pest) && criticalStages.contains(stage)) {
      return UrgencyLevel.critical;
    }
    if (criticalPests.contains(pest)) return UrgencyLevel.high;
    if (highPests.contains(pest)) return UrgencyLevel.high;
    if (pest == 'no_alert') return UrgencyLevel.low;
    return UrgencyLevel.medium;
  }

  static int _predictEngagement(CampaignInput input) {
    int base = 60;
    // Localized content gets higher engagement
    if (input.language != 'en') base += 12;
    // WhatsApp has highest open rate for farmers
    if (input.channel == 'whatsapp') base += 10;
    if (input.channel == 'voice_call') base += 8;
    // High urgency drives engagement
    final urgency = _calculateUrgency(input.pestAlert, input.growthStage);
    if (urgency == UrgencyLevel.critical) base += 15;
    if (urgency == UrgencyLevel.high) base += 10;
    // Flowering/fruiting stage - farmer is most attentive
    if (input.growthStage == 'flowering' || input.growthStage == 'fruiting') {
      base += 5;
    }
    return base.clamp(50, 96);
  }

  static Map<String, String> _generateContent(
    CampaignInput input,
    Map<String, String> product,
  ) {
    final cropName = _cropDisplay(input.crop, input.language);
    final regionName = input.region;
    final pestName = _pestDisplay(input.pestAlert, input.language);
    final productName = product['product']!.split(' ').first;
    final isAlert = input.pestAlert != 'no_alert';

    switch (input.language) {
      case 'hi':
        return _generateHindi(
            cropName, regionName, pestName, productName, product, isAlert, input);
      case 'ta':
        return _generateTamil(
            cropName, regionName, pestName, productName, product, isAlert, input);
      case 'te':
        return _generateTelugu(
            cropName, regionName, pestName, productName, product, isAlert, input);
      case 'mr':
        return _generateMarathi(
            cropName, regionName, pestName, productName, product, isAlert, input);
      default:
        return _generateEnglish(
            cropName, regionName, pestName, productName, product, isAlert, input);
    }
  }

  static Map<String, String> _generateEnglish(
    String crop, String region, String pest, String product,
    Map<String, String> productData, bool isAlert, CampaignInput input,
  ) {
    final headline = isAlert
        ? '🚨 ${pest.toUpperCase()} ALERT: Protect your $crop crop NOW!'
        : '🌾 Smart Crop Protection for $crop farmers in $region';

    final body = isAlert
        ? '''Dear $crop Farmer in $region,

⚠️ ${pest} has been detected in your region at ${input.growthStage} stage.

✅ Recommended Solution: ${productData['product']}
💊 Dose: ${productData['dose']}
⏰ Application: ${productData['timing']}

Don't wait — every day of delay reduces crop yield by 5-15%.

📞 Contact your nearest Syngenta dealer today.
🌱 Powered by KisanConnect AI'''
        : '''Dear $crop Farmer in $region,

🌾 Your crop is at ${input.growthStage} stage — the right time for preventive protection.

✅ Recommended: ${productData['product']}
💊 Dose: ${productData['dose']}

Protect your yield before threats emerge.

📞 Ask your Syngenta dealer for more info.
🌱 Powered by KisanConnect AI''';

    return {
      'headline': headline,
      'whatsapp': body,
      'sms': isAlert
          ? 'ALERT: $pest in $crop crops, $region. Use $product. ${productData['dose']}. Call dealer now. -KisanConnect'
          : 'Advisory: Protect your $crop at ${input.growthStage} stage. Use $product. ${productData['dose']}. -KisanConnect',
      'voice': 'Namaste $crop farmer! This is an important message from KisanConnect. '
          '${isAlert ? "$pest has been detected in $region." : "Protect your $crop crop at ${input.growthStage} stage."} '
          'Syngenta recommends $product at ${productData['dose']}. '
          'Please contact your nearest dealer immediately. Thank you.',
      'social': '${isAlert ? "🚨 CROP ALERT" : "🌾 CROP ADVISORY"}: $crop farmers in $region!\n\n'
          '${isAlert ? "$pest detected at ${input.growthStage} stage." : "Protect your crop at ${input.growthStage} stage."}\n\n'
          'Solution: $product\nDose: ${productData['dose']}\n\n'
          '#KisanConnect #${crop}Farming #Syngenta #IndianFarmer #SmartAgriculture',
    };
  }

  static Map<String, String> _generateHindi(
    String crop, String region, String pest, String product,
    Map<String, String> productData, bool isAlert, CampaignInput input,
  ) {
    final stage = _stageHindi(input.growthStage);
    final headline = isAlert
        ? '🚨 $pest चेतावनी: अभी अपनी $crop फसल बचाएं!'
        : '🌾 $region के $crop किसानों के लिए स्मार्ट सुरक्षा';

    final body = isAlert
        ? '''प्रिय $crop किसान, $region,

⚠️ आपके क्षेत्र में $pest का प्रकोप देखा गया है ($stage)।

✅ समाधान: ${productData['product']}
💊 मात्रा: ${productData['dose']}
⏰ प्रयोग: ${productData['timing']}

देरी न करें — हर दिन की देरी से 5-15% उपज कम होती है।

📞 अभी अपने Syngenta डीलर से संपर्क करें।
🌱 KisanConnect AI द्वारा'''
        : '''प्रिय $crop किसान, $region,

🌾 आपकी फसल $stage में है — अभी सुरक्षा का सही समय।

✅ सिफारिश: ${productData['product']}
💊 मात्रा: ${productData['dose']}

रोग आने से पहले ही फसल को सुरक्षित करें।

📞 Syngenta डीलर से जानकारी लें।
🌱 KisanConnect AI द्वारा''';

    return {
      'headline': headline,
      'whatsapp': body,
      'sms': isAlert
          ? 'चेतावनी: $region में $crop पर $pest। $product उपयोग करें। मात्रा: ${productData['dose']}। अभी डीलर से मिलें। -KisanConnect'
          : 'सलाह: $stage में $crop की सुरक्षा करें। $product, ${productData['dose']}। -KisanConnect',
      'voice': 'नमस्ते $crop किसान भाई! KisanConnect की ओर से महत्वपूर्ण संदेश। '
          '${isAlert ? "$region में $pest का प्रकोप है।" : "$crop फसल को $stage में सुरक्षित करें।"} '
          'Syngenta का $product, ${productData['dose']} में उपयोग करें। '
          'तुरंत अपने डीलर से संपर्क करें। धन्यवाद।',
      'social': '${isAlert ? "🚨 फसल चेतावनी" : "🌾 फसल सलाह"}: $region के $crop किसान!\n\n'
          '${isAlert ? "$stage में $pest का प्रकोप।" : "$stage में फसल की देखभाल करें।"}\n\n'
          'उपाय: $product\nमात्रा: ${productData['dose']}\n\n'
          '#KisanConnect #किसान #Syngenta #SmartKheti',
    };
  }

  static Map<String, String> _generateTamil(
    String crop, String region, String pest, String product,
    Map<String, String> productData, bool isAlert, CampaignInput input,
  ) {
    return {
      'headline': isAlert
          ? '🚨 $pest எச்சரிக்கை: உங்கள் $crop பயிரை இப்போதே காப்பாற்றுங்கள்!'
          : '🌾 $region $crop விவசாயிகளுக்கான பாதுகாப்பு',
      'whatsapp': '''அன்பான $crop விவசாயி, $region,

${isAlert ? "⚠️ உங்கள் பகுதியில் $pest கண்டறியப்பட்டுள்ளது." : "🌾 உங்கள் பயிர் ${input.growthStage} நிலையில் உள்ளது."}

✅ பரிந்துரை: ${productData['product']}
💊 அளவு: ${productData['dose']}
⏰ பயன்பாடு: ${productData['timing']}

📞 Syngenta விற்பனையாளரை இன்றே தொடர்பு கொள்ளுங்கள்.
🌱 KisanConnect AI''',
      'sms': isAlert
          ? 'எச்சரிக்கை: $region-ல் $crop-ல் $pest. $product பயன்படுத்துங்கள். -KisanConnect'
          : 'ஆலோசனை: $crop-ஐ $product மூலம் பாதுகாக்கவும். -KisanConnect',
      'voice': 'வணக்கம் $crop விவசாயி! KisanConnect-இல் இருந்து முக்கிய செய்தி. '
          '${isAlert ? "$region-ல் $pest கண்டறியப்பட்டுள்ளது." : "$crop பயிரை ${input.growthStage} நிலையில் பாதுகாக்கவும்."} '
          'Syngenta $product பயன்படுத்துங்கள். விற்பனையாளரை தொடர்பு கொள்ளுங்கள். நன்றி.',
      'social': '${isAlert ? "🚨 பயிர் எச்சரிக்கை" : "🌾 பயிர் ஆலோசனை"}: $region $crop விவசாயிகளே!\n\n'
          'தீர்வு: $product\n#KisanConnect #விவசாயி #Syngenta',
    };
  }

  static Map<String, String> _generateTelugu(
    String crop, String region, String pest, String product,
    Map<String, String> productData, bool isAlert, CampaignInput input,
  ) {
    return {
      'headline': isAlert
          ? '🚨 $pest హెచ్చరిక: మీ $crop పంటను ఇప్పుడే రక్షించుకోండి!'
          : '🌾 $region $crop రైతులకు స్మార్ట్ రక్షణ',
      'whatsapp': '''ప్రియమైన $crop రైతు, $region,

${isAlert ? "⚠️ మీ ప్రాంతంలో $pest గుర్తించబడింది (${input.growthStage} దశలో)." : "🌾 మీ పంట ${input.growthStage} దశలో ఉంది."}

✅ సిఫార్సు: ${productData['product']}
💊 మోతాదు: ${productData['dose']}
⏰ వినియోగం: ${productData['timing']}

📞 Syngenta డీలర్‌ను ఈరోజే సంప్రదించండి.
🌱 KisanConnect AI''',
      'sms': isAlert
          ? 'హెచ్చరిక: $region-లో $crop-పై $pest. $product వాడండి. -KisanConnect'
          : 'సలహా: $crop-ను $product తో రక్షించండి. -KisanConnect',
      'voice': 'నమస్కారం $crop రైతు! KisanConnect నుండి ముఖ్యమైన సందేశం. '
          '${isAlert ? "$region-లో $pest గుర్తించబడింది." : "$crop పంటను ${input.growthStage} దశలో రక్షించండి."} '
          'Syngenta $product వాడండి. డీలర్‌ని సంప్రదించండి. ధన్యవాదాలు.',
      'social': '${isAlert ? "🚨 పంట హెచ్చరిక" : "🌾 పంట సలహా"}: $region $crop రైతులు!\n\n'
          'పరిష్కారం: $product\n#KisanConnect #రైతు #Syngenta',
    };
  }

  static Map<String, String> _generateMarathi(
    String crop, String region, String pest, String product,
    Map<String, String> productData, bool isAlert, CampaignInput input,
  ) {
    return {
      'headline': isAlert
          ? '🚨 $pest इशारा: आपल्या $crop पिकाला आत्ताच वाचवा!'
          : '🌾 $region च्या $crop शेतकऱ्यांसाठी स्मार्ट संरक्षण',
      'whatsapp': '''प्रिय $crop शेतकरी, $region,

${isAlert ? "⚠️ तुमच्या परिसरात $pest आढळला आहे (${input.growthStage} अवस्था)." : "🌾 तुमचे पीक ${input.growthStage} अवस्थेत आहे."}

✅ शिफारस: ${productData['product']}
💊 मात्रा: ${productData['dose']}
⏰ वापर: ${productData['timing']}

📞 Syngenta डीलरशी आज संपर्क करा.
🌱 KisanConnect AI''',
      'sms': isAlert
          ? 'इशारा: $region मध्ये $crop वर $pest. $product वापरा. -KisanConnect'
          : 'सल्ला: $crop पिकाला $product ने संरक्षण द्या. -KisanConnect',
      'voice': 'नमस्कार $crop शेतकरी! KisanConnect कडून महत्वाचा संदेश. '
          '${isAlert ? "$region मध्ये $pest आढळला आहे." : "$crop पिकाला ${input.growthStage} अवस्थेत संरक्षण द्या."} '
          'Syngenta $product वापरा. डीलरशी संपर्क करा. धन्यवाद.',
      'social': '${isAlert ? "🚨 पीक इशारा" : "🌾 पीक सल्ला"}: $region चे $crop शेतकरी!\n\n'
          'उपाय: $product\n#KisanConnect #शेतकरी #Syngenta',
    };
  }

  static String _cropDisplay(String crop, String lang) {
    const cropHindi = {
      'rice': 'धान', 'wheat': 'गेहूं', 'cotton': 'कपास',
      'sugarcane': 'गन्ना', 'maize': 'मक्का', 'soybean': 'सोयाबीन',
      'tomato': 'टमाटर', 'chili': 'मिर्च', 'groundnut': 'मूंगफली',
    };
    const cropTamil = {
      'rice': 'நெல்', 'wheat': 'கோதுமை', 'cotton': 'பருத்தி',
      'sugarcane': 'கரும்பு', 'maize': 'சோளம்', 'tomato': 'தக்காளி',
      'chili': 'மிளகாய்', 'groundnut': 'நிலக்கடலை', 'soybean': 'சோயா',
    };
    const cropTelugu = {
      'rice': 'వరి', 'wheat': 'గోధుమ', 'cotton': 'పత్తి',
      'sugarcane': 'చెరకు', 'maize': 'మొక్కజొన్న', 'tomato': 'టమాటా',
      'chili': 'మిర్చి', 'groundnut': 'వేరుశెనగ', 'soybean': 'సోయా',
    };
    const cropMarathi = {
      'rice': 'भात', 'wheat': 'गहू', 'cotton': 'कापूस',
      'sugarcane': 'ऊस', 'maize': 'मका', 'soybean': 'सोयाबीन',
      'tomato': 'टोमॅटो', 'chili': 'मिरची', 'groundnut': 'भुईमूग',
    };

    switch (lang) {
      case 'hi': return cropHindi[crop] ?? crop;
      case 'ta': return cropTamil[crop] ?? crop;
      case 'te': return cropTelugu[crop] ?? crop;
      case 'mr': return cropMarathi[crop] ?? crop;
      default: return crop[0].toUpperCase() + crop.substring(1);
    }
  }

  static String _pestDisplay(String pest, String lang) {
    if (pest == 'no_alert') return '';
    const pestHindi = {
      'blast': 'ब्लास्ट', 'bollworm': 'बॉलवर्म', 'aphids': 'माहू',
      'whitefly': 'सफेद मक्खी', 'bph': 'भूरा माहो', 'rust': 'रस्ट',
      'blight': 'झुलसा रोग', 'stem_borer': 'तना छेदक',
      'downy_mildew': 'मृदुरोमिल', 'helicoverpa': 'हेलिकोवर्पा',
    };
    if (lang == 'hi') return pestHindi[pest] ?? pest;
    return AppConstants.pestDisplayNames[pest] ?? pest;
  }

  static String _stageHindi(String stage) {
    const stages = {
      'sowing': 'बुवाई', 'vegetative': 'वानस्पतिक', 'flowering': 'फूल',
      'fruiting': 'दाना भरने', 'maturity': 'परिपक्वता',
    };
    return stages[stage] ?? stage;
  }

  static String _getTargetSegment(CampaignInput input) {
    final cropMap = {
      'rice': 'Rice Growers (5-15 acres)',
      'wheat': 'Wheat Farmers (3-20 acres)',
      'cotton': 'Cotton Cultivators (5-25 acres)',
      'sugarcane': 'Sugarcane Farmers (2-10 acres)',
      'maize': 'Maize Growers (2-8 acres)',
    };
    return '${cropMap[input.crop] ?? "${input.crop} Farmers"} in ${input.region}';
  }

  static String _getOptimalTime(CampaignInput input) {
    final urgency = _calculateUrgency(input.pestAlert, input.growthStage);
    switch (input.channel) {
      case 'whatsapp':
        return urgency == UrgencyLevel.critical
            ? 'Immediately (within 2 hours)'
            : 'Today 7:00 AM – 9:00 AM';
      case 'sms':
        return urgency == UrgencyLevel.critical
            ? 'Immediately'
            : 'Today 6:30 AM – 8:00 AM';
      case 'voice_call':
        return 'Today 8:00 AM – 10:00 AM (post breakfast)';
      case 'social_media':
        return 'Today 7:00 AM or 6:00 PM (peak engagement)';
      default:
        return 'Today morning (7–9 AM)';
    }
  }

  static List<String> _getKeyPoints(
    CampaignInput input, Map<String, String> product,
  ) {
    return [
      '${input.crop} farmers in ${input.region} — ${input.growthStage} stage',
      if (input.pestAlert != 'no_alert')
        '${AppConstants.pestDisplayNames[input.pestAlert]} detected — immediate action needed',
      'Recommended: ${product['product']}',
      'Dose: ${product['dose']}',
      'Predicted open rate: higher with localized ${input.language.toUpperCase()} content',
      'Channel: ${input.channel} reaches ~85% of target farmers in region',
    ];
  }

  static String _getCTA(String channel) {
    switch (channel) {
      case 'whatsapp':
        return 'Reply YES to connect with Syngenta dealer';
      case 'sms':
        return 'Call 1800-XXX-XXXX (toll free)';
      case 'voice_call':
        return 'Press 1 to speak with agronomist';
      case 'social_media':
        return 'Tag a farmer friend who needs this';
      default:
        return 'Contact nearest Syngenta dealer';
    }
  }
}
