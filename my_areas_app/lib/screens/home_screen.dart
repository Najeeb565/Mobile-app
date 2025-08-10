import 'package:flutter/material.dart';
import 'area_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final areas = const [
      ('A', 'Area A'),
      ('B', 'Area B'),
      ('C', 'Area C'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('My Areas')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: areas.length,
          itemBuilder: (context, index) {
            final (id, title) = areas[index];
            return _AreaCard(
              title: title,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AreaScreen(areaId: id, areaTitle: title),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({required this.title, required this.onTap});
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Center(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}