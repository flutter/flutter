// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:camera_web/src/types/types.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('ZoomLevelCapability', () {
    testWidgets('sets all properties', (WidgetTester tester) async {
      const double minimum = 100.0;
      const double maximum = 400.0;
      final MockMediaStreamTrack videoTrack = MockMediaStreamTrack();

      final ZoomLevelCapability capability = ZoomLevelCapability(
        minimum: minimum,
        maximum: maximum,
        videoTrack: videoTrack,
      );

      expect(capability.minimum, equals(minimum));
      expect(capability.maximum, equals(maximum));
      expect(capability.videoTrack, equals(videoTrack));
    });

    testWidgets('supports value equality', (WidgetTester tester) async {
      final MockMediaStreamTrack videoTrack = MockMediaStreamTrack();

      expect(
        ZoomLevelCapability(
          minimum: 0.0,
          maximum: 100.0,
          videoTrack: videoTrack,
        ),
        equals(
          ZoomLevelCapability(
            minimum: 0.0,
            maximum: 100.0,
            videoTrack: videoTrack,
          ),
        ),
      );
    });
  });
}
