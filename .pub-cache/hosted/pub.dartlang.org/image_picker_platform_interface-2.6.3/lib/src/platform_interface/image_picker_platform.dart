// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../method_channel/method_channel_image_picker.dart';
import '../types/types.dart';

/// The interface that implementations of image_picker must implement.
///
/// Platform implementations should extend this class rather than implement it as `image_picker`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [ImagePickerPlatform] methods.
abstract class ImagePickerPlatform extends PlatformInterface {
  /// Constructs a ImagePickerPlatform.
  ImagePickerPlatform() : super(token: _token);

  static final Object _token = Object();

  static ImagePickerPlatform _instance = MethodChannelImagePicker();

  /// The default instance of [ImagePickerPlatform] to use.
  ///
  /// Defaults to [MethodChannelImagePicker].
  static ImagePickerPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [ImagePickerPlatform] when they register themselves.
  // TODO(amirh): Extract common platform interface logic.
  // https://github.com/flutter/flutter/issues/43368
  static set instance(ImagePickerPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  // Next version of the API.

  /// Returns a [PickedFile] with the image that was picked.
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
  ///
  /// The `imageQuality` argument modifies the quality of the image, ranging from 0-100
  /// where 100 is the original/max quality. If `imageQuality` is null, the image with
  /// the original quality will be returned. Compression is only supported for certain
  /// image types such as JPEG. If compression is not supported for the image that is picked,
  /// a warning message will be logged.
  ///
  /// Use `preferredCameraDevice` to specify the camera to use when the `source` is [ImageSource.camera].
  /// The `preferredCameraDevice` is ignored when `source` is [ImageSource.gallery]. It is also ignored if the chosen camera is not supported on the device.
  /// Defaults to [CameraDevice.rear]. Note that Android has no documented parameter for an intent to specify if
  /// the front or rear camera should be opened, this function is not guaranteed
  /// to work on an Android device.
  ///
  /// In Android, the MainActivity can be destroyed for various reasons. If that happens, the result will be lost
  /// in this call. You can then call [retrieveLostData] when your app relaunches to retrieve the lost data.
  ///
  /// If no images were picked, the return value is null.
  Future<PickedFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) {
    throw UnimplementedError('pickImage() has not been implemented.');
  }

  /// Returns a [List<PickedFile>] with the images that were picked.
  ///
  /// The images come from the [ImageSource.gallery].
  ///
  /// Where iOS supports HEIC images, Android 8 and below doesn't. Android 9 and above only support HEIC images if used
  /// in addition to a size modification, of which the usage is explained below.
  ///
  /// If specified, the image will be at most `maxWidth` wide and
  /// `maxHeight` tall. Otherwise the image will be returned at it's
  /// original width and height.
  ///
  /// The `imageQuality` argument modifies the quality of the images, ranging from 0-100
  /// where 100 is the original/max quality. If `imageQuality` is null, the images with
  /// the original quality will be returned. Compression is only supported for certain
  /// image types such as JPEG. If compression is not supported for the image that is picked,
  /// a warning message will be logged.
  ///
  /// If no images were picked, the return value is null.
  Future<List<PickedFile>?> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) {
    throw UnimplementedError('pickMultiImage() has not been implemented.');
  }

  /// Returns a [PickedFile] containing the video that was picked.
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
  /// If no images were picked, the return value is null.
  Future<PickedFile?> pickVideo({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
  }) {
    throw UnimplementedError('pickVideo() has not been implemented.');
  }

  /// Retrieves any previously picked file, that was lost due to the MainActivity being destroyed.
  /// In case multiple files were lost, only the last file will be recovered. (Android only).
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
  Future<LostData> retrieveLostData() {
    throw UnimplementedError('retrieveLostData() has not been implemented.');
  }

  /// This method is deprecated in favor of [getImageFromSource] and will be removed in a future update.
  ///
  /// Returns an [XFile] with the image that was picked.
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
  ///
  /// The `imageQuality` argument modifies the quality of the image, ranging from 0-100
  /// where 100 is the original/max quality. If `imageQuality` is null, the image with
  /// the original quality will be returned. Compression is only supported for certain
  /// image types such as JPEG. If compression is not supported for the image that is picked,
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
  /// If no images were picked, the return value is null.
  Future<XFile?> getImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) {
    throw UnimplementedError('getImage() has not been implemented.');
  }

  /// This method is deprecated in favor of [getMultiImageWithOptions] and will be removed in a future update.
  ///
  /// Returns a [List<XFile>] with the images that were picked.
  ///
  /// The images come from the [ImageSource.gallery].
  ///
  /// Where iOS supports HEIC images, Android 8 and below doesn't. Android 9 and above only support HEIC images if used
  /// in addition to a size modification, of which the usage is explained below.
  ///
  /// If specified, the image will be at most `maxWidth` wide and
  /// `maxHeight` tall. Otherwise the image will be returned at it's
  /// original width and height.
  ///
  /// The `imageQuality` argument modifies the quality of the images, ranging from 0-100
  /// where 100 is the original/max quality. If `imageQuality` is null, the images with
  /// the original quality will be returned. Compression is only supported for certain
  /// image types such as JPEG. If compression is not supported for the image that is picked,
  /// a warning message will be logged.
  ///
  /// If no images were picked, the return value is null.
  Future<List<XFile>?> getMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) {
    throw UnimplementedError('getMultiImage() has not been implemented.');
  }

  /// Returns a [XFile] containing the video that was picked.
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
  /// If no images were picked, the return value is null.
  Future<XFile?> getVideo({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
  }) {
    throw UnimplementedError('getVideo() has not been implemented.');
  }

  /// Retrieves any previously picked files, that were lost due to the MainActivity being destroyed. (Android only)
  ///
  /// Image or video can be lost if the MainActivity is destroyed. And there is no guarantee that the MainActivity is
  /// always alive. Call this method to retrieve the lost data and process the data according to your APP's business logic.
  ///
  /// Returns a [LostDataResponse] object if successfully retrieved the lost data. The [LostDataResponse] object can
  /// represent either a successful image/video selection, or a failure.
  ///
  /// Calling this on a non-Android platform will throw [UnimplementedError] exception.
  ///
  /// See also:
  /// * [LostDataResponse], for what's included in the response.
  /// * [Android Activity Lifecycle](https://developer.android.com/reference/android/app/Activity.html), for more
  ///   information on MainActivity destruction.
  Future<LostDataResponse> getLostData() {
    throw UnimplementedError('getLostData() has not been implemented.');
  }

  /// Returns an [XFile] with the image that was picked.
  ///
  /// The `source` argument controls where the image comes from. This can
  /// be either [ImageSource.camera] or [ImageSource.gallery].
  ///
  /// The `options` argument controls additional settings that can be used when
  /// picking an image. See [ImagePickerOptions] for more details.
  ///
  /// Where iOS supports HEIC images, Android 8 and below doesn't. Android 9 and
  /// above only support HEIC images if used in addition to a size modification,
  /// of which the usage is explained in [ImagePickerOptions].
  ///
  /// In Android, the MainActivity can be destroyed for various reasons. If that
  /// happens, the result will be lost in this call. You can then call [getLostData]
  /// when your app relaunches to retrieve the lost data.
  ///
  /// If no images were picked, the return value is null.
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) {
    return getImage(
      source: source,
      maxHeight: options.maxHeight,
      maxWidth: options.maxWidth,
      imageQuality: options.imageQuality,
      preferredCameraDevice: options.preferredCameraDevice,
    );
  }

  /// Returns a [List<XFile>] with the images that were picked.
  ///
  /// The images come from the [ImageSource.gallery].
  ///
  /// The `options` argument controls additional settings that can be used when
  /// picking an image. See [MultiImagePickerOptions] for more details.
  ///
  /// If no images were picked, returns an empty list.
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async {
    final List<XFile>? pickedImages = await getMultiImage(
      maxWidth: options.imageOptions.maxWidth,
      maxHeight: options.imageOptions.maxHeight,
      imageQuality: options.imageOptions.imageQuality,
    );
    return pickedImages ?? <XFile>[];
  }
}
