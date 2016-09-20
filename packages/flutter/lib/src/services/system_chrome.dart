// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_services/platform/system_chrome.dart' as mojom;
import 'package:flutter_services/platform/system_chrome.dart'
    show DeviceOrientation, SystemUiOverlay, SystemUiOverlayStyle;

import 'shell.dart';

export 'package:flutter_services/platform/system_chrome.dart'
    show DeviceOrientation, SystemUiOverlay, SystemUiOverlayStyle;

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
  static Future<bool> setPreferredOrientations(int deviceOrientationMask) {
    Completer<bool> completer = new Completer<bool>();
    _systemChromeProxy.setPreferredOrientations(deviceOrientationMask, (bool success) {
      completer.complete(success);
    });
    return completer.future;
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
  static Future<bool> setApplicationSwitcherDescription(mojom.ApplicationSwitcherDescription description) {
    Completer<bool> completer = new Completer<bool>();
    _systemChromeProxy.setApplicationSwitcherDescription(description, (bool success) {
      completer.complete(success);
    });
    return completer.future;
  }

  /// Specifies the set of overlays visible on the embedder when the
  /// application is running. The embedder may choose to ignore unsupported
  /// overlays
  ///
  /// Arguments:
  ///
  ///  * [overlaysMask]: A mask of [SystemUiOverlay] enum values that denotes
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
  static Future<bool> setEnabledSystemUIOverlays(int overlaysMask) {
    Completer<bool> completer = new Completer<bool>();
    _systemChromeProxy.setEnabledSystemUiOverlays(overlaysMask, (bool success) {
      completer.complete(success);
    });
    return completer.future;
 }

  /// Specifies the style of the system overlays that are visible on the
  /// embedder (if any). The embedder may choose to ignore unsupported
  /// overlays.
  ///
  /// This method will schedule the embedder update to be run in a microtask.
  /// Any subsequent calls to this method during the current event loop will
  /// overwrite the pending value to be set on the embedder.
  static void setSystemUIOverlayStyle(SystemUiOverlayStyle style) {
    assert(style != null);

    if (_pendingStyle != null) {
      // The microtask has already been queued; just update the pending value.
      _pendingStyle = style;
      return;
    }

    if (style == _latestStyle) {
      // Trivial success; no need to queue a microtask.
      return;
    }

    _pendingStyle = style;
    scheduleMicrotask(() {
      assert(_pendingStyle != null);
      if (_pendingStyle != _latestStyle) {
        _systemChromeProxy.setSystemUiOverlayStyle(_pendingStyle, (bool success) {
          // Ignored.
        });
        _latestStyle = _pendingStyle;
      }
      _pendingStyle = null;
    });
  }

  static SystemUiOverlayStyle _pendingStyle;
  static SystemUiOverlayStyle _latestStyle;
}
