// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/src/closed_caption_file.dart';

void main() {
  group('ClosedCaptionFile', () {
    test('toString()', () {
      final Caption caption = const Caption(
        number: 1,
        start: Duration(seconds: 1),
        end: Duration(seconds: 2),
        text: 'caption',
      );

      expect(
          caption.toString(),
          'Caption('
          'number: 1, '
          'start: 0:00:01.000000, '
          'end: 0:00:02.000000, '
          'text: caption'
          ')');
    });
  });
}
