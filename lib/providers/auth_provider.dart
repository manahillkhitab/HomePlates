import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/local/models/user_model.dart';
import '../data/local/services/auth_local_service.dart';
import '../data/local/services/supabase_storage_service.dart';

final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(
  AuthNotifier.new,
);

final userByIdProvider = FutureProvider.family<UserModel?, String>((
  ref,
  id,
) async {
  return ref.read(authProvider.notifier).getUserById(id);
});

class AuthNotifier extends AsyncNotifier<UserModel?> {
  final AuthLocalService _authService = AuthLocalService();
  final SupabaseStorageService _storageService = SupabaseStorageService();

  @override
  Future<UserModel?> build() async {
    // Listen for auth state changes (crucial for Deep Links)
    final sub = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        // Fetch real profile from users table
        final remoteUser = await getUserById(session.user.id);

        if (remoteUser != null) {
          final user = remoteUser.copyWith(isLoggedIn: true, isSynced: true);
          await _authService.saveUser(user);
          state = AsyncValue.data(user);
        } else {
          // Fallback to metadata if DB entry missing
          final metadata = session.user.userMetadata ?? {};
          final userRole = UserRole.values.firstWhere(
            (e) => e.name == (metadata['role'] ?? 'customer'),
            orElse: () => UserRole.customer,
          );

          final user = UserModel(
            id: session.user.id,
            name: metadata['name'] ?? 'User',
            email: session.user.email ?? '',
            phone: metadata['phone'] ?? '',
            address: metadata['address'] ?? '',
            role: userRole,
            kitchenName: metadata['kitchenName'] ?? '',
            categories: List<String>.from(metadata['categories'] ?? []),
            vehicleType: metadata['vehicleType'] ?? '',
            vehicleNumber: metadata['vehicleNumber'] ?? '',
            termsAccepted: metadata['termsAccepted'] ?? false,
            isLoggedIn: true,
            isSynced: true,
            status: (userRole == UserRole.chef || userRole == UserRole.rider)
                ? UserStatus.pending
                : UserStatus.approved,
          );

          await _authService.saveUser(user);
          state = AsyncValue.data(user);
        }
      } else if (event == AuthChangeEvent.signedOut) {
        state = const AsyncValue.data(null);
      }
    });

    ref.onDispose(() => sub.cancel());

    return _authService.getCurrentUser();
  }

  // Reload user state from Supabase
  Future<void> reloadUser() async {
    final current = state.value;
    if (current == null) return;

    final updated = await getUserById(current.id);
    if (updated != null) {
      final user = updated.copyWith(isLoggedIn: true, isSynced: true);
      await _authService.saveUser(user);
      state = AsyncValue.data(user);
    }
  }

  // Proper Sign Up
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    required UserRole role,
    String kitchenName = '',
    List<String> categories = const [],
    String vehicleType = '',
    String vehicleNumber = '',
    bool termsAccepted = false,
  }) async {
    final supabase = Supabase.instance.client;

    final res = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'role': role.name,
        'phone': phone,
        'address': address,
        'kitchenName': kitchenName,
        'categories': categories,
        'vehicleType': vehicleType,
        'vehicleNumber': vehicleNumber,
        'termsAccepted': termsAccepted,
      },
    );

    if (res.user == null) throw Exception('Signup failed');

    final bool isEmailConfirmed = res.session != null;

    if (isEmailConfirmed) {
      final user = UserModel(
        id: res.user!.id,
        name: name,
        email: email,
        phone: phone,
        address: address,
        role: role, // Initial Active Role
        kitchenName: kitchenName,
        categories: categories,
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
        termsAccepted: termsAccepted,
        isLoggedIn: true,
        isSynced: true,
        status: (role == UserRole.chef || role == UserRole.rider)
            ? UserStatus.pending
            : UserStatus.approved,
        // Initialize roles map
        rolesData: {
          'customer': true, // Everyone is a customer
          if (role == UserRole.chef) 'chef': 'pending',
          if (role == UserRole.rider) 'rider': 'pending',
        },
      );

      await _authService.saveUser(user);
      state = AsyncValue.data(user);
      return true;
    } else {
      return false;
    }
  }

  // Proper Sign In
  Future<void> signIn(String email, String password) async {
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.session != null && res.user != null) {
        final remoteUser = await getUserById(res.user!.id);
        if (remoteUser != null) {
          final user = remoteUser.copyWith(isLoggedIn: true, isSynced: true);
          await _authService.saveUser(user);
          state = AsyncValue.data(user);
        } else {
          throw Exception('User profile not found in database');
        }
      } else {
        throw Exception('Failed to establish session after sign in');
      }
    } catch (e) {
      debugPrint('SignIn Error: $e');
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out on remote: $e');
    } finally {
      await _authService.clearUser();
      state = const AsyncValue.data(null);
    }
  }

  // Verify OTP
  Future<bool> verifyOTP({
    required String email,
    required String token,
    UserRole? role,
  }) async {
    try {
      final res = await Supabase.instance.client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.signup,
      );

      if (res.session != null && res.user != null) {
        final remoteUser = await getUserById(res.user!.id);
        if (remoteUser != null) {
          final user = remoteUser.copyWith(isLoggedIn: true, isSynced: true);
          await _authService.saveUser(user);
          state = AsyncValue.data(user);
          return true;
        } else {
          throw Exception('Verified, but profile not found');
        }
      } else {
        throw Exception('Verification failed or incomplete session');
      }
    } catch (e) {
      debugPrint('VerifyOTP Error: $e');
      rethrow;
    }
  }

  // Resend OTP
  Future<void> resendOTP(String email) async {
    await Supabase.instance.client.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  // ... (verifyOTP remains similar as it fetches from Supabase mostly, but let's check if we construct it manually there too. Yes we do.)
  // We need to update verifyOTP manually constructed user too if strictly needed, but getting from DB is safer.

  // ROLE SWITCHING LOGIC
  Future<void> switchRole(UserRole newRole) async {
    final currentUser = state.value;
    if (currentUser == null) return;

    // 1. Check if user actually HAS this role
    if (!currentUser.hasRole(newRole)) {
      throw Exception(
        'User does not have permission for role: ${newRole.name}',
      );
    }

    // 2. Optimistic Local Update
    final updatedUser = currentUser.copyWith(
      role: newRole,
    ); // Update active role locally

    // 3. Save to Hive
    await _authService.saveUser(updatedUser);
    state = AsyncValue.data(updatedUser);

    // 4. Sync Active Role to Supabase (Background)
    try {
      await Supabase.instance.client
          .from('users')
          .update({'active_role': newRole.name})
          .eq('id', currentUser.id);
    } catch (e) {
      debugPrint('Failed to sync active_role to cloud: $e');
      // Revert optimism on failure to avoid inconsistency
      await _authService.saveUser(currentUser);
      state = AsyncValue.data(currentUser);
      rethrow;
    }
  }

  // Dedicated Bypass Method for Development
  Future<void> bypassVerification({
    required String email,
    required UserRole role,
  }) async {
    if (kReleaseMode) {
      throw Exception(
        'Security Constraint: Dev bypass strictly disabled in production builds.',
      );
    }
    final client = Supabase.instance.client;

    // Try to fetch existing data from public.users (Signup creates this)
    String name = email.split('@')[0].toUpperCase();
    String phone = '0000000000';
    String address = 'Bypass Address';
    String kitchenName = '';
    String vehicleNumber = '';
    Map<String, dynamic> rolesHelper = {
      'customer': true,
      if (role == UserRole.chef) 'chef': 'pending',
      if (role == UserRole.rider) 'rider': 'pending',
    };

    try {
      final res = await client
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();
      if (res != null) {
        name = res['name'] ?? name;
        phone = res['phone'] ?? phone;
        address = res['address'] ?? address;
        kitchenName = res['kitchen_name'] ?? '';
        vehicleNumber = res['vehicle_number'] ?? '';
        // If DB has roles, use them
        if (res['roles'] != null) {
          rolesHelper = Map<String, dynamic>.from(res['roles']);
        }
      }
    } catch (e) {
      debugPrint('Bypass: Could not fetch metadata, using defaults: $e');
    }

    final user = UserModel(
      id: 'dev-bypass-${email.hashCode}', // Use a stable ID for the session
      name: name,
      email: email,
      phone: phone,
      address: address,
      role: role,
      kitchenName: kitchenName,
      vehicleNumber: vehicleNumber,
      isLoggedIn: true,
      isSynced: true,
      termsAccepted: true,
      status: (role == UserRole.chef || role == UserRole.rider)
          ? UserStatus.pending
          : UserStatus.approved,
      rolesData: rolesHelper,
    );

    await _authService.saveUser(user);
    state = AsyncValue.data(user);
  }

  Future<void> toggleKitchenStatus() async {
    final currentUser = state.value;
    if (currentUser == null) return;

    final updatedUser = currentUser.copyWith(
      isKitchenClosed: !currentUser.isKitchenClosed,
    );

    // Optimistic UI updates
    state = AsyncValue.data(updatedUser);

    try {
      // Update Supabase
      await Supabase.instance.client
          .from('users')
          .update({'is_kitchen_closed': updatedUser.isKitchenClosed})
          .eq('id', updatedUser.id);

      await _authService.saveUser(updatedUser);
    } catch (e) {
      debugPrint('Failed to toggle kitchen status: $e');
      state = AsyncValue.data(currentUser); // Revert local and state update
      rethrow;
    }
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    // 1. Check if image needs upload
    UserModel finalUser = updatedUser;
    if (updatedUser.profileImageUrl.isNotEmpty &&
        !updatedUser.profileImageUrl.startsWith('http')) {
      final file = File(updatedUser.profileImageUrl);
      if (file.existsSync()) {
        final fileName = _storageService.generateFileName(
          updatedUser.profileImageUrl,
          'profile_${updatedUser.id}',
        );
        final publicUrl = await _storageService.uploadFile(
          file: file,
          bucket: 'profile_images',
          remotePath: fileName,
        );
        if (publicUrl != null) {
          finalUser = updatedUser.copyWith(profileImageUrl: publicUrl);
        }
      }
    }

    // 2. Update Local
    await _authService.saveUser(finalUser);
    state = AsyncValue.data(finalUser);

    // 3. Update Supabase
    try {
      await Supabase.instance.client
          .from('users')
          .update({
            'name': finalUser.name,
            'phone': finalUser.phone,
            'address': finalUser.address,
            'kitchen_name': finalUser.kitchenName,
            'profile_image_url': finalUser.profileImageUrl,
            'ordered_categories': finalUser.orderedCategories,
            'following_chef_ids': finalUser.followingChefIds,
            'referral_code': finalUser.referralCode,
            'referred_by': finalUser.referredBy,
            'subscription_tier': finalUser.subscriptionTier.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', finalUser.id);
    } catch (e) {
      debugPrint('Profile sync error: $e');
    }
  }

  Future<UserModel?> getUserById(String id) async {
    // Check local cache first or fetch from Supabase
    // For now, simpler implementation:
    final client = Supabase.instance.client;
    try {
      final res = await client
          .from('users')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (res != null) {
        return UserModel.fromJson(res);
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
    }
    return null;
  }

  Future<int> getFollowerCount(String chefId) async {
    try {
      final res = await Supabase.instance.client
          .from('users')
          .select('id')
          .contains('following_chef_ids', [chefId])
          .count(CountOption.exact);

      return res.count;
    } catch (e) {
      debugPrint('Error counting followers: $e');
      return 0;
    }
  }
}
