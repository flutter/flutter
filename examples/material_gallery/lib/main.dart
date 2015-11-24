// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'chip_demo.dart';
import 'gallery_page.dart';
import 'date_picker_demo.dart';
import 'widget_demo.dart';
import 'drop_down_demo.dart';

final List<WidgetDemo> _kDemos = <WidgetDemo>[
  kChipDemo,
  kDatePickerDemo,
  kDropDownDemo,
];

void main() {
  Map<String, RouteBuilder> routes = new Map<String, RouteBuilder>();
  routes['/'] = (_) => new GalleryPage(demos: _kDemos);

  for (WidgetDemo demo in _kDemos)
    routes[demo.routeName] = (_) => new GalleryPage(demos: _kDemos, active: demo);

  runApp(new MaterialApp(
    title: 'Material Gallery',
    routes: routes
  ));
}
