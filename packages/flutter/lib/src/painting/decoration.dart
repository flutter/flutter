// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic_types.dart';
import 'edge_insets.dart';

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
abstract class Decoration {
  /// Abstract const constructor.
  const Decoration();

  /// In checked mode, throws an exception if the object is not in a
  /// valid configuration. Otherwise, returns true.
  ///
  /// This is intended to be used as follows:
  /// ```dart
  ///   assert(myDecoration.debugAssertValid());
  /// ```
  bool debugAssertValid() => true;

  /// Returns the insets to apply when using this decoration on a box
  /// that has contents, so that the contents do not overlap the edges
  /// of the decoration. For example, if the decoration draws a frame
  /// around its edge, the padding would return the distance by which
  /// to inset the children so as to not overlap the frame.
  EdgeInsets get padding => null;

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
      return end.lerpTo(begin, t);
    if (begin != null)
      return begin.lerpFrom(end, t);
    return null;
  }

  /// Tests whether the given point, on a rectangle of a given size,
  /// would be considered to hit the decoration or not. For example,
  /// if the decoration only draws a circle, this function might
  /// return true if the point was inside the circle and false
  /// otherwise.
  bool hitTest(Size size, Point position) => true;

  /// Whether this [Decoration] subclass needs its painters to use
  /// [addChangeListener] to listen for updates. For example, if a
  /// decoration draws a background image, owners would have to listen
  /// for the image's load completing so that they could repaint
  /// themselves when appropriate.
  bool get needsListeners => false;

  /// Register a listener. See [needsListeners].
  ///
  /// Only call this if [needsListeners] is true.
  void addChangeListener(VoidCallback listener) { assert(false); }

  /// Unregisters a listener previous registered with
  /// [addChangeListener]. See [needsListeners].
  ///
  /// Only call this if [needsListeners] is true.
  void removeChangeListener(VoidCallback listener) { assert(false); }

  /// Returns a [BoxPainter] that will paint this decoration.
  BoxPainter createBoxPainter();

  @override
  String toString([String prefix = '']) => '$prefix$runtimeType';
}

/// A stateful class that can paint a particular [Decoration].
///
/// [BoxPainter] objects can cache resources so that they can be used
/// multiple times.
abstract class BoxPainter { // ignore: one_member_abstracts

  /// Paints the [Decoration] for which this object was created on the
  /// given canvas using the given rectangle.
  ///
  /// If this object caches resources for painting (e.g. [Paint]
  /// objects), the cache may be flushed when [paint] is called with a
  /// new [Rect]. For this reason, it may be more efficient to call
  /// [Decoration.createBoxPainter] for each different rectangle that
  /// is being painted in a particular frame.
  ///
  /// For example, if a decoration's owner wants to paint a particular
  /// decoration once for its whole size, and once just in the bottom
  /// right, it might get two [BoxPainter] instances, one for each.
  /// However, when its size changes, it could continue using those
  /// same instances, since the previous resources would no longer be
  /// relevant and thus losing them would not be an issue.
  void paint(Canvas canvas, Rect rect);
}
