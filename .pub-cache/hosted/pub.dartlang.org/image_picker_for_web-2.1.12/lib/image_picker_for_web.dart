// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import 'src/image_resizer.dart';

const String _kImagePickerInputsDomId = '__image_picker_web-file-input';
const String _kAcceptImageMimeType = 'image/*';
const String _kAcceptVideoMimeType = 'video/3gpp,video/x-m4v,video/mp4,video/*';

/// The web implementation of [ImagePickerPlatform].
///
/// This class implements the `package:image_picker` functionality for the web.
class ImagePickerPlugin extends ImagePickerPlatform {
  /// A constructor that allows tests to override the function that creates file inputs.
  ImagePickerPlugin({
    @visibleForTesting ImagePickerPluginTestOverrides? overrides,
    @visibleForTesting ImageResizer? imageResizer,
  }) : _overrides = overrides {
    _imageResizer = imageResizer ?? ImageResizer();
    _target = _ensureInitialized(_kImagePickerInputsDomId);
  }

  final ImagePickerPluginTestOverrides? _overrides;

  bool get _hasOverrides => _overrides != null;

  late html.Element _target;

  late ImageResizer _imageResizer;

  /// Registers this class as the default instance of [ImagePickerPlatform].
  static void registerWith(Registrar registrar) {
    ImagePickerPlatform.instance = ImagePickerPlugin();
  }

  /// Returns a [PickedFile] with the image that was picked.
  ///
  /// The `source` argument controls where the image comes from. This can
  /// be either [ImageSource.camera] or [ImageSource.gallery].
  ///
  /// Note that the `maxWidth`, `maxHeight` and `imageQuality` arguments are not supported on the web. If any of these arguments is supplied, it'll be silently ignored by the web version of the plugin.
  ///
  /// Use `preferredCameraDevice` to specify the camera to use when the `source` is [ImageSource.camera].
  /// The `preferredCameraDevice` is ignored when `source` is [ImageSource.gallery]. It is also ignored if the chosen camera is not supported on the device.
  /// Defaults to [CameraDevice.rear].
  ///
  /// If no images were picked, the return value is null.
  @override
  Future<PickedFile> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) {
    final String? capture =
        computeCaptureAttribute(source, preferredCameraDevice);
    return pickFile(accept: _kAcceptImageMimeType, capture: capture);
  }

  /// Returns a [PickedFile] containing the video that was picked.
  ///
  /// The [source] argument controls where the video comes from. This can
  /// be either [ImageSource.camera] or [ImageSource.gallery].
  ///
  /// Note that the `maxDuration` argument is not supported on the web. If the argument is supplied, it'll be silently ignored by the web version of the plugin.
  ///
  /// Use `preferredCameraDevice` to specify the camera to use when the `source` is [ImageSource.camera].
  /// The `preferredCameraDevice` is ignored when `source` is [ImageSource.gallery]. It is also ignored if the chosen camera is not supported on the device.
  /// Defaults to [CameraDevice.rear].
  ///
  /// If no images were picked, the return value is null.
  @override
  Future<PickedFile> pickVideo({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
  }) {
    final String? capture =
        computeCaptureAttribute(source, preferredCameraDevice);
    return pickFile(accept: _kAcceptVideoMimeType, capture: capture);
  }

  /// Injects a file input with the specified accept+capture attributes, and
  /// returns the PickedFile that the user selected locally.
  ///
  /// `capture` is only supported in mobile browsers.
  /// See https://caniuse.com/#feat=html-media-capture
  @visibleForTesting
  Future<PickedFile> pickFile({
    String? accept,
    String? capture,
  }) {
    final html.FileUploadInputElement input =
        createInputElement(accept, capture) as html.FileUploadInputElement;
    _injectAndActivate(input);
    return _getSelectedFile(input);
  }

  /// Returns an [XFile] with the image that was picked.
  ///
  /// The `source` argument controls where the image comes from. This can
  /// be either [ImageSource.camera] or [ImageSource.gallery].
  ///
  /// Note that the `maxWidth`, `maxHeight` and `imageQuality` arguments are not supported on the web. If any of these arguments is supplied, it'll be silently ignored by the web version of the plugin.
  ///
  /// Use `preferredCameraDevice` to specify the camera to use when the `source` is [ImageSource.camera].
  /// The `preferredCameraDevice` is ignored when `source` is [ImageSource.gallery]. It is also ignored if the chosen camera is not supported on the device.
  /// Defaults to [CameraDevice.rear].
  ///
  /// If no images were picked, the return value is null.
  @override
  Future<XFile> getImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    final String? capture =
        computeCaptureAttribute(source, preferredCameraDevice);
    final List<XFile> files = await getFiles(
      accept: _kAcceptImageMimeType,
      capture: capture,
    );
    return _imageResizer.resizeImageIfNeeded(
      files.first,
      maxWidth,
      maxHeight,
      imageQuality,
    );
  }

  /// Returns an [XFile] containing the video that was picked.
  ///
  /// The [source] argument controls where the video comes from. This can
  /// be either [ImageSource.camera] or [ImageSource.gallery].
  ///
  /// Note that the `maxDuration` argument is not supported on the web. If the argument is supplied, it'll be silently ignored by the web version of the plugin.
  ///
  /// Use `preferredCameraDevice` to specify the camera to use when the `source` is [ImageSource.camera].
  /// The `preferredCameraDevice` is ignored when `source` is [ImageSource.gallery]. It is also ignored if the chosen camera is not supported on the device.
  /// Defaults to [CameraDevice.rear].
  ///
  /// If no images were picked, the return value is null.
  @override
  Future<XFile> getVideo({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
  }) async {
    final String? capture =
        computeCaptureAttribute(source, preferredCameraDevice);
    final List<XFile> files = await getFiles(
      accept: _kAcceptVideoMimeType,
      capture: capture,
    );
    return files.first;
  }

  /// Injects a file input, and returns a list of XFile that the user selected locally.
  @override
  Future<List<XFile>> getMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    final List<XFile> images = await getFiles(
      accept: _kAcceptImageMimeType,
      multiple: true,
    );
    final Iterable<Future<XFile>> resized = images.map(
      (XFile image) => _imageResizer.resizeImageIfNeeded(
        image,
        maxWidth,
        maxHeight,
        imageQuality,
      ),
    );

    return Future.wait<XFile>(resized);
  }

  /// Injects a file input with the specified accept+capture attributes, and
  /// returns a list of XFile that the user selected locally.
  ///
  /// `capture` is only supported in mobile browsers.
  ///
  /// `multiple` can be passed to allow for multiple selection of files. Defaults
  /// to false.
  ///
  /// See https://caniuse.com/#feat=html-media-capture
  @visibleForTesting
  Future<List<XFile>> getFiles({
    String? accept,
    String? capture,
    bool multiple = false,
  }) {
    final html.FileUploadInputElement input = createInputElement(
      accept,
      capture,
      multiple: multiple,
    ) as html.FileUploadInputElement;
    _injectAndActivate(input);

    return _getSelectedXFiles(input);
  }

  // DOM methods

  /// Converts plugin configuration into a proper value for the `capture` attribute.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/file#capture
  @visibleForTesting
  String? computeCaptureAttribute(ImageSource source, CameraDevice device) {
    if (source == ImageSource.camera) {
      return (device == CameraDevice.front) ? 'user' : 'environment';
    }
    return null;
  }

  List<html.File>? _getFilesFromInput(html.FileUploadInputElement input) {
    if (_hasOverrides) {
      return _overrides!.getMultipleFilesFromInput(input);
    }
    return input.files;
  }

  /// Handles the OnChange event from a FileUploadInputElement object
  /// Returns a list of selected files.
  List<html.File>? _handleOnChangeEvent(html.Event event) {
    final html.FileUploadInputElement? input =
        event.target as html.FileUploadInputElement?;
    return input == null ? null : _getFilesFromInput(input);
  }

  /// Monitors an <input type="file"> and returns the selected file.
  Future<PickedFile> _getSelectedFile(html.FileUploadInputElement input) {
    final Completer<PickedFile> completer = Completer<PickedFile>();
    // Observe the input until we can return something
    input.onChange.first.then((html.Event event) {
      final List<html.File>? files = _handleOnChangeEvent(event);
      if (!completer.isCompleted && files != null) {
        completer.complete(PickedFile(
          html.Url.createObjectUrl(files.first),
        ));
      }
    });
    input.onError.first.then((html.Event event) {
      if (!completer.isCompleted) {
        completer.completeError(event);
      }
    });
    // Note that we don't bother detaching from these streams, since the
    // "input" gets re-created in the DOM every time the user needs to
    // pick a file.
    return completer.future;
  }

  /// Monitors an <input type="file"> and returns the selected file(s).
  Future<List<XFile>> _getSelectedXFiles(html.FileUploadInputElement input) {
    final Completer<List<XFile>> completer = Completer<List<XFile>>();
    // Observe the input until we can return something
    input.onChange.first.then((html.Event event) {
      final List<html.File>? files = _handleOnChangeEvent(event);
      if (!completer.isCompleted && files != null) {
        completer.complete(files.map((html.File file) {
          return XFile(
            html.Url.createObjectUrl(file),
            name: file.name,
            length: file.size,
            lastModified: DateTime.fromMillisecondsSinceEpoch(
              file.lastModified ?? DateTime.now().millisecondsSinceEpoch,
            ),
            mimeType: file.type,
          );
        }).toList());
      }
    });
    input.onError.first.then((html.Event event) {
      if (!completer.isCompleted) {
        completer.completeError(event);
      }
    });
    // Note that we don't bother detaching from these streams, since the
    // "input" gets re-created in the DOM every time the user needs to
    // pick a file.
    return completer.future;
  }

  /// Initializes a DOM container where we can host input elements.
  html.Element _ensureInitialized(String id) {
    html.Element? target = html.querySelector('#$id');
    if (target == null) {
      final html.Element targetElement =
          html.Element.tag('flt-image-picker-inputs')..id = id;

      html.querySelector('body')!.children.add(targetElement);
      target = targetElement;
    }
    return target;
  }

  /// Creates an input element that accepts certain file types, and
  /// allows to `capture` from the device's cameras (where supported)
  @visibleForTesting
  html.Element createInputElement(
    String? accept,
    String? capture, {
    bool multiple = false,
  }) {
    if (_hasOverrides) {
      return _overrides!.createInputElement(accept, capture);
    }

    final html.Element element = html.FileUploadInputElement()
      ..accept = accept
      ..multiple = multiple;

    if (capture != null) {
      element.setAttribute('capture', capture);
    }

    return element;
  }

  /// Injects the file input element, and clicks on it
  void _injectAndActivate(html.Element element) {
    _target.children.clear();
    _target.children.add(element);
    element.click();
  }
}

// Some tools to override behavior for unit-testing
/// A function that creates a file input with the passed in `accept` and `capture` attributes.
@visibleForTesting
typedef OverrideCreateInputFunction = html.Element Function(
  String? accept,
  String? capture,
);

/// A function that extracts list of files from the file `input` passed in.
@visibleForTesting
typedef OverrideExtractMultipleFilesFromInputFunction = List<html.File>
    Function(html.Element? input);

/// Overrides for some of the functionality above.
@visibleForTesting
class ImagePickerPluginTestOverrides {
  /// Override the creation of the input element.
  late OverrideCreateInputFunction createInputElement;

  /// Override the extraction of the selected files from an input element.
  late OverrideExtractMultipleFilesFromInputFunction getMultipleFilesFromInput;
}
