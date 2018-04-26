// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JsonEncoder;

import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_gallery/gallery/item.dart';
import 'package:flutter_gallery/main.dart' as app;

Future<String> _handleMessages(String message) async {
  assert(message == 'demoNames');
  return const JsonEncoder.withIndent('  ').convert(
    kAllGalleryItems.map((GalleryItem item) => item.title).toList(),
  );
}

void main() {
  enableFlutterDriverExtension(handler: _handleMessages);
  app.main();
}
