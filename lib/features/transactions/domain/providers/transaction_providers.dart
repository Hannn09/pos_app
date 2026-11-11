import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_pos/features/transactions/data/datasource/transaction_local_datasource.dart';
import 'package:food_pos/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:food_pos/features/transactions/domain/repositories/transaction_repository.dart';

final transactionLocalDataSourceProvider = Provider(
  (ref) => TransactionLocalDataSource(),
);

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepositoryImpl(
    localDataSource: ref.read(transactionLocalDataSourceProvider),
  ),
);
