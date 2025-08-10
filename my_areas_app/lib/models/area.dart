class Area {
  final String id; // 'A', 'B', 'C'
  final String name; // 'Area A', etc
  const Area({required this.id, required this.name});
}

const kAreas = <Area>[
  Area(id: 'A', name: 'Area A'),
  Area(id: 'B', name: 'Area B'),
  Area(id: 'C', name: 'Area C'),
];