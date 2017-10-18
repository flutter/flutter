// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'basic_types.dart';
import 'edge_insets.dart';

export 'package:flutter/services.dart' show ImageConfiguration;

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
abstract class Decoration extends Diagnosticable {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const Decoration();

  @override
  String toStringShort() => '$runtimeType';

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
  ///
  /// This only works for decorations that have absolute sizes. If the padding
  /// needed would change based on the size at which the decoration is drawn,
  /// then this will return incorrect padding values.
  ///
  /// For example, when a [BoxDecoration] has [BoxShape.circle], the padding
  /// does not take into account that the circle is drawn in the center of the
  /// box regardless of the ratio of the box; it does not provide the extra
  /// padding that is implied by changing the ratio.
  ///
  /// The value returned by this getter must be resolved (using
  /// [EdgeInsetsGeometry.resolve] to obtain an absolute [EdgeInsets]. (For
  /// example, [BorderDirectional] will return an [EdgeInsetsDirectional] for
  /// its [padding].)
  EdgeInsetsGeometry get padding => EdgeInsets.zero;

  /// Whether this decoration is complex enough to benefit from caching its painting.
  bool get isComplex => false;

  /// Linearly interpolates from `a` to [this].
  ///
  /// When implementing this method in subclasses, return null if this class
  /// cannot interpolate from `a`. In that case, [lerp] will try `a`'s [lerpTo]
  /// method instead.
  ///
  /// Supporting interpolating from null is recommended as the [Decoration.lerp]
  /// method uses this as a fallback when two classes can't interpolate between
  /// each other.
  ///
  /// Instead of calling this directly, use [Decoration.lerp].
  @protected
  Decoration lerpFrom(Decoration a, double t) => null;

  /// Linearly interpolates from [this] to `b`.
  ///
  /// This is called if `b`'s [lerpTo] did not know how to handle this class.
  ///
  /// When implementing this method in subclasses, return null if this class
  /// cannot interpolate from `b`. In that case, [lerp] will apply a default
  /// behavior instead.
  ///
  /// Supporting interpolating to null is recommended as the [Decoration.lerp]
  /// method uses this as a fallback when two classes can't interpolate between
  /// each other.
  ///
  /// Instead of calling this directly, use [Decoration.lerp].
  @protected
  Decoration lerpTo(Decoration b, double t) => null;

  /// Linearly interpolates from `begin` to `end`.
  ///
  /// This attempts to use [lerpFrom] and [lerpTo] on `end` and `begin`
  /// respectively to find a solution. If the two values can't directly be
  /// interpolated, then the interpolation is done via null (at `t == 0.5`).
  ///
  /// If the values aren't null, then for `t == 0.0` and `t == 1.0` the values
  /// `begin` and `end` are return verbatim.
  static Decoration lerp(Decoration begin, Decoration end, double t) {
    if (begin == null && end == null)
      return null;
    if (begin == null)
      return end.lerpFrom(null, t) ?? end;
    if (end == null)
      return begin.lerpTo(null, t) ?? begin;
    if (t == 0.0)
      return begin;
    if (t == 1.0)
      return end;
    return end.lerpFrom(begin, t)
        ?? begin.lerpTo(end, t)
        ?? (t < 0.5 ? begin.lerpTo(null, t * 2.0) : end.lerpFrom(null, (t - 0.5) * 2.0));
  }

  /// Tests whether the given point, on a rectangle of a given size,
  /// would be considered to hit the decoration or not. For example,
  /// if the decoration only draws a circle, this function might
  /// return true if the point was inside the circle and false
  /// otherwise.
  ///
  /// The decoration may be sensitive to the [TextDirection]. The
  /// `textDirection` argument should therefore be provided. If it is known that
  /// the decoration is not affected by the text direction, then the argument
  /// may be ommitted or set to null.
  bool hitTest(Size size, Offset position, { TextDirection textDirection }) => true;

  /// Returns a [BoxPainter] that will paint this decoration.
  ///
  /// The `onChanged` argument configures [BoxPainter.onChanged]. It can be
  /// omitted if there is no chance that the painter will change (for example,
  /// if it is a [BoxDecoration] with definitely no [DecorationImage]).
  BoxPainter createBoxPainter([VoidCallback onChanged]);
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
