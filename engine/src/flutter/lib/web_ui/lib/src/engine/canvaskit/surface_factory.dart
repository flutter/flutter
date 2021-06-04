// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:ui/src/engine.dart';

/// Caches surfaces used to overlay platform views.
class SurfaceFactory {
  /// The cache singleton.
  static final SurfaceFactory instance =
      SurfaceFactory(HtmlViewEmbedder.maximumOverlaySurfaces);

  SurfaceFactory(this.maximumSurfaces)
      : assert(maximumSurfaces >= 2,
            'The maximum number of surfaces must be at least 2');

  /// The base surface to paint on. This is the default surface which will be
  /// painted to. If there are no platform views, then this surface will receive
  /// all painting commands.
  final Surface baseSurface = Surface();

  /// The shared backup surface
  final Surface backupSurface = Surface();

  /// The maximum number of surfaces which can be live at once.
  final int maximumSurfaces;

  /// Surfaces created by this factory which are currently in use.
  final List<Surface> _liveSurfaces = <Surface>[];

  /// Surfaces created by this factory which are no longer in use. These can be
  /// reused.
  final List<Surface> _cache = <Surface>[];

  /// The number of surfaces which have been created by this factory.
  int get _surfaceCount => _liveSurfaces.length + _cache.length + 2;

  /// The number of surfaces created by this factory. Used for testing.
  @visibleForTesting
  int get debugSurfaceCount => _surfaceCount;

  /// Returns the number of cached surfaces.
  ///
  /// Useful in tests.
  int get debugCacheSize => _cache.length;

  /// Whether or not we have already emitted a warning about creating too many
  /// surfaces.
  bool _warnedAboutTooManySurfaces = false;

  /// Gets a [Surface] which is ready to paint to.
  ///
  /// If there are available surfaces in the cache, then this will return one of
  /// them. If this factory hasn't yet created [maximumSurfaces] surfaces, then a
  /// new one will be created. If this factory has already created [maximumSurfaces]
  /// surfaces, then this will return a backup surface which will be returned by
  /// all subsequent calls to [getSurface] until some surfaces have been
  /// released with [releaseSurface].
  Surface getSurface() {
    if (_cache.isNotEmpty) {
      final surface = _cache.removeLast();
      _liveSurfaces.add(surface);
      return surface;
    } else if (debugSurfaceCount < maximumSurfaces) {
      final surface = Surface();
      _liveSurfaces.add(surface);
      return surface;
    } else {
      if (!_warnedAboutTooManySurfaces) {
        _warnedAboutTooManySurfaces = true;
        printWarning('Flutter was unable to create enough overlay surfaces. '
            'This is usually caused by too many platform views being '
            'displayed at once. '
            'You may experience incorrect rendering.');
      }
      return backupSurface;
    }
  }

  /// Signals that a surface is no longer being used. It can be reused.
  void releaseSurface(Surface surface) {
    assert(surface != baseSurface, 'Attempting to release the base surface');
    if (surface == backupSurface) {
      // If it's the backup surface, just remove it from the DOM.
      surface.htmlElement.remove();
      return;
    }
    assert(
        _liveSurfaces.contains(surface),
        'Attempting to release a Surface which '
        'was not created by this factory');
    surface.htmlElement.remove();
    _liveSurfaces.remove(surface);
    _cache.add(surface);
  }

  /// Returns [true] if [surface] is currently being used to paint content.
  ///
  /// The base surface and backup surface always count as live.
  ///
  /// If a surface is not live, then it must be in the cache and ready to be
  /// reused.
  bool isLive(Surface surface) {
    if (surface == baseSurface ||
        surface == backupSurface ||
        _liveSurfaces.contains(surface)) {
      return true;
    }
    assert(_cache.contains(surface));
    return false;
  }

  /// Dispose all surfaces created by this factory. Used in tests.
  void debugClear() {
    for (final Surface surface in _cache) {
      surface.dispose();
    }
    for (final Surface surface in _liveSurfaces) {
      surface.dispose();
    }
    _liveSurfaces.clear();
    _cache.clear();
  }
}
