import 'package:flutter/material.dart';

class AlchemyElement {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const AlchemyElement({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

final List<AlchemyElement> initialElements = [
  AlchemyElement(id: 'fire', name: 'Fire', icon: Icons.local_fire_department, color: Colors.orange),
  AlchemyElement(id: 'water', name: 'Water', icon: Icons.water_drop, color: Colors.blue),
  AlchemyElement(id: 'earth', name: 'Earth', icon: Icons.landscape, color: Colors.brown),
  AlchemyElement(id: 'air', name: 'Air', icon: Icons.air, color: Colors.lightBlueAccent),
];

final List<AlchemyElement> allElements = [
  ...initialElements,
  AlchemyElement(id: 'steam', name: 'Steam', icon: Icons.cloud, color: Colors.grey.shade400),
  AlchemyElement(id: 'lava', name: 'Lava', icon: Icons.volcano, color: Colors.red.shade700),
  AlchemyElement(id: 'dust', name: 'Dust', icon: Icons.grain, color: Colors.brown.shade300),
  AlchemyElement(id: 'mud', name: 'Mud', icon: Icons.bubble_chart, color: Colors.brown.shade800),
  AlchemyElement(id: 'rain', name: 'Rain', icon: Icons.cloud_download, color: Colors.blueGrey),
  AlchemyElement(id: 'plant', name: 'Plant', icon: Icons.grass, color: Colors.green),
  AlchemyElement(id: 'energy', name: 'Energy', icon: Icons.bolt, color: Colors.yellow.shade700),
  AlchemyElement(id: 'stone', name: 'Stone', icon: Icons.circle, color: Colors.grey.shade800),
  AlchemyElement(id: 'sand', name: 'Sand', icon: Icons.circle_outlined, color: Colors.amber.shade100),
  AlchemyElement(id: 'glass', name: 'Glass', icon: Icons.crop_square, color: Colors.cyan.shade100),
  AlchemyElement(id: 'metal', name: 'Metal', icon: Icons.build, color: Colors.blueGrey.shade700),
  AlchemyElement(id: 'electricity', name: 'Electricity', icon: Icons.electric_bolt, color: Colors.yellowAccent),
  AlchemyElement(id: 'swamp', name: 'Swamp', icon: Icons.grass_outlined, color: Colors.green.shade900),
  AlchemyElement(id: 'life', name: 'Life', icon: Icons.favorite, color: Colors.pink),
  AlchemyElement(id: 'human', name: 'Human', icon: Icons.person, color: Colors.orange.shade200),
  AlchemyElement(id: 'wizard', name: 'Wizard', icon: Icons.auto_fix_high, color: Colors.purple),
];

// Map of sorted(id1, id2) -> resultId
final Map<String, String> recipes = {
  'fire+water': 'steam',
  'earth+fire': 'lava',
  'air+earth': 'dust',
  'earth+water': 'mud',
  'air+water': 'rain',
  'earth+rain': 'plant',
  'air+fire': 'energy',
  'lava+water': 'stone',
  'air+stone': 'sand',
  'fire+sand': 'glass',
  'fire+stone': 'metal',
  'energy+metal': 'electricity',
  'mud+plant': 'swamp',
  'energy+swamp': 'life',
  'earth+life': 'human',
  'energy+human': 'wizard',
};

String? getCombinationResult(String id1, String id2) {
  final List<String> ids = [id1, id2]..sort();
  final key = '${ids[0]}+${ids[1]}';
  return recipes[key];
}

AlchemyElement getElementById(String id) {
  return allElements.firstWhere(
    (e) => e.id == id, 
    orElse: () => AlchemyElement(id: 'unknown', name: '?', icon: Icons.question_mark, color: Colors.grey),
  );
}
