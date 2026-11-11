import 'package:food_pos/features/auth/data/datasource/auth_local_datasource.dart';
import 'package:food_pos/features/auth/data/models/user_table_model.dart';
import 'package:food_pos/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl({AuthLocalDataSource? localDataSource})
      : _localDataSource = localDataSource ?? AuthLocalDataSource();

  @override
  Future<UserTableModel> login(String username, String password) =>
      _localDataSource.login(username, password);

  @override
  Future<UserTableModel> register({
    required String name,
    required String username,
    required String email,
    required String phone,
    required String password,
    String role = 'cashier',
  }) =>
      _localDataSource.register(
        name: name,
        username: username,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );

  @override
  Future<UserTableModel?> getSessionUser() => _localDataSource.getSessionUser();

  @override
  Future<String?> getSessionToken() => _localDataSource.getSessionToken();

  @override
  Future<bool> isLoggedIn() => _localDataSource.isLoggedIn();

  @override
  Future<void> logout() => _localDataSource.clearSession();
}
