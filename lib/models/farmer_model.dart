import 'package:cloud_firestore/cloud_firestore.dart';

class FarmerModel {
  final String uid;
  final String name;
  final String phone;
  final String photoUrl;
  final String region;
  final String state;
  final List<String> crops;
  final double farmSize;
  final double latitude;
  final double longitude;
  final String language;
  final bool isAnonymous;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime createdAt;
  double? distanceKm;

  FarmerModel({
    required this.uid,
    required this.name,
    this.phone = '',
    this.photoUrl = '',
    this.region = '',
    this.state = '',
    this.crops = const [],
    this.farmSize = 0,
    this.latitude = 0,
    this.longitude = 0,
    this.language = 'en',
    this.isAnonymous = false,
    this.isOnline = false,
    this.lastSeen,
    required this.createdAt,
    this.distanceKm,
  });

  factory FarmerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FarmerModel(
      uid: doc.id,
      name: data['name'] ?? 'Farmer',
      phone: data['phone'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      region: data['region'] ?? '',
      state: data['state'] ?? '',
      crops: List<String>.from(data['crops'] ?? []),
      farmSize: (data['farmSize'] ?? 0).toDouble(),
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      language: data['language'] ?? 'en',
      isAnonymous: data['isAnonymous'] ?? false,
      isOnline: data['isOnline'] ?? false,
      lastSeen: data['lastSeen'] != null
          ? (data['lastSeen'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'phone': phone,
        'photoUrl': photoUrl,
        'region': region,
        'state': state,
        'crops': crops,
        'farmSize': farmSize,
        'latitude': latitude,
        'longitude': longitude,
        'language': language,
        'isAnonymous': isAnonymous,
        'isOnline': isOnline,
        'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  FarmerModel copyWith({
    String? name,
    String? phone,
    String? photoUrl,
    String? region,
    String? state,
    List<String>? crops,
    double? farmSize,
    double? latitude,
    double? longitude,
    String? language,
    bool? isOnline,
    DateTime? lastSeen,
    double? distanceKm,
  }) {
    return FarmerModel(
      uid: uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      region: region ?? this.region,
      state: state ?? this.state,
      crops: crops ?? this.crops,
      farmSize: farmSize ?? this.farmSize,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      language: language ?? this.language,
      isAnonymous: isAnonymous,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }

  // Mock farmers for demo when Firebase is not configured
  static List<FarmerModel> getMockFarmers() => [
        FarmerModel(
          uid: 'mock1',
          name: 'Rajesh Kumar',
          region: 'Ludhiana',
          state: 'Punjab',
          crops: ['wheat', 'rice'],
          farmSize: 8.5,
          latitude: 30.9010,
          longitude: 75.8573,
          language: 'hi',
          isOnline: true,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          distanceKm: 2.4,
        ),
        FarmerModel(
          uid: 'mock2',
          name: 'Suresh Patil',
          region: 'Pune',
          state: 'Maharashtra',
          crops: ['sugarcane', 'soybean'],
          farmSize: 5.0,
          latitude: 18.5204,
          longitude: 73.8567,
          language: 'mr',
          isOnline: false,
          lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          distanceKm: 4.1,
        ),
        FarmerModel(
          uid: 'mock3',
          name: 'Venkata Rao',
          region: 'Guntur',
          state: 'Andhra Pradesh',
          crops: ['cotton', 'chili'],
          farmSize: 12.0,
          latitude: 16.3067,
          longitude: 80.4365,
          language: 'te',
          isOnline: true,
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
          distanceKm: 6.7,
        ),
        FarmerModel(
          uid: 'mock4',
          name: 'Murugan S.',
          region: 'Thanjavur',
          state: 'Tamil Nadu',
          crops: ['rice'],
          farmSize: 3.5,
          latitude: 10.7870,
          longitude: 79.1378,
          language: 'ta',
          isOnline: false,
          lastSeen: DateTime.now().subtract(const Duration(days: 1)),
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
          distanceKm: 8.3,
        ),
        FarmerModel(
          uid: 'mock5',
          name: 'Ramesh Singh',
          region: 'Varanasi',
          state: 'Uttar Pradesh',
          crops: ['wheat', 'maize', 'rice'],
          farmSize: 6.0,
          latitude: 25.3176,
          longitude: 82.9739,
          language: 'hi',
          isOnline: true,
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
          distanceKm: 11.2,
        ),
      ];
}
