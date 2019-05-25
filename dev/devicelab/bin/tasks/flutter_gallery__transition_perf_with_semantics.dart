// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_devicelab/tasks/gallery.dart';
import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';

Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.android;
  await task(() async {
    final TaskResult withoutSemantics = await createGalleryTransitionTest()();
    final TaskResult withSemantics = await createGalleryTransitionTest(semanticsEnabled: true)();

    final List<String> benchmarkScoreKeys = <String>[];
    final Map<String, dynamic> data = <String, dynamic>{};
    for (String key in withSemantics.benchmarkScoreKeys) {
      final String deltaKey = 'delta_$key';
      data[deltaKey] = withSemantics.data[key] - withoutSemantics.data[key];
      data['semantics_$key'] = withSemantics.data[key];
      data[key] = withoutSemantics.data[key];
      benchmarkScoreKeys.add(deltaKey);
    }

    return TaskResult.success(data, benchmarkScoreKeys: benchmarkScoreKeys);
  });
}
