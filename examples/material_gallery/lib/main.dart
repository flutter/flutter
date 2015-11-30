// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'demo/chip_demo.dart';
import 'demo/date_picker_demo.dart';
import 'demo/drop_down_demo.dart';
import 'demo/selection_controls_demo.dart';
import 'demo/slider_demo.dart';
import 'demo/tabs_demo.dart';
import 'demo/time_picker_demo.dart';
import 'demo/widget_demo.dart';
import 'gallery_page.dart';

final List<WidgetDemo> _kDemos = <WidgetDemo>[
  kChipDemo,
  kSelectionControlsDemo,
  kSliderDemo,
  kDatePickerDemo,
  kTabsDemo,
  kTimePickerDemo,
  kDropDownDemo,
];

class _MaterialGallery extends StatefulComponent {
  _MaterialGalleryState createState() => new _MaterialGalleryState();
}

class _MaterialGalleryState extends State<_MaterialGallery> {
  final Map<String, RouteBuilder> _routes = new Map<String, RouteBuilder>();

  void initState() {
    super.initState();
    _routes['/'] = (_) => new GalleryPage(
      demos: _kDemos,
      onThemeChanged: _handleThemeChanged
    );
    for (WidgetDemo demo in _kDemos) {
      _routes[demo.routeName] = (_) {
        return new GalleryPage(
          demos: _kDemos,
          active: demo,
          onThemeChanged: _handleThemeChanged
        );
      };
    }
  }

  ThemeData _theme;

  void _handleThemeChanged(ThemeData newTheme) {
    setState(() {
      _theme = newTheme;
    });
  }

  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Material Gallery',
      theme: _theme,
      routes: _routes
    );
  }
}

void main() {
  runApp(new _MaterialGallery());
}
