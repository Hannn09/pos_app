import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_pos/features/products/data/datasource/product_local_datasource.dart';
import 'package:food_pos/features/products/data/repositories/product_repository_impl.dart';
import 'package:food_pos/features/products/domain/repositories/product_repository.dart';

final productLocalDataSourceProvider = Provider(
  (ref) => ProductLocalDataSource(),
);

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepositoryImpl(
    localDataSource: ref.read(productLocalDataSourceProvider),
  ),
);
