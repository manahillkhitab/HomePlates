import 'package:flutter/foundation.dart';
import '../data/local/local_storage_service.dart';
import '../data/local/sample_model.dart';

class HomeController {
  final LocalStorageService _storageService = LocalStorageService();
  
  // ValueNotifier for reactive UI updates
  final ValueNotifier<List<SampleModel>> samplesNotifier = ValueNotifier([]);
  
  HomeController() {
    loadSamples();
  }

  // Load samples from Hive
  void loadSamples() {
    samplesNotifier.value = _storageService.getAllSamples();
  }

  // Add a new sample
  Future<void> addSample() async {
    final sample = SampleModel.createSample();
    await _storageService.saveSample(sample);
    loadSamples(); // Refresh the list
  }

  // Delete a sample
  Future<void> deleteSample(String id) async {
    await _storageService.deleteSample(id);
    loadSamples(); // Refresh the list
  }

  // Clear all samples
  Future<void> clearAllSamples() async {
    await _storageService.clearAllSamples();
    loadSamples(); // Refresh the list
  }

  // Dispose
  void dispose() {
    samplesNotifier.dispose();
  }
}
