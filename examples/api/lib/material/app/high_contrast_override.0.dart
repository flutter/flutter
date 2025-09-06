// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [MaterialApp].

void main() => runApp(const HighContrastOverrideExample());

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
      title: 'High Contrast Override Demo',
      builder: (context, child) {
        // Override MediaQuery to force high contrast when switch is enabled
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
      highContrastTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      highContrastDarkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('High Contrast Override Demo'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'High Contrast Control',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Force High Contrast'),
                subtitle: const Text('Override system high contrast setting'),
                value: _forceHighContrast,
                onChanged: (bool value) {
                  setState(() {
                    _forceHighContrast = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Status Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final mediaQuery = MediaQuery.of(context);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('System High Contrast: ${mediaQuery.platformBrightness == Brightness.dark ? 'Dark' : 'Light'}'),
                      Text('Override Active: $_forceHighContrast'),
                      Text('Effective High Contrast: ${MediaQuery.highContrastOf(context)}'),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Sample UI Elements',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
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
            ],
          ),
        ),
      ),
    );
  }
}
