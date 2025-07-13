import 'package:flutter/services.dart' show rootBundle;
import 'package:lib/models/metro_data.dart';

class MetroService {
  // A static variable to cache the loaded data to avoid re-reading the file.
  static MetroData? _metroData;

  Future<MetroData> loadMetroData() async {
    // If data is already loaded, return the cached version.
    if (_metroData != null) return _metroData!;

    final String jsonString = await rootBundle.loadString('assets/kolkata_metro_data.json');
    _metroData = metroDataFromJson(jsonString);
    return _metroData!;
  }
}

