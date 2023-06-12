// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:async/async.dart';
import 'package:camera_android/src/android_camera.dart';
import 'package:camera_android/src/utils.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'method_channel_mock.dart';

const String _channelName = 'plugins.flutter.io/camera_android';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registers instance', () async {
    AndroidCamera.registerWith();
    expect(CameraPlatform.instance, isA<AndroidCamera>());
  });

  test('registration does not set message handlers', () async {
    AndroidCamera.registerWith();

    // Setting up a handler requires bindings to be initialized, and since
    // registerWith is called very early in initialization the bindings won't
    // have been initialized. While registerWith could intialize them, that
    // could slow down startup, so instead the handler should be set up lazily.
    final ByteData? response = await TestDefaultBinaryMessengerBinding
        .instance!.defaultBinaryMessenger
        .handlePlatformMessage(
            AndroidCamera.deviceEventChannelName,
            const StandardMethodCodec().encodeMethodCall(const MethodCall(
                'orientation_changed',
                <String, Object>{'orientation': 'portraitDown'})),
            (ByteData? data) {});
    expect(response, null);
  });

  group('Creation, Initialization & Disposal Tests', () {
    test('Should send creation data and receive back a camera id', () async {
      // Arrange
      final MethodChannelMock cameraMockChannel = MethodChannelMock(
          channelName: _channelName,
          methods: <String, dynamic>{
            'create': <String, dynamic>{
              'cameraId': 1,
              'imageFormatGroup': 'unknown',
            }
          });
      final AndroidCamera camera = AndroidCamera();

      // Act
      final int cameraId = await camera.createCamera(
        const CameraDescription(
            name: 'Test',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 0),
        ResolutionPreset.high,
      );

      // Assert
      expect(cameraMockChannel.log, <Matcher>[
        isMethodCall(
          'create',
          arguments: <String, Object?>{
            'cameraName': 'Test',
            'resolutionPreset': 'high',
            'enableAudio': false
          },
        ),
      ]);
      expect(cameraId, 1);
    });

    test('Should throw CameraException when create throws a PlatformException',
        () {
      // Arrange
      MethodChannelMock(channelName: _channelName, methods: <String, dynamic>{
        'create': PlatformException(
          code: 'TESTING_ERROR_CODE',
          message: 'Mock error message used during testing.',
        )
      });
      final AndroidCamera camera = AndroidCamera();

      // Act
      expect(
        () => camera.createCamera(
          const CameraDescription(
            name: 'Test',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 0,
          ),
          ResolutionPreset.high,
        ),
        throwsA(
          isA<CameraException>()
              .having(
                  (CameraException e) => e.code, 'code', 'TESTING_ERROR_CODE')
              .having((CameraException e) => e.description, 'description',
                  'Mock error message used during testing.'),
        ),
      );
    });

    test('Should throw CameraException when create throws a PlatformException',
        () {
      // Arrange
      MethodChannelMock(channelName: _channelName, methods: <String, dynamic>{
        'create': PlatformException(
          code: 'TESTING_ERROR_CODE',
          message: 'Mock error message used during testing.',
        )
      });
      final AndroidCamera camera = AndroidCamera();

      // Act
      expect(
        () => camera.createCamera(
          const CameraDescription(
            name: 'Test',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 0,
          ),
          ResolutionPreset.high,
        ),
        throwsA(
          isA<CameraException>()
              .having(
                  (CameraException e) => e.code, 'code', 'TESTING_ERROR_CODE')
              .having((CameraException e) => e.description, 'description',
                  'Mock error message used during testing.'),
        ),
      );
    });

    test(
      'Should throw CameraException when initialize throws a PlatformException',
      () {
        // Arrange
        MethodChannelMock(
          channelName: _channelName,
          methods: <String, dynamic>{
            'initialize': PlatformException(
              code: 'TESTING_ERROR_CODE',
              message: 'Mock error message used during testing.',
            )
          },
        );
        final AndroidCamera camera = AndroidCamera();

        // Act
        expect(
          () => camera.initializeCamera(0),
          throwsA(
            isA<CameraException>()
                .having(
                    (CameraException e) => e.code, 'code', 'TESTING_ERROR_CODE')
                .having(
                  (CameraException e) => e.description,
                  'description',
                  'Mock error message used during testing.',
                ),
          ),
        );
      },
    );

    test('Should send initialization data', () async {
      // Arrange
      final MethodChannelMock cameraMockChannel = MethodChannelMock(
          channelName: _channelName,
          methods: <String, dynamic>{
            'create': <String, dynamic>{
              'cameraId': 1,
              'imageFormatGroup': 'unknown',
            },
            'initialize': null
          });
      final AndroidCamera camera = AndroidCamera();
      final int cameraId = await camera.createCamera(
        const CameraDescription(
          name: 'Test',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 0,
        ),
        ResolutionPreset.high,
      );

      // Act
      final Future<void> initializeFuture = camera.initializeCamera(cameraId);
      camera.cameraEventStreamController.add(CameraInitializedEvent(
        cameraId,
        1920,
        1080,
        ExposureMode.auto,
        true,
        FocusMode.auto,
        true,
      ));
      await initializeFuture;

      // Assert
      expect(cameraId, 1);
      expect(cameraMockChannel.log, <Matcher>[
        anything,
        isMethodCall(
          'initialize',
          arguments: <String, Object?>{
            'cameraId': 1,
            'imageFormatGroup': 'unknown',
          },
        ),
      ]);
    });

    test('Should send a disposal call on dispose', () async {
      // Arrange
      final MethodChannelMock cameraMockChannel = MethodChannelMock(
          channelName: _channelName,
          methods: <String, dynamic>{
            'create': <String, dynamic>{'cameraId': 1},
            'initialize': null,
            'dispose': <String, dynamic>{'cameraId': 1}
          });

      final AndroidCamera camera = AndroidCamera();
      final int cameraId = await camera.createCamera(
        const CameraDescription(
          name: 'Test',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 0,
        ),
        ResolutionPreset.high,
      );
      final Future<void> initializeFuture = camera.initializeCamera(cameraId);
      camera.cameraEventStreamController.add(CameraInitializedEvent(
        cameraId,
        1920,
        1080,
        ExposureMode.auto,
        true,
        FocusMode.auto,
        true,
      ));
      await initializeFuture;

      // Act
      await camera.dispose(cameraId);

      // Assert
      expect(cameraId, 1);
      expect(cameraMockChannel.log, <Matcher>[
        anything,
        anything,
        isMethodCall(
          'dispose',
          arguments: <String, Object?>{'cameraId': 1},
        ),
      ]);
    });
  });

  group('Event Tests', () {
    late AndroidCamera camera;
    late int cameraId;
    setUp(() async {
      MethodChannelMock(
        channelName: _channelName,
        methods: <String, dynamic>{
          'create': <String, dynamic>{'cameraId': 1},
          'initialize': null
        },
      );
      camera = AndroidCamera();
      cameraId = await camera.createCamera(
        const CameraDescription(
          name: 'Test',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 0,
        ),
        ResolutionPreset.high,
      );
      final Future<void> initializeFuture = camera.initializeCamera(cameraId);
      camera.cameraEventStreamController.add(CameraInitializedEvent(
        cameraId,
        1920,
        1080,
        ExposureMode.auto,
        true,
        FocusMode.auto,
        true,
      ));
      await initializeFuture;
    });

    test('Should receive initialized event', () async {
      // Act
      final Stream<CameraInitializedEvent> eventStream =
          camera.onCameraInitialized(cameraId);
      final StreamQueue<CameraInitializedEvent> streamQueue =
          StreamQueue<CameraInitializedEvent>(eventStream);

      // Emit test events
      final CameraInitializedEvent event = CameraInitializedEvent(
        cameraId,
        3840,
        2160,
        ExposureMode.auto,
        true,
        FocusMode.auto,
        true,
      );
      await camera.handleCameraMethodCall(
          MethodCall('initialized', event.toJson()), cameraId);

      // Assert
      expect(await streamQueue.next, event);

      // Clean up
      await streamQueue.cancel();
    });

    test('Should receive resolution changes', () async {
      // Act
      final Stream<CameraResolutionChangedEvent> resolutionStream =
          camera.onCameraResolutionChanged(cameraId);
      final StreamQueue<CameraResolutionChangedEvent> streamQueue =
          StreamQueue<CameraResolutionChangedEvent>(resolutionStream);

      // Emit test events
      final CameraResolutionChangedEvent fhdEvent =
          CameraResolutionChangedEvent(cameraId, 1920, 1080);
      final CameraResolutionChangedEvent uhdEvent =
          CameraResolutionChangedEvent(cameraId, 3840, 2160);
      await camera.handleCameraMethodCall(
          MethodCall('resolution_changed', fhdEvent.toJson()), cameraId);
      await camera.handleCameraMethodCall(
          MethodCall('resolution_changed', uhdEvent.toJson()), cameraId);
      await camera.handleCameraMethodCall(
          MethodCall('resolution_changed', fhdEvent.toJson()), cameraId);
      await camera.handleCameraMethodCall(
          MethodCall('resolution_changed', uhdEvent.toJson()), cameraId);

      // Assert
      expect(await streamQueue.next, fhdEvent);
      expect(await streamQueue.next, uhdEvent);
      expect(await streamQueue.next, fhdEvent);
      expect(await streamQueue.next, uhdEvent);

      // Clean up
      await streamQueue.cancel();
    });

    test('Should receive camera closing events', () async {
      // Act
      final Stream<CameraClosingEvent> eventStream =
          camera.onCameraClosing(cameraId);
      final StreamQueue<CameraClosingEvent> streamQueue =
          StreamQueue<CameraClosingEvent>(eventStream);

      // Emit test events
      final CameraClosingEvent event = CameraClosingEvent(cameraId);
      await camera.handleCameraMethodCall(
          MethodCall('camera_closing', event.toJson()), cameraId);
      await camera.handleCameraMethodCall(
          MethodCall('camera_closing', event.toJson()), cameraId);
      await camera.handleCameraMethodCall(
          MethodCall('camera_closing', event.toJson()), cameraId);

      // Assert
      expect(await streamQueue.next, event);
      expect(await streamQueue.next, event);
      expect(await streamQueue.next, event);

      // Clean up
      await streamQueue.cancel();
    });

    test('Should receive camera error events', () async {
      // Act
      final Stream<CameraErrorEvent> errorStream =
          camera.onCameraError(cameraId);
      final StreamQueue<CameraErrorEvent> streamQueue =
          StreamQueue<CameraErrorEvent>(errorStream);

      // Emit test events
      final CameraErrorEvent event =
          CameraErrorEvent(cameraId, 'Error Description');
      await camera.handleCameraMethodCall(
          MethodCall('error', event.toJson()), cameraId);
      await camera.handleCameraMethodCall(
          MethodCall('error', event.toJson()), cameraId);
      await camera.handleCameraMethodCall(
          MethodCall('error', event.toJson()), cameraId);

      // Assert
      expect(await streamQueue.next, event);
      expect(await streamQueue.next, event);
      expect(await streamQueue.next, event);

      // Clean up
      await streamQueue.cancel();
    });

    test('Should receive device orientation change events', () async {
      // Act
      final Stream<DeviceOrientationChangedEvent> eventStream =
          camera.onDeviceOrientationChanged();
      final StreamQueue<DeviceOrientationChangedEvent> streamQueue =
          StreamQueue<DeviceOrientationChangedEvent>(eventStream);

      // Emit test events
      const DeviceOrientationChangedEvent event =
          DeviceOrientationChangedEvent(DeviceOrientation.portraitUp);
      for (int i = 0; i < 3; i++) {
        await TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
            .handlePlatformMessage(
                AndroidCamera.deviceEventChannelName,
                const StandardMethodCodec().encodeMethodCall(
                    MethodCall('orientation_changed', event.toJson())),
                null);
      }

      // Assert
      expect(await streamQueue.next, event);
      expect(await streamQueue.next, event);
      expect(await streamQueue.next, event);

      // Clean up
      await streamQueue.cancel();
    });
  });

  group('Function Tests', () {
    late AndroidCamera camera;
    late int cameraId;

    setUp(() async {
      MethodChannelMock(
        channelName: _channelName,
        methods: <String, dynamic>{
          'create': <String, dynamic>{'cameraId': 1},
          'initialize': null
        },
      );
      camera = AndroidCamera();
      cameraId = await camera.createCamera(
        const CameraDescription(
          name: 'Test',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 0,
        ),
        ResolutionPreset.high,
      );
      final Future<void> initializeFuture = camera.initializeCamera(cameraId);
      camera.cameraEventStreamController.add(
        CameraInitializedEvent(
          cameraId,
          1920,
          1080,
          ExposureMode.auto,
          true,
          FocusMode.auto,
          true,
        ),
      );
      await initializeFuture;
    });

    test('Should fetch CameraDescription instances for available cameras',
        () async {
      // Arrange
      final List<dynamic> returnData = <dynamic>[
        <String, dynamic>{
          'name': 'Test 1',
          'lensFacing': 'front',
          'sensorOrientation': 1
        },
        <String, dynamic>{
          'name': 'Test 2',
          'lensFacing': 'back',
          'sensorOrientation': 2
        }
      ];
      final MethodChannelMock channel = MethodChannelMock(
        channelName: _channelName,
        methods: <String, dynamic>{'availableCameras': returnData},
      );

      // Act
      final List<CameraDescription> cameras = await camera.availableCameras();

      // Assert
      expect(channel.log, <Matcher>[
        isMethodCall('availableCameras', arguments: null),
      ]);
      expect(cameras.length, returnData.length);
      for (int i = 0; i < returnData.length; i++) {
        final CameraDescription cameraDescription = CameraDescription(
          name: returnData[i]['name']! as String,
          lensDirection:
              parseCameraLensDirection(returnData[i]['lensFacing']! as String),
          sensorOrientation: returnData[i]['sensorOrientation']! as int,
        );
        expect(cameras[i], cameraDescription);
      }
    });

    test(
        'Should throw CameraException when availableCameras throws a PlatformException',
        () {
      // Arrange
      MethodChannelMock(channelName: _channelName, methods: <String, dynamic>{
        'availableCameras': PlatformException(
          code: 'TESTING_ERROR_CODE',
          message: 'Mock error message used during testing.',
        )
      });

      // Act
      expect(
        camera.availableCameras,
        throwsA(
          isA<CameraException>()
              .having(
                  (CameraException e) => e.code, 'code', 'TESTING_ERROR_CODE')
              .having((CameraException e) => e.description, 'description',
                  'Mock error message used during testing.'),
        ),
      );
    });

    test('Should take a picture and return an XFile instance', () async {
      // Arrange
      final MethodChannelMock channel = MethodChannelMock(
          channelName: _channelName,
          methods: <String, dynamic>{'takePicture': '/test/path.jpg'});

      // Act
      final XFile file = await camera.takePicture(cameraId);

      // Assert
      expect(channel.log, <Matcher>[
        isMethodCall('takePicture', arguments: <String, Object?>{
          'cameraId': cameraId,
        }),
      ]);
      expect(file.path, '/test/path.jpg');
    });

    test('Should prepare for video recording', () async {
      // Arrange
      final MethodChannelMock channel = MethodChannelMock(
        channelName: _channelName,
        methods: <String, dynamic>{'prepareForVideoRecording': null},
      );

      // Act
      await camera.prepareForVideoRecording();

      // Assert
      expect(channel.log, <Matcher>[
        isMethodCall('prepareForVideoRecording', arguments: null),
      ]);
    });

    test('Should start recording a video', () async {
      // Arrange
      final MethodChannelMock channel = MethodChannelMock(
        channelName: _channelName,
        methods: <String, dynamic>{'startVideoRecording': null},
      );

      // Act
      await camera.startVideoRecording(cameraId);

      // Assert
      expect(channel.log, <Matcher>[
        isMethodCall('startVideoRecording', arguments: <String, Object?>{
          'cameraId': cameraId,
          'maxVideoDuration': null,
        }),
      ]);
    });

    test('Should pass maxVideoDuration when starting recording a video',
        () async {
      // Arrange
      final MethodChannelMock channel = MethodChannelMock(
        channelName: _channelName,
        methods: <String, dynamic>{'startVideoRecording': null},
      );

      // Act
      await camera.startVideoRecording(
        cameraId,
        maxVideoDuration: const Duration(seconds: 10),
      );

      // Assert
      expect(channel.log, <Matcher>[
        isMethodCall('startVideoRecording', arguments: <String, Object?>{
          'cameraId': cameraId,
          'maxVideoDuration': 10000
        }),
      ]);
    });

    test('Should stop a video recording and return the file', () async {
      // Arrange
      final MethodChannelMock channel = MethodChannelMock(
        channelName: _channelName,
        methods: <String, dynamic>{'stopVideoRecording': '/test/path.mp4'},
      );

      // Act
      final XFile file = await camera.stopVideoRecording(cameraId);

      // Assert
      expect(channel.log, <Matcher>[
        isMethodCall('stopVideoRecording', arguments: <String, Object?>{
          'cameraId': cameraId,
        }),
      ]);
      expect(file.path, '/test/path.mp4');
    });

    test('Should pause a video recording', () async {
      // Arrange
      final MethodChannelMock channel = MethodChannelMock(
        channelName: _channelName,
        methods: <String, dynamic>{'pauseVideoRecording': null},
      );

      // Act
      await camera.pauseVideoRecording(cameraId);

      // Assert
      expect(channel.log, <Matcher>[
        isMethodCall('pauseVideoRecording', arguments: <String, Object?>{
          'cameraId': cameraId,
        }),
      ]);
    });

    test('Should resume a video recording', () async {
      // Arrange
      final MethodChannelMock channel = MethodChannelMock(
        channelName: _channelName,
        methods: <String, dynamic>{'resumeVideoRecording': null},
      );

      // Act
      await camera.resumeVideoRecording(cameraId);

      // Assert
      expect(channel.log, <Matcher>[
        isMethodCall('resumeVideoRecording', arguments: <String, Object?>{
          'cameraId': cameraId,
        }),
      ]);
    });

    test('Should set the flash mode', () async {
      // Arrange
      final MethodChannelMock channel = MethodChannelMock(
        channelName: _channelName,
        methods: <String, dynamic>{'setFlashMode': null},
      );

      // Act
      await camera.setFlashMode(cameraId, FlashMode.torch);
      await camera.setFlashMode(cameraId, FlashMode.always);
      await camera.setFlashMode(cameraId, FlashMode.auto);
      await camera.setFlashMode(cameraId, FlashMode.off);

      // Assert
      expect(channel.log, <Matcher>[
        isMethodCall('setFlashMode', arguments: <String, Object?>{
          'cameraId': cameraId,
          'mode': 'torch'
        }),
        isMethodCall('setFlashMode', arguments: <String, Object?>{
          'cameraId': cameraId,
          'mode': 'always'
        }),
        isMethodCall('setFlashMode',
            arguments: <String, Object?>{'cameraId': cameraId, 'mode': 'auto'}),
        isMethodCall('setFlashMode',
            arguments: <String, Object?>{'cameraId': cameraId, 'mode': 'off'}),
      ]);
    });

    test('Should set the exposure mode', () async {
      // Arrange
      final MethodChannelMock channel = MethodChannelMock(
        channelName: _channelName,
        methods: <String, dynamic>{'setExposureMode': null},
      );

      // Act
      await camera.setExposureMode(cameraId, ExposureMode.auto);
      await camera.setExposureMode(cameraId, ExposureMode.locked);

      // Assert
      expect(channel.log, <Matcher>[
        isMethodCall('setExposureMode',
            arguments: <String, Object?>{'cameraId': cameraId, 'mode': 'auto'}),
        isMethodCall('setExposureMode', arguments: <String, Object?>{
          'cameraId': cameraId,
          'mode': 'locked'
        }),
      ]);
    });

    test('Should set the exposure point', () async {
      // Arrange
      final MethodChannelMock channel = MethodChannelMock(
        channelName: _channelName,
        methods: <String, dynamic>{'setExposurePoint': null},
      );

      // Act
      await camera.setExposurePoint(cameraId, const Point<double>(0.5, 0.5));
      await camera.setExposurePoint(cameraId, null);

      // Assert
      expect(channel.log, <Matcher>[
        isMethodCall('setExposurePoint', arguments: <String, Object?>{
          'cameraId': cameraId,
          'x': 0.5,
          'y': 0.5,
          'reset': false
        }),
        isMethodCall('setExposurePoint', arguments: <String, Object?>{
          'cameraId': cameraId,
          'x': null,
          'y': null,
          'reset': true
        }),
      ]);
    });

    test('Should get the min exposure offset', () async {
      // Arrange
      final MethodChannelMock channel = MethodChannelMock(
        channelName: _channelName,
        methods: <String, dynamic>{'getMinExposureOffset': 2.0},
      );

      // Act
      final double minExposureOffset =
          await camera.getMinExposureOffset(cameraId);

      // Assert
      expect(minExposureOffset, 2.0);
      expect(channel.log, <Matcher>[
        isMethodCall('getMinExposureOffset', arguments: <String, Object?>{
          'cameraId': cameraId,
        }),
      ]);
    });

    test('Should get the max exposure offset', () async {
      // Arrange
      final MethodChannelMock channel = MethodChannelMock(
        channelName: _channelName,
        methods: <String, dynamic>{'getMaxExposureOffset': 2.0},
      );

      // Act
      final double maxExposureOffset =
          await camera.getMaxExposureOffset(cameraId);

      // Assert
      expect(maxExposureOffset, 2.0);
      expect(channel.log, <Matcher>[
        isMethodCall('getMaxExposureOffset', arguments: <String, Object?>{
          'cameraId': cameraId,
        }),
      ]);
    });

    test('Should get the exposure offset step size', () async {
      // Arrange
      final MethodChannelMock channel = MethodChannelMock(
        channelName: _channelName,
        methods: <String, dynamic>{'getExposureOffsetStepSize': 0.25},
      );

      // Act
      final double stepSize = await camera.getExposureOffsetStepSize(cameraId);

      // Assert
      expect(stepSize, 0.25);
      expect(channel.log, <Matcher>[
        isMethodCall('getExposureOffsetStepSize', arguments: <String, Object?>{
          'cameraId': cameraId,
        }),
      ]);
    });

    test('Should set the exposure offset', () async {
      // Arrange
      final MethodChannelMock channel = MethodChannelMock(
        channelName: _channelName,
        methods: <String, dynamic>{'setExposureOffset': 0.6},
      );

      // Act
      final double actualOffset = await camera.setExposureOffset(cameraId, 0.5);

      // Assert
      expect(actualOffset, 0.6);
      expect(channel.log, <Matcher>[
        isMethodCall('setExposureOffset', arguments: <String, Object?>{
          'cameraId': cameraId,
          'offset': 0.5,
        }),
      ]);
    });

    test('Should set the focus mode', () async {
      // Arrange
      final MethodChannelMock channel = MethodChannelMock(
        channelName: _channelName,
        methods: <String, dynamic>{'setFocusMode': null},
      );

      // Act
      await camera.setFocusMode(cameraId, FocusMode.auto);
      await camera.setFocusMode(cameraId, FocusMode.locked);

      // Assert
      expect(channel.log, <Matcher>[
        isMethodCall('setFocusMode',
            arguments: <String, Object?>{'cameraId': cameraId, 'mode': 'auto'}),
        isMethodCall('setFocusMode', arguments: <String, Object?>{
          'cameraId': cameraId,
          'mode': 'locked'
        }),
      ]);
    });

    test('Should set the exposure point', () async {
      // Arrange
      final MethodChannelMock channel = MethodChannelMock(
        channelName: _channelName,
        methods: <String, dynamic>{'setFocusPoint': null},
      );

      // Act
      await camera.setFocusPoint(cameraId, const Point<double>(0.5, 0.5));
      await camera.setFocusPoint(cameraId, null);

      // Assert
      expect(channel.log, <Matcher>[
        isMethodCall('setFocusPoint', arguments: <String, Object?>{
          'cameraId': cameraId,
          'x': 0.5,
          'y': 0.5,
          'reset': false
        }),
        isMethodCall('setFocusPoint', arguments: <String, Object?>{
          'cameraId': cameraId,
          'x': null,
          'y': null,
          'reset': true
        }),
      ]);
    });

    test('Should build a texture widget as preview widget', () async {
      // Act
      final Widget widget = camera.buildPreview(cameraId);

      // Act
      expect(widget is Texture, isTrue);
      expect((widget as Texture).textureId, cameraId);
    });

    test('Should throw MissingPluginException when handling unknown method',
        () {
      final AndroidCamera camera = AndroidCamera();

      expect(
          () => camera.handleCameraMethodCall(
              const MethodCall('unknown_method'), 1),
          throwsA(isA<MissingPluginException>()));
    });

    test('Should get the max zoom level', () async {
      // Arrange
      final MethodChannelMock channel = MethodChannelMock(
        channelName: _channelName,
        methods: <String, dynamic>{'getMaxZoomLevel': 10.0},
      );

      // Act
      final double maxZoomLevel = await camera.getMaxZoomLevel(cameraId);

      // Assert
      expect(maxZoomLevel, 10.0);
      expect(channel.log, <Matcher>[
        isMethodCall('getMaxZoomLevel', arguments: <String, Object?>{
          'cameraId': cameraId,
        }),
      ]);
    });

    test('Should get the min zoom level', () async {
      // Arrange
      final MethodChannelMock channel = MethodChannelMock(
        channelName: _channelName,
        methods: <String, dynamic>{'getMinZoomLevel': 1.0},
      );

      // Act
      final double maxZoomLevel = await camera.getMinZoomLevel(cameraId);

      // Assert
      expect(maxZoomLevel, 1.0);
      expect(channel.log, <Matcher>[
        isMethodCall('getMinZoomLevel', arguments: <String, Object?>{
          'cameraId': cameraId,
        }),
      ]);
    });

    test('Should set the zoom level', () async {
      // Arrange
      final MethodChannelMock channel = MethodChannelMock(
        channelName: _channelName,
        methods: <String, dynamic>{'setZoomLevel': null},
      );

      // Act
      await camera.setZoomLevel(cameraId, 2.0);

      // Assert
      expect(channel.log, <Matcher>[
        isMethodCall('setZoomLevel',
            arguments: <String, Object?>{'cameraId': cameraId, 'zoom': 2.0}),
      ]);
    });

    test('Should throw CameraException when illegal zoom level is supplied',
        () async {
      // Arrange
      MethodChannelMock(
        channelName: _channelName,
        methods: <String, dynamic>{
          'setZoomLevel': PlatformException(
            code: 'ZOOM_ERROR',
            message: 'Illegal zoom error',
            details: null,
          )
        },
      );

      // Act & assert
      expect(
          () => camera.setZoomLevel(cameraId, -1.0),
          throwsA(isA<CameraException>()
              .having((CameraException e) => e.code, 'code', 'ZOOM_ERROR')
              .having((CameraException e) => e.description, 'description',
                  'Illegal zoom error')));
    });

    test('Should lock the capture orientation', () async {
      // Arrange
      final MethodChannelMock channel = MethodChannelMock(
        channelName: _channelName,
        methods: <String, dynamic>{'lockCaptureOrientation': null},
      );

      // Act
      await camera.lockCaptureOrientation(
          cameraId, DeviceOrientation.portraitUp);

      // Assert
      expect(channel.log, <Matcher>[
        isMethodCall('lockCaptureOrientation', arguments: <String, Object?>{
          'cameraId': cameraId,
          'orientation': 'portraitUp'
        }),
      ]);
    });

    test('Should unlock the capture orientation', () async {
      // Arrange
      final MethodChannelMock channel = MethodChannelMock(
        channelName: _channelName,
        methods: <String, dynamic>{'unlockCaptureOrientation': null},
      );

      // Act
      await camera.unlockCaptureOrientation(cameraId);

      // Assert
      expect(channel.log, <Matcher>[
        isMethodCall('unlockCaptureOrientation',
            arguments: <String, Object?>{'cameraId': cameraId}),
      ]);
    });

    test('Should pause the camera preview', () async {
      // Arrange
      final MethodChannelMock channel = MethodChannelMock(
        channelName: _channelName,
        methods: <String, dynamic>{'pausePreview': null},
      );

      // Act
      await camera.pausePreview(cameraId);

      // Assert
      expect(channel.log, <Matcher>[
        isMethodCall('pausePreview',
            arguments: <String, Object?>{'cameraId': cameraId}),
      ]);
    });

    test('Should resume the camera preview', () async {
      // Arrange
      final MethodChannelMock channel = MethodChannelMock(
        channelName: _channelName,
        methods: <String, dynamic>{'resumePreview': null},
      );

      // Act
      await camera.resumePreview(cameraId);

      // Assert
      expect(channel.log, <Matcher>[
        isMethodCall('resumePreview',
            arguments: <String, Object?>{'cameraId': cameraId}),
      ]);
    });

    test('Should start streaming', () async {
      // Arrange
      final MethodChannelMock channel = MethodChannelMock(
        channelName: _channelName,
        methods: <String, dynamic>{
          'startImageStream': null,
          'stopImageStream': null,
        },
      );

      // Act
      final StreamSubscription<CameraImageData> subscription = camera
          .onStreamedFrameAvailable(cameraId)
          .listen((CameraImageData imageData) {});

      // Assert
      expect(channel.log, <Matcher>[
        isMethodCall('startImageStream', arguments: null),
      ]);

      subscription.cancel();
    });

    test('Should stop streaming', () async {
      // Arrange
      final MethodChannelMock channel = MethodChannelMock(
        channelName: _channelName,
        methods: <String, dynamic>{
          'startImageStream': null,
          'stopImageStream': null,
        },
      );

      // Act
      final StreamSubscription<CameraImageData> subscription = camera
          .onStreamedFrameAvailable(cameraId)
          .listen((CameraImageData imageData) {});
      subscription.cancel();

      // Assert
      expect(channel.log, <Matcher>[
        isMethodCall('startImageStream', arguments: null),
        isMethodCall('stopImageStream', arguments: null),
      ]);
    });
  });
}
