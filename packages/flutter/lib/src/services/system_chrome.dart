// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:sky_services/flutter/platform/system_chrome.mojom.dart' as mojom;
import 'package:sky_services/flutter/platform/system_chrome.mojom.dart';

import 'shell.dart';

export 'package:sky_services/flutter/platform/system_chrome.mojom.dart' show DeviceOrientation;

mojom.SystemChromeProxy _initSystemChromeProxy() {
  return shell.connectToApplicationService('mojo:flutter_platform', mojom.SystemChrome.connectToService);
}

final mojom.SystemChromeProxy _systemChromeProxy = _initSystemChromeProxy();

/// Controls specific aspects of the embedder interface.
class SystemChrome {
  SystemChrome._();

  /// Specifies the set of orientations the application interface can
  /// be displayed in.
  ///
  /// Arguments:
  ///
  ///  * [deviceOrientationMask]: A mask of [DeviceOrientation] enum values.
  ///    The value 0 is synonymous with having all options enabled.
  ///
  /// Return Value:
  ///
  ///   boolean indicating if the orientation mask is valid and the changes
  ///   could be conveyed successfully to the embedder.
  static Future<bool> setPreferredOrientations(int deviceOrientationMask) async {
    return (await _systemChromeProxy.setPreferredOrientations(deviceOrientationMask)).success;
  }

  /// Specifies the description of the current state of the application as it
  /// pertains to the application switcher (a.k.a "recent tasks").
  ///
  /// Arguments:
  ///
  ///  * [description]: The application description.
  ///
  /// Return Value:
  ///
  ///   boolean indicating if the description was conveyed successfully to the
  ///   embedder.
  ///
  /// Platform Specific Notes:
  ///
  ///   If application-specified metadata is unsupported on the platform,
  ///   specifying it is a no-op and always return true.
  static Future<bool> setApplicationSwitcherDescription(mojom.ApplicationSwitcherDescription description) async {
    return (await _systemChromeProxy.setApplicationSwitcherDescription(
      description)).success;
  }

  /// Specifies the set of overlays visible on the embedder when the
  /// application is running. The embedder may choose to ignore unsupported
  /// overlays
  ///
  /// Arguments:
  ///
  ///  * [overlaysMask]: A mask of [SystemUIOverlay] enum values that denotes
  ///    the overlays to show.
  ///
  /// Return Value:
  ///
  ///   boolean indicating if the preference was conveyed successfully to the
  ///   embedder.
  ///
  /// Platform Specific Notes:
  ///
  ///   If the overlay is unsupported on the platform, enabling or disabling
  ///   that overlay is a no-op and always return true.
  static Future<bool> setEnabledSystemUIOverlays(int overlaysMask) async {
    return (await _systemChromeProxy.setEnabledSystemUiOverlays(
      overlaysMask)).success;
  }

  /// Specifies the style of the system overlays that are visible on the
  /// embedder (if any). The embedder may choose to ignore unsupported
  /// overlays.
  ///
  /// This method will schedule the embedder update to be run in a microtask.
  /// Any subsequent calls to this method during the current event loop will
  /// overwrite the pending value to be set on the embedder.
  ///
  /// The return value indicates both the preference that was eventually
  /// conveyed to the embedder, along with whether it was successfully
  /// conveyed.
  static Future<SystemUiOverlayStyleUpdate> setSystemUIOverlayStyle(SystemUiOverlayStyle style) {
    assert(style != null);

    if (_pendingStyleUpdate != null) {
      _pendingStyleUpdate.style = style;
      return _pendingStyleUpdate.future;
    }

    _pendingStyleUpdate = new _PendingStyleUpdate(style);
    scheduleMicrotask(() {
      assert(_pendingStyleUpdate != null);
      if (_pendingStyleUpdate.style == _latestStyle) {
        // No update needed; trivial success.
        _pendingStyleUpdate.complete(success: true);
        _pendingStyleUpdate = null;
        return;
      }

      _PendingStyleUpdate update = _pendingStyleUpdate;
      _systemChromeProxy.setSystemUiOverlayStyle(update.style)
        .then((SystemChromeSetSystemUiOverlayStyleResponseParams value) {
          update.complete(success: value.success);
        }, onError: () {
          update.complete(success: false);
        });
      _latestStyle = _pendingStyleUpdate.style;
      _pendingStyleUpdate = null;
    });

    return _pendingStyleUpdate.future;
  }

  static _PendingStyleUpdate _pendingStyleUpdate;
  static SystemUiOverlayStyle _latestStyle;
}

/// Struct that represents an attempted update to the system overlays that are
/// visible on the embedder.
class SystemUiOverlayStyleUpdate {
  const SystemUiOverlayStyleUpdate._({
    @required this.style,
    @required this.success
  });

  /// The style that was passed to the embedder.
  final SystemUiOverlayStyle style;

  /// Whether the preference was successfully conveyed to the embedder.
  final bool success;
}

class _PendingStyleUpdate {
  _PendingStyleUpdate(this.style);

  final Completer<SystemUiOverlayStyleUpdate> _completer =
    new Completer<SystemUiOverlayStyleUpdate>();
  SystemUiOverlayStyle style;

  Future<SystemUiOverlayStyleUpdate> get future => _completer.future;

  void complete({@required bool success}) {
    _completer.complete(new SystemUiOverlayStyleUpdate._(
      style: style,
      success: success
    ));
  }
}
