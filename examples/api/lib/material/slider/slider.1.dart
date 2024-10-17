// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [Slider] with custom theme.

void main() => runApp(const SliderApp());

class SliderApp extends StatelessWidget {
  const SliderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        sliderTheme: SliderThemeData(
          // Track shape.
          trackShape: const RoundedRectSliderTrackShape(),
          trackHeight: 4,
          // Thumb shape.
          thumbShape: const RoundSliderThumbShape(),
          // Value indicator shape.
          valueIndicatorShape: const DropSliderValueIndicatorShape(),
          // Tick mark shape.
          tickMarkShape: const RoundSliderTickMarkShape(),
          // Color mappings.
          inactiveTrackColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          activeTickMarkColor:
              Theme.of(context).colorScheme.onPrimary.withOpacity(0.38),
          inactiveTickMarkColor:
              Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.38),
          disabledActiveTrackColor:
              Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
          disabledInactiveTrackColor:
              Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
          disabledThumbColor:
              Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
          valueIndicatorColor: Theme.of(context).colorScheme.primary,
          valueIndicatorTextStyle:
              Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
        ),
      ),
      home: const SliderExample(),
    );
  }
}

class SliderExample extends StatefulWidget {
  const SliderExample({super.key});

  @override
  State<SliderExample> createState() => _SliderExampleState();
}

class _SliderExampleState extends State<SliderExample> {
  double _currentSlider1Value = 60;
  double _currentSlider2Value = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Slider Sample')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 20,
        children: <Widget>[
          Slider(
            value: _currentSlider1Value,
            max: 100,
            label: _currentSlider1Value.round().toString(),
            onChanged: (double value) {
              setState(() {
                _currentSlider1Value = value;
              });
            },
          ),
          Slider(
            value: _currentSlider2Value,
            max: 100,
            divisions: 5,
            label: _currentSlider2Value.round().toString(),
            onChanged: (double value) {
              setState(() {
                _currentSlider2Value = value;
              });
            },
          ),
        ],
      ),
    );
  }
}
