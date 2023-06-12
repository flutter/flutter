// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

export 'package:image_picker_platform_interface/image_picker_platform_interface.dart'
    show
        kTypeImage,
        kTypeVideo,
        ImageSource,
        CameraDevice,
        LostData,
        LostDataResponse,
        PickedFile,
        XFile,
        RetrieveType;

/// Provides an easy way to pick an image/video from the image library,
/// or to take a picture/video with the camera.
class ImagePicker {
  /// The platform interface that drives this plugin
  @visibleForTesting
  static ImagePickerPlatform get platform => ImagePickerPlatform.instance;

  /// Returns a [PickedFile] object wrapping the image that was picked.
  ///
  /// The returned [PickedFile] is intended to be used within a single APP session. Do not save the file path and use it across sessions.
  ///
  /// The `source` argument controls where the image comes from. This can
  /// be either [ImageSource.camera] or [ImageSource.gallery].
  ///
  /// Where iOS supports HEIC images, Android 8 and below doesn't. Android 9 and above only support HEIC images if used
  /// in addition to a size modification, of which the usage is explained below.
  ///
  /// If specified, the image will be at most `maxWidth` wide and
  /// `maxHeight` tall. Otherwise the image will be returned at it's
  /// original width and height.
  /// The `imageQuality` argument modifies the quality of the image, ranging from 0-100
  /// where 100 is the original/max quality. If `imageQuality` is null, the image with
  /// the original quality will be returned. Compression is only supported for certain
  /// image types such as JPEG and on Android PNG and WebP, too. If compression is not supported for the image that is picked,
  /// a warning message will be logged.
  ///
  /// Use `preferredCameraDevice` to specify the camera to use when the `source` is [ImageSource.camera].
  /// The `preferredCameraDevice` is ignored when `source` is [ImageSource.gallery]. It is also ignored if the chosen camera is not supported on the device.
  /// Defaults to [CameraDevice.rear]. Note that Android has no documented parameter for an intent to specify if
  /// the front or rear camera should be opened, this function is not guaranteed
  /// to work on an Android device.
  ///
  /// In Android, the MainActivity can be destroyed for various reasons. If that happens, the result will be lost
  /// in this call. You can then call [getLostData] when your app relaunches to retrieve the lost data.
  ///
  /// See also [getMultiImage] to allow users to select multiple images at once.
  ///
  /// The method could throw [PlatformException] if the app does not have permission to access
  /// the camera or photos gallery, no camera is available, plugin is already in use,
  /// temporary file could not be created (iOS only), plugin activity could not
  /// be allocated (Android only) or due to an unknown error.
  @Deprecated('Switch to using pickImage instead')
  Future<PickedFile?> getImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) {
    return platform.pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
      preferredCameraDevice: preferredCameraDevice,
    );
  }

  /// Returns a [List<PickedFile>] object wrapping the images that were picked.
  ///
  /// The returned [List<PickedFile>] is intended to be used within a single APP session. Do not save the file path and use it across sessions.
  ///
  /// Where iOS supports HEIC images, Android 8 and below doesn't. Android 9 and above only support HEIC images if used
  /// in addition to a size modification, of which the usage is explained below.
  ///
  /// This method is not supported in iOS versions lower than 14.
  ///
  /// If specified, the images will be at most `maxWidth` wide and
  /// `maxHeight` tall. Otherwise the images will be returned at it's
  /// original width and height.
  /// The `imageQuality` argument modifies the quality of the images, ranging from 0-100
  /// where 100 is the original/max quality. If `imageQuality` is null, the images with
  /// the original quality will be returned. Compression is only supported for certain
  /// image types such as JPEG and on Android PNG and WebP, too. If compression is not supported for the image that is picked,
  /// a warning message will be logged.
  ///
  /// The method could throw [PlatformException] if the app does not have permission to access
  /// the camera or photos gallery, no camera is available, plugin is already in use,
  /// temporary file could not be created (iOS only), plugin activity could not
  /// be allocated (Android only) or due to an unknown error.
  ///
  /// See also [getImage] to allow users to only pick a single image.
  @Deprecated('Switch to using pickMultiImage instead')
  Future<List<PickedFile>?> getMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) {
    return platform.pickMultiImage(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }

  /// Returns a [PickedFile] object wrapping the video that was picked.
  ///
  /// The returned [PickedFile] is intended to be used within a single APP session. Do not save the file path and use it across sessions.
  ///
  /// The [source] argument controls where the video comes from. This can
  /// be either [ImageSource.camera] or [ImageSource.gallery].
  ///
  /// The [maxDuration] argument specifies the maximum duration of the captured video. If no [maxDuration] is specified,
  /// the maximum duration will be infinite.
  ///
  /// Use `preferredCameraDevice` to specify the camera to use when the `source` is [ImageSource.camera].
  /// The `preferredCameraDevice` is ignored when `source` is [ImageSource.gallery]. It is also ignored if the chosen camera is not supported on the device.
  /// Defaults to [CameraDevice.rear].
  ///
  /// In Android, the MainActivity can be destroyed for various fo reasons. If that happens, the result will be lost
  /// in this call. You can then call [getLostData] when your app relaunches to retrieve the lost data.
  ///
  /// The method could throw [PlatformException] if the app does not have permission to access
  /// the camera or photos gallery, no camera is available, plugin is already in use,
  /// temporary file could not be created and video could not be cached (iOS only),
  /// plugin activity could not be allocated (Android only) or due to an unknown error.
  ///
  @Deprecated('Switch to using pickVideo instead')
  Future<PickedFile?> getVideo({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
  }) {
    return platform.pickVideo(
      source: source,
      preferredCameraDevice: preferredCameraDevice,
      maxDuration: maxDuration,
    );
  }

  /// Retrieve the lost [PickedFile] when [selectImage] or [selectVideo] failed because the  MainActivity is destroyed. (Android only)
  ///
  /// Image or video can be lost if the MainActivity is destroyed. And there is no guarantee that the MainActivity is always alive.
  /// Call this method to retrieve the lost data and process the data according to your APP's business logic.
  ///
  /// Returns a [LostData] object if successfully retrieved the lost data. The [LostData] object can represent either a
  /// successful image/video selection, or a failure.
  ///
  /// Calling this on a non-Android platform will throw [UnimplementedError] exception.
  ///
  /// See also:
  /// * [LostData], for what's included in the response.
  /// * [Android Activity Lifecycle](https://developer.android.com/reference/android/app/Activity.html), for more information on MainActivity destruction.
  @Deprecated('Switch to using retrieveLostData instead')
  Future<LostData> getLostData() {
    return platform.retrieveLostData();
  }

  /// Returns an [XFile] object wrapping the image that was picked.
  ///
  /// The returned [XFile] is intended to be used within a single APP session. Do not save the file path and use it across sessions.
  ///
  /// The `source` argument controls where the image comes from. This can
  /// be either [ImageSource.camera] or [ImageSource.gallery].
  ///
  /// Where iOS supports HEIC images, Android 8 and below doesn't. Android 9 and
  /// above only support HEIC images if used in addition to a size modification,
  /// of which the usage is explained below.
  ///
  /// If specified, the image will be at most `maxWidth` wide and
  /// `maxHeight` tall. Otherwise the image will be returned at it's
  /// original width and height.
  /// The `imageQuality` argument modifies the quality of the image, ranging from 0-100
  /// where 100 is the original/max quality. If `imageQuality` is null, the image with
  /// the original quality will be returned. Compression is only supported for certain
  /// image types such as JPEG and on Android PNG and WebP, too. If compression is not
  /// supported for the image that is picked, a warning message will be logged.
  ///
  /// Use `preferredCameraDevice` to specify the camera to use when the `source` is
  /// [ImageSource.camera].
  /// The `preferredCameraDevice` is ignored when `source` is [ImageSource.gallery].
  /// It is also ignored if the chosen camera is not supported on the device.
  /// Defaults to [CameraDevice.rear]. Note that Android has no documented parameter
  /// for an intent to specify if the front or rear camera should be opened, this
  /// function is not guaranteed to work on an Android device.
  ///
  /// Use `requestFullMetadata` (defaults to `true`) to control how much additional
  /// information the plugin tries to get.
  /// If `requestFullMetadata` is set to `true`, the plugin tries to get the full
  /// image metadata which may require extra permission requests on some platforms,
  /// such as `Photo Library Usage` permission on iOS.
  ///
  /// In Android, the MainActivity can be destroyed for various reasons. If that happens, the result will be lost
  /// in this call. You can then call [retrieveLostData] when your app relaunches to retrieve the lost data.
  ///
  /// See also [pickMultiImage] to allow users to select multiple images at once.
  ///
  /// The method could throw [PlatformException] if the app does not have permission to access
  /// the camera or photos gallery, no camera is available, plugin is already in use,
  /// temporary file could not be created (iOS only), plugin activity could not
  /// be allocated (Android only) or due to an unknown error.
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) {
    if (imageQuality != null && (imageQuality < 0 || imageQuality > 100)) {
      throw ArgumentError.value(
          imageQuality, 'imageQuality', 'must be between 0 and 100');
    }
    if (maxWidth != null && maxWidth < 0) {
      throw ArgumentError.value(maxWidth, 'maxWidth', 'cannot be negative');
    }
    if (maxHeight != null && maxHeight < 0) {
      throw ArgumentError.value(maxHeight, 'maxHeight', 'cannot be negative');
    }

    return platform.getImageFromSource(
      source: source,
      options: ImagePickerOptions(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        preferredCameraDevice: preferredCameraDevice,
        requestFullMetadata: requestFullMetadata,
      ),
    );
  }

  /// Returns a [List<XFile>] object wrapping the images that were picked.
  ///
  /// The returned [List<XFile>] is intended to be used within a single APP session. Do not save the file path and use it across sessions.
  ///
  /// Where iOS supports HEIC images, Android 8 and below doesn't. Android 9 and above only support HEIC images if used
  /// in addition to a size modification, of which the usage is explained below.
  ///
  /// This method is not supported in iOS versions lower than 14.
  ///
  /// If specified, the images will be at most `maxWidth` wide and
  /// `maxHeight` tall. Otherwise the images will be returned at it's
  /// original width and height.
  ///
  /// The `imageQuality` argument modifies the quality of the images, ranging from 0-100
  /// where 100 is the original/max quality. If `imageQuality` is null, the images with
  /// the original quality will be returned. Compression is only supported for certain
  /// image types such as JPEG and on Android PNG and WebP, too. If compression is not
  /// supported for the image that is picked, a warning message will be logged.
  ///
  /// Use `requestFullMetadata` (defaults to `true`) to control how much additional
  /// information the plugin tries to get.
  /// If `requestFullMetadata` is set to `true`, the plugin tries to get the full
  /// image metadata which may require extra permission requests on some platforms,
  /// such as `Photo Library Usage` permission on iOS.
  ///
  /// The method could throw [PlatformException] if the app does not have permission to access
  /// the camera or photos gallery, no camera is available, plugin is already in use,
  /// temporary file could not be created (iOS only), plugin activity could not
  /// be allocated (Android only) or due to an unknown error.
  ///
  /// See also [pickImage] to allow users to only pick a single image.
  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    bool requestFullMetadata = true,
  }) {
    if (imageQuality != null && (imageQuality < 0 || imageQuality > 100)) {
      throw ArgumentError.value(
          imageQuality, 'imageQuality', 'must be between 0 and 100');
    }
    if (maxWidth != null && maxWidth < 0) {
      throw ArgumentError.value(maxWidth, 'maxWidth', 'cannot be negative');
    }
    if (maxHeight != null && maxHeight < 0) {
      throw ArgumentError.value(maxHeight, 'maxHeight', 'cannot be negative');
    }

    return platform.getMultiImageWithOptions(
      options: MultiImagePickerOptions(
        imageOptions: ImageOptions(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: imageQuality,
          requestFullMetadata: requestFullMetadata,
        ),
      ),
    );
  }

  /// Returns an [XFile] object wrapping the video that was picked.
  ///
  /// The returned [XFile] is intended to be used within a single APP session. Do not save the file path and use it across sessions.
  ///
  /// The [source] argument controls where the video comes from. This can
  /// be either [ImageSource.camera] or [ImageSource.gallery].
  ///
  /// The [maxDuration] argument specifies the maximum duration of the captured video. If no [maxDuration] is specified,
  /// the maximum duration will be infinite.
  ///
  /// Use `preferredCameraDevice` to specify the camera to use when the `source` is [ImageSource.camera].
  /// The `preferredCameraDevice` is ignored when `source` is [ImageSource.gallery]. It is also ignored if the chosen camera is not supported on the device.
  /// Defaults to [CameraDevice.rear].
  ///
  /// In Android, the MainActivity can be destroyed for various fo reasons. If that happens, the result will be lost
  /// in this call. You can then call [retrieveLostData] when your app relaunches to retrieve the lost data.
  ///
  /// The method could throw [PlatformException] if the app does not have permission to access
  /// the camera or photos gallery, no camera is available, plugin is already in use,
  /// temporary file could not be created and video could not be cached (iOS only),
  /// plugin activity could not be allocated (Android only) or due to an unknown error.
  ///
  Future<XFile?> pickVideo({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
  }) {
    return platform.getVideo(
      source: source,
      preferredCameraDevice: preferredCameraDevice,
      maxDuration: maxDuration,
    );
  }

  /// Retrieve the lost [XFile] when [pickImage], [pickMultiImage] or [pickVideo] failed because the MainActivity
  /// is destroyed. (Android only)
  ///
  /// Image or video can be lost if the MainActivity is destroyed. And there is no guarantee that the MainActivity is always alive.
  /// Call this method to retrieve the lost data and process the data according to your APP's business logic.
  ///
  /// Returns a [LostDataResponse] object if successfully retrieved the lost data. The [LostDataResponse] object can \
  /// represent either a successful image/video selection, or a failure.
  ///
  /// Calling this on a non-Android platform will throw [UnimplementedError] exception.
  ///
  /// See also:
  /// * [LostDataResponse], for what's included in the response.
  /// * [Android Activity Lifecycle](https://developer.android.com/reference/android/app/Activity.html), for more information on MainActivity destruction.
  Future<LostDataResponse> retrieveLostData() {
    return platform.getLostData();
  }
}
