import 'dart:convert';
import '../widgets/counter_item.dart';
import '../widgets/add_counter_dialog.dart';
import '../widgets/edit_delete_dialog.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/counter.dart';
import '../models/enums/counter_layout.dart';
import '../models/enums/counter_shape.dart';
import '../models/enums/counter_size.dart';

import 'settings_screen.dart';

class CounterListScreen extends StatefulWidget {
  const CounterListScreen({super.key});

  @override
  State<CounterListScreen> createState() => _CounterListScreenState();
}

class _CounterListScreenState extends State<CounterListScreen>
    with WidgetsBindingObserver {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Counter> _counters = [];
  
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCounters();
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveCounters();
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _counterShape = CounterShape.values[prefs.getInt('counterShape') ?? 0];
      _counterSize = CounterSize.values[prefs.getInt('counterSize') ?? 1];
      _counterLayout =
          CounterLayout.values[prefs.getInt('counterLayout') ?? 0];
    });
  }

  Future<void> _loadCounters() async {
    final prefs = await SharedPreferences.getInstance();
    final String? countersString = prefs.getString('counters');
    if (countersString != null) {
      try {
        final List<dynamic> countersJson = jsonDecode(countersString);
        setState(() {
          _counters =
              countersJson.map((json) => Counter.fromJson(json)).toList();
        });
      } catch (e) {
        // Handle error, maybe show a dialog to the user
        print('Error loading counters: $e');
      }
    }

  }

  Future<void> _saveCounters() async {
    final prefs = await SharedPreferences.getInstance();
    final String countersString = jsonEncode(
      _counters.map((counter) => counter.toJson()).toList(),
    );
    await prefs.setString('counters', countersString);

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

    });
  }

  void _decrementCounter(int index) {
    setState(() {
      if (_counters[index].value > 0) {
        _counters[index].value--;

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
        child: CounterItem(
          key: ValueKey(removedCounter),
          counter: removedCounter,
          counterShape: _counterShape,
          isReorderMode: _isReorderMode,
          onIncrement: () {},
          onDecrement: () {},
          onSet: () {},
          onEdit: () {},
        ),
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
    showDialog(
      context: context,
      builder: (context) {
        return AddCounterDialog(
          onAdd: _addCounter,
          existingCounters: _counters,
          presetColors: _presetColors,
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
          content:
              Text('Are you sure you want to delete "${_counters[index].name}"?'),
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
                if (value != null && value >= 0) {
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
        return EditDeleteDialog(
          counterName: _counters[index].name,
          onEdit: () => _showSetCounterDialog(index),
          onDelete: () => _showDeleteConfirmationDialog(index),
          onReorder: () {
            HapticFeedback.mediumImpact();
            setState(() {
              _isReorderMode = true;
            });
          },
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
        final counter = _counters[index];
        return CounterItem(
          key: ValueKey(counter),
          counter: counter,
          counterShape: _counterShape,
          isReorderMode: _isReorderMode,
          onIncrement: () => _incrementCounter(index),
          onDecrement: () => _decrementCounter(index),
          onSet: () => _showSetCounterDialog(index),
          onEdit: () => _showEditDeleteDialog(index),
        );
      },
      dragEnabled: _isReorderMode,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          final counter = _counters.removeAt(oldIndex);
          _counters.insert(newIndex, counter);
        });
        _saveCounters();
      },
    );
  }

  Widget _buildCountersList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _counters.length,
      itemBuilder: (context, index) {
        final counter = _counters[index];
        return CounterItem(
          key: ValueKey(counter),
          counter: counter,
          counterShape: _counterShape,
          isReorderMode: _isReorderMode,
          onIncrement: () => _incrementCounter(index),
          onDecrement: () => _decrementCounter(index),
          onSet: () => _showSetCounterDialog(index),
          onEdit: () => _showEditDeleteDialog(index),
        );
      },
      buildDefaultDragHandles: _isReorderMode,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final counter = _counters.removeAt(oldIndex);
          _counters.insert(newIndex, counter);
        });
        _saveCounters();
      },
    );
  }


}
