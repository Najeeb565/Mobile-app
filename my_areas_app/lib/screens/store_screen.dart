import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/product_entry.dart';
import '../providers/store_providers.dart';

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key, required this.storeId});
  final String storeId;

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  late DateTime selectedDate;
  final _productController = TextEditingController();
  final _qtyController = TextEditingController();
  DateTime? _expiryDate;
  String _search = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _productController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeByIdProvider(widget.storeId));
    final products = ref.watch(productsForStoreAndDateProvider(ProductsQuery(storeId: widget.storeId, date: selectedDate)));
    final controller = ProductController(ref);

    final filtered = products
        .where((e) => e.productName.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(store?.name ?? 'Store'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Date: '),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = DateTime(picked.year, picked.month, picked.day));
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: products.isEmpty
                      ? null
                      : () async {
                          final confirmed = await _confirmClear(context);
                          if (confirmed == true) {
                            await controller.clearDate(storeId: widget.storeId, date: selectedDate);
                          }
                        },
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text("Clear Today's Data"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add Product', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _productController,
                      decoration: const InputDecoration(labelText: 'Product Name'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _expiryDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => _expiryDate = DateTime(picked.year, picked.month, picked.day));
                              }
                            },
                            icon: const Icon(Icons.event),
                            label: Text(
                              _expiryDate == null
                                  ? 'Expiry Date'
                                  : 'Expiry: ${DateFormat('yyyy-MM-dd').format(_expiryDate!)}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _qtyController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Quantity'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            final name = _productController.text.trim();
                            final qty = int.tryParse(_qtyController.text.trim());
                            if (name.isEmpty || _expiryDate == null || qty == null) {
                              _showSnack(context, 'Please enter name, expiry, and numeric quantity');
                              return;
                            }
                            await controller.addProduct(
                              storeId: widget.storeId,
                              date: selectedDate,
                              productName: name,
                              expiryDate: _expiryDate!,
                              quantity: qty,
                            );
                            setState(() {
                              _productController.clear();
                              _qtyController.clear();
                              _expiryDate = null;
                            });
                          },
                          child: const Text('Add Product'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search products for this date',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No products for this date'))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return ListTile(
                          title: Text(item.productName),
                          subtitle: Text('Expiry: ${DateFormat('yyyy-MM-dd').format(item.expiryDate)} • Qty: ${item.quantity}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  final edited = await _editProductDialog(context, item);
                                  if (edited != null) {
                                    await controller.editProduct(
                                      storeId: widget.storeId,
                                      date: selectedDate,
                                      productId: item.id,
                                      productName: edited.productName,
                                      expiryDate: edited.expiryDate,
                                      quantity: edited.quantity,
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  final confirm = await _confirmDelete(context, item);
                                  if (confirm == true) {
                                    await controller.deleteProduct(
                                      storeId: widget.storeId,
                                      date: selectedDate,
                                      productId: item.id,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, ProductEntry entry) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "${entry.productName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          )
        ],
      ),
    );
  }

  Future<ProductEntry?> _editProductDialog(BuildContext context, ProductEntry entry) async {
    final nameController = TextEditingController(text: entry.productName);
    final qtyController = TextEditingController(text: entry.quantity.toString());
    DateTime? expiry = entry.expiryDate;

    final result = await showDialog<ProductEntry>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: expiry ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        expiry = DateTime(picked.year, picked.month, picked.day);
                        // ignore: use_build_context_synchronously
                        (context as Element).markNeedsBuild();
                      }
                    },
                    icon: const Icon(Icons.event),
                    label: Text(
                      expiry == null
                          ? 'Expiry Date'
                          : 'Expiry: ${DateFormat('yyyy-MM-dd').format(expiry!)}',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final qty = int.tryParse(qtyController.text.trim());
              if (name.isEmpty || expiry == null || qty == null) return;
              Navigator.pop(
                context,
                ProductEntry(id: entry.id, productName: name, expiryDate: expiry!, quantity: qty),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    return result;
  }

  Future<bool?> _confirmClear(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Clear Today's Data"),
        content: const Text('Delete all products for the selected date?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          )
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}