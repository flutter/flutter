// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'chip_demo.dart';
import 'gallery_page.dart';
import 'widget_demo.dart';

final List<WidgetDemo> _kDemos = <WidgetDemo>[
  kChipDemo
];

void main() {
  Map<String, RouteBuilder> routes = new Map<String, RouteBuilder>();
  for (WidgetDemo demo in _kDemos)
    routes[demo.route] = (_) => new GalleryPage(demo: demo);

  runApp(new MaterialApp(
    title: 'Material Gallery',
    routes: routes
  ));
}
