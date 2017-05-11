// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'basic_types.dart';
import 'edge_insets.dart';

export 'package:flutter/services.dart' show ImageConfiguration;

export 'basic_types.dart' show Offset, Size;
export 'edge_insets.dart' show EdgeInsets;

// This group of classes is intended for painting in cartesian coordinates.

/// A description of a box decoration (a decoration applied to a [Rect]).
///
/// This class presents the abstract interface for all decorations.
/// See [BoxDecoration] for a concrete example.
///
/// To actually paint a [Decoration], use the [createBoxPainter]
/// method to obtain a [BoxPainter]. [Decoration] objects can be
/// shared between boxes; [BoxPainter] objects can cache resources to
/// make painting on a particular surface faster.
@immutable
abstract class Decoration {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const Decoration();

  /// In checked mode, throws an exception if the object is not in a
  /// valid configuration. Otherwise, returns true.
  ///
  /// This is intended to be used as follows:
  /// ```dart
  ///   assert(myDecoration.debugAssertIsValid());
  /// ```
  bool debugAssertIsValid() => true;

  /// Returns the insets to apply when using this decoration on a box
  /// that has contents, so that the contents do not overlap the edges
  /// of the decoration. For example, if the decoration draws a frame
  /// around its edge, the padding would return the distance by which
  /// to inset the children so as to not overlap the frame.
  EdgeInsets get padding => null;

  /// Whether this decoration is complex enough to benefit from caching its painting.
  bool get isComplex => false;

  /// Linearly interpolates from [a] to [this].
  Decoration lerpFrom(Decoration a, double t) => this;

  /// Linearly interpolates from [this] to [b].
  Decoration lerpTo(Decoration b, double t) => b;

  /// Linearly interpolates from [begin] to [end].
  ///
  /// This defers to [end]'s [lerpTo] function if [end] is not null,
  /// otherwise it uses [begin]'s [lerpFrom] function.
  static Decoration lerp(Decoration begin, Decoration end, double t) {
    if (end != null)
      return end.lerpFrom(begin, t);
    if (begin != null)
      return begin.lerpTo(end, t);
    return null;
  }

  /// Tests whether the given point, on a rectangle of a given size,
  /// would be considered to hit the decoration or not. For example,
  /// if the decoration only draws a circle, this function might
  /// return true if the point was inside the circle and false
  /// otherwise.
  bool hitTest(Size size, Offset position) => true;

  /// Returns a [BoxPainter] that will paint this decoration.
  ///
  /// The `onChanged` argument configures [BoxPainter.onChanged]. It can be
  /// omitted if there is no chance that the painter will change (for example,
  /// if it is a [BoxDecoration] with definitely no [DecorationImage]).
  BoxPainter createBoxPainter([VoidCallback onChanged]);

  /// Returns a string representation of this object.
  ///
  /// Every line of the output should be prefixed by `prefix`.
  ///
  /// If `indentPrefix` is non-null, then the description can be further split
  /// into sublines, and each subline should be prefixed with `indentPrefix`
  /// (rather that `prefix`). This is used, for example, by [BoxDecoration] for
  /// the otherwise quite verbose [BoxShadow] descriptions.
  @override
  String toString([String prefix = '', String indentPrefix ]) => '$prefix$runtimeType';
}

/// A stateful class that can paint a particular [Decoration].
///
/// [BoxPainter] objects can cache resources so that they can be used
/// multiple times.
///
/// Some resources used by [BoxPainter] may load asynchronously. When this
/// happens, the [onChanged] callback will be invoked. To stop this callback
/// from being called after the painter has been discarded, call [dispose].
abstract class BoxPainter {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  BoxPainter([this._onChanged]);

  /// Paints the [Decoration] for which this object was created on the
  /// given canvas using the given configuration.
  ///
  /// The [ImageConfiguration] object passed as the third argument must, at a
  /// minimum, have a non-null [Size].
  ///
  /// If this object caches resources for painting (e.g. [Paint] objects), the
  /// cache may be flushed when [paint] is called with a new configuration. For
  /// this reason, it may be more efficient to call
  /// [Decoration.createBoxPainter] for each different rectangle that is being
  /// painted in a particular frame.
  ///
  /// For example, if a decoration's owner wants to paint a particular
  /// decoration once for its whole size, and once just in the bottom
  /// right, it might get two [BoxPainter] instances, one for each.
  /// However, when its size changes, it could continue using those
  /// same instances, since the previous resources would no longer be
  /// relevant and thus losing them would not be an issue.
  ///
  /// Implementations should paint their decorations on the canvas in a
  /// rectangle whose top left corner is at the given `offset` and whose size is
  /// given by `configuration.size`.
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration);

  /// Callback that is invoked if an asynchronously-loading resource used by the
  /// decoration finishes loading. For example, an image. When this is invoked,
  /// the [paint] method should be called again.
  ///
  /// Resources might not start to load until after [paint] has been called,
  /// because they might depend on the configuration.
  VoidCallback get onChanged => _onChanged;
  VoidCallback _onChanged;

  /// Discard any resources being held by the object. This also guarantees that
  /// the [onChanged] callback will not be called again.
  @mustCallSuper
  void dispose() {
    _onChanged = null;
  }
}
