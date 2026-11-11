import 'package:food_pos/features/auth/data/models/user_table_model.dart';

abstract class AuthRepository {
  Future<UserTableModel> login(String username, String password);
  Future<UserTableModel> register({
    required String name,
    required String username,
    required String email,
    required String phone,
    required String password,
    String role,
  });
  Future<UserTableModel?> getSessionUser();
  Future<String?> getSessionToken();
  Future<bool> isLoggedIn();
  Future<void> logout();
}
