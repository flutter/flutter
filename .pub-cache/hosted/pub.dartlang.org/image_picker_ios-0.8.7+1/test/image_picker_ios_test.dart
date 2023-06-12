// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_ios/image_picker_ios.dart';
import 'package:image_picker_ios/src/messages.g.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import 'test_api.g.dart';

@immutable
class _LoggedMethodCall {
  const _LoggedMethodCall(this.name, {required this.arguments});
  final String name;
  final Map<String, Object?> arguments;

  @override
  bool operator ==(Object other) {
    return other is _LoggedMethodCall &&
        name == other.name &&
        mapEquals(arguments, other.arguments);
  }

  @override
  int get hashCode => Object.hash(name, arguments);

  @override
  String toString() {
    return 'MethodCall: $name $arguments';
  }
}

class _ApiLogger implements TestHostImagePickerApi {
  // The value to return from future calls.
  dynamic returnValue = '';
  final List<_LoggedMethodCall> calls = <_LoggedMethodCall>[];

  @override
  Future<String?> pickImage(
    SourceSpecification source,
    MaxSize maxSize,
    int? imageQuality,
    bool requestFullMetadata,
  ) async {
    // Flatten arguments for easy comparison.
    calls.add(_LoggedMethodCall('pickImage', arguments: <String, dynamic>{
      'source': source.type,
      'cameraDevice': source.camera,
      'maxWidth': maxSize.width,
      'maxHeight': maxSize.height,
      'imageQuality': imageQuality,
      'requestFullMetadata': requestFullMetadata,
    }));
    return returnValue as String?;
  }

  @override
  Future<List<String?>?> pickMultiImage(
    MaxSize maxSize,
    int? imageQuality,
    bool requestFullMetadata,
  ) async {
    calls.add(_LoggedMethodCall('pickMultiImage', arguments: <String, dynamic>{
      'maxWidth': maxSize.width,
      'maxHeight': maxSize.height,
      'imageQuality': imageQuality,
      'requestFullMetadata': requestFullMetadata,
    }));
    return returnValue as List<String?>?;
  }

  @override
  Future<String?> pickVideo(
      SourceSpecification source, int? maxDurationSeconds) async {
    calls.add(_LoggedMethodCall('pickVideo', arguments: <String, dynamic>{
      'source': source.type,
      'cameraDevice': source.camera,
      'maxDuration': maxDurationSeconds,
    }));
    return returnValue as String?;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final ImagePickerIOS picker = ImagePickerIOS();
  late _ApiLogger log;

  setUp(() {
    log = _ApiLogger();
    TestHostImagePickerApi.setup(log);
  });

  test('registration', () async {
    ImagePickerIOS.registerWith();
    expect(ImagePickerPlatform.instance, isA<ImagePickerIOS>());
  });

  group('#pickImage', () {
    test('passes the image source argument correctly', () async {
      await picker.pickImage(source: ImageSource.camera);
      await picker.pickImage(source: ImageSource.gallery);

      expect(
        log.calls,
        <_LoggedMethodCall>[
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxWidth': null,
            'maxHeight': null,
            'imageQuality': null,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.gallery,
            'maxWidth': null,
            'maxHeight': null,
            'imageQuality': null,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
        ],
      );
    });

    test('passes the width and height arguments correctly', () async {
      await picker.pickImage(source: ImageSource.camera);
      await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 10.0,
      );
      await picker.pickImage(
        source: ImageSource.camera,
        maxHeight: 10.0,
      );
      await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 10.0,
        maxHeight: 20.0,
      );
      await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 10.0,
        imageQuality: 70,
      );
      await picker.pickImage(
        source: ImageSource.camera,
        maxHeight: 10.0,
        imageQuality: 70,
      );
      await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 10.0,
        maxHeight: 20.0,
        imageQuality: 70,
      );

      expect(
        log.calls,
        <_LoggedMethodCall>[
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxWidth': null,
            'maxHeight': null,
            'imageQuality': null,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxWidth': 10.0,
            'maxHeight': null,
            'imageQuality': null,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxWidth': null,
            'maxHeight': 10.0,
            'imageQuality': null,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxWidth': 10.0,
            'maxHeight': 20.0,
            'imageQuality': null,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxWidth': 10.0,
            'maxHeight': null,
            'imageQuality': 70,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxWidth': null,
            'maxHeight': 10.0,
            'imageQuality': 70,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxWidth': 10.0,
            'maxHeight': 20.0,
            'imageQuality': 70,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
        ],
      );
    });

    test('does not accept a invalid imageQuality argument', () {
      expect(
        () => picker.pickImage(imageQuality: -1, source: ImageSource.gallery),
        throwsArgumentError,
      );

      expect(
        () => picker.pickImage(imageQuality: 101, source: ImageSource.gallery),
        throwsArgumentError,
      );

      expect(
        () => picker.pickImage(imageQuality: -1, source: ImageSource.camera),
        throwsArgumentError,
      );

      expect(
        () => picker.pickImage(imageQuality: 101, source: ImageSource.camera),
        throwsArgumentError,
      );
    });

    test('does not accept a negative width or height argument', () {
      expect(
        () => picker.pickImage(source: ImageSource.camera, maxWidth: -1.0),
        throwsArgumentError,
      );

      expect(
        () => picker.pickImage(source: ImageSource.camera, maxHeight: -1.0),
        throwsArgumentError,
      );
    });

    test('handles a null image path response gracefully', () async {
      log.returnValue = null;

      expect(await picker.pickImage(source: ImageSource.gallery), isNull);
      expect(await picker.pickImage(source: ImageSource.camera), isNull);
    });

    test('camera position defaults to back', () async {
      await picker.pickImage(source: ImageSource.camera);

      expect(
        log.calls,
        <_LoggedMethodCall>[
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxWidth': null,
            'maxHeight': null,
            'imageQuality': null,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
        ],
      );
    });

    test('camera position can set to front', () async {
      await picker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.front);

      expect(
        log.calls,
        <_LoggedMethodCall>[
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxWidth': null,
            'maxHeight': null,
            'imageQuality': null,
            'cameraDevice': SourceCamera.front,
            'requestFullMetadata': true,
          }),
        ],
      );
    });
  });

  group('#pickMultiImage', () {
    test('calls the method correctly', () async {
      log.returnValue = <String>['0', '1'];
      await picker.pickMultiImage();

      expect(
        log.calls,
        <_LoggedMethodCall>[
          const _LoggedMethodCall('pickMultiImage',
              arguments: <String, dynamic>{
                'maxWidth': null,
                'maxHeight': null,
                'imageQuality': null,
                'requestFullMetadata': true,
              }),
        ],
      );
    });

    test('passes the width and height arguments correctly', () async {
      log.returnValue = <String>['0', '1'];
      await picker.pickMultiImage();
      await picker.pickMultiImage(
        maxWidth: 10.0,
      );
      await picker.pickMultiImage(
        maxHeight: 10.0,
      );
      await picker.pickMultiImage(
        maxWidth: 10.0,
        maxHeight: 20.0,
      );
      await picker.pickMultiImage(
        maxWidth: 10.0,
        imageQuality: 70,
      );
      await picker.pickMultiImage(
        maxHeight: 10.0,
        imageQuality: 70,
      );
      await picker.pickMultiImage(
        maxWidth: 10.0,
        maxHeight: 20.0,
        imageQuality: 70,
      );

      expect(
        log.calls,
        <_LoggedMethodCall>[
          const _LoggedMethodCall('pickMultiImage',
              arguments: <String, dynamic>{
                'maxWidth': null,
                'maxHeight': null,
                'imageQuality': null,
                'requestFullMetadata': true,
              }),
          const _LoggedMethodCall('pickMultiImage',
              arguments: <String, dynamic>{
                'maxWidth': 10.0,
                'maxHeight': null,
                'imageQuality': null,
                'requestFullMetadata': true,
              }),
          const _LoggedMethodCall('pickMultiImage',
              arguments: <String, dynamic>{
                'maxWidth': null,
                'maxHeight': 10.0,
                'imageQuality': null,
                'requestFullMetadata': true,
              }),
          const _LoggedMethodCall('pickMultiImage',
              arguments: <String, dynamic>{
                'maxWidth': 10.0,
                'maxHeight': 20.0,
                'imageQuality': null,
                'requestFullMetadata': true,
              }),
          const _LoggedMethodCall('pickMultiImage',
              arguments: <String, dynamic>{
                'maxWidth': 10.0,
                'maxHeight': null,
                'imageQuality': 70,
                'requestFullMetadata': true,
              }),
          const _LoggedMethodCall('pickMultiImage',
              arguments: <String, dynamic>{
                'maxWidth': null,
                'maxHeight': 10.0,
                'imageQuality': 70,
                'requestFullMetadata': true,
              }),
          const _LoggedMethodCall('pickMultiImage',
              arguments: <String, dynamic>{
                'maxWidth': 10.0,
                'maxHeight': 20.0,
                'imageQuality': 70,
                'requestFullMetadata': true,
              }),
        ],
      );
    });

    test('does not accept a negative width or height argument', () {
      expect(
        () => picker.pickMultiImage(maxWidth: -1.0),
        throwsArgumentError,
      );

      expect(
        () => picker.pickMultiImage(maxHeight: -1.0),
        throwsArgumentError,
      );
    });

    test('does not accept a invalid imageQuality argument', () {
      expect(
        () => picker.pickMultiImage(imageQuality: -1),
        throwsArgumentError,
      );

      expect(
        () => picker.pickMultiImage(imageQuality: 101),
        throwsArgumentError,
      );
    });

    test('handles a null image path response gracefully', () async {
      log.returnValue = null;

      expect(await picker.pickMultiImage(), isNull);
    });
  });

  group('#pickVideo', () {
    test('passes the image source argument correctly', () async {
      await picker.pickVideo(source: ImageSource.camera);
      await picker.pickVideo(source: ImageSource.gallery);

      expect(
        log.calls,
        <_LoggedMethodCall>[
          const _LoggedMethodCall('pickVideo', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'cameraDevice': SourceCamera.rear,
            'maxDuration': null,
          }),
          const _LoggedMethodCall('pickVideo', arguments: <String, dynamic>{
            'source': SourceType.gallery,
            'cameraDevice': SourceCamera.rear,
            'maxDuration': null,
          }),
        ],
      );
    });

    test('passes the duration argument correctly', () async {
      await picker.pickVideo(source: ImageSource.camera);
      await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 10),
      );
      await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 1),
      );
      await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(hours: 1),
      );
      expect(
        log.calls,
        <_LoggedMethodCall>[
          const _LoggedMethodCall('pickVideo', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxDuration': null,
            'cameraDevice': SourceCamera.rear,
          }),
          const _LoggedMethodCall('pickVideo', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxDuration': 10,
            'cameraDevice': SourceCamera.rear,
          }),
          const _LoggedMethodCall('pickVideo', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxDuration': 60,
            'cameraDevice': SourceCamera.rear,
          }),
          const _LoggedMethodCall('pickVideo', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxDuration': 3600,
            'cameraDevice': SourceCamera.rear,
          }),
        ],
      );
    });

    test('handles a null video path response gracefully', () async {
      log.returnValue = null;

      expect(await picker.pickVideo(source: ImageSource.gallery), isNull);
      expect(await picker.pickVideo(source: ImageSource.camera), isNull);
    });

    test('camera position defaults to back', () async {
      await picker.pickVideo(source: ImageSource.camera);

      expect(
        log.calls,
        <_LoggedMethodCall>[
          const _LoggedMethodCall('pickVideo', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'cameraDevice': SourceCamera.rear,
            'maxDuration': null,
          }),
        ],
      );
    });

    test('camera position can set to front', () async {
      await picker.pickVideo(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );

      expect(
        log.calls,
        <_LoggedMethodCall>[
          const _LoggedMethodCall('pickVideo', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxDuration': null,
            'cameraDevice': SourceCamera.front,
          }),
        ],
      );
    });
  });

  group('#getImage', () {
    test('passes the image source argument correctly', () async {
      await picker.getImage(source: ImageSource.camera);
      await picker.getImage(source: ImageSource.gallery);

      expect(
        log.calls,
        <_LoggedMethodCall>[
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxWidth': null,
            'maxHeight': null,
            'imageQuality': null,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.gallery,
            'maxWidth': null,
            'maxHeight': null,
            'imageQuality': null,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
        ],
      );
    });

    test('passes the width and height arguments correctly', () async {
      await picker.getImage(source: ImageSource.camera);
      await picker.getImage(
        source: ImageSource.camera,
        maxWidth: 10.0,
      );
      await picker.getImage(
        source: ImageSource.camera,
        maxHeight: 10.0,
      );
      await picker.getImage(
        source: ImageSource.camera,
        maxWidth: 10.0,
        maxHeight: 20.0,
      );
      await picker.getImage(
        source: ImageSource.camera,
        maxWidth: 10.0,
        imageQuality: 70,
      );
      await picker.getImage(
        source: ImageSource.camera,
        maxHeight: 10.0,
        imageQuality: 70,
      );
      await picker.getImage(
        source: ImageSource.camera,
        maxWidth: 10.0,
        maxHeight: 20.0,
        imageQuality: 70,
      );

      expect(
        log.calls,
        <_LoggedMethodCall>[
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxWidth': null,
            'maxHeight': null,
            'imageQuality': null,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxWidth': 10.0,
            'maxHeight': null,
            'imageQuality': null,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxWidth': null,
            'maxHeight': 10.0,
            'imageQuality': null,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxWidth': 10.0,
            'maxHeight': 20.0,
            'imageQuality': null,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxWidth': 10.0,
            'maxHeight': null,
            'imageQuality': 70,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxWidth': null,
            'maxHeight': 10.0,
            'imageQuality': 70,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxWidth': 10.0,
            'maxHeight': 20.0,
            'imageQuality': 70,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
        ],
      );
    });

    test('does not accept a invalid imageQuality argument', () {
      expect(
        () => picker.getImage(imageQuality: -1, source: ImageSource.gallery),
        throwsArgumentError,
      );

      expect(
        () => picker.getImage(imageQuality: 101, source: ImageSource.gallery),
        throwsArgumentError,
      );

      expect(
        () => picker.getImage(imageQuality: -1, source: ImageSource.camera),
        throwsArgumentError,
      );

      expect(
        () => picker.getImage(imageQuality: 101, source: ImageSource.camera),
        throwsArgumentError,
      );
    });

    test('does not accept a negative width or height argument', () {
      expect(
        () => picker.getImage(source: ImageSource.camera, maxWidth: -1.0),
        throwsArgumentError,
      );

      expect(
        () => picker.getImage(source: ImageSource.camera, maxHeight: -1.0),
        throwsArgumentError,
      );
    });

    test('handles a null image path response gracefully', () async {
      log.returnValue = null;

      expect(await picker.getImage(source: ImageSource.gallery), isNull);
      expect(await picker.getImage(source: ImageSource.camera), isNull);
    });

    test('camera position defaults to back', () async {
      await picker.getImage(source: ImageSource.camera);

      expect(
        log.calls,
        <_LoggedMethodCall>[
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxWidth': null,
            'maxHeight': null,
            'imageQuality': null,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
        ],
      );
    });

    test('camera position can set to front', () async {
      await picker.getImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.front);

      expect(
        log.calls,
        <_LoggedMethodCall>[
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxWidth': null,
            'maxHeight': null,
            'imageQuality': null,
            'cameraDevice': SourceCamera.front,
            'requestFullMetadata': true,
          }),
        ],
      );
    });
  });

  group('#getMultiImage', () {
    test('calls the method correctly', () async {
      log.returnValue = <String>['0', '1'];
      await picker.getMultiImage();

      expect(
        log.calls,
        <_LoggedMethodCall>[
          const _LoggedMethodCall('pickMultiImage',
              arguments: <String, dynamic>{
                'maxWidth': null,
                'maxHeight': null,
                'imageQuality': null,
                'requestFullMetadata': true,
              }),
        ],
      );
    });

    test('passes the width and height arguments correctly', () async {
      log.returnValue = <String>['0', '1'];
      await picker.getMultiImage();
      await picker.getMultiImage(
        maxWidth: 10.0,
      );
      await picker.getMultiImage(
        maxHeight: 10.0,
      );
      await picker.getMultiImage(
        maxWidth: 10.0,
        maxHeight: 20.0,
      );
      await picker.getMultiImage(
        maxWidth: 10.0,
        imageQuality: 70,
      );
      await picker.getMultiImage(
        maxHeight: 10.0,
        imageQuality: 70,
      );
      await picker.getMultiImage(
        maxWidth: 10.0,
        maxHeight: 20.0,
        imageQuality: 70,
      );

      expect(
        log.calls,
        <_LoggedMethodCall>[
          const _LoggedMethodCall('pickMultiImage',
              arguments: <String, dynamic>{
                'maxWidth': null,
                'maxHeight': null,
                'imageQuality': null,
                'requestFullMetadata': true,
              }),
          const _LoggedMethodCall('pickMultiImage',
              arguments: <String, dynamic>{
                'maxWidth': 10.0,
                'maxHeight': null,
                'imageQuality': null,
                'requestFullMetadata': true,
              }),
          const _LoggedMethodCall('pickMultiImage',
              arguments: <String, dynamic>{
                'maxWidth': null,
                'maxHeight': 10.0,
                'imageQuality': null,
                'requestFullMetadata': true,
              }),
          const _LoggedMethodCall('pickMultiImage',
              arguments: <String, dynamic>{
                'maxWidth': 10.0,
                'maxHeight': 20.0,
                'imageQuality': null,
                'requestFullMetadata': true,
              }),
          const _LoggedMethodCall('pickMultiImage',
              arguments: <String, dynamic>{
                'maxWidth': 10.0,
                'maxHeight': null,
                'imageQuality': 70,
                'requestFullMetadata': true,
              }),
          const _LoggedMethodCall('pickMultiImage',
              arguments: <String, dynamic>{
                'maxWidth': null,
                'maxHeight': 10.0,
                'imageQuality': 70,
                'requestFullMetadata': true,
              }),
          const _LoggedMethodCall('pickMultiImage',
              arguments: <String, dynamic>{
                'maxWidth': 10.0,
                'maxHeight': 20.0,
                'imageQuality': 70,
                'requestFullMetadata': true,
              }),
        ],
      );
    });

    test('does not accept a negative width or height argument', () {
      log.returnValue = <String>['0', '1'];
      expect(
        () => picker.getMultiImage(maxWidth: -1.0),
        throwsArgumentError,
      );

      expect(
        () => picker.getMultiImage(maxHeight: -1.0),
        throwsArgumentError,
      );
    });

    test('does not accept a invalid imageQuality argument', () {
      log.returnValue = <String>['0', '1'];
      expect(
        () => picker.getMultiImage(imageQuality: -1),
        throwsArgumentError,
      );

      expect(
        () => picker.getMultiImage(imageQuality: 101),
        throwsArgumentError,
      );
    });

    test('handles a null image path response gracefully', () async {
      log.returnValue = null;

      expect(await picker.getMultiImage(), isNull);
      expect(await picker.getMultiImage(), isNull);
    });
  });

  group('#getVideo', () {
    test('passes the image source argument correctly', () async {
      await picker.getVideo(source: ImageSource.camera);
      await picker.getVideo(source: ImageSource.gallery);

      expect(
        log.calls,
        <_LoggedMethodCall>[
          const _LoggedMethodCall('pickVideo', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'cameraDevice': SourceCamera.rear,
            'maxDuration': null,
          }),
          const _LoggedMethodCall('pickVideo', arguments: <String, dynamic>{
            'source': SourceType.gallery,
            'cameraDevice': SourceCamera.rear,
            'maxDuration': null,
          }),
        ],
      );
    });

    test('passes the duration argument correctly', () async {
      await picker.getVideo(source: ImageSource.camera);
      await picker.getVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 10),
      );
      await picker.getVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 1),
      );
      await picker.getVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(hours: 1),
      );
      expect(
        log.calls,
        <_LoggedMethodCall>[
          const _LoggedMethodCall('pickVideo', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxDuration': null,
            'cameraDevice': SourceCamera.rear,
          }),
          const _LoggedMethodCall('pickVideo', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxDuration': 10,
            'cameraDevice': SourceCamera.rear,
          }),
          const _LoggedMethodCall('pickVideo', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxDuration': 60,
            'cameraDevice': SourceCamera.rear,
          }),
          const _LoggedMethodCall('pickVideo', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxDuration': 3600,
            'cameraDevice': SourceCamera.rear,
          }),
        ],
      );
    });

    test('handles a null video path response gracefully', () async {
      log.returnValue = null;

      expect(await picker.getVideo(source: ImageSource.gallery), isNull);
      expect(await picker.getVideo(source: ImageSource.camera), isNull);
    });

    test('camera position defaults to back', () async {
      await picker.getVideo(source: ImageSource.camera);

      expect(
        log.calls,
        <_LoggedMethodCall>[
          const _LoggedMethodCall('pickVideo', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'cameraDevice': SourceCamera.rear,
            'maxDuration': null,
          }),
        ],
      );
    });

    test('camera position can set to front', () async {
      await picker.getVideo(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );

      expect(
        log.calls,
        <_LoggedMethodCall>[
          const _LoggedMethodCall('pickVideo', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxDuration': null,
            'cameraDevice': SourceCamera.front,
          }),
        ],
      );
    });
  });

  group('#getImageFromSource', () {
    test('passes the image source argument correctly', () async {
      await picker.getImageFromSource(source: ImageSource.camera);
      await picker.getImageFromSource(source: ImageSource.gallery);

      expect(
        log.calls,
        <_LoggedMethodCall>[
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxWidth': null,
            'maxHeight': null,
            'imageQuality': null,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.gallery,
            'maxWidth': null,
            'maxHeight': null,
            'imageQuality': null,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
        ],
      );
    });

    test('passes the width and height arguments correctly', () async {
      await picker.getImageFromSource(source: ImageSource.camera);
      await picker.getImageFromSource(
        source: ImageSource.camera,
        options: const ImagePickerOptions(maxWidth: 10.0),
      );
      await picker.getImageFromSource(
        source: ImageSource.camera,
        options: const ImagePickerOptions(maxHeight: 10.0),
      );
      await picker.getImageFromSource(
        source: ImageSource.camera,
        options: const ImagePickerOptions(
          maxWidth: 10.0,
          maxHeight: 20.0,
        ),
      );
      await picker.getImageFromSource(
        source: ImageSource.camera,
        options: const ImagePickerOptions(
          maxWidth: 10.0,
          imageQuality: 70,
        ),
      );
      await picker.getImageFromSource(
        source: ImageSource.camera,
        options: const ImagePickerOptions(
          maxHeight: 10.0,
          imageQuality: 70,
        ),
      );
      await picker.getImageFromSource(
        source: ImageSource.camera,
        options: const ImagePickerOptions(
          maxWidth: 10.0,
          maxHeight: 20.0,
          imageQuality: 70,
        ),
      );

      expect(
        log.calls,
        <_LoggedMethodCall>[
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxWidth': null,
            'maxHeight': null,
            'imageQuality': null,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxWidth': 10.0,
            'maxHeight': null,
            'imageQuality': null,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxWidth': null,
            'maxHeight': 10.0,
            'imageQuality': null,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxWidth': 10.0,
            'maxHeight': 20.0,
            'imageQuality': null,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxWidth': 10.0,
            'maxHeight': null,
            'imageQuality': 70,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxWidth': null,
            'maxHeight': 10.0,
            'imageQuality': 70,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxWidth': 10.0,
            'maxHeight': 20.0,
            'imageQuality': 70,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
        ],
      );
    });

    test('does not accept a invalid imageQuality argument', () {
      expect(
        () => picker.getImageFromSource(
          source: ImageSource.gallery,
          options: const ImagePickerOptions(imageQuality: -1),
        ),
        throwsArgumentError,
      );

      expect(
        () => picker.getImageFromSource(
          source: ImageSource.gallery,
          options: const ImagePickerOptions(imageQuality: 101),
        ),
        throwsArgumentError,
      );

      expect(
        () => picker.getImageFromSource(
          source: ImageSource.camera,
          options: const ImagePickerOptions(imageQuality: -1),
        ),
        throwsArgumentError,
      );

      expect(
        () => picker.getImageFromSource(
          source: ImageSource.camera,
          options: const ImagePickerOptions(imageQuality: 101),
        ),
        throwsArgumentError,
      );
    });

    test('does not accept a negative width or height argument', () {
      expect(
        () => picker.getImageFromSource(
          source: ImageSource.camera,
          options: const ImagePickerOptions(maxWidth: -1.0),
        ),
        throwsArgumentError,
      );

      expect(
        () => picker.getImageFromSource(
          source: ImageSource.camera,
          options: const ImagePickerOptions(maxHeight: -1.0),
        ),
        throwsArgumentError,
      );
    });

    test('handles a null image path response gracefully', () async {
      log.returnValue = null;

      expect(
          await picker.getImageFromSource(source: ImageSource.gallery), isNull);
      expect(
          await picker.getImageFromSource(source: ImageSource.camera), isNull);
    });

    test('camera position defaults to back', () async {
      await picker.getImageFromSource(source: ImageSource.camera);

      expect(
        log.calls,
        <_LoggedMethodCall>[
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxWidth': null,
            'maxHeight': null,
            'imageQuality': null,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
        ],
      );
    });

    test('camera position can set to front', () async {
      await picker.getImageFromSource(
        source: ImageSource.camera,
        options:
            const ImagePickerOptions(preferredCameraDevice: CameraDevice.front),
      );

      expect(
        log.calls,
        <_LoggedMethodCall>[
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.camera,
            'maxWidth': null,
            'maxHeight': null,
            'imageQuality': null,
            'cameraDevice': SourceCamera.front,
            'requestFullMetadata': true,
          }),
        ],
      );
    });

    test('Request full metadata argument defaults to true', () async {
      await picker.getImageFromSource(source: ImageSource.gallery);

      expect(
        log.calls,
        <_LoggedMethodCall>[
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.gallery,
            'maxWidth': null,
            'maxHeight': null,
            'imageQuality': null,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': true,
          }),
        ],
      );
    });

    test('passes the request full metadata argument correctly', () async {
      await picker.getImageFromSource(
        source: ImageSource.gallery,
        options: const ImagePickerOptions(requestFullMetadata: false),
      );

      expect(
        log.calls,
        <_LoggedMethodCall>[
          const _LoggedMethodCall('pickImage', arguments: <String, dynamic>{
            'source': SourceType.gallery,
            'maxWidth': null,
            'maxHeight': null,
            'imageQuality': null,
            'cameraDevice': SourceCamera.rear,
            'requestFullMetadata': false,
          }),
        ],
      );
    });
  });

  group('#getMultiImageWithOptions', () {
    test('calls the method correctly', () async {
      log.returnValue = <String>['0', '1'];
      await picker.getMultiImageWithOptions();

      expect(
        log.calls,
        <_LoggedMethodCall>[
          const _LoggedMethodCall('pickMultiImage',
              arguments: <String, dynamic>{
                'maxWidth': null,
                'maxHeight': null,
                'imageQuality': null,
                'requestFullMetadata': true,
              }),
        ],
      );
    });

    test('passes the width and height arguments correctly', () async {
      log.returnValue = <String>['0', '1'];
      await picker.getMultiImageWithOptions();
      await picker.getMultiImageWithOptions(
        options: const MultiImagePickerOptions(
          imageOptions: ImageOptions(maxWidth: 10.0),
        ),
      );
      await picker.getMultiImageWithOptions(
        options: const MultiImagePickerOptions(
          imageOptions: ImageOptions(maxHeight: 10.0),
        ),
      );
      await picker.getMultiImageWithOptions(
        options: const MultiImagePickerOptions(
          imageOptions: ImageOptions(maxWidth: 10.0, maxHeight: 20.0),
        ),
      );
      await picker.getMultiImageWithOptions(
        options: const MultiImagePickerOptions(
          imageOptions: ImageOptions(maxWidth: 10.0, imageQuality: 70),
        ),
      );
      await picker.getMultiImageWithOptions(
        options: const MultiImagePickerOptions(
          imageOptions: ImageOptions(maxHeight: 10.0, imageQuality: 70),
        ),
      );
      await picker.getMultiImageWithOptions(
        options: const MultiImagePickerOptions(
          imageOptions: ImageOptions(
            maxWidth: 10.0,
            maxHeight: 20.0,
            imageQuality: 70,
          ),
        ),
      );

      expect(
        log.calls,
        <_LoggedMethodCall>[
          const _LoggedMethodCall('pickMultiImage',
              arguments: <String, dynamic>{
                'maxWidth': null,
                'maxHeight': null,
                'imageQuality': null,
                'requestFullMetadata': true,
              }),
          const _LoggedMethodCall('pickMultiImage',
              arguments: <String, dynamic>{
                'maxWidth': 10.0,
                'maxHeight': null,
                'imageQuality': null,
                'requestFullMetadata': true,
              }),
          const _LoggedMethodCall('pickMultiImage',
              arguments: <String, dynamic>{
                'maxWidth': null,
                'maxHeight': 10.0,
                'imageQuality': null,
                'requestFullMetadata': true,
              }),
          const _LoggedMethodCall('pickMultiImage',
              arguments: <String, dynamic>{
                'maxWidth': 10.0,
                'maxHeight': 20.0,
                'imageQuality': null,
                'requestFullMetadata': true,
              }),
          const _LoggedMethodCall('pickMultiImage',
              arguments: <String, dynamic>{
                'maxWidth': 10.0,
                'maxHeight': null,
                'imageQuality': 70,
                'requestFullMetadata': true,
              }),
          const _LoggedMethodCall('pickMultiImage',
              arguments: <String, dynamic>{
                'maxWidth': null,
                'maxHeight': 10.0,
                'imageQuality': 70,
                'requestFullMetadata': true,
              }),
          const _LoggedMethodCall('pickMultiImage',
              arguments: <String, dynamic>{
                'maxWidth': 10.0,
                'maxHeight': 20.0,
                'imageQuality': 70,
                'requestFullMetadata': true,
              }),
        ],
      );
    });

    test('does not accept a negative width or height argument', () {
      log.returnValue = <String>['0', '1'];
      expect(
        () => picker.getMultiImageWithOptions(
          options: const MultiImagePickerOptions(
            imageOptions: ImageOptions(maxWidth: -1.0),
          ),
        ),
        throwsArgumentError,
      );

      expect(
        () => picker.getMultiImageWithOptions(
          options: const MultiImagePickerOptions(
            imageOptions: ImageOptions(maxHeight: -1.0),
          ),
        ),
        throwsArgumentError,
      );
    });

    test('does not accept a invalid imageQuality argument', () {
      log.returnValue = <String>['0', '1'];
      expect(
        () => picker.getMultiImageWithOptions(
          options: const MultiImagePickerOptions(
            imageOptions: ImageOptions(imageQuality: -1),
          ),
        ),
        throwsArgumentError,
      );

      expect(
        () => picker.getMultiImageWithOptions(
          options: const MultiImagePickerOptions(
            imageOptions: ImageOptions(imageQuality: 101),
          ),
        ),
        throwsArgumentError,
      );
    });

    test('handles a null image path response gracefully', () async {
      log.returnValue = null;

      expect(await picker.getMultiImageWithOptions(), isEmpty);
    });

    test('Request full metadata argument defaults to true', () async {
      log.returnValue = <String>['0', '1'];
      await picker.getMultiImageWithOptions();

      expect(
        log.calls,
        <_LoggedMethodCall>[
          const _LoggedMethodCall('pickMultiImage',
              arguments: <String, dynamic>{
                'maxWidth': null,
                'maxHeight': null,
                'imageQuality': null,
                'requestFullMetadata': true,
              }),
        ],
      );
    });

    test('Passes the request full metadata argument correctly', () async {
      log.returnValue = <String>['0', '1'];
      await picker.getMultiImageWithOptions(
        options: const MultiImagePickerOptions(
          imageOptions: ImageOptions(requestFullMetadata: false),
        ),
      );

      expect(
        log.calls,
        <_LoggedMethodCall>[
          const _LoggedMethodCall('pickMultiImage',
              arguments: <String, dynamic>{
                'maxWidth': null,
                'maxHeight': null,
                'imageQuality': null,
                'requestFullMetadata': false,
              }),
        ],
      );
    });
  });
}
