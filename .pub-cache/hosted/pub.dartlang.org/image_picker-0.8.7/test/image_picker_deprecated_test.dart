// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: deprecated_member_use_from_same_package

// This file preserves the tests for the deprecated methods as they were before
// the migration. See image_picker_test.dart for the current tests.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'image_picker_test.mocks.dart' as base_mock;

// Add the mixin to make the platform interface accept the mock.
class MockImagePickerPlatform extends base_mock.MockImagePickerPlatform
    with MockPlatformInterfaceMixin {}

void main() {
  group('ImagePicker', () {
    late MockImagePickerPlatform mockPlatform;

    setUp(() {
      mockPlatform = MockImagePickerPlatform();
      ImagePickerPlatform.instance = mockPlatform;
    });

    group('#Single image/video', () {
      setUp(() {
        when(mockPlatform.pickImage(
                source: anyNamed('source'),
                maxWidth: anyNamed('maxWidth'),
                maxHeight: anyNamed('maxHeight'),
                imageQuality: anyNamed('imageQuality'),
                preferredCameraDevice: anyNamed('preferredCameraDevice')))
            .thenAnswer((Invocation _) async => null);
      });

      group('#pickImage', () {
        test('passes the image source argument correctly', () async {
          final ImagePicker picker = ImagePicker();
          await picker.getImage(source: ImageSource.camera);
          await picker.getImage(source: ImageSource.gallery);

          verifyInOrder(<Object>[
            mockPlatform.pickImage(source: ImageSource.camera),
            mockPlatform.pickImage(source: ImageSource.gallery),
          ]);
        });

        test('passes the width and height arguments correctly', () async {
          final ImagePicker picker = ImagePicker();
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
              source: ImageSource.camera, maxWidth: 10.0, imageQuality: 70);
          await picker.getImage(
              source: ImageSource.camera, maxHeight: 10.0, imageQuality: 70);
          await picker.getImage(
              source: ImageSource.camera,
              maxWidth: 10.0,
              maxHeight: 20.0,
              imageQuality: 70);

          verifyInOrder(<Object>[
            mockPlatform.pickImage(source: ImageSource.camera),
            mockPlatform.pickImage(source: ImageSource.camera, maxWidth: 10.0),
            mockPlatform.pickImage(source: ImageSource.camera, maxHeight: 10.0),
            mockPlatform.pickImage(
              source: ImageSource.camera,
              maxWidth: 10.0,
              maxHeight: 20.0,
            ),
            mockPlatform.pickImage(
              source: ImageSource.camera,
              maxWidth: 10.0,
              imageQuality: 70,
            ),
            mockPlatform.pickImage(
              source: ImageSource.camera,
              maxHeight: 10.0,
              imageQuality: 70,
            ),
            mockPlatform.pickImage(
              source: ImageSource.camera,
              maxWidth: 10.0,
              maxHeight: 20.0,
              imageQuality: 70,
            ),
          ]);
        });

        test('handles a null image file response gracefully', () async {
          final ImagePicker picker = ImagePicker();

          expect(await picker.getImage(source: ImageSource.gallery), isNull);
          expect(await picker.getImage(source: ImageSource.camera), isNull);
        });

        test('camera position defaults to back', () async {
          final ImagePicker picker = ImagePicker();
          await picker.getImage(source: ImageSource.camera);

          verify(mockPlatform.pickImage(source: ImageSource.camera));
        });

        test('camera position can set to front', () async {
          final ImagePicker picker = ImagePicker();
          await picker.getImage(
              source: ImageSource.camera,
              preferredCameraDevice: CameraDevice.front);

          verify(mockPlatform.pickImage(
              source: ImageSource.camera,
              preferredCameraDevice: CameraDevice.front));
        });
      });

      group('#pickVideo', () {
        setUp(() {
          when(mockPlatform.pickVideo(
                  source: anyNamed('source'),
                  preferredCameraDevice: anyNamed('preferredCameraDevice'),
                  maxDuration: anyNamed('maxDuration')))
              .thenAnswer((Invocation _) async => null);
        });

        test('passes the image source argument correctly', () async {
          final ImagePicker picker = ImagePicker();
          await picker.getVideo(source: ImageSource.camera);
          await picker.getVideo(source: ImageSource.gallery);

          verifyInOrder(<Object>[
            mockPlatform.pickVideo(source: ImageSource.camera),
            mockPlatform.pickVideo(source: ImageSource.gallery),
          ]);
        });

        test('passes the duration argument correctly', () async {
          final ImagePicker picker = ImagePicker();
          await picker.getVideo(source: ImageSource.camera);
          await picker.getVideo(
              source: ImageSource.camera,
              maxDuration: const Duration(seconds: 10));

          verifyInOrder(<Object>[
            mockPlatform.pickVideo(source: ImageSource.camera),
            mockPlatform.pickVideo(
              source: ImageSource.camera,
              maxDuration: const Duration(seconds: 10),
            ),
          ]);
        });

        test('handles a null video file response gracefully', () async {
          final ImagePicker picker = ImagePicker();

          expect(await picker.getVideo(source: ImageSource.gallery), isNull);
          expect(await picker.getVideo(source: ImageSource.camera), isNull);
        });

        test('camera position defaults to back', () async {
          final ImagePicker picker = ImagePicker();
          await picker.getVideo(source: ImageSource.camera);

          verify(mockPlatform.pickVideo(source: ImageSource.camera));
        });

        test('camera position can set to front', () async {
          final ImagePicker picker = ImagePicker();
          await picker.getVideo(
              source: ImageSource.camera,
              preferredCameraDevice: CameraDevice.front);

          verify(mockPlatform.pickVideo(
              source: ImageSource.camera,
              preferredCameraDevice: CameraDevice.front));
        });
      });

      group('#retrieveLostData', () {
        test('retrieveLostData get success response', () async {
          final ImagePicker picker = ImagePicker();
          when(mockPlatform.retrieveLostData()).thenAnswer(
              (Invocation _) async => LostData(
                  file: PickedFile('/example/path'), type: RetrieveType.image));

          final LostData response = await picker.getLostData();

          expect(response.type, RetrieveType.image);
          expect(response.file!.path, '/example/path');
        });

        test('retrieveLostData get error response', () async {
          final ImagePicker picker = ImagePicker();
          when(mockPlatform.retrieveLostData()).thenAnswer(
              (Invocation _) async => LostData(
                  exception: PlatformException(
                      code: 'test_error_code', message: 'test_error_message'),
                  type: RetrieveType.video));

          final LostData response = await picker.getLostData();

          expect(response.type, RetrieveType.video);
          expect(response.exception!.code, 'test_error_code');
          expect(response.exception!.message, 'test_error_message');
        });
      });
    });

    group('Multi images', () {
      setUp(() {
        when(mockPlatform.pickMultiImage(
                maxWidth: anyNamed('maxWidth'),
                maxHeight: anyNamed('maxHeight'),
                imageQuality: anyNamed('imageQuality')))
            .thenAnswer((Invocation _) async => null);
      });

      group('#pickMultiImage', () {
        test('passes the width and height arguments correctly', () async {
          final ImagePicker picker = ImagePicker();
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
              maxWidth: 10.0, maxHeight: 20.0, imageQuality: 70);

          verifyInOrder(<Object>[
            mockPlatform.pickMultiImage(),
            mockPlatform.pickMultiImage(maxWidth: 10.0),
            mockPlatform.pickMultiImage(maxHeight: 10.0),
            mockPlatform.pickMultiImage(maxWidth: 10.0, maxHeight: 20.0),
            mockPlatform.pickMultiImage(maxWidth: 10.0, imageQuality: 70),
            mockPlatform.pickMultiImage(maxHeight: 10.0, imageQuality: 70),
            mockPlatform.pickMultiImage(
              maxWidth: 10.0,
              maxHeight: 20.0,
              imageQuality: 70,
            ),
          ]);
        });

        test('handles a null image file response gracefully', () async {
          final ImagePicker picker = ImagePicker();

          expect(await picker.getMultiImage(), isNull);
          expect(await picker.getMultiImage(), isNull);
        });
      });
    });
  });
}
