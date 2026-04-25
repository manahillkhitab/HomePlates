// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 3;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as String,
      name: fields[1] as String,
      role: fields[2] as UserRole,
      isLoggedIn: fields[3] as bool,
      isSynced: fields[4] as bool,
      email: fields[5] as String,
      phone: fields[6] as String,
      address: fields[7] as String,
      profileImageUrl: fields[8] as String,
      kitchenName: fields[10] as String,
      categories: (fields[11] as List).cast<String>(),
      vehicleType: fields[12] as String,
      vehicleNumber: fields[13] as String,
      termsAccepted: fields[14] as bool,
      status: fields[15] as UserStatus,
      isKitchenClosed: fields[16] as bool,
      createdAt: fields[9] as DateTime?,
      updatedAt: fields[17] as DateTime?,
      followingChefIds: (fields[18] as List).cast<String>(),
      referralCode: fields[19] as String?,
      referredBy: fields[20] as String?,
      subscriptionTier: fields[21] as SubscriptionTier,
      subscriptionExpiry: fields[22] as DateTime?,
      orderedCategories: (fields[23] as Map).cast<String, int>(),
      rolesData: (fields[24] as Map).cast<dynamic, dynamic>(),
      isAdmin: fields[25] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(26)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.role)
      ..writeByte(3)
      ..write(obj.isLoggedIn)
      ..writeByte(4)
      ..write(obj.isSynced)
      ..writeByte(5)
      ..write(obj.email)
      ..writeByte(6)
      ..write(obj.phone)
      ..writeByte(7)
      ..write(obj.address)
      ..writeByte(8)
      ..write(obj.profileImageUrl)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.kitchenName)
      ..writeByte(11)
      ..write(obj.categories)
      ..writeByte(12)
      ..write(obj.vehicleType)
      ..writeByte(13)
      ..write(obj.vehicleNumber)
      ..writeByte(14)
      ..write(obj.termsAccepted)
      ..writeByte(15)
      ..write(obj.status)
      ..writeByte(16)
      ..write(obj.isKitchenClosed)
      ..writeByte(17)
      ..write(obj.updatedAt)
      ..writeByte(18)
      ..write(obj.followingChefIds)
      ..writeByte(19)
      ..write(obj.referralCode)
      ..writeByte(20)
      ..write(obj.referredBy)
      ..writeByte(21)
      ..write(obj.subscriptionTier)
      ..writeByte(22)
      ..write(obj.subscriptionExpiry)
      ..writeByte(23)
      ..write(obj.orderedCategories)
      ..writeByte(24)
      ..write(obj.rolesData)
      ..writeByte(25)
      ..write(obj.isAdmin);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserRoleAdapter extends TypeAdapter<UserRole> {
  @override
  final int typeId = 2;

  @override
  UserRole read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UserRole.customer;
      case 1:
        return UserRole.chef;
      case 2:
        return UserRole.rider;
      case 3:
        return UserRole.admin;
      default:
        return UserRole.customer;
    }
  }

  @override
  void write(BinaryWriter writer, UserRole obj) {
    switch (obj) {
      case UserRole.customer:
        writer.writeByte(0);
        break;
      case UserRole.chef:
        writer.writeByte(1);
        break;
      case UserRole.rider:
        writer.writeByte(2);
        break;
      case UserRole.admin:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserRoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserStatusAdapter extends TypeAdapter<UserStatus> {
  @override
  final int typeId = 7;

  @override
  UserStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UserStatus.pending;
      case 1:
        return UserStatus.approved;
      case 2:
        return UserStatus.rejected;
      case 3:
        return UserStatus.blocked;
      default:
        return UserStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, UserStatus obj) {
    switch (obj) {
      case UserStatus.pending:
        writer.writeByte(0);
        break;
      case UserStatus.approved:
        writer.writeByte(1);
        break;
      case UserStatus.rejected:
        writer.writeByte(2);
        break;
      case UserStatus.blocked:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
