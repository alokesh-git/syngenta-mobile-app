import 'package:flutter/foundation.dart';
import '../models/farmer_model.dart';
import '../services/firestore_service.dart';

class FarmerProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  List<FarmerModel> _farmers = [];
  List<FarmerModel> _filteredFarmers = [];
  bool _isLoading = false;
  String? _selectedCrop;
  bool _useMockData = false;

  List<FarmerModel> get farmers => _filteredFarmers;
  bool get isLoading => _isLoading;
  String? get selectedCrop => _selectedCrop;
  int get nearbyCount => _farmers.length;

  Future<void> loadNearbyFarmers({
    double lat = 20.5937,
    double lng = 78.9629,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _service
          .getNearbyFarmers(lat: lat, lng: lng)
          .listen((farmers) {
            _farmers = farmers;
            _applyFilter();
            _isLoading = false;
            notifyListeners();
          })
          .onError((_) => _loadMockData());
    } catch (_) {
      _loadMockData();
    }
  }

  void _loadMockData() {
    _useMockData = true;
    _farmers = FarmerModel.getMockFarmers();
    _applyFilter();
    _isLoading = false;
    notifyListeners();
  }

  void filterByCrop(String? crop) {
    _selectedCrop = crop;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_selectedCrop == null || _selectedCrop!.isEmpty) {
      _filteredFarmers = List.from(_farmers);
    } else {
      _filteredFarmers =
          _farmers.where((f) => f.crops.contains(_selectedCrop)).toList();
    }
  }

  void loadMockData() => _loadMockData();
}
