// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:async';

import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import 'src/messages.g.dart';

// Converts an [ImageSource] to the corresponding Pigeon API enum value.
SourceType _convertSource(ImageSource source) {
  switch (source) {
    case ImageSource.camera:
      return SourceType.camera;
    case ImageSource.gallery:
      return SourceType.gallery;
  }
  // The enum comes from a different package, which could get a new value at
  // any time, so a fallback case is necessary. Since there is no reasonable
  // default behavior, throw to alert the client that they need an updated
  // version. This is deliberately outside the switch rather than a `default`
  // so that the linter will flag the switch as needing an update.
  // ignore: dead_code
  throw UnimplementedError('Unknown source: $source');
}

// Converts a [CameraDevice] to the corresponding Pigeon API enum value.
SourceCamera _convertCamera(CameraDevice camera) {
  switch (camera) {
    case CameraDevice.front:
      return SourceCamera.front;
    case CameraDevice.rear:
      return SourceCamera.rear;
  }
  // The enum comes from a different package, which could get a new value at
  // any time, so a fallback case is necessary. Since there is no reasonable
  // default behavior, throw to alert the client that they need an updated
  // version. This is deliberately outside the switch rather than a `default`
  // so that the linter will flag the switch as needing an update.
  // ignore: dead_code
  throw UnimplementedError('Unknown camera: $camera');
}

/// An implementation of [ImagePickerPlatform] for iOS.
class ImagePickerIOS extends ImagePickerPlatform {
  final ImagePickerApi _hostApi = ImagePickerApi();

  /// Registers this class as the default platform implementation.
  static void registerWith() {
    ImagePickerPlatform.instance = ImagePickerIOS();
  }

  @override
  Future<PickedFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    final String? path = await _pickImageAsPath(
      source: source,
      options: ImagePickerOptions(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        preferredCameraDevice: preferredCameraDevice,
      ),
    );
    return path != null ? PickedFile(path) : null;
  }

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    final String? path = await _pickImageAsPath(
      source: source,
      options: options,
    );
    return path != null ? XFile(path) : null;
  }

  @override
  Future<List<PickedFile>?> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    final List<dynamic>? paths = await _pickMultiImageAsPath(
      options: MultiImagePickerOptions(
        imageOptions: ImageOptions(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: imageQuality,
        ),
      ),
    );
    if (paths == null) {
      return null;
    }

    return paths.map((dynamic path) => PickedFile(path as String)).toList();
  }

  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async {
    final List<String>? paths = await _pickMultiImageAsPath(options: options);
    if (paths == null) {
      return <XFile>[];
    }

    return paths.map((String path) => XFile(path)).toList();
  }

  Future<List<String>?> _pickMultiImageAsPath({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async {
    final int? imageQuality = options.imageOptions.imageQuality;
    if (imageQuality != null && (imageQuality < 0 || imageQuality > 100)) {
      throw ArgumentError.value(
          imageQuality, 'imageQuality', 'must be between 0 and 100');
    }

    final double? maxWidth = options.imageOptions.maxWidth;
    if (maxWidth != null && maxWidth < 0) {
      throw ArgumentError.value(maxWidth, 'maxWidth', 'cannot be negative');
    }

    final double? maxHeight = options.imageOptions.maxHeight;
    if (maxHeight != null && maxHeight < 0) {
      throw ArgumentError.value(maxHeight, 'maxHeight', 'cannot be negative');
    }

    // TODO(stuartmorgan): Remove the cast once Pigeon supports non-nullable
    //  generics, https://github.com/flutter/flutter/issues/97848
    return (await _hostApi.pickMultiImage(
            MaxSize(width: maxWidth, height: maxHeight),
            imageQuality,
            options.imageOptions.requestFullMetadata))
        ?.cast<String>();
  }

  Future<String?> _pickImageAsPath({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) {
    final int? imageQuality = options.imageQuality;
    if (imageQuality != null && (imageQuality < 0 || imageQuality > 100)) {
      throw ArgumentError.value(
          imageQuality, 'imageQuality', 'must be between 0 and 100');
    }

    final double? maxHeight = options.maxHeight;
    final double? maxWidth = options.maxWidth;
    if (maxWidth != null && maxWidth < 0) {
      throw ArgumentError.value(maxWidth, 'maxWidth', 'cannot be negative');
    }

    if (maxHeight != null && maxHeight < 0) {
      throw ArgumentError.value(maxHeight, 'maxHeight', 'cannot be negative');
    }

    return _hostApi.pickImage(
      SourceSpecification(
        type: _convertSource(source),
        camera: _convertCamera(options.preferredCameraDevice),
      ),
      MaxSize(width: maxWidth, height: maxHeight),
      imageQuality,
      options.requestFullMetadata,
    );
  }

  @override
  Future<PickedFile?> pickVideo({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
  }) async {
    final String? path = await _pickVideoAsPath(
      source: source,
      maxDuration: maxDuration,
      preferredCameraDevice: preferredCameraDevice,
    );
    return path != null ? PickedFile(path) : null;
  }

  Future<String?> _pickVideoAsPath({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
  }) {
    return _hostApi.pickVideo(
        SourceSpecification(
            type: _convertSource(source),
            camera: _convertCamera(preferredCameraDevice)),
        maxDuration?.inSeconds);
  }

  @override
  Future<XFile?> getImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    final String? path = await _pickImageAsPath(
      source: source,
      options: ImagePickerOptions(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        preferredCameraDevice: preferredCameraDevice,
      ),
    );
    return path != null ? XFile(path) : null;
  }

  @override
  Future<List<XFile>?> getMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    final List<String>? paths = await _pickMultiImageAsPath(
      options: MultiImagePickerOptions(
        imageOptions: ImageOptions(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: imageQuality,
        ),
      ),
    );
    if (paths == null) {
      return null;
    }

    return paths.map((String path) => XFile(path)).toList();
  }

  @override
  Future<XFile?> getVideo({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
  }) async {
    final String? path = await _pickVideoAsPath(
      source: source,
      maxDuration: maxDuration,
      preferredCameraDevice: preferredCameraDevice,
    );
    return path != null ? XFile(path) : null;
  }
}
