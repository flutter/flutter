// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [Slider].
/// set to false.

void main() => runApp(const SliderExampleApp());

class SliderExampleApp extends StatelessWidget {
  const SliderExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SliderExample(),
    );
  }
}

class SliderExample extends StatefulWidget {
  const SliderExample({super.key});

  @override
  State<SliderExample> createState() => _SliderExampleState();
}

class _SliderExampleState extends State<SliderExample> {
  double _currentSliderValue = 20;
  double _currentDiscreteSliderValue = 60;
  bool year2023 = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Slider')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: <Widget>[
            Slider(
              year2023: year2023,
              value: _currentSliderValue,
              max: 100,
              onChanged: (double value) {
                setState(() {
                  _currentSliderValue = value;
                });
              },
            ),
            Slider(
              year2023: year2023,
              value: _currentDiscreteSliderValue,
              max: 100,
              divisions: 5,
              label: _currentDiscreteSliderValue.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _currentDiscreteSliderValue = value;
                });
              },
            ),
            SwitchListTile(
              value: year2023,
              title: const Text('Toggle year2023 flag'),
              onChanged: (bool value) {
                setState(() {
                  year2023 = !year2023;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
