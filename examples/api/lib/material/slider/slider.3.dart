// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [SliderThemeData.use2024SliderShapes].

void main() => runApp(const SliderExampleApp());

class SliderExampleApp extends StatefulWidget {
  const SliderExampleApp({super.key});

  @override
  State<SliderExampleApp> createState() => _SliderExampleAppState();
}

class _SliderExampleAppState extends State<SliderExampleApp> {
  double _currentSlider1Value = 4.0;
  double _currentSlider2Value = 60;
  double _currentSlider3Value = 800;
  bool isDark = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = ThemeData(
      sliderTheme: const SliderThemeData(
        use2024SliderShapes: true,
        showValueIndicator: ShowValueIndicator.always,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
    );

    return MaterialApp(
      theme: themeData,
      home: Scaffold(
        appBar: AppBar(title: const Text('Slider')),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Slider(
              value: _currentSlider1Value,
              label: _currentSlider1Value.roundToDouble().toString(),
              min: 1,
              max: 10,
              onChanged: (double value) {
                setState(() {
                  _currentSlider1Value = value;
                });
              },
            ),
            const SizedBox(height: 48.0),
            Slider(
              value: _currentSlider2Value,
              label: _currentSlider2Value.round().toString(),
              min: 1,
              max: 100,
              onChanged: (double value) {
                setState(() {
                  _currentSlider2Value = value;
                });
              },
            ),
            const SizedBox(height: 48.0),
            Slider(
              value: _currentSlider3Value,
              label: _currentSlider3Value.round().toString(),
              min: 1,
              max: 1000,
              onChanged: (double value) {
                setState(() {
                  _currentSlider3Value = value;
                });
              },
            ),
            const SizedBox(height: 48.0),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  isDark = !isDark;
                });
              },
              icon: isDark ? const Icon(Icons.brightness_2_outlined) : const Icon(Icons.wb_sunny_outlined),
              label: const Text('Toggle Brightness Mode'),
            ),
          ],
        ),
      ),
    );
  }
}
