// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:camera_platform_interface/src/types/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('$ImageFormatGroup tests', () {
    test('ImageFormatGroupName extension returns correct values', () {
      expect(ImageFormatGroup.bgra8888.name(), 'bgra8888');
      expect(ImageFormatGroup.yuv420.name(), 'yuv420');
      expect(ImageFormatGroup.jpeg.name(), 'jpeg');
      expect(ImageFormatGroup.unknown.name(), 'unknown');
    });
  });
}
