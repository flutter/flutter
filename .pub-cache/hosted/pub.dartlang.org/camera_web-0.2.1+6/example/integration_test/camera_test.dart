// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'dart:ui';

import 'package:async/async.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:camera_web/src/camera.dart';
import 'package:camera_web/src/camera_service.dart';
import 'package:camera_web/src/types/types.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers/helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Camera', () {
    const int textureId = 1;

    late Window window;
    late Navigator navigator;
    late MediaDevices mediaDevices;

    late MediaStream mediaStream;
    late CameraService cameraService;

    setUp(() {
      window = MockWindow();
      navigator = MockNavigator();
      mediaDevices = MockMediaDevices();

      when(() => window.navigator).thenReturn(navigator);
      when(() => navigator.mediaDevices).thenReturn(mediaDevices);

      cameraService = MockCameraService();

      final VideoElement videoElement =
          getVideoElementWithBlankStream(const Size(10, 10));
      mediaStream = videoElement.captureStream();

      when(
        () => cameraService.getMediaStreamForOptions(
          any(),
          cameraId: any(named: 'cameraId'),
        ),
      ).thenAnswer((_) => Future<MediaStream>.value(mediaStream));
    });

    setUpAll(() {
      registerFallbackValue(MockCameraOptions());
    });

    group('initialize', () {
      testWidgets(
          'calls CameraService.getMediaStreamForOptions '
          'with provided options', (WidgetTester tester) async {
        final CameraOptions options = CameraOptions(
          video: VideoConstraints(
            facingMode: FacingModeConstraint.exact(CameraType.user),
            width: const VideoSizeConstraint(ideal: 200),
          ),
        );

        final Camera camera = Camera(
          textureId: textureId,
          options: options,
          cameraService: cameraService,
        );

        await camera.initialize();

        verify(
          () => cameraService.getMediaStreamForOptions(
            options,
            cameraId: textureId,
          ),
        ).called(1);
      });

      testWidgets(
          'creates a video element '
          'with correct properties', (WidgetTester tester) async {
        const AudioConstraints audioConstraints =
            AudioConstraints(enabled: true);
        final VideoConstraints videoConstraints = VideoConstraints(
          facingMode: FacingModeConstraint(
            CameraType.user,
          ),
        );

        final Camera camera = Camera(
          textureId: textureId,
          options: CameraOptions(
            audio: audioConstraints,
            video: videoConstraints,
          ),
          cameraService: cameraService,
        );

        await camera.initialize();

        expect(camera.videoElement, isNotNull);
        expect(camera.videoElement.autoplay, isFalse);
        expect(camera.videoElement.muted, isTrue);
        expect(camera.videoElement.srcObject, mediaStream);
        expect(camera.videoElement.attributes.keys, contains('playsinline'));

        expect(
            camera.videoElement.style.transformOrigin, equals('center center'));
        expect(camera.videoElement.style.pointerEvents, equals('none'));
        expect(camera.videoElement.style.width, equals('100%'));
        expect(camera.videoElement.style.height, equals('100%'));
        expect(camera.videoElement.style.objectFit, equals('cover'));
      });

      testWidgets(
          'flips the video element horizontally '
          'for a back camera', (WidgetTester tester) async {
        final VideoConstraints videoConstraints = VideoConstraints(
          facingMode: FacingModeConstraint(
            CameraType.environment,
          ),
        );

        final Camera camera = Camera(
          textureId: textureId,
          options: CameraOptions(
            video: videoConstraints,
          ),
          cameraService: cameraService,
        );

        await camera.initialize();

        expect(camera.videoElement.style.transform, equals('scaleX(-1)'));
      });

      testWidgets(
          'creates a wrapping div element '
          'with correct properties', (WidgetTester tester) async {
        final Camera camera = Camera(
          textureId: textureId,
          cameraService: cameraService,
        );

        await camera.initialize();

        expect(camera.divElement, isNotNull);
        expect(camera.divElement.style.objectFit, equals('cover'));
        expect(camera.divElement.children, contains(camera.videoElement));
      });

      testWidgets('initializes the camera stream', (WidgetTester tester) async {
        final Camera camera = Camera(
          textureId: textureId,
          cameraService: cameraService,
        );

        await camera.initialize();

        expect(camera.stream, mediaStream);
      });

      testWidgets(
          'throws an exception '
          'when CameraService.getMediaStreamForOptions throws',
          (WidgetTester tester) async {
        final Exception exception =
            Exception('A media stream exception occured.');

        when(() => cameraService.getMediaStreamForOptions(any(),
            cameraId: any(named: 'cameraId'))).thenThrow(exception);

        final Camera camera = Camera(
          textureId: textureId,
          cameraService: cameraService,
        );

        expect(
          camera.initialize,
          throwsA(exception),
        );
      });
    });

    group('play', () {
      testWidgets('starts playing the video element',
          (WidgetTester tester) async {
        bool startedPlaying = false;

        final Camera camera = Camera(
          textureId: textureId,
          cameraService: cameraService,
        );

        await camera.initialize();

        final StreamSubscription<Event> cameraPlaySubscription = camera
            .videoElement.onPlay
            .listen((Event event) => startedPlaying = true);

        await camera.play();

        expect(startedPlaying, isTrue);

        await cameraPlaySubscription.cancel();
      });

      testWidgets(
          'initializes the camera stream '
          'from CameraService.getMediaStreamForOptions '
          'if it does not exist', (WidgetTester tester) async {
        const CameraOptions options = CameraOptions(
          video: VideoConstraints(
            width: VideoSizeConstraint(ideal: 100),
          ),
        );

        final Camera camera = Camera(
          textureId: textureId,
          options: options,
          cameraService: cameraService,
        );

        await camera.initialize();

        /// Remove the video element's source
        /// by stopping the camera.
        camera.stop();

        await camera.play();

        // Should be called twice: for initialize and play.
        verify(
          () => cameraService.getMediaStreamForOptions(
            options,
            cameraId: textureId,
          ),
        ).called(2);

        expect(camera.videoElement.srcObject, mediaStream);
        expect(camera.stream, mediaStream);
      });
    });

    group('pause', () {
      testWidgets('pauses the camera stream', (WidgetTester tester) async {
        final Camera camera = Camera(
          textureId: textureId,
          cameraService: cameraService,
        );

        await camera.initialize();
        await camera.play();

        expect(camera.videoElement.paused, isFalse);

        camera.pause();

        expect(camera.videoElement.paused, isTrue);
      });
    });

    group('stop', () {
      testWidgets('resets the camera stream', (WidgetTester tester) async {
        final Camera camera = Camera(
          textureId: textureId,
          cameraService: cameraService,
        );

        await camera.initialize();
        await camera.play();

        camera.stop();

        expect(camera.videoElement.srcObject, isNull);
        expect(camera.stream, isNull);
      });
    });

    group('takePicture', () {
      testWidgets('returns a captured picture', (WidgetTester tester) async {
        final Camera camera = Camera(
          textureId: textureId,
          cameraService: cameraService,
        );

        await camera.initialize();
        await camera.play();

        final XFile pictureFile = await camera.takePicture();

        expect(pictureFile, isNotNull);
      });

      group(
          'enables the torch mode '
          'when taking a picture', () {
        late List<MediaStreamTrack> videoTracks;
        late MediaStream videoStream;
        late VideoElement videoElement;

        setUp(() {
          videoTracks = <MediaStreamTrack>[
            MockMediaStreamTrack(),
            MockMediaStreamTrack()
          ];
          videoStream = FakeMediaStream(videoTracks);

          videoElement = getVideoElementWithBlankStream(const Size(100, 100))
            ..muted = true;

          when(() => videoTracks.first.applyConstraints(any()))
              .thenAnswer((_) async => <dynamic, dynamic>{});

          when(videoTracks.first.getCapabilities).thenReturn(<dynamic, dynamic>{
            'torch': true,
          });
        });

        testWidgets('if the flash mode is auto', (WidgetTester tester) async {
          final Camera camera = Camera(
            textureId: textureId,
            cameraService: cameraService,
          )
            ..window = window
            ..stream = videoStream
            ..videoElement = videoElement
            ..flashMode = FlashMode.auto;

          await camera.play();

          final XFile _ = await camera.takePicture();

          verify(
            () => videoTracks.first.applyConstraints(<dynamic, dynamic>{
              'advanced': <dynamic>[
                <dynamic, dynamic>{
                  'torch': true,
                }
              ]
            }),
          ).called(1);

          verify(
            () => videoTracks.first.applyConstraints(<dynamic, dynamic>{
              'advanced': <dynamic>[
                <dynamic, dynamic>{
                  'torch': false,
                }
              ]
            }),
          ).called(1);
        });

        testWidgets('if the flash mode is always', (WidgetTester tester) async {
          final Camera camera = Camera(
            textureId: textureId,
            cameraService: cameraService,
          )
            ..window = window
            ..stream = videoStream
            ..videoElement = videoElement
            ..flashMode = FlashMode.always;

          await camera.play();

          final XFile _ = await camera.takePicture();

          verify(
            () => videoTracks.first.applyConstraints(<dynamic, dynamic>{
              'advanced': <dynamic>[
                <dynamic, dynamic>{
                  'torch': true,
                }
              ]
            }),
          ).called(1);

          verify(
            () => videoTracks.first.applyConstraints(<dynamic, dynamic>{
              'advanced': <dynamic>[
                <dynamic, dynamic>{
                  'torch': false,
                }
              ]
            }),
          ).called(1);
        });
      });
    });

    group('getVideoSize', () {
      testWidgets(
          'returns a size '
          'based on the first video track settings',
          (WidgetTester tester) async {
        const Size videoSize = Size(1280, 720);

        final VideoElement videoElement =
            getVideoElementWithBlankStream(videoSize);
        mediaStream = videoElement.captureStream();

        final Camera camera = Camera(
          textureId: textureId,
          cameraService: cameraService,
        );

        await camera.initialize();

        expect(
          camera.getVideoSize(),
          equals(videoSize),
        );
      });

      testWidgets(
          'returns Size.zero '
          'if the camera is missing video tracks', (WidgetTester tester) async {
        // Create a video stream with no video tracks.
        final VideoElement videoElement = VideoElement();
        mediaStream = videoElement.captureStream();

        final Camera camera = Camera(
          textureId: textureId,
          cameraService: cameraService,
        );

        await camera.initialize();

        expect(
          camera.getVideoSize(),
          equals(Size.zero),
        );
      });
    });

    group('setFlashMode', () {
      late List<MediaStreamTrack> videoTracks;
      late MediaStream videoStream;

      setUp(() {
        videoTracks = <MediaStreamTrack>[
          MockMediaStreamTrack(),
          MockMediaStreamTrack()
        ];
        videoStream = FakeMediaStream(videoTracks);

        when(() => videoTracks.first.applyConstraints(any()))
            .thenAnswer((_) async => <dynamic, dynamic>{});

        when(videoTracks.first.getCapabilities)
            .thenReturn(<dynamic, dynamic>{});
      });

      testWidgets('sets the camera flash mode', (WidgetTester tester) async {
        when(mediaDevices.getSupportedConstraints)
            .thenReturn(<dynamic, dynamic>{
          'torch': true,
        });

        when(videoTracks.first.getCapabilities).thenReturn(<dynamic, dynamic>{
          'torch': true,
        });

        final Camera camera = Camera(
          textureId: textureId,
          cameraService: cameraService,
        )
          ..window = window
          ..stream = videoStream;

        const FlashMode flashMode = FlashMode.always;

        camera.setFlashMode(flashMode);

        expect(
          camera.flashMode,
          equals(flashMode),
        );
      });

      testWidgets(
          'enables the torch mode '
          'if the flash mode is torch', (WidgetTester tester) async {
        when(mediaDevices.getSupportedConstraints)
            .thenReturn(<dynamic, dynamic>{
          'torch': true,
        });

        when(videoTracks.first.getCapabilities).thenReturn(<dynamic, dynamic>{
          'torch': true,
        });

        final Camera camera = Camera(
          textureId: textureId,
          cameraService: cameraService,
        )
          ..window = window
          ..stream = videoStream;

        camera.setFlashMode(FlashMode.torch);

        verify(
          () => videoTracks.first.applyConstraints(<dynamic, dynamic>{
            'advanced': <dynamic>[
              <dynamic, dynamic>{
                'torch': true,
              }
            ]
          }),
        ).called(1);
      });

      testWidgets(
          'disables the torch mode '
          'if the flash mode is not torch', (WidgetTester tester) async {
        when(mediaDevices.getSupportedConstraints)
            .thenReturn(<dynamic, dynamic>{
          'torch': true,
        });

        when(videoTracks.first.getCapabilities).thenReturn(<dynamic, dynamic>{
          'torch': true,
        });

        final Camera camera = Camera(
          textureId: textureId,
          cameraService: cameraService,
        )
          ..window = window
          ..stream = videoStream;

        camera.setFlashMode(FlashMode.auto);

        verify(
          () => videoTracks.first.applyConstraints(<dynamic, dynamic>{
            'advanced': <dynamic>[
              <dynamic, dynamic>{
                'torch': false,
              }
            ]
          }),
        ).called(1);
      });

      group('throws a CameraWebException', () {
        testWidgets(
            'with torchModeNotSupported error '
            'when there are no media devices', (WidgetTester tester) async {
          when(() => navigator.mediaDevices).thenReturn(null);

          final Camera camera = Camera(
            textureId: textureId,
            cameraService: cameraService,
          )
            ..window = window
            ..stream = videoStream;

          expect(
            () => camera.setFlashMode(FlashMode.always),
            throwsA(
              isA<CameraWebException>()
                  .having(
                    (CameraWebException e) => e.cameraId,
                    'cameraId',
                    textureId,
                  )
                  .having(
                    (CameraWebException e) => e.code,
                    'code',
                    CameraErrorCode.torchModeNotSupported,
                  ),
            ),
          );
        });

        testWidgets(
            'with torchModeNotSupported error '
            'when the torch mode is not supported '
            'in the browser', (WidgetTester tester) async {
          when(mediaDevices.getSupportedConstraints)
              .thenReturn(<dynamic, dynamic>{
            'torch': false,
          });

          when(videoTracks.first.getCapabilities).thenReturn(<dynamic, dynamic>{
            'torch': true,
          });

          final Camera camera = Camera(
            textureId: textureId,
            cameraService: cameraService,
          )
            ..window = window
            ..stream = videoStream;

          expect(
            () => camera.setFlashMode(FlashMode.always),
            throwsA(
              isA<CameraWebException>()
                  .having(
                    (CameraWebException e) => e.cameraId,
                    'cameraId',
                    textureId,
                  )
                  .having(
                    (CameraWebException e) => e.code,
                    'code',
                    CameraErrorCode.torchModeNotSupported,
                  ),
            ),
          );
        });

        testWidgets(
            'with torchModeNotSupported error '
            'when the torch mode is not supported '
            'by the camera', (WidgetTester tester) async {
          when(mediaDevices.getSupportedConstraints)
              .thenReturn(<dynamic, dynamic>{
            'torch': true,
          });

          when(videoTracks.first.getCapabilities).thenReturn(<dynamic, dynamic>{
            'torch': false,
          });

          final Camera camera = Camera(
            textureId: textureId,
            cameraService: cameraService,
          )
            ..window = window
            ..stream = videoStream;

          expect(
            () => camera.setFlashMode(FlashMode.always),
            throwsA(
              isA<CameraWebException>()
                  .having(
                    (CameraWebException e) => e.cameraId,
                    'cameraId',
                    textureId,
                  )
                  .having(
                    (CameraWebException e) => e.code,
                    'code',
                    CameraErrorCode.torchModeNotSupported,
                  ),
            ),
          );
        });

        testWidgets(
            'with notStarted error '
            'when the camera stream has not been initialized',
            (WidgetTester tester) async {
          when(mediaDevices.getSupportedConstraints)
              .thenReturn(<dynamic, dynamic>{
            'torch': true,
          });

          when(videoTracks.first.getCapabilities).thenReturn(<dynamic, dynamic>{
            'torch': true,
          });

          final Camera camera = Camera(
            textureId: textureId,
            cameraService: cameraService,
          )..window = window;

          expect(
            () => camera.setFlashMode(FlashMode.always),
            throwsA(
              isA<CameraWebException>()
                  .having(
                    (CameraWebException e) => e.cameraId,
                    'cameraId',
                    textureId,
                  )
                  .having(
                    (CameraWebException e) => e.code,
                    'code',
                    CameraErrorCode.notStarted,
                  ),
            ),
          );
        });
      });
    });

    group('zoomLevel', () {
      group('getMaxZoomLevel', () {
        testWidgets(
            'returns maximum '
            'from CameraService.getZoomLevelCapabilityForCamera',
            (WidgetTester tester) async {
          final Camera camera = Camera(
            textureId: textureId,
            cameraService: cameraService,
          );

          final ZoomLevelCapability zoomLevelCapability = ZoomLevelCapability(
            minimum: 50.0,
            maximum: 100.0,
            videoTrack: MockMediaStreamTrack(),
          );

          when(() => cameraService.getZoomLevelCapabilityForCamera(camera))
              .thenReturn(zoomLevelCapability);

          final double maximumZoomLevel = camera.getMaxZoomLevel();

          verify(() => cameraService.getZoomLevelCapabilityForCamera(camera))
              .called(1);

          expect(
            maximumZoomLevel,
            equals(zoomLevelCapability.maximum),
          );
        });
      });

      group('getMinZoomLevel', () {
        testWidgets(
            'returns minimum '
            'from CameraService.getZoomLevelCapabilityForCamera',
            (WidgetTester tester) async {
          final Camera camera = Camera(
            textureId: textureId,
            cameraService: cameraService,
          );

          final ZoomLevelCapability zoomLevelCapability = ZoomLevelCapability(
            minimum: 50.0,
            maximum: 100.0,
            videoTrack: MockMediaStreamTrack(),
          );

          when(() => cameraService.getZoomLevelCapabilityForCamera(camera))
              .thenReturn(zoomLevelCapability);

          final double minimumZoomLevel = camera.getMinZoomLevel();

          verify(() => cameraService.getZoomLevelCapabilityForCamera(camera))
              .called(1);

          expect(
            minimumZoomLevel,
            equals(zoomLevelCapability.minimum),
          );
        });
      });

      group('setZoomLevel', () {
        testWidgets(
            'applies zoom on the video track '
            'from CameraService.getZoomLevelCapabilityForCamera',
            (WidgetTester tester) async {
          final Camera camera = Camera(
            textureId: textureId,
            cameraService: cameraService,
          );

          final MockMediaStreamTrack videoTrack = MockMediaStreamTrack();

          final ZoomLevelCapability zoomLevelCapability = ZoomLevelCapability(
            minimum: 50.0,
            maximum: 100.0,
            videoTrack: videoTrack,
          );

          when(() => videoTrack.applyConstraints(any()))
              .thenAnswer((_) async {});

          when(() => cameraService.getZoomLevelCapabilityForCamera(camera))
              .thenReturn(zoomLevelCapability);

          const double zoom = 75.0;

          camera.setZoomLevel(zoom);

          verify(
            () => videoTrack.applyConstraints(<dynamic, dynamic>{
              'advanced': <dynamic>[
                <dynamic, dynamic>{
                  ZoomLevelCapability.constraintName: zoom,
                }
              ]
            }),
          ).called(1);
        });

        group('throws a CameraWebException', () {
          testWidgets(
              'with zoomLevelInvalid error '
              'when the provided zoom level is below minimum',
              (WidgetTester tester) async {
            final Camera camera = Camera(
              textureId: textureId,
              cameraService: cameraService,
            );

            final ZoomLevelCapability zoomLevelCapability = ZoomLevelCapability(
              minimum: 50.0,
              maximum: 100.0,
              videoTrack: MockMediaStreamTrack(),
            );

            when(() => cameraService.getZoomLevelCapabilityForCamera(camera))
                .thenReturn(zoomLevelCapability);

            expect(
                () => camera.setZoomLevel(45.0),
                throwsA(
                  isA<CameraWebException>()
                      .having(
                        (CameraWebException e) => e.cameraId,
                        'cameraId',
                        textureId,
                      )
                      .having(
                        (CameraWebException e) => e.code,
                        'code',
                        CameraErrorCode.zoomLevelInvalid,
                      ),
                ));
          });

          testWidgets(
              'with zoomLevelInvalid error '
              'when the provided zoom level is below minimum',
              (WidgetTester tester) async {
            final Camera camera = Camera(
              textureId: textureId,
              cameraService: cameraService,
            );

            final ZoomLevelCapability zoomLevelCapability = ZoomLevelCapability(
              minimum: 50.0,
              maximum: 100.0,
              videoTrack: MockMediaStreamTrack(),
            );

            when(() => cameraService.getZoomLevelCapabilityForCamera(camera))
                .thenReturn(zoomLevelCapability);

            expect(
              () => camera.setZoomLevel(105.0),
              throwsA(
                isA<CameraWebException>()
                    .having(
                      (CameraWebException e) => e.cameraId,
                      'cameraId',
                      textureId,
                    )
                    .having(
                      (CameraWebException e) => e.code,
                      'code',
                      CameraErrorCode.zoomLevelInvalid,
                    ),
              ),
            );
          });
        });
      });
    });

    group('getLensDirection', () {
      testWidgets(
          'returns a lens direction '
          'based on the first video track settings',
          (WidgetTester tester) async {
        final MockVideoElement videoElement = MockVideoElement();

        final Camera camera = Camera(
          textureId: textureId,
          cameraService: cameraService,
        )..videoElement = videoElement;

        final MockMediaStreamTrack firstVideoTrack = MockMediaStreamTrack();

        when(() => videoElement.srcObject).thenReturn(
          FakeMediaStream(<MediaStreamTrack>[
            firstVideoTrack,
            MockMediaStreamTrack(),
          ]),
        );

        when(firstVideoTrack.getSettings)
            .thenReturn(<dynamic, dynamic>{'facingMode': 'environment'});

        when(() => cameraService.mapFacingModeToLensDirection('environment'))
            .thenReturn(CameraLensDirection.external);

        expect(
          camera.getLensDirection(),
          equals(CameraLensDirection.external),
        );
      });

      testWidgets(
          'returns null '
          'if the first video track is missing the facing mode',
          (WidgetTester tester) async {
        final MockVideoElement videoElement = MockVideoElement();

        final Camera camera = Camera(
          textureId: textureId,
          cameraService: cameraService,
        )..videoElement = videoElement;

        final MockMediaStreamTrack firstVideoTrack = MockMediaStreamTrack();

        when(() => videoElement.srcObject).thenReturn(
          FakeMediaStream(<MediaStreamTrack>[
            firstVideoTrack,
            MockMediaStreamTrack(),
          ]),
        );

        when(firstVideoTrack.getSettings).thenReturn(<dynamic, dynamic>{});

        expect(
          camera.getLensDirection(),
          isNull,
        );
      });

      testWidgets(
          'returns null '
          'if the camera is missing video tracks', (WidgetTester tester) async {
        // Create a video stream with no video tracks.
        final VideoElement videoElement = VideoElement();
        mediaStream = videoElement.captureStream();

        final Camera camera = Camera(
          textureId: textureId,
          cameraService: cameraService,
        );

        await camera.initialize();

        expect(
          camera.getLensDirection(),
          isNull,
        );
      });
    });

    group('getViewType', () {
      testWidgets('returns a correct view type', (WidgetTester tester) async {
        final Camera camera = Camera(
          textureId: textureId,
          cameraService: cameraService,
        );

        await camera.initialize();

        expect(
          camera.getViewType(),
          equals('plugins.flutter.io/camera_$textureId'),
        );
      });
    });

    group('video recording', () {
      const String supportedVideoType = 'video/webm';

      late MediaRecorder mediaRecorder;

      bool isVideoTypeSupported(String type) => type == supportedVideoType;

      setUp(() {
        mediaRecorder = MockMediaRecorder();

        when(() => mediaRecorder.onError)
            .thenAnswer((_) => const Stream<Event>.empty());
      });

      group('startVideoRecording', () {
        testWidgets(
            'creates a media recorder '
            'with appropriate options', (WidgetTester tester) async {
          final Camera camera = Camera(
            textureId: 1,
            cameraService: cameraService,
          )..isVideoTypeSupported = isVideoTypeSupported;

          await camera.initialize();
          await camera.play();

          await camera.startVideoRecording();

          expect(
            camera.mediaRecorder!.stream,
            equals(camera.stream),
          );

          expect(
            camera.mediaRecorder!.mimeType,
            equals(supportedVideoType),
          );

          expect(
            camera.mediaRecorder!.state,
            equals('recording'),
          );
        });

        testWidgets('listens to the media recorder data events',
            (WidgetTester tester) async {
          final Camera camera = Camera(
            textureId: 1,
            cameraService: cameraService,
          )
            ..mediaRecorder = mediaRecorder
            ..isVideoTypeSupported = isVideoTypeSupported;

          await camera.initialize();
          await camera.play();

          await camera.startVideoRecording();

          verify(
            () => mediaRecorder.addEventListener('dataavailable', any()),
          ).called(1);
        });

        testWidgets('listens to the media recorder stop events',
            (WidgetTester tester) async {
          final Camera camera = Camera(
            textureId: 1,
            cameraService: cameraService,
          )
            ..mediaRecorder = mediaRecorder
            ..isVideoTypeSupported = isVideoTypeSupported;

          await camera.initialize();
          await camera.play();

          await camera.startVideoRecording();

          verify(
            () => mediaRecorder.addEventListener('stop', any()),
          ).called(1);
        });

        testWidgets('starts a video recording', (WidgetTester tester) async {
          final Camera camera = Camera(
            textureId: 1,
            cameraService: cameraService,
          )
            ..mediaRecorder = mediaRecorder
            ..isVideoTypeSupported = isVideoTypeSupported;

          await camera.initialize();
          await camera.play();

          await camera.startVideoRecording();

          verify(mediaRecorder.start).called(1);
        });

        testWidgets(
            'starts a video recording '
            'with maxVideoDuration', (WidgetTester tester) async {
          const Duration maxVideoDuration = Duration(hours: 1);

          final Camera camera = Camera(
            textureId: 1,
            cameraService: cameraService,
          )
            ..mediaRecorder = mediaRecorder
            ..isVideoTypeSupported = isVideoTypeSupported;

          await camera.initialize();
          await camera.play();

          await camera.startVideoRecording(maxVideoDuration: maxVideoDuration);

          verify(() => mediaRecorder.start(maxVideoDuration.inMilliseconds))
              .called(1);
        });

        group('throws a CameraWebException', () {
          testWidgets(
              'with notSupported error '
              'when maxVideoDuration is 0 milliseconds or less',
              (WidgetTester tester) async {
            final Camera camera = Camera(
              textureId: 1,
              cameraService: cameraService,
            )
              ..mediaRecorder = mediaRecorder
              ..isVideoTypeSupported = isVideoTypeSupported;

            await camera.initialize();
            await camera.play();

            expect(
              () => camera.startVideoRecording(maxVideoDuration: Duration.zero),
              throwsA(
                isA<CameraWebException>()
                    .having(
                      (CameraWebException e) => e.cameraId,
                      'cameraId',
                      textureId,
                    )
                    .having(
                      (CameraWebException e) => e.code,
                      'code',
                      CameraErrorCode.notSupported,
                    ),
              ),
            );
          });

          testWidgets(
              'with notSupported error '
              'when no video types are supported', (WidgetTester tester) async {
            final Camera camera = Camera(
              textureId: 1,
              cameraService: cameraService,
            )..isVideoTypeSupported = (String type) => false;

            await camera.initialize();
            await camera.play();

            expect(
              camera.startVideoRecording,
              throwsA(
                isA<CameraWebException>()
                    .having(
                      (CameraWebException e) => e.cameraId,
                      'cameraId',
                      textureId,
                    )
                    .having(
                      (CameraWebException e) => e.code,
                      'code',
                      CameraErrorCode.notSupported,
                    ),
              ),
            );
          });
        });
      });

      group('pauseVideoRecording', () {
        testWidgets('pauses a video recording', (WidgetTester tester) async {
          final Camera camera = Camera(
            textureId: 1,
            cameraService: cameraService,
          )..mediaRecorder = mediaRecorder;

          await camera.pauseVideoRecording();

          verify(mediaRecorder.pause).called(1);
        });

        testWidgets(
            'throws a CameraWebException '
            'with videoRecordingNotStarted error '
            'if the video recording was not started',
            (WidgetTester tester) async {
          final Camera camera = Camera(
            textureId: 1,
            cameraService: cameraService,
          );

          expect(
            camera.pauseVideoRecording,
            throwsA(
              isA<CameraWebException>()
                  .having(
                    (CameraWebException e) => e.cameraId,
                    'cameraId',
                    textureId,
                  )
                  .having(
                    (CameraWebException e) => e.code,
                    'code',
                    CameraErrorCode.videoRecordingNotStarted,
                  ),
            ),
          );
        });
      });

      group('resumeVideoRecording', () {
        testWidgets('resumes a video recording', (WidgetTester tester) async {
          final Camera camera = Camera(
            textureId: 1,
            cameraService: cameraService,
          )..mediaRecorder = mediaRecorder;

          await camera.resumeVideoRecording();

          verify(mediaRecorder.resume).called(1);
        });

        testWidgets(
            'throws a CameraWebException '
            'with videoRecordingNotStarted error '
            'if the video recording was not started',
            (WidgetTester tester) async {
          final Camera camera = Camera(
            textureId: 1,
            cameraService: cameraService,
          );

          expect(
            camera.resumeVideoRecording,
            throwsA(
              isA<CameraWebException>()
                  .having(
                    (CameraWebException e) => e.cameraId,
                    'cameraId',
                    textureId,
                  )
                  .having(
                    (CameraWebException e) => e.code,
                    'code',
                    CameraErrorCode.videoRecordingNotStarted,
                  ),
            ),
          );
        });
      });

      group('stopVideoRecording', () {
        testWidgets(
            'stops a video recording and '
            'returns the captured file '
            'based on all video data parts', (WidgetTester tester) async {
          final Camera camera = Camera(
            textureId: 1,
            cameraService: cameraService,
          )
            ..mediaRecorder = mediaRecorder
            ..isVideoTypeSupported = isVideoTypeSupported;

          await camera.initialize();
          await camera.play();

          late void Function(Event) videoDataAvailableListener;
          late void Function(Event) videoRecordingStoppedListener;

          when(
            () => mediaRecorder.addEventListener('dataavailable', any()),
          ).thenAnswer((Invocation invocation) {
            videoDataAvailableListener =
                invocation.positionalArguments[1] as void Function(Event);
          });

          when(
            () => mediaRecorder.addEventListener('stop', any()),
          ).thenAnswer((Invocation invocation) {
            videoRecordingStoppedListener =
                invocation.positionalArguments[1] as void Function(Event);
          });

          Blob? finalVideo;
          List<Blob>? videoParts;
          camera.blobBuilder = (List<Blob> blobs, String videoType) {
            videoParts = <Blob>[...blobs];
            finalVideo = Blob(blobs, videoType);
            return finalVideo!;
          };

          await camera.startVideoRecording();
          final Future<XFile> videoFileFuture = camera.stopVideoRecording();

          final Blob capturedVideoPartOne = Blob(<Object>[]);
          final Blob capturedVideoPartTwo = Blob(<Object>[]);

          final List<Blob> capturedVideoParts = <Blob>[
            capturedVideoPartOne,
            capturedVideoPartTwo,
          ];

          videoDataAvailableListener
            ..call(FakeBlobEvent(capturedVideoPartOne))
            ..call(FakeBlobEvent(capturedVideoPartTwo));

          videoRecordingStoppedListener.call(Event('stop'));

          final XFile videoFile = await videoFileFuture;

          verify(mediaRecorder.stop).called(1);

          expect(
            videoFile,
            isNotNull,
          );

          expect(
            videoFile.mimeType,
            equals(supportedVideoType),
          );

          expect(
            videoFile.name,
            equals(finalVideo.hashCode.toString()),
          );

          expect(
            videoParts,
            equals(capturedVideoParts),
          );
        });

        testWidgets(
            'throws a CameraWebException '
            'with videoRecordingNotStarted error '
            'if the video recording was not started',
            (WidgetTester tester) async {
          final Camera camera = Camera(
            textureId: 1,
            cameraService: cameraService,
          );

          expect(
            camera.stopVideoRecording,
            throwsA(
              isA<CameraWebException>()
                  .having(
                    (CameraWebException e) => e.cameraId,
                    'cameraId',
                    textureId,
                  )
                  .having(
                    (CameraWebException e) => e.code,
                    'code',
                    CameraErrorCode.videoRecordingNotStarted,
                  ),
            ),
          );
        });
      });

      group('on video data available', () {
        late void Function(Event) videoDataAvailableListener;

        setUp(() {
          when(
            () => mediaRecorder.addEventListener('dataavailable', any()),
          ).thenAnswer((Invocation invocation) {
            videoDataAvailableListener =
                invocation.positionalArguments[1] as void Function(Event);
          });
        });

        testWidgets(
            'stops a video recording '
            'if maxVideoDuration is given and '
            'the recording was not stopped manually',
            (WidgetTester tester) async {
          const Duration maxVideoDuration = Duration(hours: 1);

          final Camera camera = Camera(
            textureId: 1,
            cameraService: cameraService,
          )
            ..mediaRecorder = mediaRecorder
            ..isVideoTypeSupported = isVideoTypeSupported;

          await camera.initialize();
          await camera.play();
          await camera.startVideoRecording(maxVideoDuration: maxVideoDuration);

          when(() => mediaRecorder.state).thenReturn('recording');

          videoDataAvailableListener.call(FakeBlobEvent(Blob(<Object>[])));

          await Future<void>.microtask(() {});

          verify(mediaRecorder.stop).called(1);
        });
      });

      group('on video recording stopped', () {
        late void Function(Event) videoRecordingStoppedListener;

        setUp(() {
          when(
            () => mediaRecorder.addEventListener('stop', any()),
          ).thenAnswer((Invocation invocation) {
            videoRecordingStoppedListener =
                invocation.positionalArguments[1] as void Function(Event);
          });
        });

        testWidgets('stops listening to the media recorder data events',
            (WidgetTester tester) async {
          final Camera camera = Camera(
            textureId: 1,
            cameraService: cameraService,
          )
            ..mediaRecorder = mediaRecorder
            ..isVideoTypeSupported = isVideoTypeSupported;

          await camera.initialize();
          await camera.play();

          await camera.startVideoRecording();

          videoRecordingStoppedListener.call(Event('stop'));

          await Future<void>.microtask(() {});

          verify(
            () => mediaRecorder.removeEventListener('dataavailable', any()),
          ).called(1);
        });

        testWidgets('stops listening to the media recorder stop events',
            (WidgetTester tester) async {
          final Camera camera = Camera(
            textureId: 1,
            cameraService: cameraService,
          )
            ..mediaRecorder = mediaRecorder
            ..isVideoTypeSupported = isVideoTypeSupported;

          await camera.initialize();
          await camera.play();

          await camera.startVideoRecording();

          videoRecordingStoppedListener.call(Event('stop'));

          await Future<void>.microtask(() {});

          verify(
            () => mediaRecorder.removeEventListener('stop', any()),
          ).called(1);
        });

        testWidgets('stops listening to the media recorder errors',
            (WidgetTester tester) async {
          final StreamController<ErrorEvent> onErrorStreamController =
              StreamController<ErrorEvent>();

          final Camera camera = Camera(
            textureId: 1,
            cameraService: cameraService,
          )
            ..mediaRecorder = mediaRecorder
            ..isVideoTypeSupported = isVideoTypeSupported;

          when(() => mediaRecorder.onError)
              .thenAnswer((_) => onErrorStreamController.stream);

          await camera.initialize();
          await camera.play();

          await camera.startVideoRecording();

          videoRecordingStoppedListener.call(Event('stop'));

          await Future<void>.microtask(() {});

          expect(
            onErrorStreamController.hasListener,
            isFalse,
          );
        });
      });
    });

    group('dispose', () {
      testWidgets("resets the video element's source",
          (WidgetTester tester) async {
        final Camera camera = Camera(
          textureId: textureId,
          cameraService: cameraService,
        );

        await camera.initialize();
        await camera.dispose();

        expect(camera.videoElement.srcObject, isNull);
      });

      testWidgets('closes the onEnded stream', (WidgetTester tester) async {
        final Camera camera = Camera(
          textureId: textureId,
          cameraService: cameraService,
        );

        await camera.initialize();
        await camera.dispose();

        expect(
          camera.onEndedController.isClosed,
          isTrue,
        );
      });

      testWidgets('closes the onVideoRecordedEvent stream',
          (WidgetTester tester) async {
        final Camera camera = Camera(
          textureId: textureId,
          cameraService: cameraService,
        );

        await camera.initialize();
        await camera.dispose();

        expect(
          camera.videoRecorderController.isClosed,
          isTrue,
        );
      });

      testWidgets('closes the onVideoRecordingError stream',
          (WidgetTester tester) async {
        final Camera camera = Camera(
          textureId: textureId,
          cameraService: cameraService,
        );

        await camera.initialize();
        await camera.dispose();

        expect(
          camera.videoRecordingErrorController.isClosed,
          isTrue,
        );
      });
    });

    group('events', () {
      group('onVideoRecordedEvent', () {
        testWidgets(
            'emits a VideoRecordedEvent '
            'when a video recording is created', (WidgetTester tester) async {
          const Duration maxVideoDuration = Duration(hours: 1);
          const String supportedVideoType = 'video/webm';

          final MockMediaRecorder mediaRecorder = MockMediaRecorder();
          when(() => mediaRecorder.onError)
              .thenAnswer((_) => const Stream<Event>.empty());

          final Camera camera = Camera(
            textureId: 1,
            cameraService: cameraService,
          )
            ..mediaRecorder = mediaRecorder
            ..isVideoTypeSupported = (String type) => type == 'video/webm';

          await camera.initialize();
          await camera.play();

          late void Function(Event) videoDataAvailableListener;
          late void Function(Event) videoRecordingStoppedListener;

          when(
            () => mediaRecorder.addEventListener('dataavailable', any()),
          ).thenAnswer((Invocation invocation) {
            videoDataAvailableListener =
                invocation.positionalArguments[1] as void Function(Event);
          });

          when(
            () => mediaRecorder.addEventListener('stop', any()),
          ).thenAnswer((Invocation invocation) {
            videoRecordingStoppedListener =
                invocation.positionalArguments[1] as void Function(Event);
          });

          final StreamQueue<VideoRecordedEvent> streamQueue =
              StreamQueue<VideoRecordedEvent>(camera.onVideoRecordedEvent);

          await camera.startVideoRecording(maxVideoDuration: maxVideoDuration);

          Blob? finalVideo;
          camera.blobBuilder = (List<Blob> blobs, String videoType) {
            finalVideo = Blob(blobs, videoType);
            return finalVideo!;
          };

          videoDataAvailableListener.call(FakeBlobEvent(Blob(<Object>[])));
          videoRecordingStoppedListener.call(Event('stop'));

          expect(
            await streamQueue.next,
            equals(
              isA<VideoRecordedEvent>()
                  .having(
                    (VideoRecordedEvent e) => e.cameraId,
                    'cameraId',
                    textureId,
                  )
                  .having(
                    (VideoRecordedEvent e) => e.file,
                    'file',
                    isA<XFile>()
                        .having(
                          (XFile f) => f.mimeType,
                          'mimeType',
                          supportedVideoType,
                        )
                        .having(
                          (XFile f) => f.name,
                          'name',
                          finalVideo.hashCode.toString(),
                        ),
                  )
                  .having(
                    (VideoRecordedEvent e) => e.maxVideoDuration,
                    'maxVideoDuration',
                    maxVideoDuration,
                  ),
            ),
          );

          await streamQueue.cancel();
        });
      });

      group('onEnded', () {
        testWidgets(
            'emits the default video track '
            'when it emits an ended event', (WidgetTester tester) async {
          final Camera camera = Camera(
            textureId: textureId,
            cameraService: cameraService,
          );

          final StreamQueue<MediaStreamTrack> streamQueue =
              StreamQueue<MediaStreamTrack>(camera.onEnded);

          await camera.initialize();

          final List<MediaStreamTrack> videoTracks =
              camera.stream!.getVideoTracks();
          final MediaStreamTrack defaultVideoTrack = videoTracks.first;

          defaultVideoTrack.dispatchEvent(Event('ended'));

          expect(
            await streamQueue.next,
            equals(defaultVideoTrack),
          );

          await streamQueue.cancel();
        });

        testWidgets(
            'emits the default video track '
            'when the camera is stopped', (WidgetTester tester) async {
          final Camera camera = Camera(
            textureId: textureId,
            cameraService: cameraService,
          );

          final StreamQueue<MediaStreamTrack> streamQueue =
              StreamQueue<MediaStreamTrack>(camera.onEnded);

          await camera.initialize();

          final List<MediaStreamTrack> videoTracks =
              camera.stream!.getVideoTracks();
          final MediaStreamTrack defaultVideoTrack = videoTracks.first;

          camera.stop();

          expect(
            await streamQueue.next,
            equals(defaultVideoTrack),
          );

          await streamQueue.cancel();
        });
      });

      group('onVideoRecordingError', () {
        testWidgets(
            'emits an ErrorEvent '
            'when the media recorder fails '
            'when recording a video', (WidgetTester tester) async {
          final MockMediaRecorder mediaRecorder = MockMediaRecorder();
          final StreamController<ErrorEvent> errorController =
              StreamController<ErrorEvent>();

          final Camera camera = Camera(
            textureId: textureId,
            cameraService: cameraService,
          )..mediaRecorder = mediaRecorder;

          when(() => mediaRecorder.onError)
              .thenAnswer((_) => errorController.stream);

          final StreamQueue<ErrorEvent> streamQueue =
              StreamQueue<ErrorEvent>(camera.onVideoRecordingError);

          await camera.initialize();
          await camera.play();

          await camera.startVideoRecording();

          final ErrorEvent errorEvent = ErrorEvent('type');
          errorController.add(errorEvent);

          expect(
            await streamQueue.next,
            equals(errorEvent),
          );

          await streamQueue.cancel();
        });
      });
    });
  });
}
