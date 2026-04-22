// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppConfigModelAdapter extends TypeAdapter<AppConfigModel> {
  @override
  final int typeId = 21;

  @override
  AppConfigModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppConfigModel(
      chefCommission: fields[0] as double,
      riderCommission: fields[1] as double,
      baseDeliveryFee: fields[2] as double,
      platformServiceFee: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, AppConfigModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.chefCommission)
      ..writeByte(1)
      ..write(obj.riderCommission)
      ..writeByte(2)
      ..write(obj.baseDeliveryFee)
      ..writeByte(3)
      ..write(obj.platformServiceFee);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppConfigModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
