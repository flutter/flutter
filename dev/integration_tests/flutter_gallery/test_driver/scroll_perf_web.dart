// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_gallery/gallery/app.dart' show GalleryApp;
import 'package:flutter/material.dart';

void main() {
  enableFlutterDriverExtension();
  runApp(const GalleryApp(testMode: true));
}
