import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/store_providers.dart';
import '../providers/hive_providers.dart';
import '../models/store_model.dart';
import 'store_screen.dart';

class AreaScreen extends ConsumerWidget {
  const AreaScreen({super.key, required this.areaId, required this.areaTitle});
  final String areaId; // 'A', 'B', 'C'
  final String areaTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stores = ref.watch(storeListByAreaProvider(areaId));
    final controller = StoreController(ref);

    return Scaffold(
      appBar: AppBar(
        title: Text(areaTitle),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: stores.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final store = stores[index];
          return ListTile(
            title: Text(store.name),
            subtitle: Text('Store ID: ${store.id.substring(0, 6)}…'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StoreScreen(storeId: store.id),
              ),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  final name = await _promptForName(context, initial: store.name);
                  if (name != null && name.trim().isNotEmpty) {
                    await controller.renameStore(storeId: store.id, newName: name);
                  }
                } else if (value == 'delete') {
                  final confirmed = await _confirmDelete(context, store);
                  if (confirmed == true) {
                    await controller.deleteStore(storeId: store.id);
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit Name')),
                const PopupMenuItem(value: 'delete', child: Text('Delete Store')),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final name = await _promptForName(context);
          if (name != null && name.trim().isNotEmpty) {
            await controller.addStore(areaId: areaId, name: name);
          }
        },
        label: const Text('Add Store'),
        icon: const Icon(Icons.add_business),
      ),
    );
  }

  Future<String?> _promptForName(BuildContext context, {String? initial}) async {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(initial == null ? 'Add Store' : 'Edit Store'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Store name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, StoreModel store) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Store'),
        content: Text('Delete "${store.name}"? This will remove all saved products for this store.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}