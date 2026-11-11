import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_pos/features/auth/data/datasource/auth_local_datasource.dart';
import 'package:food_pos/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:food_pos/features/auth/domain/repositories/auth_repository.dart';

final authLocalDataSourceProvider = Provider(
  (ref) => AuthLocalDataSource(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    localDataSource: ref.read(authLocalDataSourceProvider),
  ),
);
