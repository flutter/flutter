// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_gallery/gallery/demos.dart';
import 'package:flutter_gallery/gallery/app.dart' show GalleryApp;
import 'package:flutter/material.dart';

import 'package:lib.app_driver.dart/module_driver.dart';
import 'package:lib.app.dart/logging.dart';

void main() {
  setupLogger(name: 'flutter_gallery_app');
  final ModuleDriver driver = ModuleDriver();
  driver.startSync();
  runApp(const GalleryApp(testMode: true));
}
