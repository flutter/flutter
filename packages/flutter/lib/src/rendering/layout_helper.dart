// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'box.dart';

/// Signature for a function that takes a [RenderBox] and returns the [Size]
/// that the [RenderBox] would have if it were laid out with the given
/// [BoxConstraints].
///
/// The methods of [ChildLayoutHelper] adhere to this signature.
typedef ChildLayouter = Size Function(RenderBox child, BoxConstraints constraints);

/// A collection of static functions to layout a [RenderBox] child with the
/// given set of [BoxConstraints].
///
/// All of the functions adhere to the [ChildLayouter] signature.
class ChildLayoutHelper {
  // This class is not meant to be instantiated or extended; this constructor
  // prevents instantiation and extension.
  const ChildLayoutHelper._();

  /// Returns the [Size] that the [RenderBox] would have if it were to
  /// be laid out with the given [BoxConstraints].
  ///
  /// This method calls [RenderBox.getDryLayout] on the given [RenderBox].
  ///
  /// This method should only be called by the parent of the provided
  /// [RenderBox] child as it bounds parent and child together (if the child
  /// is marked as dirty, the child will also be marked as dirty).
  ///
  /// See also:
  ///
  ///  * [layoutChild], which actually lays out the child with the given
  ///    constraints.
  static Size dryLayoutChild(RenderBox child, BoxConstraints constraints) {
    return child.getDryLayout(constraints);
  }

  /// Lays out the [RenderBox] with the given constraints and returns its
  /// [Size].
  ///
  /// This method calls [RenderBox.layout] on the given [RenderBox] with
  /// `parentUsesSize` set to true to receive its [Size].
  ///
  /// This method should only be called by the parent of the provided
  /// [RenderBox] child as it bounds parent and child together (if the child
  /// is marked as dirty, the child will also be marked as dirty).
  ///
  /// See also:
  ///
  ///  * [dryLayoutChild], which does not perform a real layout of the child.
  static Size layoutChild(RenderBox child, BoxConstraints constraints) {
    child.layout(constraints, parentUsesSize: true);
    return child.size;
  }
}
