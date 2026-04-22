import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../../../utils/constants.dart';

class AuthLocalService {
  Box<UserModel> get _userBox => Hive.box<UserModel>(AppConstants.userBox);

  // Save the current user (only one active user at a time)
  Future<void> saveUser(UserModel user) async {
    await _userBox.put('current_user', user);
  }

  // Retrieve the current user session
  UserModel? getCurrentUser() {
    return _userBox.get('current_user');
  }

  // Clear session (Logout)
  Future<void> clearSession() async {
    final user = getCurrentUser();
    if (user != null) {
      await saveUser(user.copyWith(isLoggedIn: false));
    }
  }

  // Delete everything (Wipe data)
  Future<void> deleteUser() async {
    await _userBox.clear();
  }

  // Listen to user changes
  ValueListenable<Box<UserModel>> watchUser() {
    return _userBox.listenable(keys: ['current_user']);
  }
}
