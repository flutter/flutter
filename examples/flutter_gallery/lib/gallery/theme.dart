// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class GalleryTheme {
  const GalleryTheme({ this.name, this.icon, this.theme });
  final String name;
  final IconData icon;
  final ThemeData theme;
}

const MaterialColor _kPurpleSwatch = const MaterialColor(
  500,
  const <int, Color> {
    50: const Color(0xFFF2E7FE),
    100: const Color(0xFFD7B7FD),
    200: const Color(0xFFBB86FC),
    300: const Color(0xFF9E55FC),
    400: const Color(0xFF7F22FD),
    500: const Color(0xFF6200EE),
    600: const Color(0xFF4B00D1),
    700: const Color(0xFF3700B3),
    800: const Color(0xFF270096),
    900: const Color(0xFF190078),
  }
);

final List<GalleryTheme> kAllGalleryThemes = <GalleryTheme>[
  new GalleryTheme(
    name: 'Light',
    icon: Icons.brightness_5,
    theme: new ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
    ),
  ),
  new GalleryTheme(
    name: 'Dark',
    icon: Icons.brightness_7,
    theme: new ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
    ),
  ),
  new GalleryTheme(
    name: 'Purple',
    icon: Icons.brightness_6,
    theme: new ThemeData(
      brightness: Brightness.light,
      primarySwatch: _kPurpleSwatch,
      buttonColor: _kPurpleSwatch[500],
      splashColor: Colors.white24,
      splashFactory: InkRipple.splashFactory,
      errorColor: const Color(0xFFFF1744),
      buttonTheme: const ButtonThemeData(
        textTheme: ButtonTextTheme.primary,
      ),
    ),
  ),
];
