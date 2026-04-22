import 'package:hive/hive.dart';

part 'sample_model.g.dart';

@HiveType(typeId: 0)
class SampleModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  bool isSynced;

  SampleModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.isSynced = false,
  });

  // Factory constructor for creating sample data
  factory SampleModel.createSample() {
    return SampleModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Welcome to HomePlates!',
      description: 'This is a sample data stored in Hive (offline database). The app is working correctly!',
      createdAt: DateTime.now(),
      isSynced: false,
    );
  }
}
