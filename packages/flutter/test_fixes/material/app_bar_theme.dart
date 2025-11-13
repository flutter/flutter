// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() {
  // Changes made in https://github.com/flutter/flutter/pull/86198
  AppBarTheme appBarTheme = AppBarTheme();
  appBarTheme = AppBarTheme(brightness: Brightness.light);
  appBarTheme = AppBarTheme(brightness: Brightness.dark);
  appBarTheme = AppBarTheme(error: '');
  appBarTheme = appBarTheme.copyWith(error: '');
  appBarTheme = appBarTheme.copyWith(brightness: Brightness.light);
  appBarTheme = appBarTheme.copyWith(brightness: Brightness.dark);
  appBarTheme.brightness;

  TextTheme myTextTheme = TextTheme();
  AppBarTheme appBarTheme = AppBarTheme();
  appBarTheme = AppBarTheme(textTheme: myTextTheme);
  appBarTheme = AppBarTheme(textTheme: myTextTheme);
  appBarTheme = appBarTheme.copyWith(textTheme: myTextTheme);
  appBarTheme = appBarTheme.copyWith(textTheme: myTextTheme);

  AppBarTheme appBarTheme = AppBarTheme();
  appBarTheme = AppBarTheme(backwardsCompatibility: true);
  appBarTheme = AppBarTheme(backwardsCompatibility: false);
  appBarTheme = appBarTheme.copyWith(backwardsCompatibility: true);
  appBarTheme = appBarTheme.copyWith(backwardsCompatibility: false);
  appBarTheme.backwardsCompatibility; // Removing field reference not supported.

  AppBarTheme appBarTheme = AppBarTheme();
  appBarTheme.color;

  AppBarTheme appBarTheme = AppBarTheme(color: Colors.red);

  AppBarThemeData appBarThemeData = AppBarThemeData(color: Colors.red);
}
