import 'package:hive/hive.dart';
import 'sample_model.dart';
import '../../utils/constants.dart';

class LocalStorageService {
  // Get the sample box
  Box<SampleModel> get _sampleBox => Hive.box<SampleModel>(HiveBoxes.sampleBox);

  // Save a sample item
  Future<void> saveSample(SampleModel sample) async {
    await _sampleBox.put(sample.id, sample);
  }

  // Get all samples
  List<SampleModel> getAllSamples() {
    return _sampleBox.values.toList();
  }

  // Get a specific sample by ID
  SampleModel? getSample(String id) {
    return _sampleBox.get(id);
  }

  // Delete a sample
  Future<void> deleteSample(String id) async {
    await _sampleBox.delete(id);
  }

  // Clear all samples
  Future<void> clearAllSamples() async {
    await _sampleBox.clear();
  }

  // Get count of samples
  int getSampleCount() {
    return _sampleBox.length;
  }

  // Listen to box changes
  Stream<List<SampleModel>> watchSamples() {
    return _sampleBox.watch().map((_) => getAllSamples());
  }
}
