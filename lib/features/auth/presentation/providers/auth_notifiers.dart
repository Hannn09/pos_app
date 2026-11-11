import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_pos/features/auth/data/models/user_table_model.dart';
import 'package:food_pos/features/auth/domain/providers/auth_providers.dart';

class AuthState {
  final bool isLoading;
  final UserTableModel? currentUser;
  final String? errorMessage;
  final bool isAuthenticated;

  const AuthState({
    this.isLoading = false,
    this.currentUser,
    this.errorMessage,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    UserTableModel? currentUser,
    String? errorMessage,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      currentUser: currentUser ?? this.currentUser,
      errorMessage: errorMessage,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Cek status sesi lokal saat inisialisasi
    _checkInitialAuth();
    return const AuthState(isLoading: true);
  }

  Future<void> _checkInitialAuth() async {
    final repo = ref.read(authRepositoryProvider);
    try {
      final isLoggedIn = await repo.isLoggedIn();
      if (isLoggedIn) {
        final user = await repo.getSessionUser();
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          currentUser: user,
        );
      } else {
        state = state.copyWith(isLoading: false, isAuthenticated: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false, isAuthenticated: false);
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.login(username, password);

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        currentUser: user,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String username,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.register(
        name: name,
        username: username,
        email: email,
        phone: phone,
        password: password,
      );

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        currentUser: user,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AuthState(isAuthenticated: false);
  }
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final currentUserProvider = Provider<UserTableModel?>((ref) {
  return ref.watch(authNotifierProvider).currentUser;
});
