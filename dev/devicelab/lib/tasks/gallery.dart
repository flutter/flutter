// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

import '../framework/adb.dart';
import '../framework/framework.dart';
import '../framework/utils.dart';

TaskFunction createGalleryTransitionTest({ @required DeviceOperatingSystem os }) {
  return new GalleryTransitionTest(os: os);
}

class GalleryTransitionTest {
  GalleryTransitionTest({ this.os }) {
    deviceOperatingSystem = os;
  }

  final DeviceOperatingSystem os;

  Future<TaskResult> call() async {
    Device device = await devices.workingDevice;
    await device.unlock();
    String deviceId = device.deviceId;
    Directory galleryDirectory =
        dir('${flutterDirectory.path}/examples/flutter_gallery');
    await inDirectory(galleryDirectory, () async {
      await flutter('packages', options: <String>['get']);

      if (os == DeviceOperatingSystem.ios) {
        // This causes an Xcode project to be created.
        await flutter('build', options: <String>['ios', '--profile']);
      }

      await flutter('drive', options: <String>[
        '--profile',
        '--trace-startup',
        '-t',
        'test_driver/transitions_perf.dart',
        '-d',
        deviceId,
      ]);
    });

    // Route paths contains slashes, which Firebase doesn't accept in keys, so we
    // remove them.
    Map<String, dynamic> original = JSON.decode(file(
            '${galleryDirectory.path}/build/transition_durations.timeline.json')
        .readAsStringSync());
    Map<String, dynamic> clean = new Map<String, dynamic>.fromIterable(
        original.keys,
        key: (String key) => key.replaceAll('/', ''),
        value: (String key) => original[key]);

    return new TaskResult.success(clean);
  }
}
