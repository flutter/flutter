// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This example demonstrates how to override high contrast accessibility
// settings using MediaQuery to control theme selection in MaterialApp.
//
// This approach allows developers to manually control high contrast mode
// without adding new API surfaces to MaterialApp.

import 'dart:ui' as ui;
import 'package:flutter/material.dart';

void main() {
  runApp(const HighContrastOverrideExample());
}

class HighContrastOverrideExample extends StatefulWidget {
  const HighContrastOverrideExample({super.key});

  @override
  State<HighContrastOverrideExample> createState() => _HighContrastOverrideExampleState();
}

class _HighContrastOverrideExampleState extends State<HighContrastOverrideExample> {
  bool _forceHighContrast = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'High Contrast Override Example',
      // Example of how to override high contrast setting
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            highContrast: _forceHighContrast,
          ),
          child: child!,
        );
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      // Define high contrast themes
      highContrastTheme: ThemeData(
        colorScheme: const ColorScheme.highContrastLight(),
        useMaterial3: true,
      ),
      highContrastDarkTheme: ThemeData(
        colorScheme: const ColorScheme.highContrastDark(),
        useMaterial3: true,
      ),
      home: HighContrastDemo(
        forceHighContrast: _forceHighContrast,
        onToggleHighContrast: (bool value) {
          setState(() {
            _forceHighContrast = value;
          });
        },
      ),
    );
  }
}

class HighContrastDemo extends StatelessWidget {
  const HighContrastDemo({
    super.key,
    required this.forceHighContrast,
    required this.onToggleHighContrast,
  });

  final bool forceHighContrast;
  final ValueChanged<bool> onToggleHighContrast;

  @override
  Widget build(BuildContext context) {
    final bool systemHighContrast = ui.PlatformDispatcher.instance
        .accessibilityFeatures.highContrast;
    final bool effectiveHighContrast = MediaQuery.highContrastOf(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('High Contrast Override Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'High Contrast Status',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    _StatusRow(
                      label: 'System High Contrast',
                      value: systemHighContrast ? 'Enabled' : 'Disabled',
                      color: systemHighContrast ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    _StatusRow(
                      label: 'Override Active',
                      value: forceHighContrast ? 'Yes' : 'No',
                      color: forceHighContrast ? Colors.orange : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    _StatusRow(
                      label: 'Effective High Contrast',
                      value: effectiveHighContrast ? 'Enabled' : 'Disabled',
                      color: effectiveHighContrast ? Colors.blue : Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Controls',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Force High Contrast'),
                      subtitle: const Text(
                        'Override system setting to force high contrast mode',
                      ),
                      value: forceHighContrast,
                      onChanged: onToggleHighContrast,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Sample UI Elements',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: <Widget>[
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text('Elevated Button'),
                        ),
                        FilledButton(
                          onPressed: () {},
                          child: const Text('Filled Button'),
                        ),
                        OutlinedButton(
                          onPressed: () {},
                          child: const Text('Outlined Button'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Text Field',
                        helperText: 'This shows contrast differences',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                effectiveHighContrast
                    ? 'High contrast is currently active'
                    : 'Standard contrast is currently active',
              ),
            ),
          );
        },
        child: const Icon(Icons.contrast),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
