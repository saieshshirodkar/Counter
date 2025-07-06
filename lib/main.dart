import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'log_screen.dart';
import 'settings_screen.dart';
import 'theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final themeIndex = prefs.getInt('appTheme') ?? 0;
  final appTheme = AppTheme.values[themeIndex];
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(appTheme),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Counters',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: ThemeProvider.getThemeColor(themeProvider.appTheme),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: GoogleFonts.robotoMonoTextTheme(
          Theme.of(context).textTheme,
        ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: const CounterListScreen(),
    );
  }
}

class LogEntry {
  final String counterName;
  final String action;
  final DateTime timestamp;

  LogEntry({
    required this.counterName,
    required this.action,
    required this.timestamp,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      counterName: json['counterName'],
      action: json['action'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'counterName': counterName,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class Log {
  List<LogEntry> entries = [];

  Log();

  factory Log.fromJson(Map<String, dynamic> json) {
    final log = Log();
    log.entries = (json['entries'] as List)
        .map((entryJson) => LogEntry.fromJson(entryJson))
        .toList();
    return log;
  }

  void add(LogEntry entry) {
    entries.add(entry);
  }

  Map<String, dynamic> toJson() {
    return {'entries': entries.map((entry) => entry.toJson()).toList()};
  }
}

class Counter {
  String name;
  int value;
  Color color;

  Counter({required this.name, this.value = 0, required this.color});

  factory Counter.fromJson(Map<String, dynamic> json) {
    return Counter(
      name: json['name'],
      value: json['value'],
      color: Color(json['color']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'value': value, 'color': color.value};
  }
}

class CounterListScreen extends StatefulWidget {
  const CounterListScreen({super.key});

  @override
  State<CounterListScreen> createState() => _CounterListScreenState();
}

class _CounterListScreenState extends State<CounterListScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Counter> _counters = [];
  Log _log = Log();
  final List<Color> _presetColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
  ];
  CounterShape _counterShape = CounterShape.rectangle;
  CounterSize _counterSize = CounterSize.medium;
  CounterLayout _counterLayout = CounterLayout.grid;
  bool _isReorderMode = false;

  @override
  void initState() {
    super.initState();
    _loadCounters();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _counterShape = CounterShape.values[prefs.getInt('counterShape') ?? 0];
      _counterSize = CounterSize.values[prefs.getInt('counterSize') ?? 1];
      _counterLayout = CounterLayout.values[prefs.getInt('counterLayout') ?? 0];
    });
  }

  Future<void> _loadCounters() async {
    final prefs = await SharedPreferences.getInstance();
    final String? countersString = prefs.getString('counters');
    if (countersString != null) {
      final List<dynamic> countersJson = jsonDecode(countersString);
      setState(() {
        _counters = countersJson.map((json) => Counter.fromJson(json)).toList();
      });
    }
    final String? logString = prefs.getString('log');
    if (logString != null) {
      final Map<String, dynamic> logJson = jsonDecode(logString);
      setState(() {
        _log = Log.fromJson(logJson);
      });
    }
  }

  Future<void> _saveCounters() async {
    final prefs = await SharedPreferences.getInstance();
    final String countersString = jsonEncode(
      _counters.map((counter) => counter.toJson()).toList(),
    );
    await prefs.setString('counters', countersString);
    final String logString = jsonEncode(_log.toJson());
    await prefs.setString('log', logString);
  }

  void _addCounter(String name, Color color) {
    setState(() {
      final newCounter = Counter(name: name, color: color);
      _counters.add(newCounter);
      _listKey.currentState?.insertItem(_counters.length - 1);
    });
    _saveCounters();
  }

  void _incrementCounter(int index) {
    setState(() {
      _counters[index].value++;
      _log.add(
        LogEntry(
          counterName: _counters[index].name,
          action: 'increment',
          timestamp: DateTime.now(),
        ),
      );
    });
    _saveCounters();
  }

  void _decrementCounter(int index) {
    setState(() {
      if (_counters[index].value > 0) {
        _counters[index].value--;
        _log.add(
          LogEntry(
            counterName: _counters[index].name,
            action: 'decrement',
            timestamp: DateTime.now(),
          ),
        );
      }
    });
    _saveCounters();
  }

  void _deleteCounter(int index) {
    final removedCounter = _counters[index];
    setState(() {
      _counters.removeAt(index);
    });
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => SizeTransition(
        sizeFactor: animation,
        child: _buildCounterItem(index, counter: removedCounter),
      ),
    );
    _saveCounters();
  }

  void _setCounterValue(int index, int value) {
    setState(() {
      _counters[index].value = value;
    });
    _saveCounters();
  }

  void _showAddCounterDialog() {
    final TextEditingController controller = TextEditingController();
    Color selectedColor = _presetColors[Random().nextInt(_presetColors.length)];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Counter'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Counter Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Select a Color'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _presetColors.map((color) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedColor = color;
                          });
                        },
                        child: CircleAvatar(
                          backgroundColor: color,
                          radius: 22,
                          child: selectedColor == color
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      _addCounter(controller.text, selectedColor);
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Counter?'),
          content: Text('Are you sure you want to delete "${_counters[index].name}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteCounter(index);
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showSetCounterDialog(int index) {
    final TextEditingController controller = TextEditingController();
    controller.text = _counters[index].value.toString();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Set Value for ${_counters[index].name}'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Enter value'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final int? value = int.tryParse(controller.text);
                if (value != null) {
                  _setCounterValue(index, value);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Set'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_counters[index].name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showSetCounterDialog(index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showDeleteConfirmationDialog(index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.reorder),
                title: const Text('Reorder'),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _isReorderMode = true;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Counters',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: _isReorderMode
            ? [
                IconButton(
                  icon: const Icon(Icons.done),
                  onPressed: () {
                    setState(() {
                      _isReorderMode = false;
                    });
                  },
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => LogScreen(log: _log)),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        )
                        .then((_) => _loadSettings());
                  },
                ),
              ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return _counterLayout == CounterLayout.grid
              ? _buildCountersGrid(constraints)
              : _buildCountersList();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCounterDialog,
        label: const Text('Add Counter'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  double _getGridAspectRatio(int crossAxisCount) {
    double aspectRatio = 1.0;
    if (_counterShape == CounterShape.rectangle) {
      aspectRatio = crossAxisCount == 2 ? 1.5 : 2.0;
    }
    switch (_counterSize) {
      case CounterSize.small:
        return aspectRatio * 1.2;
      case CounterSize.medium:
        return aspectRatio;
      case CounterSize.large:
        return aspectRatio * 0.8;
    }
  }

  Widget _buildCountersGrid(BoxConstraints constraints) {
    final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
    return ReorderableGridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: _getGridAspectRatio(crossAxisCount),
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: _counters.length,
      itemBuilder: (context, index) {
        return _buildCounterItem(index, key: ValueKey(_counters[index]));
      },
      onReorder: _isReorderMode
          ? (oldIndex, newIndex) {
              setState(() {
                final counter = _counters.removeAt(oldIndex);
                _counters.insert(newIndex, counter);
              });
              _saveCounters();
            }
          : (oldIndex, newIndex) {},
    );
  }

  Widget _buildCountersList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _counters.length,
      itemBuilder: (context, index) {
        return _buildCounterItem(index, key: ValueKey(_counters[index]));
      },
      onReorder: _isReorderMode
          ? (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final counter = _counters.removeAt(oldIndex);
                _counters.insert(newIndex, counter);
              });
              _saveCounters();
            }
          : (oldIndex, newIndex) {},
    );
  }

  Widget _buildCounterItem(int index, {Counter? counter, Key? key}) {
    final currentCounter = counter ?? _counters[index];
    return Card(
      key: key,
      color: currentCounter.color.withOpacity(0.2),
      shape: _counterShape == CounterShape.circle
          ? const CircleBorder()
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onLongPress: () {
          _showEditDeleteDialog(index);
        },
        borderRadius: _counterShape == CounterShape.circle
            ? BorderRadius.circular(100)
            : BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currentCounter.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox.shrink(),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        onDoubleTap: () => _showSetCounterDialog(index),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Text(
                            '${currentCounter.value}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 60,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () => _decrementCounter(index),
                    splashRadius: 24,
                  ),
                  const SizedBox(width: 32),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _incrementCounter(index),
                    splashRadius: 24,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
