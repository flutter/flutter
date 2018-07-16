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
  PlatformViewRegistry._instance();

  int _nextPlatformViewId = 0;

  /// Allocates a unique identifier for a platform view.
  ///
  /// A platform view identifier can refer to a platform view that was never created,
  /// a platform view that was disposed, or a platform view that is alive.
  ///
  /// Typically a platform view identifier is passed to a [PlatformView] widget
  /// which creates the platform view and manages its lifecycle.
  int getNextPlatformViewId() => _nextPlatformViewId++;
}

/// Callback signature for when a platform view was created.
///
/// `id` is the platform view's unique identifier.
typedef void OnPlatformViewCreated(int id);

/// Provides access to the platform views service.
///
/// This service allows creating and controlling Android views.
///
/// See also: [PlatformView].
class PlatformViewsService {
  PlatformViewsService._();

  /// Creates a controller for a new Android view.
  ///
  /// `id` is an unused unique identifier generated with [platformViewsRegistry].
  ///
  /// `viewType` is the identifier of the Android view type to be created, a
  /// factory for this view type must have been registered on the platform side.
  /// Platform view factories are typically registered by plugin code.
  /// Plugins can register a platform view factory with
  /// [PlatformViewRegistry#registerViewFactory](/javadoc/io/flutter/plugin/platform/PlatformViewRegistry.html#registerViewFactory-java.lang.String-io.flutter.plugin.platform.PlatformViewFactory-).
  ///
  /// The Android view will only be created after [AndroidViewController.setSize] is called for the
  /// first time.
  static AndroidViewController initAndroidView({
    @required int id,
    @required String viewType,
    OnPlatformViewCreated onPlatformViewCreated,
  }) {
    return new AndroidViewController._(
        id: id,
        viewType: viewType,
        onPlatformViewCreated: onPlatformViewCreated
    );
  }
}

enum _AndroidViewState {
  waitingForSize,
  creating,
  created,
  createFailed,
  disposed,
}

/// Controls an Android view.
///
/// Typically created with [PlatformViewsService.initAndroidView].
class AndroidViewController {
  AndroidViewController._({
    @required this.id,
    @required String viewType,
    OnPlatformViewCreated onPlatformViewCreated,
  }) : assert(id != null),
       assert(viewType != null),
       _viewType = viewType,
        _onPlatformViewCreated = onPlatformViewCreated,
       _state = _AndroidViewState.waitingForSize;

  /// The unique identifier of the Android view controlled by this controller.
  final int id;

  final String _viewType;

  final OnPlatformViewCreated _onPlatformViewCreated;

  /// The texture entry id into which the Android view is rendered.
  int _textureId;

  /// Returns the texture entry id that the Android view is rendering into.
  ///
  /// Returns null if the Android view has not been successfully created, or if it has been
  /// disposed.
  int get textureId => _textureId;

  _AndroidViewState _state;

  /// Disposes the Android view.
  ///
  /// The [AndroidViewController] object is unusable after calling this.
  /// The identifier of the platform view cannot be reused after the view is
  /// disposed.
  Future<void> dispose() async {
    if (_state == _AndroidViewState.creating || _state == _AndroidViewState.created)
      await SystemChannels.platform_views.invokeMethod('dispose', id);
    _state = _AndroidViewState.disposed;
  }

  /// Sizes the Android View.
  ///
  /// `size` is the view's new size in logical pixel, and must not be null.
  ///
  /// The first time a size is set triggers the creation of the Android view.
  Future<void> setSize(Size size) async {
    if (_state == _AndroidViewState.disposed)
      throw new FlutterError('trying to size a disposed Android View. View id: $id');

    assert(size != null);

    if (_state == _AndroidViewState.waitingForSize)
      return _create(size);

    await SystemChannels.platform_views.invokeMethod('resize', <String, dynamic> {
      'id': id,
      'width': size.width,
      'height': size.height,
    });
  }

  Future<void> _create(Size size) async {
    _textureId = await SystemChannels.platform_views.invokeMethod('create', <String, dynamic> {
      'id':  id,
      'viewType': _viewType,
      'width': size.width,
      'height': size.height,
    });
    if (_onPlatformViewCreated != null)
      _onPlatformViewCreated(id);
    _state = _AndroidViewState.created;
  }
}
