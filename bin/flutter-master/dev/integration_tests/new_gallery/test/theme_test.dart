// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery/themes/material_demo_theme_data.dart';

void main() {
  test('verify the activeColors of toggleable widget themes are set', () async {
    const Color primaryColor = Color(0xFF6200EE);
    final ThemeData themeData = MaterialDemoThemeData.themeData;

    expect(
      themeData.checkboxTheme.fillColor!.resolve(<MaterialState>{MaterialState.selected}),
      primaryColor,
    );
    expect(
      themeData.radioTheme.fillColor!.resolve(<MaterialState>{MaterialState.selected}),
      primaryColor,
    );
    expect(
      themeData.switchTheme.thumbColor!.resolve(<MaterialState>{MaterialState.selected}),
      primaryColor,
    );
    expect(
      themeData.switchTheme.trackColor!.resolve(<MaterialState>{MaterialState.selected}),
      primaryColor.withOpacity(0.5),
    );
  });
}
