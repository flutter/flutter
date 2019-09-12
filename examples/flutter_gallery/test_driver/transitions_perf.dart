// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JsonEncoder;

import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_gallery/gallery/demos.dart';
import 'package:flutter_gallery/gallery/app.dart' show GalleryApp;
import 'package:flutter/material.dart';

Future<String> _handleMessages(String message) async {
  assert(message == 'demoNames');
  return const JsonEncoder.withIndent('  ').convert(
    kAllGalleryDemos.map((GalleryDemo demo) => '${demo.title}@${demo.category.name}').toList(),
  );
}

void main() {
  enableFlutterDriverExtension(handler: _handleMessages);
  // As in lib/main.dart: overriding https://github.com/flutter/flutter/issues/13736
  // for better visual effect at the cost of performance.
  runApp(const GalleryApp(testMode: true));
}
