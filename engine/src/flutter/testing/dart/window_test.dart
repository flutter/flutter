// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:test/test.dart';

void main() {
  test('window.sendPlatformMessage preserves callback zone', () {
    runZoned(() {
      final Zone innerZone = Zone.current;
      window.sendPlatformMessage('test', new ByteData.view(new Uint8List(0).buffer), expectAsync((ByteData data) {
        final Zone runZone = Zone.current;
        expect(runZone, isNotNull);
        expect(runZone, same(innerZone));
      }));
    });
  });
}
