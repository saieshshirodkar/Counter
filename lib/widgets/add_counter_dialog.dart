import 'dart:math';
import 'package:flutter/material.dart';
import '../models/counter.dart';

class AddCounterDialog extends StatefulWidget {
  final Function(String, Color) onAdd;
  final List<Counter> existingCounters;
  final List<Color> presetColors;

  const AddCounterDialog({
    Key? key,
    required this.onAdd,
    required this.existingCounters,
    required this.presetColors,
  }) : super(key: key);

  @override
  _AddCounterDialogState createState() => _AddCounterDialogState();
}

class _AddCounterDialogState extends State<AddCounterDialog> {
  final TextEditingController _controller = TextEditingController();
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    // Find an unused color from presets, or generate a random one
    final usedColors = widget.existingCounters.map((c) => c.color).toSet();

    final unusedColors = widget.presetColors.where((c) => !usedColors.contains(c)).toList();

    if (unusedColors.isNotEmpty) {
      _selectedColor = unusedColors[Random().nextInt(unusedColors.length)];
    } else {
      // All preset colors are used, generate a new random color
      _selectedColor = Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Counter'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
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
            children: widget.presetColors.map((color) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                  });
                },
                child: CircleAvatar(
                  backgroundColor: color,
                  radius: 22,
                  child: _selectedColor == color
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
            if (_controller.text.isNotEmpty) {
              if (widget.existingCounters.any((c) => c.name == _controller.text)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('A counter with this name already exists.')),
                );
              } else {
                widget.onAdd(_controller.text, _selectedColor);
                Navigator.of(context).pop();
              }
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
