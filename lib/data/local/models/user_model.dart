import 'package:hive/hive.dart';
import 'subscription_model.dart';

part 'user_model.g.dart';

@HiveType(typeId: 2)
enum UserRole {
  @HiveField(0)
  customer,
  @HiveField(1)
  chef,
  @HiveField(2)
  rider,
  @HiveField(3)
  admin,
}

@HiveType(typeId: 7)
enum UserStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  approved,
  @HiveField(2)
  rejected,
  @HiveField(3)
  blocked,
}

@HiveType(typeId: 3)
class UserModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  // 1. We keep 'role' as the *Active Role* for app-wide compatibility
  @HiveField(2)
  final UserRole role;

  @HiveField(3)
  final bool isLoggedIn;

  @HiveField(4)
  final bool isSynced;
  
  @HiveField(5)
  final String email;

  @HiveField(6)
  final String phone;

  @HiveField(7)
  final String address;

  @HiveField(8)
  final String profileImageUrl;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final String kitchenName;

  @HiveField(11)
  final List<String> categories;

  @HiveField(12)
  final String vehicleType;

  @HiveField(13)
  final String vehicleNumber;

  @HiveField(14)
  final bool termsAccepted;

  // 2. Status is now derived from the Active Role's status in the roles map
  @HiveField(15)
  final UserStatus status;

  @HiveField(16)
  final bool isKitchenClosed;

  @HiveField(17)
  final DateTime updatedAt;

  @HiveField(18)
  final List<String> followingChefIds;

  @HiveField(19)
  final String? referralCode;

  @HiveField(20)
  final String? referredBy;

  @HiveField(21)
  final SubscriptionTier subscriptionTier;

  @HiveField(22)
  final DateTime? subscriptionExpiry;

  @HiveField(23)
  final Map<String, int> orderedCategories;

  // 3. NEW: The Multi-Role Data Source
  @HiveField(24)
  final Map<String, dynamic> rolesData;

  @HiveField(25)
  final bool isAdmin;

  UserModel({
    required this.id,
    required this.name,
    required this.role, // Acts as Active Role
    this.isLoggedIn = false,
    this.isSynced = false,
    this.email = '',
    this.phone = '',
    this.address = '',
    this.profileImageUrl = '',
    this.kitchenName = '',
    this.categories = const [],
    this.vehicleType = '',
    this.vehicleNumber = '',
    this.termsAccepted = false,
    this.status = UserStatus.approved,
    this.isKitchenClosed = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.followingChefIds = const [],
    this.referralCode,
    this.referredBy,
    this.subscriptionTier = SubscriptionTier.free,
    this.subscriptionExpiry,
    this.orderedCategories = const {},
    this.rolesData = const {'customer': true}, // Default to simple customer
    this.isAdmin = false,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Helper to check if a specific role is approved
  bool isRoleApproved(UserRole targetRole) {
    if (targetRole == UserRole.admin) return isAdmin; // Admins rely on isAdmin flag
    if (targetRole == UserRole.customer) return true; // Customers are always approved
    
    final val = rolesData[targetRole.name];
    return val == 'approved';
  }

  // Helper to check if user HAS a role (pending or approved)
  bool hasRole(UserRole targetRole) {
    if (targetRole == UserRole.admin) return isAdmin;
    if (targetRole == UserRole.customer) return true;
    final val = rolesData[targetRole.name];
    return val != null && val != 'none' && val != false;
  }

  UserModel copyWith({
    String? id,
    String? name,
    UserRole? role,
    bool? isLoggedIn,
    bool? isSynced,
    String? email,
    String? phone,
    String? address,
    String? profileImageUrl,
    String? kitchenName,
    List<String>? categories,
    String? vehicleType,
    String? vehicleNumber,
    bool? termsAccepted,
    UserStatus? status,
    bool? isKitchenClosed,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? followingChefIds,
    String? referralCode,
    String? referredBy,
    SubscriptionTier? subscriptionTier,
    DateTime? subscriptionExpiry,
    Map<String, int>? orderedCategories,
    Map<String, dynamic>? rolesData,
    bool? isAdmin,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isSynced: isSynced ?? this.isSynced,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      kitchenName: kitchenName ?? this.kitchenName,
      categories: categories ?? this.categories,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      status: status ?? this.status,
      isKitchenClosed: isKitchenClosed ?? this.isKitchenClosed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      followingChefIds: followingChefIds ?? this.followingChefIds,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      orderedCategories: orderedCategories ?? this.orderedCategories,
      rolesData: rolesData ?? this.rolesData,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // 1. Parse Active Role
    final activeRoleStr = json['active_role'] as String? ?? 'customer';
    final activeRole = UserRole.values.firstWhere(
      (e) => e.name == activeRoleStr, 
      orElse: () => UserRole.customer
    );

    // 2. Parse Roles Data
    Map<String, dynamic> rolesHelper = {};
    if (json['roles'] != null) {
      rolesHelper = Map<String, dynamic>.from(json['roles']);
    } else {
      // Fallback for old data or immediate migration
      rolesHelper = {'customer': true};
      final oldRole = json['role'] as String?;
      if (oldRole == 'chef') rolesHelper['chef'] = json['status'] ?? 'pending';
      if (oldRole == 'rider') rolesHelper['rider'] = json['status'] ?? 'pending';
    }

    // 3. Determine Status based on Active Role
    // If active role is customer, status is approved. 
    // If chef/rider, fetch status from the map.
    UserStatus resolvedStatus = UserStatus.approved;
    
    if (activeRole == UserRole.chef || activeRole == UserRole.rider) {
      final statusStr = rolesHelper[activeRole.name];
      if (statusStr is String) {
        resolvedStatus = UserStatus.values.firstWhere(
          (e) => e.name == statusStr, 
          orElse: () => UserStatus.pending
        );
      }
    } else if (activeRole == UserRole.admin) {
        resolvedStatus = UserStatus.approved;
    }

    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'User',
      role: activeRole, // Mapped to active_role
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      kitchenName: json['kitchen_name'] as String? ?? '',
      categories: (json['categories'] is List) 
          ? (json['categories'] as List).map((e) => e.toString()).toList()
          : (json['categories'] is String && json['categories'] != null)
              ? List<String>.from(json['categories'].toString().replaceAll('[', '').replaceAll(']', '').split(',').map((e) => e.trim()))
              : [],
      vehicleType: json['vehicle_type'] as String? ?? '',
      vehicleNumber: json['vehicle_number'] as String? ?? '',
      termsAccepted: json['terms_accepted'] as bool? ?? false,
      isLoggedIn: true,
      isSynced: true,
      status: resolvedStatus,
      isKitchenClosed: json['is_kitchen_closed'] as bool? ?? false,
      createdAt: json['created_at'] != null ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? (DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()) : DateTime.now(),
      
      // Extended Fields
      orderedCategories: json['ordered_categories'] is Map 
          ? Map<String, int>.from(json['ordered_categories'] as Map) 
          : {},
      followingChefIds: (json['following_chef_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      referralCode: json['referral_code']?.toString(),
      referredBy: json['referred_by']?.toString(),
      subscriptionTier: SubscriptionTier.values.firstWhere(
        (e) => e.name == (json['subscription_tier'] ?? 'free'),
        orElse: () => SubscriptionTier.free,
      ),
      subscriptionExpiry: json['subscription_expiry'] != null ? DateTime.tryParse(json['subscription_expiry'].toString()) : null,
      
      // New Roles Data
      rolesData: rolesHelper,
      isAdmin: json['is_admin'] as bool? ?? (activeRole == UserRole.admin),
    );
  }
}
