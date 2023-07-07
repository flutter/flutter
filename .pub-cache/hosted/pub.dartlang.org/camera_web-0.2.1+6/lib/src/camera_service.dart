// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'dart:ui';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:camera_web/src/camera.dart';
import 'package:camera_web/src/shims/dart_js_util.dart';
import 'package:camera_web/src/types/types.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A service to fetch, map camera settings and
/// obtain the camera stream.
class CameraService {
  // A facing mode constraint name.
  static const String _facingModeKey = 'facingMode';

  /// The current browser window used to access media devices.
  @visibleForTesting
  html.Window? window = html.window;

  /// The utility to manipulate JavaScript interop objects.
  @visibleForTesting
  JsUtil jsUtil = JsUtil();

  /// Returns a media stream associated with the camera device
  /// with [cameraId] and constrained by [options].
  Future<html.MediaStream> getMediaStreamForOptions(
    CameraOptions options, {
    int cameraId = 0,
  }) async {
    final html.MediaDevices? mediaDevices = window?.navigator.mediaDevices;

    // Throw a not supported exception if the current browser window
    // does not support any media devices.
    if (mediaDevices == null) {
      throw PlatformException(
        code: CameraErrorCode.notSupported.toString(),
        message: 'The camera is not supported on this device.',
      );
    }

    try {
      final Map<String, dynamic> constraints = options.toJson();
      return await mediaDevices.getUserMedia(constraints);
    } on html.DomException catch (e) {
      switch (e.name) {
        case 'NotFoundError':
        case 'DevicesNotFoundError':
          throw CameraWebException(
            cameraId,
            CameraErrorCode.notFound,
            'No camera found for the given camera options.',
          );
        case 'NotReadableError':
        case 'TrackStartError':
          throw CameraWebException(
            cameraId,
            CameraErrorCode.notReadable,
            'The camera is not readable due to a hardware error '
            'that prevented access to the device.',
          );
        case 'OverconstrainedError':
        case 'ConstraintNotSatisfiedError':
          throw CameraWebException(
            cameraId,
            CameraErrorCode.overconstrained,
            'The camera options are impossible to satisfy.',
          );
        case 'NotAllowedError':
        case 'PermissionDeniedError':
          throw CameraWebException(
            cameraId,
            CameraErrorCode.permissionDenied,
            'The camera cannot be used or the permission '
            'to access the camera is not granted.',
          );
        case 'TypeError':
          throw CameraWebException(
            cameraId,
            CameraErrorCode.type,
            'The camera options are incorrect or attempted '
            'to access the media input from an insecure context.',
          );
        case 'AbortError':
          throw CameraWebException(
            cameraId,
            CameraErrorCode.abort,
            'Some problem occurred that prevented the camera from being used.',
          );
        case 'SecurityError':
          throw CameraWebException(
            cameraId,
            CameraErrorCode.security,
            'The user media support is disabled in the current browser.',
          );
        default:
          throw CameraWebException(
            cameraId,
            CameraErrorCode.unknown,
            'An unknown error occured when fetching the camera stream.',
          );
      }
    } catch (_) {
      throw CameraWebException(
        cameraId,
        CameraErrorCode.unknown,
        'An unknown error occured when fetching the camera stream.',
      );
    }
  }

  /// Returns the zoom level capability for the given [camera].
  ///
  /// Throws a [CameraWebException] if the zoom level is not supported
  /// or the camera has not been initialized or started.
  ZoomLevelCapability getZoomLevelCapabilityForCamera(
    Camera camera,
  ) {
    final html.MediaDevices? mediaDevices = window?.navigator.mediaDevices;
    final Map<dynamic, dynamic>? supportedConstraints =
        mediaDevices?.getSupportedConstraints();
    final bool zoomLevelSupported =
        supportedConstraints?[ZoomLevelCapability.constraintName] as bool? ??
            false;

    if (!zoomLevelSupported) {
      throw CameraWebException(
        camera.textureId,
        CameraErrorCode.zoomLevelNotSupported,
        'The zoom level is not supported in the current browser.',
      );
    }

    final List<html.MediaStreamTrack> videoTracks =
        camera.stream?.getVideoTracks() ?? <html.MediaStreamTrack>[];

    if (videoTracks.isNotEmpty) {
      final html.MediaStreamTrack defaultVideoTrack = videoTracks.first;

      /// The zoom level capability is represented by MediaSettingsRange.
      /// See: https://developer.mozilla.org/en-US/docs/Web/API/MediaSettingsRange
      final Object zoomLevelCapability = defaultVideoTrack
                  .getCapabilities()[ZoomLevelCapability.constraintName]
              as Object? ??
          <dynamic, dynamic>{};

      // The zoom level capability is a nested JS object, therefore
      // we need to access its properties with the js_util library.
      // See: https://api.dart.dev/stable/2.13.4/dart-js_util/getProperty.html
      final num? minimumZoomLevel =
          jsUtil.getProperty(zoomLevelCapability, 'min') as num?;
      final num? maximumZoomLevel =
          jsUtil.getProperty(zoomLevelCapability, 'max') as num?;

      if (minimumZoomLevel != null && maximumZoomLevel != null) {
        return ZoomLevelCapability(
          minimum: minimumZoomLevel.toDouble(),
          maximum: maximumZoomLevel.toDouble(),
          videoTrack: defaultVideoTrack,
        );
      } else {
        throw CameraWebException(
          camera.textureId,
          CameraErrorCode.zoomLevelNotSupported,
          'The zoom level is not supported by the current camera.',
        );
      }
    } else {
      throw CameraWebException(
        camera.textureId,
        CameraErrorCode.notStarted,
        'The camera has not been initialized or started.',
      );
    }
  }

  /// Returns a facing mode of the [videoTrack]
  /// (null if the facing mode is not available).
  String? getFacingModeForVideoTrack(html.MediaStreamTrack videoTrack) {
    final html.MediaDevices? mediaDevices = window?.navigator.mediaDevices;

    // Throw a not supported exception if the current browser window
    // does not support any media devices.
    if (mediaDevices == null) {
      throw PlatformException(
        code: CameraErrorCode.notSupported.toString(),
        message: 'The camera is not supported on this device.',
      );
    }

    // Check if the camera facing mode is supported by the current browser.
    final Map<dynamic, dynamic> supportedConstraints =
        mediaDevices.getSupportedConstraints();
    final bool facingModeSupported =
        supportedConstraints[_facingModeKey] as bool? ?? false;

    // Return null if the facing mode is not supported.
    if (!facingModeSupported) {
      return null;
    }

    // Extract the facing mode from the video track settings.
    // The property may not be available if it's not supported
    // by the browser or not available due to context.
    //
    // MediaTrackSettings:
    // https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings
    final Map<dynamic, dynamic> videoTrackSettings = videoTrack.getSettings();
    final String? facingMode = videoTrackSettings[_facingModeKey] as String?;

    if (facingMode == null) {
      // If the facing mode does not exist in the video track settings,
      // check for the facing mode in the video track capabilities.
      //
      // MediaTrackCapabilities:
      // https://www.w3.org/TR/mediacapture-streams/#dom-mediatrackcapabilities

      // Check if getting the video track capabilities is supported.
      //
      // The method may not be supported on Firefox.
      // See: https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamTrack/getCapabilities#browser_compatibility
      if (!jsUtil.hasProperty(videoTrack, 'getCapabilities')) {
        // Return null if the video track capabilites are not supported.
        return null;
      }

      final Map<dynamic, dynamic> videoTrackCapabilities =
          videoTrack.getCapabilities();

      // A list of facing mode capabilities as
      // the camera may support multiple facing modes.
      final List<String> facingModeCapabilities = List<String>.from(
          (videoTrackCapabilities[_facingModeKey] as List<dynamic>?)
                  ?.cast<String>() ??
              <String>[]);

      if (facingModeCapabilities.isNotEmpty) {
        final String facingModeCapability = facingModeCapabilities.first;
        return facingModeCapability;
      } else {
        // Return null if there are no facing mode capabilities.
        return null;
      }
    }

    return facingMode;
  }

  /// Maps the given [facingMode] to [CameraLensDirection].
  ///
  /// The following values for the facing mode are supported:
  /// https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings/facingMode
  CameraLensDirection mapFacingModeToLensDirection(String facingMode) {
    switch (facingMode) {
      case 'user':
        return CameraLensDirection.front;
      case 'environment':
        return CameraLensDirection.back;
      case 'left':
      case 'right':
      default:
        return CameraLensDirection.external;
    }
  }

  /// Maps the given [facingMode] to [CameraType].
  ///
  /// See [CameraMetadata.facingMode] for more details.
  CameraType mapFacingModeToCameraType(String facingMode) {
    switch (facingMode) {
      case 'user':
        return CameraType.user;
      case 'environment':
        return CameraType.environment;
      case 'left':
      case 'right':
      default:
        return CameraType.user;
    }
  }

  /// Maps the given [resolutionPreset] to [Size].
  Size mapResolutionPresetToSize(ResolutionPreset resolutionPreset) {
    switch (resolutionPreset) {
      case ResolutionPreset.max:
      case ResolutionPreset.ultraHigh:
        return const Size(4096, 2160);
      case ResolutionPreset.veryHigh:
        return const Size(1920, 1080);
      case ResolutionPreset.high:
        return const Size(1280, 720);
      case ResolutionPreset.medium:
        return const Size(720, 480);
      case ResolutionPreset.low:
      default:
        return const Size(320, 240);
    }
  }

  /// Maps the given [deviceOrientation] to [OrientationType].
  String mapDeviceOrientationToOrientationType(
    DeviceOrientation deviceOrientation,
  ) {
    switch (deviceOrientation) {
      case DeviceOrientation.portraitUp:
        return OrientationType.portraitPrimary;
      case DeviceOrientation.landscapeLeft:
        return OrientationType.landscapePrimary;
      case DeviceOrientation.portraitDown:
        return OrientationType.portraitSecondary;
      case DeviceOrientation.landscapeRight:
        return OrientationType.landscapeSecondary;
    }
  }

  /// Maps the given [orientationType] to [DeviceOrientation].
  DeviceOrientation mapOrientationTypeToDeviceOrientation(
    String orientationType,
  ) {
    switch (orientationType) {
      case OrientationType.portraitPrimary:
        return DeviceOrientation.portraitUp;
      case OrientationType.landscapePrimary:
        return DeviceOrientation.landscapeLeft;
      case OrientationType.portraitSecondary:
        return DeviceOrientation.portraitDown;
      case OrientationType.landscapeSecondary:
        return DeviceOrientation.landscapeRight;
      default:
        return DeviceOrientation.portraitUp;
    }
  }
}
