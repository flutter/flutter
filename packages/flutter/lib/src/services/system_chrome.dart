// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'platform_messages.dart';

/// Specifies a particular device orientation.
///
/// Discussion:
///
/// To determine which values correspond to which orientations, first position
/// the device in its default orientation (this is the orientation that the
/// system first uses for its boot logo, or the orientation in which the
/// hardware logos or markings are upright, or the orientation in which the
/// cameras are at the top). If this is a portrait orientation, then this is
/// [portraitUp]. Otherwise, it's [landscapeLeft]. As you rotate the device by 90
/// degrees in a counter-clockwise direction around the axis that traverses the
/// screen, you step through each value in this enum in the order given. (For a
/// device with a landscape default orientation, the orientation obtained by
/// rotating the device 90 degrees clockwise from its default orientation is
/// [portraitUp].)
enum DeviceOrientation {
  /// If the device shows its boot logo in portrait, then the boot logo is shown
  /// in [portraitUp]. Otherwise, the device shows its boot logo in landscape
  /// and this orientation is obtained by rotating the device 90 degrees
  /// clockwise from its boot orientation.
  portraitUp,

  /// The orientation that is 90 degrees clockwise from [portraitUp].
  landscapeLeft,

  /// The orientation that is 180 degrees from [portraitUp].
  portraitDown,

  /// The orientation that is 90 degrees counterclockwise from [portraitUp].
  landscapeRight,
}

/// Specifies a description of the application that is pertinent to the
/// embedder's application switcher (a.k.a. "recent tasks") user interface.
class ApplicationSwitcherDescription {
  /// Creates an ApplicationSwitcherDescription.
  const ApplicationSwitcherDescription({ this.label, this.primaryColor });

  /// A label and description of the current state of the application.
  final String label;

  /// The application's primary color.
  final int primaryColor;
}

/// Specifies a system overlay at a particular location. Certain platforms
/// may not use all overlays specified here.
enum SystemUiOverlay {
  /// The status bar provided by the embedder on the top of the application
  /// surface (optional)
  top,

  /// The status bar provided by the embedder on the bottom of the application
  /// surface (optional)
  bottom,
}

/// Specifies a preference for the style of the system overlays. Certain
/// platforms may not respect this preference.
enum SystemUiOverlayStyle {
  /// System overlays should be drawn with a light color. Intended for
  /// applications with a dark background.
  light,

  /// System overlays should be drawn with a dark color. Intended for
  /// applications with a light background.
  dark,
}

List<String> _stringify(List<dynamic> list) {
  List<String> result = <String>[];
  for (dynamic item in list)
    result.add(item.toString());
  return result;
}

/// Controls specific aspects of the embedder interface.
class SystemChrome {
  SystemChrome._();

  /// Specifies the set of orientations the application interface can
  /// be displayed in.
  ///
  /// Arguments:
  ///
  ///  * [orientation]: A list of [DeviceOrientation] enum values. The empty
  ///    list is synonymous with having all options enabled.
  static Future<Null> setPreferredOrientations(List<DeviceOrientation> orientations) async {
    await PlatformMessages.sendJSON('flutter/platform', <String, dynamic>{
      'method': 'SystemChrome.setPreferredOrientations',
      'args': <List<String>>[ _stringify(orientations) ],
    });
  }

  /// Specifies the description of the current state of the application as it
  /// pertains to the application switcher (a.k.a "recent tasks").
  ///
  /// Arguments:
  ///
  ///  * [description]: The application description.
  ///
  /// Platform Specific Notes:
  ///
  ///   If application-specified metadata is unsupported on the platform,
  ///   specifying it is a no-op and always return true.
  static Future<Null> setApplicationSwitcherDescription(ApplicationSwitcherDescription description) async {
    await PlatformMessages.sendJSON('flutter/platform', <String, dynamic>{
      'method': 'SystemChrome.setApplicationSwitcherDescription',
      'args': <Map<String, dynamic>>[<String, dynamic>{
        'label': description.label,
        'primaryColor': description.primaryColor,
      }],
    });
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
  /// Platform Specific Notes:
  ///
  ///   If the overlay is unsupported on the platform, enabling or disabling
  ///   that overlay is a no-op and always return true.
  static Future<Null> setEnabledSystemUIOverlays(List<SystemUiOverlay> overlays) async {
    await PlatformMessages.sendJSON('flutter/platform', <String, dynamic>{
      'method': 'SystemChrome.setEnabledSystemUIOverlays',
      'args': <List<String>>[ _stringify(overlays) ],
    });
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
        PlatformMessages.sendJSON('flutter/platform', <String, dynamic>{
          'method': 'SystemChrome.setSystemUIOverlayStyle',
          'args': <String>[ _pendingStyle.toString() ],
        });
        _latestStyle = _pendingStyle;
      }
      _pendingStyle = null;
    });
  }

  static SystemUiOverlayStyle _pendingStyle;
  static SystemUiOverlayStyle _latestStyle;
}
