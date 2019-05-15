// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Thanks for checking out Flutter!
// Like what you see? Tweet us @FlutterDev

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'gallery/app.dart';

Future<void> main() async {
  await ui.webOnlyInitializePlatform(); // ignore: undefined_function
  runApp(const GalleryApp());
}
