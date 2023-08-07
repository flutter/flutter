// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_relative_lib_imports

import 'package:litetest/litetest.dart';
import '../../lib/gpu/lib/gpu.dart' as gpu;

void main() {
  // TODO(131346): Remove this once we migrate the Dart GPU API into this space.
  test('smoketest', () async {
    final int result = gpu.testProc();
    expect(result, 1);

    final String? message = gpu.testProcWithCallback((int result) {
      expect(result, 1234);
    });
    expect(message, null);

    final gpu.FlutterGpuTestClass a = gpu.FlutterGpuTestClass();
    a.coolMethod(9847);
  });

  test('gpu.context throws exception for incompatible embedders', () async {
    try {
      // ignore: unnecessary_statements
      gpu.gpuContext; // Force the
      fail('Exception not thrown');
    } catch (e) {
      expect(
          e.toString(),
          contains(
              'Flutter GPU requires the Impeller rendering backend to be enabled.'));
    }
  });
}
