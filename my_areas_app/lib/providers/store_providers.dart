import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../models/product_entry.dart';
import '../models/store_model.dart';
import 'hive_providers.dart';

String dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(DateTime(date.year, date.month, date.day));

/// Returns all stores within an area, sorted by name.
final storeListByAreaProvider = Provider.family<List<StoreModel>, String>((ref, areaId) {
  final box = ref.watch(storesBoxProvider);
  final stores = box.values.where((s) => s.areaId == areaId).toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return stores;
});

/// Returns a store by id.
final storeByIdProvider = Provider.family<StoreModel?, String>((ref, storeId) {
  final box = ref.watch(storesBoxProvider);
  return box.get(storeId);
});

class ProductsQuery {
  final String storeId;
  final DateTime date;
  const ProductsQuery({required this.storeId, required this.date});

  @override
  bool operator ==(Object other) =>
      other is ProductsQuery && other.storeId == storeId && dateKey(other.date) == dateKey(date);

  @override
  int get hashCode => Object.hash(storeId, dateKey(date));
}

/// Returns products for a store for the specified date.
final productsForStoreAndDateProvider = Provider.family<List<ProductEntry>, ProductsQuery>((ref, query) {
  final box = ref.watch(storesBoxProvider);
  final store = box.get(query.storeId);
  if (store == null) return const [];
  final key = dateKey(query.date);
  final list = store.productsByDate[key];
  final copy = List<ProductEntry>.from(list ?? const []);
  copy.sort((a, b) => a.productName.toLowerCase().compareTo(b.productName.toLowerCase()));
  return copy;
});

/// Controller for managing stores.
class StoreController {
  StoreController(this.ref);
  final Ref ref;

  Box<StoreModel> get _box => ref.read(storesBoxProvider);

  Future<void> addStore({required String areaId, required String name}) async {
    final id = _generateId();
    final store = StoreModel(id: id, areaId: areaId, name: name.trim());
    await _box.put(store.id, store);
    ref.invalidate(storeListByAreaProvider(areaId));
  }

  Future<void> renameStore({required String storeId, required String newName}) async {
    final store = _box.get(storeId);
    if (store == null) return;
    store.name = newName.trim();
    await _box.put(store.id, store);
    ref.invalidate(storeListByAreaProvider(store.areaId));
    ref.invalidate(storeByIdProvider(store.id));
  }

  Future<void> deleteStore({required String storeId}) async {
    final store = _box.get(storeId);
    if (store == null) return;
    final areaId = store.areaId;
    await _box.delete(storeId);
    ref.invalidate(storeListByAreaProvider(areaId));
  }

  String _generateId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rand = Random().nextInt(1 << 32);
    return '${now}_$rand';
  }
}

/// Controller for managing products per store/date.
class ProductController {
  ProductController(this.ref);
  final Ref ref;

  Box<StoreModel> get _box => ref.read(storesBoxProvider);

  Future<void> addProduct({
    required String storeId,
    required DateTime date,
    required String productName,
    required DateTime expiryDate,
    required int quantity,
  }) async {
    final store = _box.get(storeId);
    if (store == null) return;
    final key = dateKey(date);
    final entry = ProductEntry(
      id: _generateId(),
      productName: productName.trim(),
      expiryDate: DateTime(expiryDate.year, expiryDate.month, expiryDate.day),
      quantity: quantity,
    );
    final list = List<ProductEntry>.from(store.productsByDate[key] ?? const []);
    list.add(entry);
    store.productsByDate[key] = list;
    await _box.put(store.id, store);
    ref.invalidate(productsForStoreAndDateProvider(ProductsQuery(storeId: storeId, date: date)));
  }

  Future<void> editProduct({
    required String storeId,
    required DateTime date,
    required String productId,
    required String productName,
    required DateTime expiryDate,
    required int quantity,
  }) async {
    final store = _box.get(storeId);
    if (store == null) return;
    final key = dateKey(date);
    final list = List<ProductEntry>.from(store.productsByDate[key] ?? const []);
    final idx = list.indexWhere((e) => e.id == productId);
    if (idx == -1) return;
    list[idx] = ProductEntry(
      id: productId,
      productName: productName.trim(),
      expiryDate: DateTime(expiryDate.year, expiryDate.month, expiryDate.day),
      quantity: quantity,
    );
    store.productsByDate[key] = list;
    await _box.put(store.id, store);
    ref.invalidate(productsForStoreAndDateProvider(ProductsQuery(storeId: storeId, date: date)));
  }

  Future<void> deleteProduct({
    required String storeId,
    required DateTime date,
    required String productId,
  }) async {
    final store = _box.get(storeId);
    if (store == null) return;
    final key = dateKey(date);
    final list = List<ProductEntry>.from(store.productsByDate[key] ?? const []);
    list.removeWhere((e) => e.id == productId);
    if (list.isEmpty) {
      store.productsByDate.remove(key);
    } else {
      store.productsByDate[key] = list;
    }
    await _box.put(store.id, store);
    ref.invalidate(productsForStoreAndDateProvider(ProductsQuery(storeId: storeId, date: date)));
  }

  Future<void> clearDate({required String storeId, required DateTime date}) async {
    final store = _box.get(storeId);
    if (store == null) return;
    final key = dateKey(date);
    store.productsByDate.remove(key);
    await _box.put(store.id, store);
    ref.invalidate(productsForStoreAndDateProvider(ProductsQuery(storeId: storeId, date: date)));
  }

  String _generateId() => StoreController(ref)._generateId();
}