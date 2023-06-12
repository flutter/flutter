// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/messages.g.dart',
  dartTestOut: 'test/test_api.g.dart',
  objcHeaderOut: 'ios/Classes/messages.g.h',
  objcSourceOut: 'ios/Classes/messages.g.m',
  objcOptions: ObjcOptions(
    prefix: 'FLT',
  ),
  copyrightHeader: 'pigeons/copyright.txt',
))
class MaxSize {
  MaxSize(this.width, this.height);
  double? width;
  double? height;
}

// Corresponds to `CameraDevice` from the platform interface package.
enum SourceCamera { rear, front }

// Corresponds to `ImageSource` from the platform interface package.
enum SourceType { camera, gallery }

class SourceSpecification {
  SourceSpecification(this.type, this.camera);
  SourceType type;
  SourceCamera? camera;
}

@HostApi(dartHostTestHandler: 'TestHostImagePickerApi')
abstract class ImagePickerApi {
  @async
  @ObjCSelector('pickImageWithSource:maxSize:quality:fullMetadata:')
  String? pickImage(SourceSpecification source, MaxSize maxSize,
      int? imageQuality, bool requestFullMetadata);
  @async
  @ObjCSelector('pickMultiImageWithMaxSize:quality:fullMetadata:')
  List<String>? pickMultiImage(
      MaxSize maxSize, int? imageQuality, bool requestFullMetadata);
  @async
  @ObjCSelector('pickVideoWithSource:maxDuration:')
  String? pickVideo(SourceSpecification source, int? maxDurationSeconds);
}
