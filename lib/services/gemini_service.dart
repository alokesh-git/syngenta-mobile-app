import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/constants.dart';

/// Diagnosis result returned by Gemini.
class DiagnosisResult {
  final String crop;
  final String issue;
  final String explanation;
  final String recommendedProduct;
  final String dose;
  final String timing;
  final bool isSyngenta;

  DiagnosisResult({
    required this.crop,
    required this.issue,
    required this.explanation,
    required this.recommendedProduct,
    required this.dose,
    required this.timing,
    required this.isSyngenta,
  });

  factory DiagnosisResult.fallback() {
    final fb = AppConstants.productRecommendations['no_alert']!;
    return DiagnosisResult(
      crop: 'Crop',
      issue: 'General health check',
      explanation:
          'Your crop looks generally healthy. Keep monitoring and use preventive sprays as the season progresses.',
      recommendedProduct: fb['product']!,
      dose: fb['dose']!,
      timing: fb['timing']!,
      isSyngenta: true,
    );
  }
}

class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  bool get isConfigured => _apiKey.isNotEmpty;

  /// Analyzes a crop photo and returns a Syngenta-first diagnosis.
  Future<DiagnosisResult> diagnoseCrop(File photo) async {
    if (!isConfigured) return DiagnosisResult.fallback();

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final catalog = AppConstants.productRecommendations.entries
          .map((e) =>
              '- ${e.value['product']} (for ${e.key}): dose ${e.value['dose']}, ${e.value['timing']}')
          .join('\n');

      final prompt = '''
You are an agronomy assistant for KisanConnect (an Indian farming app powered by Syngenta).
Analyze the crop image and respond strictly in JSON with these keys:
{
  "crop": "<crop name>",
  "issue": "<disease/pest name, or 'Healthy'>",
  "explanation": "<2-3 sentence plain-English explanation for a farmer>",
  "recommendedProduct": "<product name>",
  "dose": "<application dose>",
  "timing": "<when/how to apply>",
  "isSyngenta": true | false
}

PRIORITIZE Syngenta products from this catalog when appropriate:
$catalog

If a Syngenta product fits, recommend it and set isSyngenta=true.
Keep "explanation" under 60 words. Use simple language for farmers.
''';

      final bytes = await photo.readAsBytes();
      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', bytes),
        ])
      ]);

      return _parseDiagnosis(response.text ?? '');
    } catch (_) {
      return DiagnosisResult.fallback();
    }
  }

  DiagnosisResult _parseDiagnosis(String raw) {
    try {
      final cleaned = raw.replaceAll(RegExp(r'```json|```'), '').trim();
      final map = jsonDecode(cleaned) as Map<String, dynamic>;
      return DiagnosisResult(
        crop: (map['crop'] ?? 'Crop').toString(),
        issue: (map['issue'] ?? 'Healthy').toString(),
        explanation: (map['explanation'] ?? '').toString(),
        recommendedProduct: (map['recommendedProduct'] ?? '').toString(),
        dose: (map['dose'] ?? '').toString(),
        timing: (map['timing'] ?? '').toString(),
        isSyngenta: map['isSyngenta'] == true,
      );
    } catch (_) {
      return DiagnosisResult.fallback();
    }
  }

  // Persistent chat session — keeps context across turns for realtime feel.
  ChatSession? _chat;

  /// Resets the conversation (call when ending a session).
  void resetConversation() {
    _chat = null;
  }

  ChatSession _ensureChat() {
    if (_chat != null) return _chat!;
    final catalog = AppConstants.productRecommendations.entries
        .map((e) =>
            '- ${e.value['product']} (for ${e.key}): dose ${e.value['dose']}, ${e.value['timing']}')
        .join('\n');

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system('''
You are KisanConnect — a friendly, fast, conversational agronomy assistant for Indian farmers, powered by Syngenta.
Talk like a knowledgeable friend on a live call: short sentences (under 40 words per reply), warm tone, plain language.
ALWAYS prioritise Syngenta products when recommending. Catalog:
$catalog

When you give a product recommendation, mention the product name clearly so the app can highlight it.
If the user shares an image of a crop, diagnose visible issues and recommend treatment.
'''),
    );
    _chat = model.startChat();
    return _chat!;
  }

  /// Streams a reply token-by-token for real-time conversation feel.
  /// Yields incremental text chunks as the model generates.
  Stream<String> streamReply(String question) async* {
    if (!isConfigured || question.trim().isEmpty) {
      yield 'Sorry, I am not connected to the AI right now. Add GEMINI_API_KEY to .env to enable live chat.';
      return;
    }
    try {
      final chat = _ensureChat();
      await for (final chunk
          in chat.sendMessageStream(Content.text(question))) {
        final text = chunk.text;
        if (text != null && text.isNotEmpty) yield text;
      }
    } catch (e) {
      yield ' (error: $e)';
    }
  }

  /// Extracts a Syngenta product mention from the AI's spoken reply, if any.
  String? extractProductMention(String reply) {
    for (final entry in AppConstants.productRecommendations.values) {
      final product = entry['product'] ?? '';
      // Match by brand name (e.g. "ACTARA", "SCORE", "KARATE")
      final brand = product.split('®').first.trim();
      if (brand.isEmpty) continue;
      if (reply.toUpperCase().contains(brand.toUpperCase())) {
        return product;
      }
    }
    return null;
  }

  /// Answers a farmer's spoken/typed question. Returns a short spoken-style
  /// reply plus a Syngenta-first product recommendation when relevant.
  Future<DiagnosisResult> askQuestion(String question) async {
    if (!isConfigured || question.trim().isEmpty) {
      return DiagnosisResult.fallback();
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        generationConfig:
            GenerationConfig(responseMimeType: 'application/json'),
      );

      final catalog = AppConstants.productRecommendations.entries
          .map((e) =>
              '- ${e.value['product']} (for ${e.key}): dose ${e.value['dose']}, ${e.value['timing']}')
          .join('\n');

      final prompt = '''
You are an agronomy assistant for KisanConnect (an Indian farming app powered by Syngenta).
A farmer asked: "$question"

Reply strictly in JSON with these keys:
{
  "crop": "<crop they're talking about, best guess>",
  "issue": "<issue / topic>",
  "explanation": "<2-3 short conversational sentences, suitable to be spoken aloud>",
  "recommendedProduct": "<product name>",
  "dose": "<application dose>",
  "timing": "<when/how to apply>",
  "isSyngenta": true | false
}

PRIORITIZE Syngenta products from this catalog whenever appropriate:
$catalog
Use simple language for farmers, under 60 words in "explanation".
''';

      final response =
          await model.generateContent([Content.text(prompt)]);
      return _parseDiagnosis(response.text ?? '');
    } catch (_) {
      return DiagnosisResult.fallback();
    }
  }

  /// Generates a promotional poster image with the user's face + product
  /// using Gemini 2.5 Flash Image ("nano banana").
  /// Returns PNG/JPEG bytes, or null on failure.
  Future<Uint8List?> generatePromoImage({
    required File userPhoto,
    required String productName,
    required String crop,
  }) async {
    if (!isConfigured) return null;

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash-image-preview',
        apiKey: _apiKey,
      );

      final userBytes = await userPhoto.readAsBytes();
      final prompt = '''
Create a vibrant promotional poster image based on the provided photo:
- Keep the same person and same face from the photo (preserve identity, friendly smile)
- Place them in a lush green $crop field
- Show a clearly visible Syngenta "$productName" product bottle in their hand or beside them
- Add a green banner at the bottom with the bold text: "I recommend $productName - KisanConnect"
- Style: warm, professional, photorealistic agricultural marketing poster
- High quality, well-lit, natural outdoor lighting
''';

      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', userBytes),
        ])
      ]);

      for (final candidate in response.candidates) {
        for (final part in candidate.content.parts) {
          if (part is DataPart && part.mimeType.startsWith('image/')) {
            return part.bytes;
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
