// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'dart:ui';

import 'package:async/async.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:camera_web/camera_web.dart';
import 'package:camera_web/src/camera.dart';
import 'package:camera_web/src/camera_service.dart';
import 'package:camera_web/src/types/types.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers/helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('CameraPlugin', () {
    const int cameraId = 0;

    late Window window;
    late Navigator navigator;
    late MediaDevices mediaDevices;
    late VideoElement videoElement;
    late Screen screen;
    late ScreenOrientation screenOrientation;
    late Document document;
    late Element documentElement;

    late CameraService cameraService;

    setUp(() async {
      window = MockWindow();
      navigator = MockNavigator();
      mediaDevices = MockMediaDevices();

      videoElement = getVideoElementWithBlankStream(const Size(10, 10));

      when(() => window.navigator).thenReturn(navigator);
      when(() => navigator.mediaDevices).thenReturn(mediaDevices);

      screen = MockScreen();
      screenOrientation = MockScreenOrientation();

      when(() => screen.orientation).thenReturn(screenOrientation);
      when(() => window.screen).thenReturn(screen);

      document = MockDocument();
      documentElement = MockElement();

      when(() => document.documentElement).thenReturn(documentElement);
      when(() => window.document).thenReturn(document);

      cameraService = MockCameraService();

      when(
        () => cameraService.getMediaStreamForOptions(
          any(),
          cameraId: any(named: 'cameraId'),
        ),
      ).thenAnswer(
        (_) async => videoElement.captureStream(),
      );

      CameraPlatform.instance = CameraPlugin(
        cameraService: cameraService,
      )..window = window;
    });

    setUpAll(() {
      registerFallbackValue(MockMediaStreamTrack());
      registerFallbackValue(MockCameraOptions());
      registerFallbackValue(FlashMode.off);
    });

    testWidgets('CameraPlugin is the live instance',
        (WidgetTester tester) async {
      expect(CameraPlatform.instance, isA<CameraPlugin>());
    });

    group('availableCameras', () {
      setUp(() {
        when(
          () => cameraService.getFacingModeForVideoTrack(
            any(),
          ),
        ).thenReturn(null);

        when(mediaDevices.enumerateDevices).thenAnswer(
          (_) async => <dynamic>[],
        );
      });

      testWidgets('requests video and audio permissions',
          (WidgetTester tester) async {
        final List<CameraDescription> _ =
            await CameraPlatform.instance.availableCameras();

        verify(
          () => cameraService.getMediaStreamForOptions(
            const CameraOptions(
              audio: AudioConstraints(enabled: true),
            ),
          ),
        ).called(1);
      });

      testWidgets(
          'releases the camera stream '
          'used to request video and audio permissions',
          (WidgetTester tester) async {
        final MockMediaStreamTrack videoTrack = MockMediaStreamTrack();

        bool videoTrackStopped = false;
        when(videoTrack.stop).thenAnswer((Invocation _) {
          videoTrackStopped = true;
        });

        when(
          () => cameraService.getMediaStreamForOptions(
            const CameraOptions(
              audio: AudioConstraints(enabled: true),
            ),
          ),
        ).thenAnswer(
          (_) => Future<MediaStream>.value(
            FakeMediaStream(<MediaStreamTrack>[videoTrack]),
          ),
        );

        final List<CameraDescription> _ =
            await CameraPlatform.instance.availableCameras();

        expect(videoTrackStopped, isTrue);
      });

      testWidgets(
          'gets a video stream '
          'for a video input device', (WidgetTester tester) async {
        final FakeMediaDeviceInfo videoDevice = FakeMediaDeviceInfo(
          '1',
          'Camera 1',
          MediaDeviceKind.videoInput,
        );

        when(mediaDevices.enumerateDevices).thenAnswer(
          (_) => Future<List<dynamic>>.value(<Object>[videoDevice]),
        );

        final List<CameraDescription> _ =
            await CameraPlatform.instance.availableCameras();

        verify(
          () => cameraService.getMediaStreamForOptions(
            CameraOptions(
              video: VideoConstraints(
                deviceId: videoDevice.deviceId,
              ),
            ),
          ),
        ).called(1);
      });

      testWidgets(
          'does not get a video stream '
          'for the video input device '
          'with an empty device id', (WidgetTester tester) async {
        final FakeMediaDeviceInfo videoDevice = FakeMediaDeviceInfo(
          '',
          'Camera 1',
          MediaDeviceKind.videoInput,
        );

        when(mediaDevices.enumerateDevices).thenAnswer(
          (_) => Future<List<dynamic>>.value(<Object>[videoDevice]),
        );

        final List<CameraDescription> _ =
            await CameraPlatform.instance.availableCameras();

        verifyNever(
          () => cameraService.getMediaStreamForOptions(
            CameraOptions(
              video: VideoConstraints(
                deviceId: videoDevice.deviceId,
              ),
            ),
          ),
        );
      });

      testWidgets(
          'gets the facing mode '
          'from the first available video track '
          'of the video input device', (WidgetTester tester) async {
        final FakeMediaDeviceInfo videoDevice = FakeMediaDeviceInfo(
          '1',
          'Camera 1',
          MediaDeviceKind.videoInput,
        );

        final FakeMediaStream videoStream = FakeMediaStream(
            <MediaStreamTrack>[MockMediaStreamTrack(), MockMediaStreamTrack()]);

        when(
          () => cameraService.getMediaStreamForOptions(
            CameraOptions(
              video: VideoConstraints(deviceId: videoDevice.deviceId),
            ),
          ),
        ).thenAnswer((Invocation _) => Future<MediaStream>.value(videoStream));

        when(mediaDevices.enumerateDevices).thenAnswer(
          (_) => Future<List<dynamic>>.value(<Object>[videoDevice]),
        );

        final List<CameraDescription> _ =
            await CameraPlatform.instance.availableCameras();

        verify(
          () => cameraService.getFacingModeForVideoTrack(
            videoStream.getVideoTracks().first,
          ),
        ).called(1);
      });

      testWidgets(
          'returns appropriate camera descriptions '
          'for multiple video devices '
          'based on video streams', (WidgetTester tester) async {
        final FakeMediaDeviceInfo firstVideoDevice = FakeMediaDeviceInfo(
          '1',
          'Camera 1',
          MediaDeviceKind.videoInput,
        );

        final FakeMediaDeviceInfo secondVideoDevice = FakeMediaDeviceInfo(
          '4',
          'Camera 4',
          MediaDeviceKind.videoInput,
        );

        // Create a video stream for the first video device.
        final FakeMediaStream firstVideoStream = FakeMediaStream(
            <MediaStreamTrack>[MockMediaStreamTrack(), MockMediaStreamTrack()]);

        // Create a video stream for the second video device.
        final FakeMediaStream secondVideoStream =
            FakeMediaStream(<MediaStreamTrack>[MockMediaStreamTrack()]);

        // Mock media devices to return two video input devices
        // and two audio devices.
        when(mediaDevices.enumerateDevices).thenAnswer(
          (_) => Future<List<dynamic>>.value(<Object>[
            firstVideoDevice,
            FakeMediaDeviceInfo(
              '2',
              'Audio Input 2',
              MediaDeviceKind.audioInput,
            ),
            FakeMediaDeviceInfo(
              '3',
              'Audio Output 3',
              MediaDeviceKind.audioOutput,
            ),
            secondVideoDevice,
          ]),
        );

        // Mock camera service to return the first video stream
        // for the first video device.
        when(
          () => cameraService.getMediaStreamForOptions(
            CameraOptions(
              video: VideoConstraints(deviceId: firstVideoDevice.deviceId),
            ),
          ),
        ).thenAnswer(
            (Invocation _) => Future<MediaStream>.value(firstVideoStream));

        // Mock camera service to return the second video stream
        // for the second video device.
        when(
          () => cameraService.getMediaStreamForOptions(
            CameraOptions(
              video: VideoConstraints(deviceId: secondVideoDevice.deviceId),
            ),
          ),
        ).thenAnswer(
            (Invocation _) => Future<MediaStream>.value(secondVideoStream));

        // Mock camera service to return a user facing mode
        // for the first video stream.
        when(
          () => cameraService.getFacingModeForVideoTrack(
            firstVideoStream.getVideoTracks().first,
          ),
        ).thenReturn('user');

        when(() => cameraService.mapFacingModeToLensDirection('user'))
            .thenReturn(CameraLensDirection.front);

        // Mock camera service to return an environment facing mode
        // for the second video stream.
        when(
          () => cameraService.getFacingModeForVideoTrack(
            secondVideoStream.getVideoTracks().first,
          ),
        ).thenReturn('environment');

        when(() => cameraService.mapFacingModeToLensDirection('environment'))
            .thenReturn(CameraLensDirection.back);

        final List<CameraDescription> cameras =
            await CameraPlatform.instance.availableCameras();

        // Expect two cameras and ignore two audio devices.
        expect(
          cameras,
          equals(<CameraDescription>[
            CameraDescription(
              name: firstVideoDevice.label!,
              lensDirection: CameraLensDirection.front,
              sensorOrientation: 0,
            ),
            CameraDescription(
              name: secondVideoDevice.label!,
              lensDirection: CameraLensDirection.back,
              sensorOrientation: 0,
            )
          ]),
        );
      });

      testWidgets(
          'sets camera metadata '
          'for the camera description', (WidgetTester tester) async {
        final FakeMediaDeviceInfo videoDevice = FakeMediaDeviceInfo(
          '1',
          'Camera 1',
          MediaDeviceKind.videoInput,
        );

        final FakeMediaStream videoStream = FakeMediaStream(
            <MediaStreamTrack>[MockMediaStreamTrack(), MockMediaStreamTrack()]);

        when(mediaDevices.enumerateDevices).thenAnswer(
          (_) => Future<List<dynamic>>.value(<Object>[videoDevice]),
        );

        when(
          () => cameraService.getMediaStreamForOptions(
            CameraOptions(
              video: VideoConstraints(deviceId: videoDevice.deviceId),
            ),
          ),
        ).thenAnswer((Invocation _) => Future<MediaStream>.value(videoStream));

        when(
          () => cameraService.getFacingModeForVideoTrack(
            videoStream.getVideoTracks().first,
          ),
        ).thenReturn('left');

        when(() => cameraService.mapFacingModeToLensDirection('left'))
            .thenReturn(CameraLensDirection.external);

        final CameraDescription camera =
            (await CameraPlatform.instance.availableCameras()).first;

        expect(
          (CameraPlatform.instance as CameraPlugin).camerasMetadata,
          equals(<CameraDescription, CameraMetadata>{
            camera: CameraMetadata(
              deviceId: videoDevice.deviceId!,
              facingMode: 'left',
            )
          }),
        );
      });

      testWidgets(
          'releases the video stream '
          'of a video input device', (WidgetTester tester) async {
        final FakeMediaDeviceInfo videoDevice = FakeMediaDeviceInfo(
          '1',
          'Camera 1',
          MediaDeviceKind.videoInput,
        );

        final FakeMediaStream videoStream = FakeMediaStream(
            <MediaStreamTrack>[MockMediaStreamTrack(), MockMediaStreamTrack()]);

        when(mediaDevices.enumerateDevices).thenAnswer(
          (_) => Future<List<dynamic>>.value(<Object>[videoDevice]),
        );

        when(
          () => cameraService.getMediaStreamForOptions(
            CameraOptions(
              video: VideoConstraints(deviceId: videoDevice.deviceId),
            ),
          ),
        ).thenAnswer((Invocation _) => Future<MediaStream>.value(videoStream));

        final List<CameraDescription> _ =
            await CameraPlatform.instance.availableCameras();

        for (final MediaStreamTrack videoTrack
            in videoStream.getVideoTracks()) {
          verify(videoTrack.stop).called(1);
        }
      });

      group('throws CameraException', () {
        testWidgets(
            'with notSupported error '
            'when there are no media devices', (WidgetTester tester) async {
          when(() => navigator.mediaDevices).thenReturn(null);

          expect(
            () => CameraPlatform.instance.availableCameras(),
            throwsA(
              isA<CameraException>().having(
                (CameraException e) => e.code,
                'code',
                CameraErrorCode.notSupported.toString(),
              ),
            ),
          );
        });

        testWidgets('when MediaDevices.enumerateDevices throws DomException',
            (WidgetTester tester) async {
          final FakeDomException exception =
              FakeDomException(DomException.UNKNOWN);

          when(mediaDevices.enumerateDevices).thenThrow(exception);

          expect(
            () => CameraPlatform.instance.availableCameras(),
            throwsA(
              isA<CameraException>().having(
                (CameraException e) => e.code,
                'code',
                exception.name,
              ),
            ),
          );
        });

        testWidgets(
            'when CameraService.getMediaStreamForOptions '
            'throws CameraWebException', (WidgetTester tester) async {
          final CameraWebException exception = CameraWebException(
            cameraId,
            CameraErrorCode.security,
            'description',
          );

          when(() => cameraService.getMediaStreamForOptions(any()))
              .thenThrow(exception);

          expect(
            () => CameraPlatform.instance.availableCameras(),
            throwsA(
              isA<CameraException>().having(
                (CameraException e) => e.code,
                'code',
                exception.code.toString(),
              ),
            ),
          );
        });

        testWidgets(
            'when CameraService.getMediaStreamForOptions '
            'throws PlatformException', (WidgetTester tester) async {
          final PlatformException exception = PlatformException(
            code: CameraErrorCode.notSupported.toString(),
            message: 'message',
          );

          when(() => cameraService.getMediaStreamForOptions(any()))
              .thenThrow(exception);

          expect(
            () => CameraPlatform.instance.availableCameras(),
            throwsA(
              isA<CameraException>().having(
                (CameraException e) => e.code,
                'code',
                exception.code,
              ),
            ),
          );
        });
      });
    });

    group('createCamera', () {
      group('creates a camera', () {
        const Size ultraHighResolutionSize = Size(3840, 2160);
        const Size maxResolutionSize = Size(3840, 2160);

        const CameraDescription cameraDescription = CameraDescription(
          name: 'name',
          lensDirection: CameraLensDirection.front,
          sensorOrientation: 0,
        );

        const CameraMetadata cameraMetadata = CameraMetadata(
          deviceId: 'deviceId',
          facingMode: 'user',
        );

        setUp(() {
          // Add metadata for the camera description.
          (CameraPlatform.instance as CameraPlugin)
              .camerasMetadata[cameraDescription] = cameraMetadata;

          when(
            () => cameraService.mapFacingModeToCameraType('user'),
          ).thenReturn(CameraType.user);
        });

        testWidgets('with appropriate options', (WidgetTester tester) async {
          when(
            () => cameraService
                .mapResolutionPresetToSize(ResolutionPreset.ultraHigh),
          ).thenReturn(ultraHighResolutionSize);

          final int cameraId = await CameraPlatform.instance.createCamera(
            cameraDescription,
            ResolutionPreset.ultraHigh,
            enableAudio: true,
          );

          expect(
            (CameraPlatform.instance as CameraPlugin).cameras[cameraId],
            isA<Camera>()
                .having(
                  (Camera camera) => camera.textureId,
                  'textureId',
                  cameraId,
                )
                .having(
                  (Camera camera) => camera.options,
                  'options',
                  CameraOptions(
                    audio: const AudioConstraints(enabled: true),
                    video: VideoConstraints(
                      facingMode: FacingModeConstraint(CameraType.user),
                      width: VideoSizeConstraint(
                        ideal: ultraHighResolutionSize.width.toInt(),
                      ),
                      height: VideoSizeConstraint(
                        ideal: ultraHighResolutionSize.height.toInt(),
                      ),
                      deviceId: cameraMetadata.deviceId,
                    ),
                  ),
                ),
          );
        });

        testWidgets(
            'with a max resolution preset '
            'and enabled audio set to false '
            'when no options are specified', (WidgetTester tester) async {
          when(
            () => cameraService.mapResolutionPresetToSize(ResolutionPreset.max),
          ).thenReturn(maxResolutionSize);

          final int cameraId = await CameraPlatform.instance.createCamera(
            cameraDescription,
            null,
          );

          expect(
            (CameraPlatform.instance as CameraPlugin).cameras[cameraId],
            isA<Camera>().having(
              (Camera camera) => camera.options,
              'options',
              CameraOptions(
                audio: const AudioConstraints(enabled: false),
                video: VideoConstraints(
                  facingMode: FacingModeConstraint(CameraType.user),
                  width: VideoSizeConstraint(
                    ideal: maxResolutionSize.width.toInt(),
                  ),
                  height: VideoSizeConstraint(
                    ideal: maxResolutionSize.height.toInt(),
                  ),
                  deviceId: cameraMetadata.deviceId,
                ),
              ),
            ),
          );
        });
      });

      testWidgets(
          'throws CameraException '
          'with missingMetadata error '
          'if there is no metadata '
          'for the given camera description', (WidgetTester tester) async {
        expect(
          () => CameraPlatform.instance.createCamera(
            const CameraDescription(
              name: 'name',
              lensDirection: CameraLensDirection.back,
              sensorOrientation: 0,
            ),
            ResolutionPreset.ultraHigh,
          ),
          throwsA(
            isA<CameraException>().having(
              (CameraException e) => e.code,
              'code',
              CameraErrorCode.missingMetadata.toString(),
            ),
          ),
        );
      });
    });

    group('initializeCamera', () {
      late Camera camera;
      late VideoElement videoElement;

      late StreamController<Event> errorStreamController, abortStreamController;
      late StreamController<MediaStreamTrack> endedStreamController;

      setUp(() {
        camera = MockCamera();
        videoElement = MockVideoElement();

        errorStreamController = StreamController<Event>();
        abortStreamController = StreamController<Event>();
        endedStreamController = StreamController<MediaStreamTrack>();

        when(camera.getVideoSize).thenReturn(const Size(10, 10));
        when(camera.initialize)
            .thenAnswer((Invocation _) => Future<void>.value());
        when(camera.play).thenAnswer((Invocation _) => Future<void>.value());

        when(() => camera.videoElement).thenReturn(videoElement);
        when(() => videoElement.onError).thenAnswer((Invocation _) =>
            FakeElementStream<Event>(errorStreamController.stream));
        when(() => videoElement.onAbort).thenAnswer((Invocation _) =>
            FakeElementStream<Event>(abortStreamController.stream));

        when(() => camera.onEnded)
            .thenAnswer((Invocation _) => endedStreamController.stream);
      });

      testWidgets('initializes and plays the camera',
          (WidgetTester tester) async {
        // Save the camera in the camera plugin.
        (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

        await CameraPlatform.instance.initializeCamera(cameraId);

        verify(camera.initialize).called(1);
        verify(camera.play).called(1);
      });

      testWidgets('starts listening to the camera video error and abort events',
          (WidgetTester tester) async {
        // Save the camera in the camera plugin.
        (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

        expect(errorStreamController.hasListener, isFalse);
        expect(abortStreamController.hasListener, isFalse);

        await CameraPlatform.instance.initializeCamera(cameraId);

        expect(errorStreamController.hasListener, isTrue);
        expect(abortStreamController.hasListener, isTrue);
      });

      testWidgets('starts listening to the camera ended events',
          (WidgetTester tester) async {
        // Save the camera in the camera plugin.
        (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

        expect(endedStreamController.hasListener, isFalse);

        await CameraPlatform.instance.initializeCamera(cameraId);

        expect(endedStreamController.hasListener, isTrue);
      });

      group('throws PlatformException', () {
        testWidgets(
            'with notFound error '
            'if the camera does not exist', (WidgetTester tester) async {
          expect(
            () => CameraPlatform.instance.initializeCamera(cameraId),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                CameraErrorCode.notFound.toString(),
              ),
            ),
          );
        });

        testWidgets('when camera throws CameraWebException',
            (WidgetTester tester) async {
          final CameraWebException exception = CameraWebException(
            cameraId,
            CameraErrorCode.permissionDenied,
            'description',
          );

          when(camera.initialize).thenThrow(exception);

          // Save the camera in the camera plugin.
          (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

          expect(
            () => CameraPlatform.instance.initializeCamera(cameraId),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                exception.code.toString(),
              ),
            ),
          );
        });

        testWidgets('when camera throws DomException',
            (WidgetTester tester) async {
          final FakeDomException exception =
              FakeDomException(DomException.NOT_ALLOWED);

          when(camera.initialize)
              .thenAnswer((Invocation _) => Future<void>.value());
          when(camera.play).thenThrow(exception);

          // Save the camera in the camera plugin.
          (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

          expect(
            () => CameraPlatform.instance.initializeCamera(cameraId),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                exception.name,
              ),
            ),
          );
        });
      });
    });

    group('lockCaptureOrientation', () {
      setUp(() {
        when(
          () => cameraService.mapDeviceOrientationToOrientationType(any()),
        ).thenReturn(OrientationType.portraitPrimary);
      });

      testWidgets(
          'requests full-screen mode '
          'on documentElement', (WidgetTester tester) async {
        await CameraPlatform.instance.lockCaptureOrientation(
          cameraId,
          DeviceOrientation.portraitUp,
        );

        verify(documentElement.requestFullscreen).called(1);
      });

      testWidgets(
          'locks the capture orientation '
          'based on the given device orientation', (WidgetTester tester) async {
        when(
          () => cameraService.mapDeviceOrientationToOrientationType(
            DeviceOrientation.landscapeRight,
          ),
        ).thenReturn(OrientationType.landscapeSecondary);

        await CameraPlatform.instance.lockCaptureOrientation(
          cameraId,
          DeviceOrientation.landscapeRight,
        );

        verify(
          () => cameraService.mapDeviceOrientationToOrientationType(
            DeviceOrientation.landscapeRight,
          ),
        ).called(1);

        verify(
          () => screenOrientation.lock(
            OrientationType.landscapeSecondary,
          ),
        ).called(1);
      });

      group('throws PlatformException', () {
        testWidgets(
            'with orientationNotSupported error '
            'when screen is not supported', (WidgetTester tester) async {
          when(() => window.screen).thenReturn(null);

          expect(
            () => CameraPlatform.instance.lockCaptureOrientation(
              cameraId,
              DeviceOrientation.portraitUp,
            ),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                CameraErrorCode.orientationNotSupported.toString(),
              ),
            ),
          );
        });

        testWidgets(
            'with orientationNotSupported error '
            'when screen orientation is not supported',
            (WidgetTester tester) async {
          when(() => screen.orientation).thenReturn(null);

          expect(
            () => CameraPlatform.instance.lockCaptureOrientation(
              cameraId,
              DeviceOrientation.portraitUp,
            ),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                CameraErrorCode.orientationNotSupported.toString(),
              ),
            ),
          );
        });

        testWidgets(
            'with orientationNotSupported error '
            'when documentElement is not available',
            (WidgetTester tester) async {
          when(() => document.documentElement).thenReturn(null);

          expect(
            () => CameraPlatform.instance.lockCaptureOrientation(
              cameraId,
              DeviceOrientation.portraitUp,
            ),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                CameraErrorCode.orientationNotSupported.toString(),
              ),
            ),
          );
        });

        testWidgets('when lock throws DomException',
            (WidgetTester tester) async {
          final FakeDomException exception =
              FakeDomException(DomException.NOT_ALLOWED);

          when(() => screenOrientation.lock(any())).thenThrow(exception);

          expect(
            () => CameraPlatform.instance.lockCaptureOrientation(
              cameraId,
              DeviceOrientation.portraitDown,
            ),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                exception.name,
              ),
            ),
          );
        });
      });
    });

    group('unlockCaptureOrientation', () {
      setUp(() {
        when(
          () => cameraService.mapDeviceOrientationToOrientationType(any()),
        ).thenReturn(OrientationType.portraitPrimary);
      });

      testWidgets('unlocks the capture orientation',
          (WidgetTester tester) async {
        await CameraPlatform.instance.unlockCaptureOrientation(
          cameraId,
        );

        verify(screenOrientation.unlock).called(1);
      });

      group('throws PlatformException', () {
        testWidgets(
            'with orientationNotSupported error '
            'when screen is not supported', (WidgetTester tester) async {
          when(() => window.screen).thenReturn(null);

          expect(
            () => CameraPlatform.instance.unlockCaptureOrientation(
              cameraId,
            ),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                CameraErrorCode.orientationNotSupported.toString(),
              ),
            ),
          );
        });

        testWidgets(
            'with orientationNotSupported error '
            'when screen orientation is not supported',
            (WidgetTester tester) async {
          when(() => screen.orientation).thenReturn(null);

          expect(
            () => CameraPlatform.instance.unlockCaptureOrientation(
              cameraId,
            ),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                CameraErrorCode.orientationNotSupported.toString(),
              ),
            ),
          );
        });

        testWidgets(
            'with orientationNotSupported error '
            'when documentElement is not available',
            (WidgetTester tester) async {
          when(() => document.documentElement).thenReturn(null);

          expect(
            () => CameraPlatform.instance.unlockCaptureOrientation(
              cameraId,
            ),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                CameraErrorCode.orientationNotSupported.toString(),
              ),
            ),
          );
        });

        testWidgets('when unlock throws DomException',
            (WidgetTester tester) async {
          final FakeDomException exception =
              FakeDomException(DomException.NOT_ALLOWED);

          when(screenOrientation.unlock).thenThrow(exception);

          expect(
            () => CameraPlatform.instance.unlockCaptureOrientation(
              cameraId,
            ),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                exception.name,
              ),
            ),
          );
        });
      });
    });

    group('takePicture', () {
      testWidgets('captures a picture', (WidgetTester tester) async {
        final MockCamera camera = MockCamera();
        final MockXFile capturedPicture = MockXFile();

        when(camera.takePicture)
            .thenAnswer((Invocation _) => Future<XFile>.value(capturedPicture));

        // Save the camera in the camera plugin.
        (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

        final XFile picture =
            await CameraPlatform.instance.takePicture(cameraId);

        verify(camera.takePicture).called(1);

        expect(picture, equals(capturedPicture));
      });

      group('throws PlatformException', () {
        testWidgets(
            'with notFound error '
            'if the camera does not exist', (WidgetTester tester) async {
          expect(
            () => CameraPlatform.instance.takePicture(cameraId),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                CameraErrorCode.notFound.toString(),
              ),
            ),
          );
        });

        testWidgets('when takePicture throws DomException',
            (WidgetTester tester) async {
          final MockCamera camera = MockCamera();
          final FakeDomException exception =
              FakeDomException(DomException.NOT_SUPPORTED);

          when(camera.takePicture).thenThrow(exception);

          // Save the camera in the camera plugin.
          (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

          expect(
            () => CameraPlatform.instance.takePicture(cameraId),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                exception.name,
              ),
            ),
          );
        });

        testWidgets('when takePicture throws CameraWebException',
            (WidgetTester tester) async {
          final MockCamera camera = MockCamera();
          final CameraWebException exception = CameraWebException(
            cameraId,
            CameraErrorCode.notStarted,
            'description',
          );

          when(camera.takePicture).thenThrow(exception);

          // Save the camera in the camera plugin.
          (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

          expect(
            () => CameraPlatform.instance.takePicture(cameraId),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                exception.code.toString(),
              ),
            ),
          );
        });
      });
    });

    group('startVideoRecording', () {
      late Camera camera;

      setUp(() {
        camera = MockCamera();

        when(camera.startVideoRecording).thenAnswer((Invocation _) async {});

        when(() => camera.onVideoRecordingError)
            .thenAnswer((Invocation _) => const Stream<ErrorEvent>.empty());
      });

      testWidgets('starts a video recording', (WidgetTester tester) async {
        // Save the camera in the camera plugin.
        (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

        await CameraPlatform.instance.startVideoRecording(cameraId);

        verify(camera.startVideoRecording).called(1);
      });

      testWidgets('listens to the onVideoRecordingError stream',
          (WidgetTester tester) async {
        final StreamController<ErrorEvent> videoRecordingErrorController =
            StreamController<ErrorEvent>();

        when(() => camera.onVideoRecordingError)
            .thenAnswer((Invocation _) => videoRecordingErrorController.stream);

        // Save the camera in the camera plugin.
        (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

        await CameraPlatform.instance.startVideoRecording(cameraId);

        expect(
          videoRecordingErrorController.hasListener,
          isTrue,
        );
      });

      group('throws PlatformException', () {
        testWidgets(
            'with notFound error '
            'if the camera does not exist', (WidgetTester tester) async {
          expect(
            () => CameraPlatform.instance.startVideoRecording(cameraId),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                CameraErrorCode.notFound.toString(),
              ),
            ),
          );
        });

        testWidgets('when startVideoRecording throws DomException',
            (WidgetTester tester) async {
          final FakeDomException exception =
              FakeDomException(DomException.INVALID_STATE);

          when(camera.startVideoRecording).thenThrow(exception);

          // Save the camera in the camera plugin.
          (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

          expect(
            () => CameraPlatform.instance.startVideoRecording(cameraId),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                exception.name,
              ),
            ),
          );
        });

        testWidgets('when startVideoRecording throws CameraWebException',
            (WidgetTester tester) async {
          final CameraWebException exception = CameraWebException(
            cameraId,
            CameraErrorCode.notStarted,
            'description',
          );

          when(camera.startVideoRecording).thenThrow(exception);

          // Save the camera in the camera plugin.
          (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

          expect(
            () => CameraPlatform.instance.startVideoRecording(cameraId),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                exception.code.toString(),
              ),
            ),
          );
        });
      });
    });

    group('stopVideoRecording', () {
      testWidgets('stops a video recording', (WidgetTester tester) async {
        final MockCamera camera = MockCamera();
        final MockXFile capturedVideo = MockXFile();

        when(camera.stopVideoRecording)
            .thenAnswer((Invocation _) => Future<XFile>.value(capturedVideo));

        // Save the camera in the camera plugin.
        (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

        final XFile video =
            await CameraPlatform.instance.stopVideoRecording(cameraId);

        verify(camera.stopVideoRecording).called(1);

        expect(video, capturedVideo);
      });

      testWidgets('stops listening to the onVideoRecordingError stream',
          (WidgetTester tester) async {
        final MockCamera camera = MockCamera();
        final StreamController<ErrorEvent> videoRecordingErrorController =
            StreamController<ErrorEvent>();

        when(camera.startVideoRecording).thenAnswer((Invocation _) async {});

        when(camera.stopVideoRecording)
            .thenAnswer((Invocation _) => Future<XFile>.value(MockXFile()));

        when(() => camera.onVideoRecordingError)
            .thenAnswer((Invocation _) => videoRecordingErrorController.stream);

        // Save the camera in the camera plugin.
        (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

        await CameraPlatform.instance.startVideoRecording(cameraId);
        final XFile _ =
            await CameraPlatform.instance.stopVideoRecording(cameraId);

        expect(
          videoRecordingErrorController.hasListener,
          isFalse,
        );
      });

      group('throws PlatformException', () {
        testWidgets(
            'with notFound error '
            'if the camera does not exist', (WidgetTester tester) async {
          expect(
            () => CameraPlatform.instance.stopVideoRecording(cameraId),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                CameraErrorCode.notFound.toString(),
              ),
            ),
          );
        });

        testWidgets('when stopVideoRecording throws DomException',
            (WidgetTester tester) async {
          final MockCamera camera = MockCamera();
          final FakeDomException exception =
              FakeDomException(DomException.INVALID_STATE);

          when(camera.stopVideoRecording).thenThrow(exception);

          // Save the camera in the camera plugin.
          (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

          expect(
            () => CameraPlatform.instance.stopVideoRecording(cameraId),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                exception.name,
              ),
            ),
          );
        });

        testWidgets('when stopVideoRecording throws CameraWebException',
            (WidgetTester tester) async {
          final MockCamera camera = MockCamera();
          final CameraWebException exception = CameraWebException(
            cameraId,
            CameraErrorCode.notStarted,
            'description',
          );

          when(camera.stopVideoRecording).thenThrow(exception);

          // Save the camera in the camera plugin.
          (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

          expect(
            () => CameraPlatform.instance.stopVideoRecording(cameraId),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                exception.code.toString(),
              ),
            ),
          );
        });
      });
    });

    group('pauseVideoRecording', () {
      testWidgets('pauses a video recording', (WidgetTester tester) async {
        final MockCamera camera = MockCamera();

        when(camera.pauseVideoRecording).thenAnswer((Invocation _) async {});

        // Save the camera in the camera plugin.
        (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

        await CameraPlatform.instance.pauseVideoRecording(cameraId);

        verify(camera.pauseVideoRecording).called(1);
      });

      group('throws PlatformException', () {
        testWidgets(
            'with notFound error '
            'if the camera does not exist', (WidgetTester tester) async {
          expect(
            () => CameraPlatform.instance.pauseVideoRecording(cameraId),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                CameraErrorCode.notFound.toString(),
              ),
            ),
          );
        });

        testWidgets('when pauseVideoRecording throws DomException',
            (WidgetTester tester) async {
          final MockCamera camera = MockCamera();
          final FakeDomException exception =
              FakeDomException(DomException.INVALID_STATE);

          when(camera.pauseVideoRecording).thenThrow(exception);

          // Save the camera in the camera plugin.
          (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

          expect(
            () => CameraPlatform.instance.pauseVideoRecording(cameraId),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                exception.name,
              ),
            ),
          );
        });

        testWidgets('when pauseVideoRecording throws CameraWebException',
            (WidgetTester tester) async {
          final MockCamera camera = MockCamera();
          final CameraWebException exception = CameraWebException(
            cameraId,
            CameraErrorCode.notStarted,
            'description',
          );

          when(camera.pauseVideoRecording).thenThrow(exception);

          // Save the camera in the camera plugin.
          (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

          expect(
            () => CameraPlatform.instance.pauseVideoRecording(cameraId),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                exception.code.toString(),
              ),
            ),
          );
        });
      });
    });

    group('resumeVideoRecording', () {
      testWidgets('resumes a video recording', (WidgetTester tester) async {
        final MockCamera camera = MockCamera();

        when(camera.resumeVideoRecording).thenAnswer((Invocation _) async {});

        // Save the camera in the camera plugin.
        (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

        await CameraPlatform.instance.resumeVideoRecording(cameraId);

        verify(camera.resumeVideoRecording).called(1);
      });

      group('throws PlatformException', () {
        testWidgets(
            'with notFound error '
            'if the camera does not exist', (WidgetTester tester) async {
          expect(
            () => CameraPlatform.instance.resumeVideoRecording(cameraId),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                CameraErrorCode.notFound.toString(),
              ),
            ),
          );
        });

        testWidgets('when resumeVideoRecording throws DomException',
            (WidgetTester tester) async {
          final MockCamera camera = MockCamera();
          final FakeDomException exception =
              FakeDomException(DomException.INVALID_STATE);

          when(camera.resumeVideoRecording).thenThrow(exception);

          // Save the camera in the camera plugin.
          (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

          expect(
            () => CameraPlatform.instance.resumeVideoRecording(cameraId),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                exception.name,
              ),
            ),
          );
        });

        testWidgets('when resumeVideoRecording throws CameraWebException',
            (WidgetTester tester) async {
          final MockCamera camera = MockCamera();
          final CameraWebException exception = CameraWebException(
            cameraId,
            CameraErrorCode.notStarted,
            'description',
          );

          when(camera.resumeVideoRecording).thenThrow(exception);

          // Save the camera in the camera plugin.
          (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

          expect(
            () => CameraPlatform.instance.resumeVideoRecording(cameraId),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                exception.code.toString(),
              ),
            ),
          );
        });
      });
    });

    group('setFlashMode', () {
      testWidgets('calls setFlashMode on the camera',
          (WidgetTester tester) async {
        final MockCamera camera = MockCamera();
        const FlashMode flashMode = FlashMode.always;

        // Save the camera in the camera plugin.
        (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

        await CameraPlatform.instance.setFlashMode(
          cameraId,
          flashMode,
        );

        verify(() => camera.setFlashMode(flashMode)).called(1);
      });

      group('throws PlatformException', () {
        testWidgets(
            'with notFound error '
            'if the camera does not exist', (WidgetTester tester) async {
          expect(
            () => CameraPlatform.instance.setFlashMode(
              cameraId,
              FlashMode.always,
            ),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                CameraErrorCode.notFound.toString(),
              ),
            ),
          );
        });

        testWidgets('when setFlashMode throws DomException',
            (WidgetTester tester) async {
          final MockCamera camera = MockCamera();
          final FakeDomException exception =
              FakeDomException(DomException.NOT_SUPPORTED);

          when(() => camera.setFlashMode(any())).thenThrow(exception);

          // Save the camera in the camera plugin.
          (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

          expect(
            () => CameraPlatform.instance.setFlashMode(
              cameraId,
              FlashMode.always,
            ),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                exception.name,
              ),
            ),
          );
        });

        testWidgets('when setFlashMode throws CameraWebException',
            (WidgetTester tester) async {
          final MockCamera camera = MockCamera();
          final CameraWebException exception = CameraWebException(
            cameraId,
            CameraErrorCode.notStarted,
            'description',
          );

          when(() => camera.setFlashMode(any())).thenThrow(exception);

          // Save the camera in the camera plugin.
          (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

          expect(
            () => CameraPlatform.instance.setFlashMode(
              cameraId,
              FlashMode.torch,
            ),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                exception.code.toString(),
              ),
            ),
          );
        });
      });
    });

    testWidgets('setExposureMode throws UnimplementedError',
        (WidgetTester tester) async {
      expect(
        () => CameraPlatform.instance.setExposureMode(
          cameraId,
          ExposureMode.auto,
        ),
        throwsUnimplementedError,
      );
    });

    testWidgets('setExposurePoint throws UnimplementedError',
        (WidgetTester tester) async {
      expect(
        () => CameraPlatform.instance.setExposurePoint(
          cameraId,
          const Point<double>(0, 0),
        ),
        throwsUnimplementedError,
      );
    });

    testWidgets('getMinExposureOffset throws UnimplementedError',
        (WidgetTester tester) async {
      expect(
        () => CameraPlatform.instance.getMinExposureOffset(cameraId),
        throwsUnimplementedError,
      );
    });

    testWidgets('getMaxExposureOffset throws UnimplementedError',
        (WidgetTester tester) async {
      expect(
        () => CameraPlatform.instance.getMaxExposureOffset(cameraId),
        throwsUnimplementedError,
      );
    });

    testWidgets('getExposureOffsetStepSize throws UnimplementedError',
        (WidgetTester tester) async {
      expect(
        () => CameraPlatform.instance.getExposureOffsetStepSize(cameraId),
        throwsUnimplementedError,
      );
    });

    testWidgets('setExposureOffset throws UnimplementedError',
        (WidgetTester tester) async {
      expect(
        () => CameraPlatform.instance.setExposureOffset(
          cameraId,
          0,
        ),
        throwsUnimplementedError,
      );
    });

    testWidgets('setFocusMode throws UnimplementedError',
        (WidgetTester tester) async {
      expect(
        () => CameraPlatform.instance.setFocusMode(
          cameraId,
          FocusMode.auto,
        ),
        throwsUnimplementedError,
      );
    });

    testWidgets('setFocusPoint throws UnimplementedError',
        (WidgetTester tester) async {
      expect(
        () => CameraPlatform.instance.setFocusPoint(
          cameraId,
          const Point<double>(0, 0),
        ),
        throwsUnimplementedError,
      );
    });

    group('getMaxZoomLevel', () {
      testWidgets('calls getMaxZoomLevel on the camera',
          (WidgetTester tester) async {
        final MockCamera camera = MockCamera();
        const double maximumZoomLevel = 100.0;

        when(camera.getMaxZoomLevel).thenReturn(maximumZoomLevel);

        // Save the camera in the camera plugin.
        (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

        expect(
          await CameraPlatform.instance.getMaxZoomLevel(
            cameraId,
          ),
          equals(maximumZoomLevel),
        );

        verify(camera.getMaxZoomLevel).called(1);
      });

      group('throws PlatformException', () {
        testWidgets(
            'with notFound error '
            'if the camera does not exist', (WidgetTester tester) async {
          expect(
            () async => await CameraPlatform.instance.getMaxZoomLevel(
              cameraId,
            ),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                CameraErrorCode.notFound.toString(),
              ),
            ),
          );
        });

        testWidgets('when getMaxZoomLevel throws DomException',
            (WidgetTester tester) async {
          final MockCamera camera = MockCamera();
          final FakeDomException exception =
              FakeDomException(DomException.NOT_SUPPORTED);

          when(camera.getMaxZoomLevel).thenThrow(exception);

          // Save the camera in the camera plugin.
          (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

          expect(
            () async => await CameraPlatform.instance.getMaxZoomLevel(
              cameraId,
            ),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                exception.name,
              ),
            ),
          );
        });

        testWidgets('when getMaxZoomLevel throws CameraWebException',
            (WidgetTester tester) async {
          final MockCamera camera = MockCamera();
          final CameraWebException exception = CameraWebException(
            cameraId,
            CameraErrorCode.notStarted,
            'description',
          );

          when(camera.getMaxZoomLevel).thenThrow(exception);

          // Save the camera in the camera plugin.
          (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

          expect(
            () async => await CameraPlatform.instance.getMaxZoomLevel(
              cameraId,
            ),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                exception.code.toString(),
              ),
            ),
          );
        });
      });
    });

    group('getMinZoomLevel', () {
      testWidgets('calls getMinZoomLevel on the camera',
          (WidgetTester tester) async {
        final MockCamera camera = MockCamera();
        const double minimumZoomLevel = 100.0;

        when(camera.getMinZoomLevel).thenReturn(minimumZoomLevel);

        // Save the camera in the camera plugin.
        (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

        expect(
          await CameraPlatform.instance.getMinZoomLevel(
            cameraId,
          ),
          equals(minimumZoomLevel),
        );

        verify(camera.getMinZoomLevel).called(1);
      });

      group('throws PlatformException', () {
        testWidgets(
            'with notFound error '
            'if the camera does not exist', (WidgetTester tester) async {
          expect(
            () async => await CameraPlatform.instance.getMinZoomLevel(
              cameraId,
            ),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                CameraErrorCode.notFound.toString(),
              ),
            ),
          );
        });

        testWidgets('when getMinZoomLevel throws DomException',
            (WidgetTester tester) async {
          final MockCamera camera = MockCamera();
          final FakeDomException exception =
              FakeDomException(DomException.NOT_SUPPORTED);

          when(camera.getMinZoomLevel).thenThrow(exception);

          // Save the camera in the camera plugin.
          (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

          expect(
            () async => await CameraPlatform.instance.getMinZoomLevel(
              cameraId,
            ),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                exception.name,
              ),
            ),
          );
        });

        testWidgets('when getMinZoomLevel throws CameraWebException',
            (WidgetTester tester) async {
          final MockCamera camera = MockCamera();
          final CameraWebException exception = CameraWebException(
            cameraId,
            CameraErrorCode.notStarted,
            'description',
          );

          when(camera.getMinZoomLevel).thenThrow(exception);

          // Save the camera in the camera plugin.
          (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

          expect(
            () async => await CameraPlatform.instance.getMinZoomLevel(
              cameraId,
            ),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                exception.code.toString(),
              ),
            ),
          );
        });
      });
    });

    group('setZoomLevel', () {
      testWidgets('calls setZoomLevel on the camera',
          (WidgetTester tester) async {
        final MockCamera camera = MockCamera();

        // Save the camera in the camera plugin.
        (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

        const double zoom = 100.0;

        await CameraPlatform.instance.setZoomLevel(cameraId, zoom);

        verify(() => camera.setZoomLevel(zoom)).called(1);
      });

      group('throws CameraException', () {
        testWidgets(
            'with notFound error '
            'if the camera does not exist', (WidgetTester tester) async {
          expect(
            () async => await CameraPlatform.instance.setZoomLevel(
              cameraId,
              100.0,
            ),
            throwsA(
              isA<CameraException>().having(
                (CameraException e) => e.code,
                'code',
                CameraErrorCode.notFound.toString(),
              ),
            ),
          );
        });

        testWidgets('when setZoomLevel throws DomException',
            (WidgetTester tester) async {
          final MockCamera camera = MockCamera();
          final FakeDomException exception =
              FakeDomException(DomException.NOT_SUPPORTED);

          when(() => camera.setZoomLevel(any())).thenThrow(exception);

          // Save the camera in the camera plugin.
          (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

          expect(
            () async => await CameraPlatform.instance.setZoomLevel(
              cameraId,
              100.0,
            ),
            throwsA(
              isA<CameraException>().having(
                (CameraException e) => e.code,
                'code',
                exception.name,
              ),
            ),
          );
        });

        testWidgets('when setZoomLevel throws PlatformException',
            (WidgetTester tester) async {
          final MockCamera camera = MockCamera();
          final PlatformException exception = PlatformException(
            code: CameraErrorCode.notSupported.toString(),
            message: 'message',
          );

          when(() => camera.setZoomLevel(any())).thenThrow(exception);

          // Save the camera in the camera plugin.
          (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

          expect(
            () async => await CameraPlatform.instance.setZoomLevel(
              cameraId,
              100.0,
            ),
            throwsA(
              isA<CameraException>().having(
                (CameraException e) => e.code,
                'code',
                exception.code,
              ),
            ),
          );
        });

        testWidgets('when setZoomLevel throws CameraWebException',
            (WidgetTester tester) async {
          final MockCamera camera = MockCamera();
          final CameraWebException exception = CameraWebException(
            cameraId,
            CameraErrorCode.notStarted,
            'description',
          );

          when(() => camera.setZoomLevel(any())).thenThrow(exception);

          // Save the camera in the camera plugin.
          (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

          expect(
            () async => await CameraPlatform.instance.setZoomLevel(
              cameraId,
              100.0,
            ),
            throwsA(
              isA<CameraException>().having(
                (CameraException e) => e.code,
                'code',
                exception.code.toString(),
              ),
            ),
          );
        });
      });
    });

    group('pausePreview', () {
      testWidgets('calls pause on the camera', (WidgetTester tester) async {
        final MockCamera camera = MockCamera();

        // Save the camera in the camera plugin.
        (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

        await CameraPlatform.instance.pausePreview(cameraId);

        verify(camera.pause).called(1);
      });

      group('throws PlatformException', () {
        testWidgets(
            'with notFound error '
            'if the camera does not exist', (WidgetTester tester) async {
          expect(
            () async => await CameraPlatform.instance.pausePreview(cameraId),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                CameraErrorCode.notFound.toString(),
              ),
            ),
          );
        });

        testWidgets('when pause throws DomException',
            (WidgetTester tester) async {
          final MockCamera camera = MockCamera();
          final FakeDomException exception =
              FakeDomException(DomException.NOT_SUPPORTED);

          when(camera.pause).thenThrow(exception);

          // Save the camera in the camera plugin.
          (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

          expect(
            () async => await CameraPlatform.instance.pausePreview(cameraId),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                exception.name,
              ),
            ),
          );
        });
      });
    });

    group('resumePreview', () {
      testWidgets('calls play on the camera', (WidgetTester tester) async {
        final MockCamera camera = MockCamera();

        when(camera.play).thenAnswer((Invocation _) async {});

        // Save the camera in the camera plugin.
        (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

        await CameraPlatform.instance.resumePreview(cameraId);

        verify(camera.play).called(1);
      });

      group('throws PlatformException', () {
        testWidgets(
            'with notFound error '
            'if the camera does not exist', (WidgetTester tester) async {
          expect(
            () async => await CameraPlatform.instance.resumePreview(cameraId),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                CameraErrorCode.notFound.toString(),
              ),
            ),
          );
        });

        testWidgets('when play throws DomException',
            (WidgetTester tester) async {
          final MockCamera camera = MockCamera();
          final FakeDomException exception =
              FakeDomException(DomException.NOT_SUPPORTED);

          when(camera.play).thenThrow(exception);

          // Save the camera in the camera plugin.
          (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

          expect(
            () async => await CameraPlatform.instance.resumePreview(cameraId),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                exception.name,
              ),
            ),
          );
        });

        testWidgets('when play throws CameraWebException',
            (WidgetTester tester) async {
          final MockCamera camera = MockCamera();
          final CameraWebException exception = CameraWebException(
            cameraId,
            CameraErrorCode.unknown,
            'description',
          );

          when(camera.play).thenThrow(exception);

          // Save the camera in the camera plugin.
          (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

          expect(
            () async => await CameraPlatform.instance.resumePreview(cameraId),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                exception.code.toString(),
              ),
            ),
          );
        });
      });
    });

    testWidgets(
        'buildPreview returns an HtmlElementView '
        'with an appropriate view type', (WidgetTester tester) async {
      final Camera camera = Camera(
        textureId: cameraId,
        cameraService: cameraService,
      );

      // Save the camera in the camera plugin.
      (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

      expect(
        CameraPlatform.instance.buildPreview(cameraId),
        isA<widgets.HtmlElementView>().having(
          (widgets.HtmlElementView view) => view.viewType,
          'viewType',
          camera.getViewType(),
        ),
      );
    });

    group('dispose', () {
      late Camera camera;
      late VideoElement videoElement;

      late StreamController<Event> errorStreamController, abortStreamController;
      late StreamController<MediaStreamTrack> endedStreamController;
      late StreamController<ErrorEvent> videoRecordingErrorController;

      setUp(() {
        camera = MockCamera();
        videoElement = MockVideoElement();

        errorStreamController = StreamController<Event>();
        abortStreamController = StreamController<Event>();
        endedStreamController = StreamController<MediaStreamTrack>();
        videoRecordingErrorController = StreamController<ErrorEvent>();

        when(camera.getVideoSize).thenReturn(const Size(10, 10));
        when(camera.initialize)
            .thenAnswer((Invocation _) => Future<void>.value());
        when(camera.play).thenAnswer((Invocation _) => Future<void>.value());
        when(camera.dispose).thenAnswer((Invocation _) => Future<void>.value());

        when(() => camera.videoElement).thenReturn(videoElement);
        when(() => videoElement.onError).thenAnswer((Invocation _) =>
            FakeElementStream<Event>(errorStreamController.stream));
        when(() => videoElement.onAbort).thenAnswer((Invocation _) =>
            FakeElementStream<Event>(abortStreamController.stream));

        when(() => camera.onEnded)
            .thenAnswer((Invocation _) => endedStreamController.stream);

        when(() => camera.onVideoRecordingError)
            .thenAnswer((Invocation _) => videoRecordingErrorController.stream);

        when(camera.startVideoRecording).thenAnswer((Invocation _) async {});
      });

      testWidgets('disposes the correct camera', (WidgetTester tester) async {
        const int firstCameraId = 0;
        const int secondCameraId = 1;

        final MockCamera firstCamera = MockCamera();
        final MockCamera secondCamera = MockCamera();

        when(firstCamera.dispose)
            .thenAnswer((Invocation _) => Future<void>.value());
        when(secondCamera.dispose)
            .thenAnswer((Invocation _) => Future<void>.value());

        // Save cameras in the camera plugin.
        (CameraPlatform.instance as CameraPlugin).cameras.addAll(<int, Camera>{
          firstCameraId: firstCamera,
          secondCameraId: secondCamera,
        });

        // Dispose the first camera.
        await CameraPlatform.instance.dispose(firstCameraId);

        // The first camera should be disposed.
        verify(firstCamera.dispose).called(1);
        verifyNever(secondCamera.dispose);

        // The first camera should be removed from the camera plugin.
        expect(
          (CameraPlatform.instance as CameraPlugin).cameras,
          equals(<int, Camera>{
            secondCameraId: secondCamera,
          }),
        );
      });

      testWidgets('cancels the camera video error and abort subscriptions',
          (WidgetTester tester) async {
        // Save the camera in the camera plugin.
        (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

        await CameraPlatform.instance.initializeCamera(cameraId);
        await CameraPlatform.instance.dispose(cameraId);

        expect(errorStreamController.hasListener, isFalse);
        expect(abortStreamController.hasListener, isFalse);
      });

      testWidgets('cancels the camera ended subscriptions',
          (WidgetTester tester) async {
        // Save the camera in the camera plugin.
        (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

        await CameraPlatform.instance.initializeCamera(cameraId);
        await CameraPlatform.instance.dispose(cameraId);

        expect(endedStreamController.hasListener, isFalse);
      });

      testWidgets('cancels the camera video recording error subscriptions',
          (WidgetTester tester) async {
        // Save the camera in the camera plugin.
        (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

        await CameraPlatform.instance.initializeCamera(cameraId);
        await CameraPlatform.instance.startVideoRecording(cameraId);
        await CameraPlatform.instance.dispose(cameraId);

        expect(videoRecordingErrorController.hasListener, isFalse);
      });

      group('throws PlatformException', () {
        testWidgets(
            'with notFound error '
            'if the camera does not exist', (WidgetTester tester) async {
          expect(
            () => CameraPlatform.instance.dispose(cameraId),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                CameraErrorCode.notFound.toString(),
              ),
            ),
          );
        });

        testWidgets('when dispose throws DomException',
            (WidgetTester tester) async {
          final MockCamera camera = MockCamera();
          final FakeDomException exception =
              FakeDomException(DomException.INVALID_ACCESS);

          when(camera.dispose).thenThrow(exception);

          // Save the camera in the camera plugin.
          (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

          expect(
            () => CameraPlatform.instance.dispose(cameraId),
            throwsA(
              isA<PlatformException>().having(
                (PlatformException e) => e.code,
                'code',
                exception.name,
              ),
            ),
          );
        });
      });
    });

    group('getCamera', () {
      testWidgets('returns the correct camera', (WidgetTester tester) async {
        final Camera camera = Camera(
          textureId: cameraId,
          cameraService: cameraService,
        );

        // Save the camera in the camera plugin.
        (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

        expect(
          (CameraPlatform.instance as CameraPlugin).getCamera(cameraId),
          equals(camera),
        );
      });

      testWidgets(
          'throws PlatformException '
          'with notFound error '
          'if the camera does not exist', (WidgetTester tester) async {
        expect(
          () => (CameraPlatform.instance as CameraPlugin).getCamera(cameraId),
          throwsA(
            isA<PlatformException>().having(
              (PlatformException e) => e.code,
              'code',
              CameraErrorCode.notFound.toString(),
            ),
          ),
        );
      });
    });

    group('events', () {
      late Camera camera;
      late VideoElement videoElement;

      late StreamController<Event> errorStreamController, abortStreamController;
      late StreamController<MediaStreamTrack> endedStreamController;
      late StreamController<ErrorEvent> videoRecordingErrorController;

      setUp(() {
        camera = MockCamera();
        videoElement = MockVideoElement();

        errorStreamController = StreamController<Event>();
        abortStreamController = StreamController<Event>();
        endedStreamController = StreamController<MediaStreamTrack>();
        videoRecordingErrorController = StreamController<ErrorEvent>();

        when(camera.getVideoSize).thenReturn(const Size(10, 10));
        when(camera.initialize)
            .thenAnswer((Invocation _) => Future<void>.value());
        when(camera.play).thenAnswer((Invocation _) => Future<void>.value());

        when(() => camera.videoElement).thenReturn(videoElement);
        when(() => videoElement.onError).thenAnswer((Invocation _) =>
            FakeElementStream<Event>(errorStreamController.stream));
        when(() => videoElement.onAbort).thenAnswer((Invocation _) =>
            FakeElementStream<Event>(abortStreamController.stream));

        when(() => camera.onEnded)
            .thenAnswer((Invocation _) => endedStreamController.stream);

        when(() => camera.onVideoRecordingError)
            .thenAnswer((Invocation _) => videoRecordingErrorController.stream);

        when(() => camera.startVideoRecording())
            .thenAnswer((Invocation _) async {});
      });

      testWidgets(
          'onCameraInitialized emits a CameraInitializedEvent '
          'on initializeCamera', (WidgetTester tester) async {
        // Mock the camera to use a blank video stream of size 1280x720.
        const Size videoSize = Size(1280, 720);

        videoElement = getVideoElementWithBlankStream(videoSize);

        when(
          () => cameraService.getMediaStreamForOptions(
            any(),
            cameraId: cameraId,
          ),
        ).thenAnswer((Invocation _) async => videoElement.captureStream());

        final Camera camera = Camera(
          textureId: cameraId,
          cameraService: cameraService,
        );

        // Save the camera in the camera plugin.
        (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

        final Stream<CameraInitializedEvent> eventStream =
            CameraPlatform.instance.onCameraInitialized(cameraId);

        final StreamQueue<CameraInitializedEvent> streamQueue =
            StreamQueue<CameraInitializedEvent>(eventStream);

        await CameraPlatform.instance.initializeCamera(cameraId);

        expect(
          await streamQueue.next,
          equals(
            CameraInitializedEvent(
              cameraId,
              videoSize.width,
              videoSize.height,
              ExposureMode.auto,
              false,
              FocusMode.auto,
              false,
            ),
          ),
        );

        await streamQueue.cancel();
      });

      testWidgets('onCameraResolutionChanged emits an empty stream',
          (WidgetTester tester) async {
        expect(
          CameraPlatform.instance.onCameraResolutionChanged(cameraId),
          emits(isEmpty),
        );
      });

      testWidgets(
          'onCameraClosing emits a CameraClosingEvent '
          'on the camera ended event', (WidgetTester tester) async {
        // Save the camera in the camera plugin.
        (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

        final Stream<CameraClosingEvent> eventStream =
            CameraPlatform.instance.onCameraClosing(cameraId);

        final StreamQueue<CameraClosingEvent> streamQueue =
            StreamQueue<CameraClosingEvent>(eventStream);

        await CameraPlatform.instance.initializeCamera(cameraId);

        endedStreamController.add(MockMediaStreamTrack());

        expect(
          await streamQueue.next,
          equals(
            const CameraClosingEvent(cameraId),
          ),
        );

        await streamQueue.cancel();
      });

      group('onCameraError', () {
        setUp(() {
          // Save the camera in the camera plugin.
          (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;
        });

        testWidgets(
            'emits a CameraErrorEvent '
            'on the camera video error event '
            'with a message', (WidgetTester tester) async {
          final Stream<CameraErrorEvent> eventStream =
              CameraPlatform.instance.onCameraError(cameraId);

          final StreamQueue<CameraErrorEvent> streamQueue =
              StreamQueue<CameraErrorEvent>(eventStream);

          await CameraPlatform.instance.initializeCamera(cameraId);

          final FakeMediaError error = FakeMediaError(
            MediaError.MEDIA_ERR_NETWORK,
            'A network error occured.',
          );

          final CameraErrorCode errorCode =
              CameraErrorCode.fromMediaError(error);

          when(() => videoElement.error).thenReturn(error);

          errorStreamController.add(Event('error'));

          expect(
            await streamQueue.next,
            equals(
              CameraErrorEvent(
                cameraId,
                'Error code: $errorCode, error message: ${error.message}',
              ),
            ),
          );

          await streamQueue.cancel();
        });

        testWidgets(
            'emits a CameraErrorEvent '
            'on the camera video error event '
            'with no message', (WidgetTester tester) async {
          final Stream<CameraErrorEvent> eventStream =
              CameraPlatform.instance.onCameraError(cameraId);

          final StreamQueue<CameraErrorEvent> streamQueue =
              StreamQueue<CameraErrorEvent>(eventStream);

          await CameraPlatform.instance.initializeCamera(cameraId);

          final FakeMediaError error =
              FakeMediaError(MediaError.MEDIA_ERR_NETWORK);
          final CameraErrorCode errorCode =
              CameraErrorCode.fromMediaError(error);

          when(() => videoElement.error).thenReturn(error);

          errorStreamController.add(Event('error'));

          expect(
            await streamQueue.next,
            equals(
              CameraErrorEvent(
                cameraId,
                'Error code: $errorCode, error message: No further diagnostic information can be determined or provided.',
              ),
            ),
          );

          await streamQueue.cancel();
        });

        testWidgets(
            'emits a CameraErrorEvent '
            'on the camera video abort event', (WidgetTester tester) async {
          final Stream<CameraErrorEvent> eventStream =
              CameraPlatform.instance.onCameraError(cameraId);

          final StreamQueue<CameraErrorEvent> streamQueue =
              StreamQueue<CameraErrorEvent>(eventStream);

          await CameraPlatform.instance.initializeCamera(cameraId);

          abortStreamController.add(Event('abort'));

          expect(
            await streamQueue.next,
            equals(
              CameraErrorEvent(
                cameraId,
                "Error code: ${CameraErrorCode.abort}, error message: The video element's source has not fully loaded.",
              ),
            ),
          );

          await streamQueue.cancel();
        });

        testWidgets(
            'emits a CameraErrorEvent '
            'on takePicture error', (WidgetTester tester) async {
          final CameraWebException exception = CameraWebException(
            cameraId,
            CameraErrorCode.notStarted,
            'description',
          );

          when(camera.takePicture).thenThrow(exception);

          final Stream<CameraErrorEvent> eventStream =
              CameraPlatform.instance.onCameraError(cameraId);

          final StreamQueue<CameraErrorEvent> streamQueue =
              StreamQueue<CameraErrorEvent>(eventStream);

          expect(
            () async => await CameraPlatform.instance.takePicture(cameraId),
            throwsA(
              isA<PlatformException>(),
            ),
          );

          expect(
            await streamQueue.next,
            equals(
              CameraErrorEvent(
                cameraId,
                'Error code: ${exception.code}, error message: ${exception.description}',
              ),
            ),
          );

          await streamQueue.cancel();
        });

        testWidgets(
            'emits a CameraErrorEvent '
            'on setFlashMode error', (WidgetTester tester) async {
          final CameraWebException exception = CameraWebException(
            cameraId,
            CameraErrorCode.notStarted,
            'description',
          );

          when(() => camera.setFlashMode(any())).thenThrow(exception);

          final Stream<CameraErrorEvent> eventStream =
              CameraPlatform.instance.onCameraError(cameraId);

          final StreamQueue<CameraErrorEvent> streamQueue =
              StreamQueue<CameraErrorEvent>(eventStream);

          expect(
            () async => await CameraPlatform.instance.setFlashMode(
              cameraId,
              FlashMode.always,
            ),
            throwsA(
              isA<PlatformException>(),
            ),
          );

          expect(
            await streamQueue.next,
            equals(
              CameraErrorEvent(
                cameraId,
                'Error code: ${exception.code}, error message: ${exception.description}',
              ),
            ),
          );

          await streamQueue.cancel();
        });

        testWidgets(
            'emits a CameraErrorEvent '
            'on getMaxZoomLevel error', (WidgetTester tester) async {
          final CameraWebException exception = CameraWebException(
            cameraId,
            CameraErrorCode.zoomLevelNotSupported,
            'description',
          );

          when(camera.getMaxZoomLevel).thenThrow(exception);

          final Stream<CameraErrorEvent> eventStream =
              CameraPlatform.instance.onCameraError(cameraId);

          final StreamQueue<CameraErrorEvent> streamQueue =
              StreamQueue<CameraErrorEvent>(eventStream);

          expect(
            () async => await CameraPlatform.instance.getMaxZoomLevel(
              cameraId,
            ),
            throwsA(
              isA<PlatformException>(),
            ),
          );

          expect(
            await streamQueue.next,
            equals(
              CameraErrorEvent(
                cameraId,
                'Error code: ${exception.code}, error message: ${exception.description}',
              ),
            ),
          );

          await streamQueue.cancel();
        });

        testWidgets(
            'emits a CameraErrorEvent '
            'on getMinZoomLevel error', (WidgetTester tester) async {
          final CameraWebException exception = CameraWebException(
            cameraId,
            CameraErrorCode.zoomLevelNotSupported,
            'description',
          );

          when(camera.getMinZoomLevel).thenThrow(exception);

          final Stream<CameraErrorEvent> eventStream =
              CameraPlatform.instance.onCameraError(cameraId);

          final StreamQueue<CameraErrorEvent> streamQueue =
              StreamQueue<CameraErrorEvent>(eventStream);

          expect(
            () async => await CameraPlatform.instance.getMinZoomLevel(
              cameraId,
            ),
            throwsA(
              isA<PlatformException>(),
            ),
          );

          expect(
            await streamQueue.next,
            equals(
              CameraErrorEvent(
                cameraId,
                'Error code: ${exception.code}, error message: ${exception.description}',
              ),
            ),
          );

          await streamQueue.cancel();
        });

        testWidgets(
            'emits a CameraErrorEvent '
            'on setZoomLevel error', (WidgetTester tester) async {
          final CameraWebException exception = CameraWebException(
            cameraId,
            CameraErrorCode.zoomLevelNotSupported,
            'description',
          );

          when(() => camera.setZoomLevel(any())).thenThrow(exception);

          final Stream<CameraErrorEvent> eventStream =
              CameraPlatform.instance.onCameraError(cameraId);

          final StreamQueue<CameraErrorEvent> streamQueue =
              StreamQueue<CameraErrorEvent>(eventStream);

          expect(
            () async => await CameraPlatform.instance.setZoomLevel(
              cameraId,
              100.0,
            ),
            throwsA(
              isA<CameraException>(),
            ),
          );

          expect(
            await streamQueue.next,
            equals(
              CameraErrorEvent(
                cameraId,
                'Error code: ${exception.code}, error message: ${exception.description}',
              ),
            ),
          );

          await streamQueue.cancel();
        });

        testWidgets(
            'emits a CameraErrorEvent '
            'on resumePreview error', (WidgetTester tester) async {
          final CameraWebException exception = CameraWebException(
            cameraId,
            CameraErrorCode.unknown,
            'description',
          );

          when(camera.play).thenThrow(exception);

          final Stream<CameraErrorEvent> eventStream =
              CameraPlatform.instance.onCameraError(cameraId);

          final StreamQueue<CameraErrorEvent> streamQueue =
              StreamQueue<CameraErrorEvent>(eventStream);

          expect(
            () async => await CameraPlatform.instance.resumePreview(cameraId),
            throwsA(
              isA<PlatformException>(),
            ),
          );

          expect(
            await streamQueue.next,
            equals(
              CameraErrorEvent(
                cameraId,
                'Error code: ${exception.code}, error message: ${exception.description}',
              ),
            ),
          );

          await streamQueue.cancel();
        });

        testWidgets(
            'emits a CameraErrorEvent '
            'on startVideoRecording error', (WidgetTester tester) async {
          final CameraWebException exception = CameraWebException(
            cameraId,
            CameraErrorCode.notStarted,
            'description',
          );

          when(() => camera.onVideoRecordingError)
              .thenAnswer((Invocation _) => const Stream<ErrorEvent>.empty());

          when(
            () => camera.startVideoRecording(
              maxVideoDuration: any(named: 'maxVideoDuration'),
            ),
          ).thenThrow(exception);

          final Stream<CameraErrorEvent> eventStream =
              CameraPlatform.instance.onCameraError(cameraId);

          final StreamQueue<CameraErrorEvent> streamQueue =
              StreamQueue<CameraErrorEvent>(eventStream);

          expect(
            () async =>
                await CameraPlatform.instance.startVideoRecording(cameraId),
            throwsA(
              isA<PlatformException>(),
            ),
          );

          expect(
            await streamQueue.next,
            equals(
              CameraErrorEvent(
                cameraId,
                'Error code: ${exception.code}, error message: ${exception.description}',
              ),
            ),
          );

          await streamQueue.cancel();
        });

        testWidgets(
            'emits a CameraErrorEvent '
            'on the camera video recording error event',
            (WidgetTester tester) async {
          final Stream<CameraErrorEvent> eventStream =
              CameraPlatform.instance.onCameraError(cameraId);

          final StreamQueue<CameraErrorEvent> streamQueue =
              StreamQueue<CameraErrorEvent>(eventStream);

          await CameraPlatform.instance.initializeCamera(cameraId);
          await CameraPlatform.instance.startVideoRecording(cameraId);

          final FakeErrorEvent errorEvent = FakeErrorEvent('type', 'message');

          videoRecordingErrorController.add(errorEvent);

          expect(
            await streamQueue.next,
            equals(
              CameraErrorEvent(
                cameraId,
                'Error code: ${errorEvent.type}, error message: ${errorEvent.message}.',
              ),
            ),
          );

          await streamQueue.cancel();
        });

        testWidgets(
            'emits a CameraErrorEvent '
            'on stopVideoRecording error', (WidgetTester tester) async {
          final CameraWebException exception = CameraWebException(
            cameraId,
            CameraErrorCode.notStarted,
            'description',
          );

          when(camera.stopVideoRecording).thenThrow(exception);

          final Stream<CameraErrorEvent> eventStream =
              CameraPlatform.instance.onCameraError(cameraId);

          final StreamQueue<CameraErrorEvent> streamQueue =
              StreamQueue<CameraErrorEvent>(eventStream);

          expect(
            () async =>
                await CameraPlatform.instance.stopVideoRecording(cameraId),
            throwsA(
              isA<PlatformException>(),
            ),
          );

          expect(
            await streamQueue.next,
            equals(
              CameraErrorEvent(
                cameraId,
                'Error code: ${exception.code}, error message: ${exception.description}',
              ),
            ),
          );

          await streamQueue.cancel();
        });

        testWidgets(
            'emits a CameraErrorEvent '
            'on pauseVideoRecording error', (WidgetTester tester) async {
          final CameraWebException exception = CameraWebException(
            cameraId,
            CameraErrorCode.notStarted,
            'description',
          );

          when(camera.pauseVideoRecording).thenThrow(exception);

          final Stream<CameraErrorEvent> eventStream =
              CameraPlatform.instance.onCameraError(cameraId);

          final StreamQueue<CameraErrorEvent> streamQueue =
              StreamQueue<CameraErrorEvent>(eventStream);

          expect(
            () async =>
                await CameraPlatform.instance.pauseVideoRecording(cameraId),
            throwsA(
              isA<PlatformException>(),
            ),
          );

          expect(
            await streamQueue.next,
            equals(
              CameraErrorEvent(
                cameraId,
                'Error code: ${exception.code}, error message: ${exception.description}',
              ),
            ),
          );

          await streamQueue.cancel();
        });

        testWidgets(
            'emits a CameraErrorEvent '
            'on resumeVideoRecording error', (WidgetTester tester) async {
          final CameraWebException exception = CameraWebException(
            cameraId,
            CameraErrorCode.notStarted,
            'description',
          );

          when(camera.resumeVideoRecording).thenThrow(exception);

          final Stream<CameraErrorEvent> eventStream =
              CameraPlatform.instance.onCameraError(cameraId);

          final StreamQueue<CameraErrorEvent> streamQueue =
              StreamQueue<CameraErrorEvent>(eventStream);

          expect(
            () async =>
                await CameraPlatform.instance.resumeVideoRecording(cameraId),
            throwsA(
              isA<PlatformException>(),
            ),
          );

          expect(
            await streamQueue.next,
            equals(
              CameraErrorEvent(
                cameraId,
                'Error code: ${exception.code}, error message: ${exception.description}',
              ),
            ),
          );

          await streamQueue.cancel();
        });
      });

      testWidgets('onVideoRecordedEvent emits a VideoRecordedEvent',
          (WidgetTester tester) async {
        final MockCamera camera = MockCamera();
        final MockXFile capturedVideo = MockXFile();
        final Stream<VideoRecordedEvent> stream =
            Stream<VideoRecordedEvent>.value(
                VideoRecordedEvent(cameraId, capturedVideo, Duration.zero));
        when(() => camera.onVideoRecordedEvent)
            .thenAnswer((Invocation _) => stream);

        // Save the camera in the camera plugin.
        (CameraPlatform.instance as CameraPlugin).cameras[cameraId] = camera;

        final StreamQueue<VideoRecordedEvent> streamQueue =
            StreamQueue<VideoRecordedEvent>(
                CameraPlatform.instance.onVideoRecordedEvent(cameraId));

        expect(
          await streamQueue.next,
          equals(
            VideoRecordedEvent(cameraId, capturedVideo, Duration.zero),
          ),
        );
      });

      group('onDeviceOrientationChanged', () {
        group('emits an empty stream', () {
          testWidgets('when screen is not supported',
              (WidgetTester tester) async {
            when(() => window.screen).thenReturn(null);

            expect(
              CameraPlatform.instance.onDeviceOrientationChanged(),
              emits(isEmpty),
            );
          });

          testWidgets('when screen orientation is not supported',
              (WidgetTester tester) async {
            when(() => screen.orientation).thenReturn(null);

            expect(
              CameraPlatform.instance.onDeviceOrientationChanged(),
              emits(isEmpty),
            );
          });
        });

        testWidgets('emits the initial DeviceOrientationChangedEvent',
            (WidgetTester tester) async {
          when(
            () => cameraService.mapOrientationTypeToDeviceOrientation(
              OrientationType.portraitPrimary,
            ),
          ).thenReturn(DeviceOrientation.portraitUp);

          // Set the initial screen orientation to portraitPrimary.
          when(() => screenOrientation.type)
              .thenReturn(OrientationType.portraitPrimary);

          final StreamController<Event> eventStreamController =
              StreamController<Event>();

          when(() => screenOrientation.onChange)
              .thenAnswer((Invocation _) => eventStreamController.stream);

          final Stream<DeviceOrientationChangedEvent> eventStream =
              CameraPlatform.instance.onDeviceOrientationChanged();

          final StreamQueue<DeviceOrientationChangedEvent> streamQueue =
              StreamQueue<DeviceOrientationChangedEvent>(eventStream);

          expect(
            await streamQueue.next,
            equals(
              const DeviceOrientationChangedEvent(
                DeviceOrientation.portraitUp,
              ),
            ),
          );

          await streamQueue.cancel();
        });

        testWidgets(
            'emits a DeviceOrientationChangedEvent '
            'when the screen orientation is changed',
            (WidgetTester tester) async {
          when(
            () => cameraService.mapOrientationTypeToDeviceOrientation(
              OrientationType.landscapePrimary,
            ),
          ).thenReturn(DeviceOrientation.landscapeLeft);

          when(
            () => cameraService.mapOrientationTypeToDeviceOrientation(
              OrientationType.portraitSecondary,
            ),
          ).thenReturn(DeviceOrientation.portraitDown);

          final StreamController<Event> eventStreamController =
              StreamController<Event>();

          when(() => screenOrientation.onChange)
              .thenAnswer((Invocation _) => eventStreamController.stream);

          final Stream<DeviceOrientationChangedEvent> eventStream =
              CameraPlatform.instance.onDeviceOrientationChanged();

          final StreamQueue<DeviceOrientationChangedEvent> streamQueue =
              StreamQueue<DeviceOrientationChangedEvent>(eventStream);

          // Change the screen orientation to landscapePrimary and
          // emit an event on the screenOrientation.onChange stream.
          when(() => screenOrientation.type)
              .thenReturn(OrientationType.landscapePrimary);

          eventStreamController.add(Event('change'));

          expect(
            await streamQueue.next,
            equals(
              const DeviceOrientationChangedEvent(
                DeviceOrientation.landscapeLeft,
              ),
            ),
          );

          // Change the screen orientation to portraitSecondary and
          // emit an event on the screenOrientation.onChange stream.
          when(() => screenOrientation.type)
              .thenReturn(OrientationType.portraitSecondary);

          eventStreamController.add(Event('change'));

          expect(
            await streamQueue.next,
            equals(
              const DeviceOrientationChangedEvent(
                DeviceOrientation.portraitDown,
              ),
            ),
          );

          await streamQueue.cancel();
        });
      });
    });
  });
}
