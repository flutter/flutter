// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for FontFeature.FontFeature.notationalForms
import 'dart:ui';

import 'package:flutter/widgets.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      builder: (BuildContext context, Widget? navigator) => const ExampleWidget(),
      color: const Color(0xffffffff),
    );
  }
}

class ExampleWidget extends StatelessWidget {
  const ExampleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // The Gothic A1 font can be downloaded from Google Fonts (https://www.google.com/fonts).
    return const Text(
      'abc 123',
      style: TextStyle(
        fontFamily: 'Gothic A1',
        fontFeatures: <FontFeature>[
          FontFeature.notationalForms(3), // circled letters and digits
        ],
      ),
    );
  }
}
