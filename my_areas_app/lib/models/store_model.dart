import 'package:hive/hive.dart';
import 'product_entry.dart';

/// Represents a store under a fixed area.
@HiveType(typeId: 2)
class StoreModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String areaId; // "A", "B", or "C"

  @HiveField(2)
  String name;

  /// Map keyed by ISO date string (yyyy-MM-dd) to product entries captured on that date.
  @HiveField(3)
  Map<String, List<ProductEntry>> productsByDate;

  StoreModel({
    required this.id,
    required this.areaId,
    required this.name,
    Map<String, List<ProductEntry>>? productsByDate,
  }) : productsByDate = productsByDate ?? <String, List<ProductEntry>>{};
}

class StoreModelAdapter extends TypeAdapter<StoreModel> {
  @override
  final int typeId = 2;

  @override
  StoreModel read(BinaryReader reader) {
    final id = reader.read() as String;
    final areaId = reader.read() as String;
    final name = reader.read() as String;
    final dynamic rawMap = reader.read();
    final Map<String, List<ProductEntry>> map = {};
    if (rawMap is Map) {
      rawMap.forEach((key, value) {
        final list = (value as List).cast<ProductEntry>();
        map[key as String] = list;
      });
    }
    return StoreModel(id: id, areaId: areaId, name: name, productsByDate: map);
  }

  @override
  void write(BinaryWriter writer, StoreModel obj) {
    writer
      ..write(obj.id)
      ..write(obj.areaId)
      ..write(obj.name)
      ..write(obj.productsByDate);
  }
}