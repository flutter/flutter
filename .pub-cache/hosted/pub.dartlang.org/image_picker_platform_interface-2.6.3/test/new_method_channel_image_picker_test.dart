// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:image_picker_platform_interface/src/method_channel/method_channel_image_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$MethodChannelImagePicker', () {
    final MethodChannelImagePicker picker = MethodChannelImagePicker();

    final List<MethodCall> log = <MethodCall>[];
    dynamic returnValue = '';

    setUp(() {
      returnValue = '';
      _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
          .defaultBinaryMessenger
          .setMockMethodCallHandler(picker.channel,
              (MethodCall methodCall) async {
        log.add(methodCall);
        return returnValue;
      });

      log.clear();
    });

    group('#pickImage', () {
      test('passes the image source argument correctly', () async {
        await picker.pickImage(source: ImageSource.camera);
        await picker.pickImage(source: ImageSource.gallery);

        expect(
          log,
          <Matcher>[
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': null,
              'maxHeight': null,
              'imageQuality': null,
              'cameraDevice': 0,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 1,
              'maxWidth': null,
              'maxHeight': null,
              'imageQuality': null,
              'cameraDevice': 0,
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
          log,
          <Matcher>[
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': null,
              'maxHeight': null,
              'imageQuality': null,
              'cameraDevice': 0,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': 10.0,
              'maxHeight': null,
              'imageQuality': null,
              'cameraDevice': 0,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': null,
              'maxHeight': 10.0,
              'imageQuality': null,
              'cameraDevice': 0,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': 10.0,
              'maxHeight': 20.0,
              'imageQuality': null,
              'cameraDevice': 0,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': 10.0,
              'maxHeight': null,
              'imageQuality': 70,
              'cameraDevice': 0,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': null,
              'maxHeight': 10.0,
              'imageQuality': 70,
              'cameraDevice': 0,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': 10.0,
              'maxHeight': 20.0,
              'imageQuality': 70,
              'cameraDevice': 0,
              'requestFullMetadata': true,
            }),
          ],
        );
      });

      test('does not accept an invalid imageQuality argument', () {
        expect(
          () => picker.pickImage(imageQuality: -1, source: ImageSource.gallery),
          throwsArgumentError,
        );

        expect(
          () =>
              picker.pickImage(imageQuality: 101, source: ImageSource.gallery),
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
        _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
            .defaultBinaryMessenger
            .setMockMethodCallHandler(
                picker.channel, (MethodCall methodCall) => null);

        expect(await picker.pickImage(source: ImageSource.gallery), isNull);
        expect(await picker.pickImage(source: ImageSource.camera), isNull);
      });

      test('camera position defaults to back', () async {
        await picker.pickImage(source: ImageSource.camera);

        expect(
          log,
          <Matcher>[
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': null,
              'maxHeight': null,
              'imageQuality': null,
              'cameraDevice': 0,
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
          log,
          <Matcher>[
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': null,
              'maxHeight': null,
              'imageQuality': null,
              'cameraDevice': 1,
              'requestFullMetadata': true,
            }),
          ],
        );
      });
    });

    group('#pickMultiImage', () {
      test('calls the method correctly', () async {
        returnValue = <dynamic>['0', '1'];
        await picker.pickMultiImage();

        expect(
          log,
          <Matcher>[
            isMethodCall('pickMultiImage', arguments: <String, dynamic>{
              'maxWidth': null,
              'maxHeight': null,
              'imageQuality': null,
              'requestFullMetadata': true,
            }),
          ],
        );
      });

      test('passes the width and height arguments correctly', () async {
        returnValue = <dynamic>['0', '1'];
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
          log,
          <Matcher>[
            isMethodCall('pickMultiImage', arguments: <String, dynamic>{
              'maxWidth': null,
              'maxHeight': null,
              'imageQuality': null,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickMultiImage', arguments: <String, dynamic>{
              'maxWidth': 10.0,
              'maxHeight': null,
              'imageQuality': null,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickMultiImage', arguments: <String, dynamic>{
              'maxWidth': null,
              'maxHeight': 10.0,
              'imageQuality': null,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickMultiImage', arguments: <String, dynamic>{
              'maxWidth': 10.0,
              'maxHeight': 20.0,
              'imageQuality': null,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickMultiImage', arguments: <String, dynamic>{
              'maxWidth': 10.0,
              'maxHeight': null,
              'imageQuality': 70,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickMultiImage', arguments: <String, dynamic>{
              'maxWidth': null,
              'maxHeight': 10.0,
              'imageQuality': 70,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickMultiImage', arguments: <String, dynamic>{
              'maxWidth': 10.0,
              'maxHeight': 20.0,
              'imageQuality': 70,
              'requestFullMetadata': true,
            }),
          ],
        );
      });

      test('does not accept a negative width or height argument', () {
        returnValue = <dynamic>['0', '1'];
        expect(
          () => picker.pickMultiImage(maxWidth: -1.0),
          throwsArgumentError,
        );

        expect(
          () => picker.pickMultiImage(maxHeight: -1.0),
          throwsArgumentError,
        );
      });

      test('does not accept an invalid imageQuality argument', () {
        returnValue = <dynamic>['0', '1'];
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
        _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
            .defaultBinaryMessenger
            .setMockMethodCallHandler(
                picker.channel, (MethodCall methodCall) => null);

        expect(await picker.pickMultiImage(), isNull);
        expect(await picker.pickMultiImage(), isNull);
      });
    });

    group('#pickVideo', () {
      test('passes the image source argument correctly', () async {
        await picker.pickVideo(source: ImageSource.camera);
        await picker.pickVideo(source: ImageSource.gallery);

        expect(
          log,
          <Matcher>[
            isMethodCall('pickVideo', arguments: <String, dynamic>{
              'source': 0,
              'cameraDevice': 0,
              'maxDuration': null,
            }),
            isMethodCall('pickVideo', arguments: <String, dynamic>{
              'source': 1,
              'cameraDevice': 0,
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
          log,
          <Matcher>[
            isMethodCall('pickVideo', arguments: <String, dynamic>{
              'source': 0,
              'maxDuration': null,
              'cameraDevice': 0,
            }),
            isMethodCall('pickVideo', arguments: <String, dynamic>{
              'source': 0,
              'maxDuration': 10,
              'cameraDevice': 0,
            }),
            isMethodCall('pickVideo', arguments: <String, dynamic>{
              'source': 0,
              'maxDuration': 60,
              'cameraDevice': 0,
            }),
            isMethodCall('pickVideo', arguments: <String, dynamic>{
              'source': 0,
              'maxDuration': 3600,
              'cameraDevice': 0,
            }),
          ],
        );
      });

      test('handles a null video path response gracefully', () async {
        _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
            .defaultBinaryMessenger
            .setMockMethodCallHandler(
                picker.channel, (MethodCall methodCall) => null);

        expect(await picker.pickVideo(source: ImageSource.gallery), isNull);
        expect(await picker.pickVideo(source: ImageSource.camera), isNull);
      });

      test('camera position defaults to back', () async {
        await picker.pickVideo(source: ImageSource.camera);

        expect(
          log,
          <Matcher>[
            isMethodCall('pickVideo', arguments: <String, dynamic>{
              'source': 0,
              'cameraDevice': 0,
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
          log,
          <Matcher>[
            isMethodCall('pickVideo', arguments: <String, dynamic>{
              'source': 0,
              'maxDuration': null,
              'cameraDevice': 1,
            }),
          ],
        );
      });
    });

    group('#retrieveLostData', () {
      test('retrieveLostData get success response', () async {
        _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
            .defaultBinaryMessenger
            .setMockMethodCallHandler(picker.channel,
                (MethodCall methodCall) async {
          return <String, String>{
            'type': 'image',
            'path': '/example/path',
          };
        });
        final LostData response = await picker.retrieveLostData();
        expect(response.type, RetrieveType.image);
        expect(response.file, isNotNull);
        expect(response.file!.path, '/example/path');
      });

      test('retrieveLostData get error response', () async {
        _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
            .defaultBinaryMessenger
            .setMockMethodCallHandler(picker.channel,
                (MethodCall methodCall) async {
          return <String, String>{
            'type': 'video',
            'errorCode': 'test_error_code',
            'errorMessage': 'test_error_message',
          };
        });
        final LostData response = await picker.retrieveLostData();
        expect(response.type, RetrieveType.video);
        expect(response.exception, isNotNull);
        expect(response.exception!.code, 'test_error_code');
        expect(response.exception!.message, 'test_error_message');
      });

      test('retrieveLostData get null response', () async {
        _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
            .defaultBinaryMessenger
            .setMockMethodCallHandler(picker.channel,
                (MethodCall methodCall) async {
          return null;
        });
        expect((await picker.retrieveLostData()).isEmpty, true);
      });

      test('retrieveLostData get both path and error should throw', () async {
        _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
            .defaultBinaryMessenger
            .setMockMethodCallHandler(picker.channel,
                (MethodCall methodCall) async {
          return <String, String>{
            'type': 'video',
            'errorCode': 'test_error_code',
            'errorMessage': 'test_error_message',
            'path': '/example/path',
          };
        });
        expect(picker.retrieveLostData(), throwsAssertionError);
      });
    });

    group('#getImage', () {
      test('passes the image source argument correctly', () async {
        await picker.getImage(source: ImageSource.camera);
        await picker.getImage(source: ImageSource.gallery);

        expect(
          log,
          <Matcher>[
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': null,
              'maxHeight': null,
              'imageQuality': null,
              'cameraDevice': 0,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 1,
              'maxWidth': null,
              'maxHeight': null,
              'imageQuality': null,
              'cameraDevice': 0,
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
          log,
          <Matcher>[
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': null,
              'maxHeight': null,
              'imageQuality': null,
              'cameraDevice': 0,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': 10.0,
              'maxHeight': null,
              'imageQuality': null,
              'cameraDevice': 0,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': null,
              'maxHeight': 10.0,
              'imageQuality': null,
              'cameraDevice': 0,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': 10.0,
              'maxHeight': 20.0,
              'imageQuality': null,
              'cameraDevice': 0,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': 10.0,
              'maxHeight': null,
              'imageQuality': 70,
              'cameraDevice': 0,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': null,
              'maxHeight': 10.0,
              'imageQuality': 70,
              'cameraDevice': 0,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': 10.0,
              'maxHeight': 20.0,
              'imageQuality': 70,
              'cameraDevice': 0,
              'requestFullMetadata': true,
            }),
          ],
        );
      });

      test('does not accept an invalid imageQuality argument', () {
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
        _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
            .defaultBinaryMessenger
            .setMockMethodCallHandler(
                picker.channel, (MethodCall methodCall) => null);

        expect(await picker.getImage(source: ImageSource.gallery), isNull);
        expect(await picker.getImage(source: ImageSource.camera), isNull);
      });

      test('camera position defaults to back', () async {
        await picker.getImage(source: ImageSource.camera);

        expect(
          log,
          <Matcher>[
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': null,
              'maxHeight': null,
              'imageQuality': null,
              'cameraDevice': 0,
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
          log,
          <Matcher>[
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': null,
              'maxHeight': null,
              'imageQuality': null,
              'cameraDevice': 1,
              'requestFullMetadata': true,
            }),
          ],
        );
      });
    });

    group('#getMultiImage', () {
      test('calls the method correctly', () async {
        returnValue = <dynamic>['0', '1'];
        await picker.getMultiImage();

        expect(
          log,
          <Matcher>[
            isMethodCall('pickMultiImage', arguments: <String, dynamic>{
              'maxWidth': null,
              'maxHeight': null,
              'imageQuality': null,
              'requestFullMetadata': true,
            }),
          ],
        );
      });

      test('passes the width and height arguments correctly', () async {
        returnValue = <dynamic>['0', '1'];
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
          log,
          <Matcher>[
            isMethodCall('pickMultiImage', arguments: <String, dynamic>{
              'maxWidth': null,
              'maxHeight': null,
              'imageQuality': null,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickMultiImage', arguments: <String, dynamic>{
              'maxWidth': 10.0,
              'maxHeight': null,
              'imageQuality': null,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickMultiImage', arguments: <String, dynamic>{
              'maxWidth': null,
              'maxHeight': 10.0,
              'imageQuality': null,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickMultiImage', arguments: <String, dynamic>{
              'maxWidth': 10.0,
              'maxHeight': 20.0,
              'imageQuality': null,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickMultiImage', arguments: <String, dynamic>{
              'maxWidth': 10.0,
              'maxHeight': null,
              'imageQuality': 70,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickMultiImage', arguments: <String, dynamic>{
              'maxWidth': null,
              'maxHeight': 10.0,
              'imageQuality': 70,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickMultiImage', arguments: <String, dynamic>{
              'maxWidth': 10.0,
              'maxHeight': 20.0,
              'imageQuality': 70,
              'requestFullMetadata': true,
            }),
          ],
        );
      });

      test('does not accept a negative width or height argument', () {
        returnValue = <dynamic>['0', '1'];
        expect(
          () => picker.getMultiImage(maxWidth: -1.0),
          throwsArgumentError,
        );

        expect(
          () => picker.getMultiImage(maxHeight: -1.0),
          throwsArgumentError,
        );
      });

      test('does not accept an invalid imageQuality argument', () {
        returnValue = <dynamic>['0', '1'];
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
        _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
            .defaultBinaryMessenger
            .setMockMethodCallHandler(
                picker.channel, (MethodCall methodCall) => null);

        expect(await picker.getMultiImage(), isNull);
        expect(await picker.getMultiImage(), isNull);
      });
    });

    group('#getVideo', () {
      test('passes the image source argument correctly', () async {
        await picker.getVideo(source: ImageSource.camera);
        await picker.getVideo(source: ImageSource.gallery);

        expect(
          log,
          <Matcher>[
            isMethodCall('pickVideo', arguments: <String, dynamic>{
              'source': 0,
              'cameraDevice': 0,
              'maxDuration': null,
            }),
            isMethodCall('pickVideo', arguments: <String, dynamic>{
              'source': 1,
              'cameraDevice': 0,
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
          log,
          <Matcher>[
            isMethodCall('pickVideo', arguments: <String, dynamic>{
              'source': 0,
              'maxDuration': null,
              'cameraDevice': 0,
            }),
            isMethodCall('pickVideo', arguments: <String, dynamic>{
              'source': 0,
              'maxDuration': 10,
              'cameraDevice': 0,
            }),
            isMethodCall('pickVideo', arguments: <String, dynamic>{
              'source': 0,
              'maxDuration': 60,
              'cameraDevice': 0,
            }),
            isMethodCall('pickVideo', arguments: <String, dynamic>{
              'source': 0,
              'maxDuration': 3600,
              'cameraDevice': 0,
            }),
          ],
        );
      });

      test('handles a null video path response gracefully', () async {
        _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
            .defaultBinaryMessenger
            .setMockMethodCallHandler(
                picker.channel, (MethodCall methodCall) => null);

        expect(await picker.getVideo(source: ImageSource.gallery), isNull);
        expect(await picker.getVideo(source: ImageSource.camera), isNull);
      });

      test('camera position defaults to back', () async {
        await picker.getVideo(source: ImageSource.camera);

        expect(
          log,
          <Matcher>[
            isMethodCall('pickVideo', arguments: <String, dynamic>{
              'source': 0,
              'cameraDevice': 0,
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
          log,
          <Matcher>[
            isMethodCall('pickVideo', arguments: <String, dynamic>{
              'source': 0,
              'maxDuration': null,
              'cameraDevice': 1,
            }),
          ],
        );
      });
    });

    group('#getLostData', () {
      test('getLostData get success response', () async {
        _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
            .defaultBinaryMessenger
            .setMockMethodCallHandler(picker.channel,
                (MethodCall methodCall) async {
          return <String, String>{
            'type': 'image',
            'path': '/example/path',
          };
        });
        final LostDataResponse response = await picker.getLostData();
        expect(response.type, RetrieveType.image);
        expect(response.file, isNotNull);
        expect(response.file!.path, '/example/path');
      });

      test('getLostData should successfully retrieve multiple files', () async {
        _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
            .defaultBinaryMessenger
            .setMockMethodCallHandler(picker.channel,
                (MethodCall methodCall) async {
          return <String, dynamic>{
            'type': 'image',
            'path': '/example/path1',
            'pathList': <dynamic>['/example/path0', '/example/path1'],
          };
        });
        final LostDataResponse response = await picker.getLostData();
        expect(response.type, RetrieveType.image);
        expect(response.file, isNotNull);
        expect(response.file!.path, '/example/path1');
        expect(response.files!.first.path, '/example/path0');
        expect(response.files!.length, 2);
      });

      test('getLostData get error response', () async {
        _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
            .defaultBinaryMessenger
            .setMockMethodCallHandler(picker.channel,
                (MethodCall methodCall) async {
          return <String, String>{
            'type': 'video',
            'errorCode': 'test_error_code',
            'errorMessage': 'test_error_message',
          };
        });
        final LostDataResponse response = await picker.getLostData();
        expect(response.type, RetrieveType.video);
        expect(response.exception, isNotNull);
        expect(response.exception!.code, 'test_error_code');
        expect(response.exception!.message, 'test_error_message');
      });

      test('getLostData get null response', () async {
        _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
            .defaultBinaryMessenger
            .setMockMethodCallHandler(picker.channel,
                (MethodCall methodCall) async {
          return null;
        });
        expect((await picker.getLostData()).isEmpty, true);
      });

      test('getLostData get both path and error should throw', () async {
        _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
            .defaultBinaryMessenger
            .setMockMethodCallHandler(picker.channel,
                (MethodCall methodCall) async {
          return <String, String>{
            'type': 'video',
            'errorCode': 'test_error_code',
            'errorMessage': 'test_error_message',
            'path': '/example/path',
          };
        });
        expect(picker.getLostData(), throwsAssertionError);
      });
    });

    group('#getImageFromSource', () {
      test('passes the image source argument correctly', () async {
        await picker.getImageFromSource(source: ImageSource.camera);
        await picker.getImageFromSource(source: ImageSource.gallery);

        expect(
          log,
          <Matcher>[
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': null,
              'maxHeight': null,
              'imageQuality': null,
              'cameraDevice': 0,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 1,
              'maxWidth': null,
              'maxHeight': null,
              'imageQuality': null,
              'cameraDevice': 0,
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
          log,
          <Matcher>[
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': null,
              'maxHeight': null,
              'imageQuality': null,
              'cameraDevice': 0,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': 10.0,
              'maxHeight': null,
              'imageQuality': null,
              'cameraDevice': 0,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': null,
              'maxHeight': 10.0,
              'imageQuality': null,
              'cameraDevice': 0,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': 10.0,
              'maxHeight': 20.0,
              'imageQuality': null,
              'cameraDevice': 0,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': 10.0,
              'maxHeight': null,
              'imageQuality': 70,
              'cameraDevice': 0,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': null,
              'maxHeight': 10.0,
              'imageQuality': 70,
              'cameraDevice': 0,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': 10.0,
              'maxHeight': 20.0,
              'imageQuality': 70,
              'cameraDevice': 0,
              'requestFullMetadata': true,
            }),
          ],
        );
      });

      test('does not accept an invalid imageQuality argument', () {
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
        _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
            .defaultBinaryMessenger
            .setMockMethodCallHandler(
                picker.channel, (MethodCall methodCall) => null);

        expect(await picker.getImageFromSource(source: ImageSource.gallery),
            isNull);
        expect(await picker.getImageFromSource(source: ImageSource.camera),
            isNull);
      });

      test('camera position defaults to back', () async {
        await picker.getImageFromSource(source: ImageSource.camera);

        expect(
          log,
          <Matcher>[
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': null,
              'maxHeight': null,
              'imageQuality': null,
              'cameraDevice': 0,
              'requestFullMetadata': true,
            }),
          ],
        );
      });

      test('camera position can set to front', () async {
        await picker.getImageFromSource(
          source: ImageSource.camera,
          options: const ImagePickerOptions(
            preferredCameraDevice: CameraDevice.front,
          ),
        );

        expect(
          log,
          <Matcher>[
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': null,
              'maxHeight': null,
              'imageQuality': null,
              'cameraDevice': 1,
              'requestFullMetadata': true,
            }),
          ],
        );
      });

      test('passes the full metadata argument correctly', () async {
        await picker.getImageFromSource(
          source: ImageSource.camera,
          options: const ImagePickerOptions(requestFullMetadata: false),
        );

        expect(
          log,
          <Matcher>[
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': null,
              'maxHeight': null,
              'imageQuality': null,
              'cameraDevice': 0,
              'requestFullMetadata': false,
            }),
          ],
        );
      });
    });

    group('#getMultiImageWithOptions', () {
      test('calls the method correctly', () async {
        returnValue = <dynamic>['0', '1'];
        await picker.getMultiImageWithOptions();

        expect(
          log,
          <Matcher>[
            isMethodCall('pickMultiImage', arguments: <String, dynamic>{
              'maxWidth': null,
              'maxHeight': null,
              'imageQuality': null,
              'requestFullMetadata': true,
            }),
          ],
        );
      });

      test('passes the width, height and imageQuality arguments correctly',
          () async {
        returnValue = <dynamic>['0', '1'];
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
            imageOptions: ImageOptions(
              maxWidth: 10.0,
              maxHeight: 20.0,
            ),
          ),
        );
        await picker.getMultiImageWithOptions(
          options: const MultiImagePickerOptions(
            imageOptions: ImageOptions(
              maxWidth: 10.0,
              imageQuality: 70,
            ),
          ),
        );
        await picker.getMultiImageWithOptions(
          options: const MultiImagePickerOptions(
            imageOptions: ImageOptions(
              maxHeight: 10.0,
              imageQuality: 70,
            ),
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
          log,
          <Matcher>[
            isMethodCall('pickMultiImage', arguments: <String, dynamic>{
              'maxWidth': null,
              'maxHeight': null,
              'imageQuality': null,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickMultiImage', arguments: <String, dynamic>{
              'maxWidth': 10.0,
              'maxHeight': null,
              'imageQuality': null,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickMultiImage', arguments: <String, dynamic>{
              'maxWidth': null,
              'maxHeight': 10.0,
              'imageQuality': null,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickMultiImage', arguments: <String, dynamic>{
              'maxWidth': 10.0,
              'maxHeight': 20.0,
              'imageQuality': null,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickMultiImage', arguments: <String, dynamic>{
              'maxWidth': 10.0,
              'maxHeight': null,
              'imageQuality': 70,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickMultiImage', arguments: <String, dynamic>{
              'maxWidth': null,
              'maxHeight': 10.0,
              'imageQuality': 70,
              'requestFullMetadata': true,
            }),
            isMethodCall('pickMultiImage', arguments: <String, dynamic>{
              'maxWidth': 10.0,
              'maxHeight': 20.0,
              'imageQuality': 70,
              'requestFullMetadata': true,
            }),
          ],
        );
      });

      test('does not accept a negative width or height argument', () {
        returnValue = <dynamic>['0', '1'];
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

      test('does not accept an invalid imageQuality argument', () {
        returnValue = <dynamic>['0', '1'];
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
        _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
            .defaultBinaryMessenger
            .setMockMethodCallHandler(
                picker.channel, (MethodCall methodCall) => null);

        expect(await picker.getMultiImage(), isNull);
        expect(await picker.getMultiImage(), isNull);
      });

      test('Request full metadata argument defaults to true', () async {
        returnValue = <dynamic>['0', '1'];
        await picker.getMultiImageWithOptions();

        expect(
          log,
          <Matcher>[
            isMethodCall('pickMultiImage', arguments: <String, dynamic>{
              'maxWidth': null,
              'maxHeight': null,
              'imageQuality': null,
              'requestFullMetadata': true,
            }),
          ],
        );
      });

      test('passes the request full metadata argument correctly', () async {
        returnValue = <dynamic>['0', '1'];
        await picker.getMultiImageWithOptions(
          options: const MultiImagePickerOptions(
            imageOptions: ImageOptions(requestFullMetadata: false),
          ),
        );

        expect(
          log,
          <Matcher>[
            isMethodCall('pickMultiImage', arguments: <String, dynamic>{
              'maxWidth': null,
              'maxHeight': null,
              'imageQuality': null,
              'requestFullMetadata': false,
            }),
          ],
        );
      });
    });
  });
}

/// This allows a value of type T or T? to be treated as a value of type T?.
///
/// We use this so that APIs that have become non-nullable can still be used
/// with `!` and `?` on the stable branch.
T? _ambiguate<T>(T? value) => value;
