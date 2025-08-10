import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product_entry.dart';
import '../models/store_model.dart';

/// Provider placeholder for the opened stores box.
final storesBoxProvider = Provider<Box<StoreModel>>((ref) => throw UnimplementedError('storesBoxProvider must be overridden in main.dart'));

/// Initializes Hive and opens required boxes. Should be called before runApp.
Future<void> initHive() async {
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(ProductEntryAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(StoreModelAdapter());
  }
  await Hive.openBox<StoreModel>('storesBox');
}