import 'package:hive/hive.dart';

/// Represents a single product record captured for a specific store and date.
@HiveType(typeId: 1)
class ProductEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String productName;

  @HiveField(2)
  DateTime expiryDate;

  @HiveField(3)
  int quantity;

  ProductEntry({
    required this.id,
    required this.productName,
    required this.expiryDate,
    required this.quantity,
  });
}

class ProductEntryAdapter extends TypeAdapter<ProductEntry> {
  @override
  final int typeId = 1;

  @override
  ProductEntry read(BinaryReader reader) {
    final id = reader.read() as String;
    final name = reader.read() as String;
    final expiry = reader.read() as DateTime;
    final qty = reader.read() as int;
    return ProductEntry(
      id: id,
      productName: name,
      expiryDate: expiry,
      quantity: qty,
    );
  }

  @override
  void write(BinaryWriter writer, ProductEntry obj) {
    writer
      ..write(obj.id)
      ..write(obj.productName)
      ..write(obj.expiryDate)
      ..write(obj.quantity);
  }
}