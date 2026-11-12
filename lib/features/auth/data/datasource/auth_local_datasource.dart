import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:food_pos/core/data/local/database_helper.dart';
import 'package:food_pos/core/data/local/tables.dart';
import 'package:food_pos/features/auth/data/models/user_table_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthLocalDataSource {
  final DatabaseHelper _dbHelper;

  static const String _sessionTokenKey = 'pos_auth_token';
  static const String _sessionUserKey = 'pos_auth_user';

  AuthLocalDataSource({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password.trim())).toString();
  }

  Future<UserTableModel> login(String username, String password) async {
    final db = await _dbHelper.database;
    final cleanUsername = username.trim().toLowerCase();
    final cleanPassword = password.trim();
    final hashedPassword = _hashPassword(cleanPassword);

    final List<Map<String, dynamic>> results = await db.query(
      AppTables.users,
      where: 'LOWER(${UserColumns.username}) = ? AND ${UserColumns.isActive} = 1',
      whereArgs: [cleanUsername],
      limit: 1,
    );

    if (results.isEmpty) {
      throw Exception('User with username "$username" not found or inactive');
    }

    final userMap = results.first;
    final storedHash = userMap[UserColumns.pinHash] as String?;

    final isPasswordValid = storedHash == hashedPassword || storedHash == cleanPassword;
    if (!isPasswordValid) {
      throw Exception('Invalid password / PIN');
    }

    final user = UserTableModel.fromMap(userMap);

    final token = 'offline_token_${user.id}_${DateTime.now().millisecondsSinceEpoch}';
    await saveSession(user, token);

    return user;
  }

  Future<UserTableModel> register({
    required String name,
    required String username,
    required String email,
    required String phone,
    required String password,
    String role = 'cashier',
  }) async {
    final db = await _dbHelper.database;
    final cleanUsername = username.trim().toLowerCase();

    final existing = await db.query(
      AppTables.users,
      where: 'LOWER(${UserColumns.username}) = ?',
      whereArgs: [cleanUsername],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      throw Exception('Username "$username" is already registered');
    }

    final newId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final hashedPassword = _hashPassword(password);
    final now = DateTime.now();

    final newUser = UserTableModel(
      id: newId,
      username: cleanUsername,
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      role: role,
      isActive: true,
      createdAt: now,
    );

    await db.insert(
      AppTables.users,
      newUser.toMap(pinHash: hashedPassword),
    );

    final token = 'offline_token_${newUser.id}_${DateTime.now().millisecondsSinceEpoch}';
    await saveSession(newUser, token);

    return newUser;
  }

  Future<void> saveSession(UserTableModel user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionTokenKey, token);
    await prefs.setString(_sessionUserKey, jsonEncode(user.toJson()));
  }

  Future<UserTableModel?> getSessionUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJsonStr = prefs.getString(_sessionUserKey);
    if (userJsonStr == null || userJsonStr.isEmpty) return null;

    try {
      final Map<String, dynamic> userMap = jsonDecode(userJsonStr);
      return UserTableModel.fromJson(userMap);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionTokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getSessionToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionTokenKey);
    await prefs.remove(_sessionUserKey);
  }
}
