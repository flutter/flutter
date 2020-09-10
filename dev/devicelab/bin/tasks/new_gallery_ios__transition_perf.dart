// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/utils.dart';
import 'package:flutter_devicelab/tasks/new_gallery.dart';
import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.ios;

  final Directory galleryParentDir = Directory.systemTemp.createTempSync('new_gallery_test');
  final Directory galleryDir = Directory(path.join(galleryParentDir.path, 'gallery'));

  try {
    await task(NewGalleryPerfTest(galleryDir).run);
  } finally {
    rmTree(galleryParentDir);
  }
}
