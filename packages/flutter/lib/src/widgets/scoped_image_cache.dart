// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';

import 'framework.dart';

/// Scopes access to an [ImageCache] for a specific subtree of widgets.
///
/// Framework widgets avoid directly using [PaintingBinding.imageCache],
/// and instead look for the nearest [ImageCache] available via this widget's
/// static members [dependOn] and [of]. These methods can return the global
/// image cache if no [ScopedImageCache] is available in the tree. The
/// [dependOn] method will throw by default if there is no [ScopedImageCache],
/// since it is intended to introduce a dependency on a [ScopedImageCache], and
/// callers would not be notified if the cache were somehow changed on the
/// [PaintingBinding].
///
/// The [of] method will not throw by default since it is not intended
/// to introduce any such dependency.
@immutable
class ScopedImageCache extends InheritedWidget {
  /// Creates a new [ScopedImageCache], which is used to introduce an
  /// [ImageCache] for a specific part of a widget subtree.
  const ScopedImageCache({
    @required Widget child,
    @required ImageCache imageCache,
    Key key,
  }) : assert(child != null),
       assert(imageCache != null),
       _imageCache = imageCache,
       super(key: key, child: child);

  final ImageCache _imageCache;

  static FlutterError _getError(BuildContext context) {
    return FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary('ScopedImageCache.of() called on a context that does not contain a ScopedImageCache.'),
      ErrorDescription(
        'No ScopedImageCache ancestor could be found starting from the '
        'context that was passed to ScopedImageCache.of(). This can happen '
        'because you did not introduce a ScopedImageCache widget into the '
        'tree, or the context you are using comes from a widget above the '
        'widget you introduced.\n'
      ),
      context.describeElement('The context used was'),
    ]);
  }

  /// Finds the nearest [ImageCache] from a [ScopedImageCache] enclosing the
  /// build context. If there is no [ImageCache] widget, it will return the
  /// [ImageCache] on the [PaintingBinding.instance].
  ///
  /// This method will throw if [paintingBindingOk] is set to false and there is
  /// no [ScopedImageCache] in the tree above the caller's [context].
  ///
  /// Calling this method does not cause the caller to depend on this widget. If
  /// a caller wants to be notified when the [ImageCache] instance is changed,
  /// the [ImageCache.dependOn] method should be used instead.
  static ImageCache of(BuildContext context, { bool paintingBindingOk = true }) {
    final ScopedImageCache widget = context.findAncestorWidgetOfExactType<ScopedImageCache>();
    if (widget == null) {
      if (!paintingBindingOk) {
        throw _getError(context);
      }
      return PaintingBinding.instance.imageCache;
    }
    return widget._imageCache;
  }

  /// Finds the nearest [ImageCache] from a [ScopedImageCache] enclosing the
  /// build context and introduces a dependency on the [ScopedImageCache].
  ///
  /// If the widget tree is rebuilt and the [ScopedImageCache] parent gets a new
  /// [ImageCache] to refer to, subscribers will receive a call to
  /// [didUpdateDependencies]. Callers that use such methods to resolve images
  /// should not use this method, but instead use [of].
  static ImageCache dependOn(BuildContext context, { bool paintingBindingOk = false }) {
    final ScopedImageCache widget = context.dependOnInheritedWidgetOfExactType<ScopedImageCache>();
    if (widget == null) {
      if (!paintingBindingOk) {
        throw _getError(context);
      }
      return PaintingBinding.instance.imageCache;
    }
    return widget._imageCache;
  }

  @override
  bool updateShouldNotify(ScopedImageCache oldWidget) => _imageCache != oldWidget._imageCache;
}
