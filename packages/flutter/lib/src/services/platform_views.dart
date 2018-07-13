// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'system_channels.dart';

/// The [PlatformViewRegistry] responsible for generating unique identifiers for platform views.
final PlatformViewRegistry platformViewRegistry = PlatformViewRegistry._instance();

/// A registry responsible for generating unique identifier for platform views.
///
/// A Flutter application has a single [PlatformViewRegistry] which can be accesses
/// through the [platformViewRegistry] getter.
///
/// See also:
///   * [PlatformView], a widget that shows a platform view.
class PlatformViewRegistry {
  PlatformViewRegistry._instance() {
    _nextPlatformViewId = 0;
  }

  int _nextPlatformViewId;

  /// Allocates a unique identifier for a platform view.
  ///
  /// A platform view identifier can refer to a platform view that was never created,
  /// a platform view that was disposed, or a platform view that is alive.
  ///
  /// Typically a platform view identifier is passed to a [PlatformView] widget
  /// which creates the platform view and manages its lifecycle.
  int getNextPlatformViewId() => _nextPlatformViewId++;
}

/// Provides access to the platform views service.
///
/// This service allows creating and controlling Android views.
///
/// See also: [PlatformView].
class PlatformViewsService {
  PlatformViewsService._();

  // TODO(amirh): add a link to the javadoc for registerViewFactory once available.
  /// Creates a new Android view.
  ///
  /// `id` is an unused unique identifier generated with [platformViewsRegistry].
  ///
  /// `viewType` is the identifier of the Android view type to be created, a
  /// factory for this view type must have been registered on the platform side.
  /// Platform view factories are typically registered by plugin code.
  /// Plugins can register a platform view factory with
  /// PlatformViewRegistry#registerViewFactory from Java/Kotlin code.
  ///
  /// `size` is the initial size for the view in logical pixels.
  static Future<AndroidViewController> initAndroidView({
    @required int id,
    @required String viewType,
    @required Size size,
  }) async {
     assert(size != null);
     final int textureId = await SystemChannels.platform_views.invokeMethod('create', <String, dynamic> {
      'id':  id,
      'viewType': viewType,
      'width': size.width,
      'height': size.height,
    });
    return new AndroidViewController._(id: id, textureId: textureId);
  }
}

/// Controls an Android view.
///
/// Typically created with [PlatformViewsService.initAndroidView].
class AndroidViewController {
  const AndroidViewController._({
    @required this.id,
    this.textureId,
  }) : assert(id != null);

  /// The unique identifier of the Android view controlled by this controller.
  final int id;

  /// The texture entry id into which the Android view is rendered.
  final int textureId;

  /// Disposes the Android view.
  ///
  /// The [AndroidViewController] object is unusable after calling this.
  /// The identifier of the platform view cannot be reused after the view is
  /// disposed.
  Future<Null> dispose() async {
    await SystemChannels.platform_views.invokeMethod('dispose', id);
  }

  /// Resizes the Android View.
  ///
  /// `size` is the view's new size in logical pixel.
  Future<Null> resize(Size size) async {
    await SystemChannels.platform_views.invokeMethod('resize', <String, dynamic> {
      'id': id,
      'width': size.width,
      'height': size.height,
    });
  }
}