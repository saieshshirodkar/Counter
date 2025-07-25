
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/enums/app_theme.dart';
import '../models/enums/counter_layout.dart';
import '../models/enums/counter_shape.dart';
import '../models/enums/counter_size.dart';
import '../theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  CounterShape _counterShape = CounterShape.rectangle;
  CounterSize _counterSize = CounterSize.medium;
  CounterLayout _counterLayout = CounterLayout.grid;
  AppTheme _appTheme = AppTheme.deepPurple;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      try {
        _counterShape = CounterShape.values[prefs.getInt('counterShape') ?? 0];
      } catch (e) {
        _counterShape = CounterShape.rectangle;
      }
      try {
        _counterSize = CounterSize.values[prefs.getInt('counterSize') ?? 1];
      } catch (e) {
        _counterSize = CounterSize.medium;
      }
      try {
        _counterLayout = CounterLayout.values[prefs.getInt('counterLayout') ?? 0];
      } catch (e) {
        _counterLayout = CounterLayout.grid;
      }
      try {
        _appTheme = AppTheme.values[prefs.getInt('appTheme') ?? 0];
      } catch (e) {
        _appTheme = AppTheme.deepPurple;
      }
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('counterShape', _counterShape.index);
    await prefs.setInt('counterSize', _counterSize.index);
    await prefs.setInt('counterLayout', _counterLayout.index);
    await prefs.setInt('appTheme', _appTheme.index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          _buildSectionHeader('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Shape'),
                const SizedBox(height: 8),
                SegmentedButton<CounterShape>(
                  segments: const [
                    ButtonSegment(value: CounterShape.rectangle, label: Text('Rectangle'), icon: Icon(Icons.rectangle_outlined)),
                    ButtonSegment(value: CounterShape.circle, label: Text('Circle'), icon: Icon(Icons.circle_outlined)),
                  ],
                  selected: {_counterShape},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _counterShape = newSelection.first;
                    });
                    _saveSettings();
                  },
                ),
                const SizedBox(height: 16),
                const Text('Size'),
                const SizedBox(height: 8),
                SegmentedButton<CounterSize>(
                  segments: const [
                    ButtonSegment(value: CounterSize.small, label: Text('Small')),
                    ButtonSegment(value: CounterSize.medium, label: Text('Medium')),
                    ButtonSegment(value: CounterSize.large, label: Text('Large')),
                  ],
                  selected: {_counterSize},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _counterSize = newSelection.first;
                    });
                    _saveSettings();
                  },
                ),
                const SizedBox(height: 16),
                const Text('Layout'),
                const SizedBox(height: 8),
                SegmentedButton<CounterLayout>(
                  segments: const [
                    ButtonSegment(value: CounterLayout.grid, label: Text('Grid'), icon: Icon(Icons.grid_view)),
                    ButtonSegment(value: CounterLayout.list, label: Text('List'), icon: Icon(Icons.view_list)),
                  ],
                  selected: {_counterLayout},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _counterLayout = newSelection.first;
                    });
                    _saveSettings();
                  },
                ),
                const SizedBox(height: 16),
                const Text('Theme'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: AppTheme.values.map((theme) {
                    return GestureDetector(
                      onTap: () {
                        Provider.of<ThemeProvider>(context, listen: false)
                            .setAppTheme(theme);
                      },
                      child: CircleAvatar(
                        backgroundColor: ThemeProvider.getThemeColor(theme),
                        radius: 22,
                        child: _appTheme == theme
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }


}
