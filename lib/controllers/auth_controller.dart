import 'package:flutter/material.dart';
import '../data/local/models/user_model.dart';
import '../data/local/services/auth_local_service.dart';

class AuthController extends ChangeNotifier {
  final AuthLocalService _authService = AuthLocalService();
  
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  AuthController() {
    _loadUser();
  }

  void _loadUser() {
    _currentUser = _authService.getCurrentUser();
    notifyListeners();
  }

  // Simplified login: just name and role
  Future<void> login(String name, UserRole role) async {
    // Generate consistent ID based on name and role
    // This ensures the same user always gets the same ID
    final consistentId = '${name.toLowerCase()}_${role.name}';
    
    debugPrint('=== Login ===');
    debugPrint('Name: $name');
    debugPrint('Role: ${role.name}');
    debugPrint('Generated ID: $consistentId');
    
    final user = UserModel(
      id: consistentId,
      name: name,
      role: role,
      isLoggedIn: true,
    );
    await _authService.saveUser(user);
    _currentUser = user;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.clearSession();
    _currentUser = _currentUser?.copyWith(isLoggedIn: false);
    notifyListeners();
  }

  bool get isLoggedIn => _currentUser?.isLoggedIn ?? false;
  UserRole? get userRole => _currentUser?.role;
}
