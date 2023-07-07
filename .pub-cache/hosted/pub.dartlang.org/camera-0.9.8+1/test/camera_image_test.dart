// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(a14n): remove this import once Flutter 3.1 or later reaches stable (including flutter/flutter#104231)
// ignore: unnecessary_import
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('translates correctly from platform interface classes', () {
    final CameraImageData originalImage = CameraImageData(
      format: const CameraImageFormat(ImageFormatGroup.jpeg, raw: 1234),
      planes: <CameraImagePlane>[
        CameraImagePlane(
          bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
          bytesPerRow: 20,
          bytesPerPixel: 3,
          width: 200,
          height: 100,
        ),
        CameraImagePlane(
          bytes: Uint8List.fromList(<int>[5, 6, 7, 8]),
          bytesPerRow: 18,
          bytesPerPixel: 4,
          width: 220,
          height: 110,
        ),
      ],
      width: 640,
      height: 480,
      lensAperture: 2.5,
      sensorExposureTime: 5,
      sensorSensitivity: 1.3,
    );

    final CameraImage image = CameraImage.fromPlatformInterface(originalImage);
    // Simple values.
    expect(image.width, 640);
    expect(image.height, 480);
    expect(image.lensAperture, 2.5);
    expect(image.sensorExposureTime, 5);
    expect(image.sensorSensitivity, 1.3);
    // Format.
    expect(image.format.group, ImageFormatGroup.jpeg);
    expect(image.format.raw, 1234);
    // Planes.
    expect(image.planes.length, originalImage.planes.length);
    for (int i = 0; i < image.planes.length; i++) {
      expect(
          image.planes[i].bytes.length, originalImage.planes[i].bytes.length);
      for (int j = 0; j < image.planes[i].bytes.length; j++) {
        expect(image.planes[i].bytes[j], originalImage.planes[i].bytes[j]);
      }
      expect(
          image.planes[i].bytesPerPixel, originalImage.planes[i].bytesPerPixel);
      expect(image.planes[i].bytesPerRow, originalImage.planes[i].bytesPerRow);
      expect(image.planes[i].width, originalImage.planes[i].width);
      expect(image.planes[i].height, originalImage.planes[i].height);
    }
  });

  group('legacy constructors', () {
    test('$CameraImage can be created', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final CameraImage cameraImage =
          CameraImage.fromPlatformData(<dynamic, dynamic>{
        'format': 35,
        'height': 1,
        'width': 4,
        'lensAperture': 1.8,
        'sensorExposureTime': 9991324,
        'sensorSensitivity': 92.0,
        'planes': <dynamic>[
          <dynamic, dynamic>{
            'bytes': Uint8List.fromList(<int>[1, 2, 3, 4]),
            'bytesPerPixel': 1,
            'bytesPerRow': 4,
            'height': 1,
            'width': 4
          }
        ]
      });
      expect(cameraImage.height, 1);
      expect(cameraImage.width, 4);
      expect(cameraImage.format.group, ImageFormatGroup.yuv420);
      expect(cameraImage.planes.length, 1);
    });

    test('$CameraImage has ImageFormatGroup.yuv420 for iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final CameraImage cameraImage =
          CameraImage.fromPlatformData(<dynamic, dynamic>{
        'format': 875704438,
        'height': 1,
        'width': 4,
        'lensAperture': 1.8,
        'sensorExposureTime': 9991324,
        'sensorSensitivity': 92.0,
        'planes': <dynamic>[
          <dynamic, dynamic>{
            'bytes': Uint8List.fromList(<int>[1, 2, 3, 4]),
            'bytesPerPixel': 1,
            'bytesPerRow': 4,
            'height': 1,
            'width': 4
          }
        ]
      });
      expect(cameraImage.format.group, ImageFormatGroup.yuv420);
    });

    test('$CameraImage has ImageFormatGroup.yuv420 for Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final CameraImage cameraImage =
          CameraImage.fromPlatformData(<dynamic, dynamic>{
        'format': 35,
        'height': 1,
        'width': 4,
        'lensAperture': 1.8,
        'sensorExposureTime': 9991324,
        'sensorSensitivity': 92.0,
        'planes': <dynamic>[
          <dynamic, dynamic>{
            'bytes': Uint8List.fromList(<int>[1, 2, 3, 4]),
            'bytesPerPixel': 1,
            'bytesPerRow': 4,
            'height': 1,
            'width': 4
          }
        ]
      });
      expect(cameraImage.format.group, ImageFormatGroup.yuv420);
    });

    test('$CameraImage has ImageFormatGroup.bgra8888 for iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final CameraImage cameraImage =
          CameraImage.fromPlatformData(<dynamic, dynamic>{
        'format': 1111970369,
        'height': 1,
        'width': 4,
        'lensAperture': 1.8,
        'sensorExposureTime': 9991324,
        'sensorSensitivity': 92.0,
        'planes': <dynamic>[
          <dynamic, dynamic>{
            'bytes': Uint8List.fromList(<int>[1, 2, 3, 4]),
            'bytesPerPixel': 1,
            'bytesPerRow': 4,
            'height': 1,
            'width': 4
          }
        ]
      });
      expect(cameraImage.format.group, ImageFormatGroup.bgra8888);
    });
    test('$CameraImage has ImageFormatGroup.unknown', () {
      final CameraImage cameraImage =
          CameraImage.fromPlatformData(<dynamic, dynamic>{
        'format': null,
        'height': 1,
        'width': 4,
        'lensAperture': 1.8,
        'sensorExposureTime': 9991324,
        'sensorSensitivity': 92.0,
        'planes': <dynamic>[
          <dynamic, dynamic>{
            'bytes': Uint8List.fromList(<int>[1, 2, 3, 4]),
            'bytesPerPixel': 1,
            'bytesPerRow': 4,
            'height': 1,
            'width': 4
          }
        ]
      });
      expect(cameraImage.format.group, ImageFormatGroup.unknown);
    });
  });
}
