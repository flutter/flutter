// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import '../utils.dart';
import 'use_cases.dart';

class SliderUseCase extends UseCase {
  @override
  String get name => 'Slider';

  @override
  String get route => '/slider';

  @override
  Widget build(BuildContext context) => const MainWidget();
}

class MainWidget extends StatefulWidget {
  const MainWidget({super.key});

  @override
  State<MainWidget> createState() => MainWidgetState();
}

class MainWidgetState extends State<MainWidget> {
  double currentSliderValue = 20;
  static const String accessibilityLabel = 'Accessibility Test Slider';

  String pageTitle = getUseCaseName(SliderUseCase());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Semantics(headingLevel: 1, child: Text('$pageTitle demo')),
      ),
      body: Center(
        child: Semantics(
          label: accessibilityLabel,
          child: Slider(
            value: currentSliderValue,
            max: 100,
            divisions: 5,
            label: currentSliderValue.round().toString(),
            onChanged: (double value) {
              setState(() {
                currentSliderValue = value;
              });
            },
          ),
        ),
      ),
    );
  }
}
