// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class GalleryTheme {
  const GalleryTheme({ this.name, this.data });

  final String name;
  final ThemeData data;

  @override
  bool operator ==(dynamic other) {
    if (runtimeType != other.runtimeType)
      return false;
    final GalleryTheme typedOther = other;
    return name == typedOther.name && data == typedOther.data;
  }

  @override
  int get hashCode => hashValues(name, data);

  @override
  String toString() {
    return '$runtimeType($name)';
  }
}

final List<GalleryTheme> kAllGalleryThemes = <GalleryTheme>[
  new GalleryTheme(
    name: 'Default theme',
    data: new ThemeData(
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.white,
      backgroundColor: Colors.white,
      dividerColor: const Color(0xFFAAF7FE),
      buttonColor: Colors.blue[500],
      buttonTheme: new ButtonThemeData(
        textTheme: ButtonTextTheme.primary,
      ),
      errorColor: const Color(0xFFFF1744),
      highlightColor: Colors.transparent,
      splashColor: Colors.white24,
      splashFactory: InkRipple.splashFactory,
    ),
  ),
  new GalleryTheme(
    name: 'Light theme',
    data: new ThemeData.light(),
  ),
  new GalleryTheme(
    name: 'Dark theme',
    data: new ThemeData.dark(),
  ),
];
