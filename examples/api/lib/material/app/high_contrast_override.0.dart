// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [MaterialApp] high contrast override.

void main() => runApp(const HighContrastOverrideExampleApp());

class HighContrastOverrideExampleApp extends StatefulWidget {
  const HighContrastOverrideExampleApp({super.key});

  @override
  State<HighContrastOverrideExampleApp> createState() => _HighContrastOverrideExampleAppState();
}

class _HighContrastOverrideExampleAppState extends State<HighContrastOverrideExampleApp> {
  bool _forceHighContrast = false;

  @override
  Widget build(BuildContext context) {
    // To affect theme selection, MediaQuery must wrap the MaterialApp,
    // not be placed in the builder property
    return MediaQuery(
      data: MediaQueryData.fromView(View.of(context)).copyWith(
        highContrast: _forceHighContrast,
      ),
      child: MaterialApp(
        title: 'High Contrast Override Demo',
        theme: ThemeData.light(),
        highContrastTheme: ThemeData.light().copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
            contrastLevel: 1.0, // High contrast
          ),
        ),
        darkTheme: ThemeData.dark(),
        highContrastDarkTheme: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
            contrastLevel: 1.0, // High contrast
          ),
        ),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('High Contrast Demo'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'High contrast is ${_forceHighContrast ? 'enabled' : 'disabled'}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                Text(
                  'Current theme: ${Theme.of(context).brightness == Brightness.light ? 'Light' : 'Dark'}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _forceHighContrast = !_forceHighContrast;
                    });
                  },
                  child: Text(_forceHighContrast ? 'Disable High Contrast' : 'Enable High Contrast'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
