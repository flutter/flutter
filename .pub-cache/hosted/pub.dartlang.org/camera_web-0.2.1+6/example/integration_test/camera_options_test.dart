// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:camera_web/src/types/types.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('CameraOptions', () {
    testWidgets('serializes correctly', (WidgetTester tester) async {
      final CameraOptions cameraOptions = CameraOptions(
        audio: const AudioConstraints(enabled: true),
        video: VideoConstraints(
          facingMode: FacingModeConstraint.exact(CameraType.user),
        ),
      );

      expect(
        cameraOptions.toJson(),
        equals(<String, Object>{
          'audio': cameraOptions.audio.toJson(),
          'video': cameraOptions.video.toJson(),
        }),
      );
    });

    testWidgets('supports value equality', (WidgetTester tester) async {
      expect(
        CameraOptions(
          audio: const AudioConstraints(enabled: false),
          video: VideoConstraints(
            facingMode: FacingModeConstraint(CameraType.environment),
            width:
                const VideoSizeConstraint(minimum: 10, ideal: 15, maximum: 20),
            height:
                const VideoSizeConstraint(minimum: 15, ideal: 20, maximum: 25),
            deviceId: 'deviceId',
          ),
        ),
        equals(
          CameraOptions(
            audio: const AudioConstraints(enabled: false),
            video: VideoConstraints(
              facingMode: FacingModeConstraint(CameraType.environment),
              width: const VideoSizeConstraint(
                  minimum: 10, ideal: 15, maximum: 20),
              height: const VideoSizeConstraint(
                  minimum: 15, ideal: 20, maximum: 25),
              deviceId: 'deviceId',
            ),
          ),
        ),
      );
    });
  });

  group('AudioConstraints', () {
    testWidgets('serializes correctly', (WidgetTester tester) async {
      expect(
        const AudioConstraints(enabled: true).toJson(),
        equals(true),
      );
    });

    testWidgets('supports value equality', (WidgetTester tester) async {
      expect(
        const AudioConstraints(enabled: true),
        equals(const AudioConstraints(enabled: true)),
      );
    });
  });

  group('VideoConstraints', () {
    testWidgets('serializes correctly', (WidgetTester tester) async {
      final VideoConstraints videoConstraints = VideoConstraints(
        facingMode: FacingModeConstraint.exact(CameraType.user),
        width: const VideoSizeConstraint(ideal: 100, maximum: 100),
        height: const VideoSizeConstraint(ideal: 50, maximum: 50),
        deviceId: 'deviceId',
      );

      expect(
        videoConstraints.toJson(),
        equals(<String, Object>{
          'facingMode': videoConstraints.facingMode!.toJson(),
          'width': videoConstraints.width!.toJson(),
          'height': videoConstraints.height!.toJson(),
          'deviceId': <String, Object>{
            'exact': 'deviceId',
          }
        }),
      );
    });

    testWidgets('supports value equality', (WidgetTester tester) async {
      expect(
        VideoConstraints(
          facingMode: FacingModeConstraint.exact(CameraType.environment),
          width:
              const VideoSizeConstraint(minimum: 90, ideal: 100, maximum: 100),
          height:
              const VideoSizeConstraint(minimum: 40, ideal: 50, maximum: 50),
          deviceId: 'deviceId',
        ),
        equals(
          VideoConstraints(
            facingMode: FacingModeConstraint.exact(CameraType.environment),
            width: const VideoSizeConstraint(
                minimum: 90, ideal: 100, maximum: 100),
            height:
                const VideoSizeConstraint(minimum: 40, ideal: 50, maximum: 50),
            deviceId: 'deviceId',
          ),
        ),
      );
    });
  });

  group('FacingModeConstraint', () {
    group('ideal', () {
      testWidgets(
          'serializes correctly '
          'for environment camera type', (WidgetTester tester) async {
        expect(
          FacingModeConstraint(CameraType.environment).toJson(),
          equals(<String, Object>{'ideal': 'environment'}),
        );
      });

      testWidgets(
          'serializes correctly '
          'for user camera type', (WidgetTester tester) async {
        expect(
          FacingModeConstraint(CameraType.user).toJson(),
          equals(<String, Object>{'ideal': 'user'}),
        );
      });

      testWidgets('supports value equality', (WidgetTester tester) async {
        expect(
          FacingModeConstraint(CameraType.user),
          equals(FacingModeConstraint(CameraType.user)),
        );
      });
    });

    group('exact', () {
      testWidgets(
          'serializes correctly '
          'for environment camera type', (WidgetTester tester) async {
        expect(
          FacingModeConstraint.exact(CameraType.environment).toJson(),
          equals(<String, Object>{'exact': 'environment'}),
        );
      });

      testWidgets(
          'serializes correctly '
          'for user camera type', (WidgetTester tester) async {
        expect(
          FacingModeConstraint.exact(CameraType.user).toJson(),
          equals(<String, Object>{'exact': 'user'}),
        );
      });

      testWidgets('supports value equality', (WidgetTester tester) async {
        expect(
          FacingModeConstraint.exact(CameraType.environment),
          equals(FacingModeConstraint.exact(CameraType.environment)),
        );
      });
    });
  });

  group('VideoSizeConstraint ', () {
    testWidgets('serializes correctly', (WidgetTester tester) async {
      expect(
        const VideoSizeConstraint(
          minimum: 200,
          ideal: 400,
          maximum: 400,
        ).toJson(),
        equals(<String, Object>{
          'min': 200,
          'ideal': 400,
          'max': 400,
        }),
      );
    });

    testWidgets('supports value equality', (WidgetTester tester) async {
      expect(
        const VideoSizeConstraint(
          minimum: 100,
          ideal: 200,
          maximum: 300,
        ),
        equals(
          const VideoSizeConstraint(
            minimum: 100,
            ideal: 200,
            maximum: 300,
          ),
        ),
      );
    });
  });
}
