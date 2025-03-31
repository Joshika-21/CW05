import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Virtual Aquarium', home: const AquariumPage());
  }
}

// Fish model class
class Fish {
  final Color color;
  final double speed;

  Fish({required this.color, required this.speed});

  Map<String, dynamic> toMap() => {'color': color.value, 'speed': speed};

  static Fish fromMap(Map<String, dynamic> map) =>
      Fish(color: Color(map['color']), speed: map['speed']);
}

// SQLite DB Helper
class DBHelper {
  static Future<Database> database() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      p.join(dbPath, 'aquarium.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE settings(id INTEGER PRIMARY KEY, fishCount INTEGER, speed REAL, color INTEGER)',
        );
      },
      version: 1,
    );
  }

  static Future<void> saveSettings(
    int fishCount,
    double speed,
    int color,
  ) async {
    final db = await database();
    await db.insert('settings', {
      'id': 1,
      'fishCount': fishCount,
      'speed': speed,
      'color': color,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Map<String, dynamic>?> getSettings() async {
    final db = await database();
    final result = await db.query('settings', where: 'id = ?', whereArgs: [1]);
    return result.isNotEmpty ? result.first : null;
  }
}

class AquariumPage extends StatefulWidget {
  const AquariumPage({super.key});
  @override
  State<AquariumPage> createState() => _AquariumPageState();
}

class _AquariumPageState extends State<AquariumPage>
    with TickerProviderStateMixin {
  List<_FishWidget> fishWidgets = [];
  Color selectedColor = Colors.blue;
  double selectedSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final settings = await DBHelper.getSettings();
    if (settings != null) {
      setState(() {
        selectedColor = Color(settings['color']);
        selectedSpeed = settings['speed'];
        for (int i = 0; i < settings['fishCount']; i++) {
          fishWidgets.add(_createFish(selectedColor, selectedSpeed));
        }
      });
    }
  }

  _FishWidget _createFish(Color color, double speed) {
    return _FishWidget(
      key: UniqueKey(),
      color: color,
      speed: speed,
      vsync: this,
    );
  }

  void _addFish() {
    if (fishWidgets.length >= 10) return;
    setState(() {
      fishWidgets.add(_createFish(selectedColor, selectedSpeed));
    });
  }

  void _saveSettings() async {
    await DBHelper.saveSettings(
      fishWidgets.length,
      selectedSpeed,
      selectedColor.value,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings saved!')));
  }

  void _pickColor() {
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
    ];
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Pick a Color"),
            content: Wrap(
              children:
                  colors.map((c) {
                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedColor = c);
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: CircleAvatar(backgroundColor: c),
                      ),
                    );
                  }).toList(),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Virtual Aquarium")),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueAccent),
              color: Colors.lightBlue[50],
            ),
            child: Stack(children: fishWidgets),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _addFish,
                child: const Text("Add Fish"),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: _saveSettings,
                child: const Text("Save Settings"),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Slider(
            label: "Speed",
            min: 0.5,
            max: 5,
            divisions: 9,
            value: selectedSpeed,
            onChanged: (val) => setState(() => selectedSpeed = val),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Color: "),
              GestureDetector(
                onTap: _pickColor,
                child: CircleAvatar(backgroundColor: selectedColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FishWidget extends StatefulWidget {
  final Color color;
  final double speed;
  final TickerProvider vsync;

  const _FishWidget({
    required Key key,
    required this.color,
    required this.speed,
    required this.vsync,
  }) : super(key: key);

  @override
  State<_FishWidget> createState() => _FishWidgetState();
}

class _FishWidgetState extends State<_FishWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late double top;
  late double left;
  final random = Random();
  late double dx, dy;

  @override
  void initState() {
    super.initState();
    top = random.nextDouble() * 250;
    left = random.nextDouble() * 250;
    dx = (random.nextBool() ? 1 : -1) * widget.speed;
    dy = (random.nextBool() ? 1 : -1) * widget.speed;

    _controller =
        AnimationController(
            duration: const Duration(seconds: 1),
            vsync: widget.vsync,
          )
          ..addListener(() {
            setState(() {
              left += dx;
              top += dy;

              if (left < 0 || left > 270) dx = -dx;
              if (top < 0 || top > 270) dy = -dy;
            });
          })
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: CircleAvatar(backgroundColor: widget.color, radius: 10),
    );
  }
}
