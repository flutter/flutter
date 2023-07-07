// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:camera_web/src/types/types.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('CameraMetadata', () {
    testWidgets('supports value equality', (WidgetTester tester) async {
      expect(
        const CameraMetadata(
          deviceId: 'deviceId',
          facingMode: 'environment',
        ),
        equals(
          const CameraMetadata(
            deviceId: 'deviceId',
            facingMode: 'environment',
          ),
        ),
      );
    });
  });
}
