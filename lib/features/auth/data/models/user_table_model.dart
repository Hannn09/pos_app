import 'package:food_pos/core/data/local/tables.dart';

class UserTableModel {
  final String id;
  final String username;
  final String name;
  final String? email;
  final String? phone;
  final String role;
  final bool isActive;
  final DateTime createdAt;

  const UserTableModel({
    required this.id,
    required this.username,
    required this.name,
    this.email,
    this.phone,
    this.role = 'cashier',
    this.isActive = true,
    required this.createdAt,
  });

  factory UserTableModel.fromMap(Map<String, dynamic> map) {
    return UserTableModel(
      id: map[UserColumns.id] as String,
      username: map[UserColumns.username] as String,
      name: map[UserColumns.name] as String,
      email: map[UserColumns.email] as String?,
      phone: map[UserColumns.phone] as String?,
      role: map[UserColumns.role] as String? ?? 'cashier',
      isActive: (map[UserColumns.isActive] as int? ?? 1) == 1,
      createdAt: DateTime.tryParse(map[UserColumns.createdAt] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap({String? pinHash}) {
    final map = <String, dynamic>{
      UserColumns.id: id,
      UserColumns.username: username,
      UserColumns.name: name,
      UserColumns.email: email,
      UserColumns.phone: phone,
      UserColumns.role: role,
      UserColumns.isActive: isActive ? 1 : 0,
      UserColumns.createdAt: createdAt.toIso8601String(),
    };
    if (pinHash != null) {
      map[UserColumns.pinHash] = pinHash;
    }
    return map;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserTableModel.fromJson(Map<String, dynamic> json) {
    return UserTableModel(
      id: json['id'] as String,
      username: json['username'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'cashier',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
