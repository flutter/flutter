// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/material.dart';
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// The position information for a text selection toolbar.
///
/// Typically, a menu will attempt to position itself at [primaryAnchor], and
/// if that's not possible, then it will use [secondaryAnchor] instead, if it
/// exists.
///
/// See also:
///
///  * [AdaptiveTextSelectionToolbar.anchors], which is of this type.
@immutable
class TextSelectionToolbarAnchors {
  /// Creates an instance of [TextSelectionToolbarAnchors] directly from the
  /// anchor points.
  const TextSelectionToolbarAnchors({required this.primaryAnchor, this.secondaryAnchor});

  /// Creates an instance of [TextSelectionToolbarAnchors] for some selection.
  ///
  /// When [ancestor] is provided, the returned anchors are in [ancestor]'s
  /// coordinate space. When null, they are in global (screen) coordinates.
  /// Passing the [Overlay]'s [RenderBox] as [ancestor] is recommended so that
  /// anchors are relative to the overlay the toolbar is painted in.
  factory TextSelectionToolbarAnchors.fromSelection({
    required RenderBox renderBox,
    required double startGlyphHeight,
    required double endGlyphHeight,
    required List<TextSelectionPoint> selectionEndpoints,
    RenderObject? ancestor,
  }) {
    final Rect selectionRect = getSelectionRect(
      renderBox,
      startGlyphHeight,
      endGlyphHeight,
      selectionEndpoints,
      ancestor: ancestor,
    );
    if (selectionRect == Rect.zero) {
      return const TextSelectionToolbarAnchors(primaryAnchor: Offset.zero);
    }

    final Rect editingRegion = _getEditingRegion(renderBox, ancestor: ancestor);
    return TextSelectionToolbarAnchors(
      primaryAnchor: Offset(
        selectionRect.left + selectionRect.width / 2,
        clampDouble(selectionRect.top, editingRegion.top, editingRegion.bottom),
      ),
      secondaryAnchor: Offset(
        selectionRect.left + selectionRect.width / 2,
        clampDouble(selectionRect.bottom, editingRegion.top, editingRegion.bottom),
      ),
    );
  }

  /// Returns the [Rect] of the [RenderBox] in the coordinate space of
  /// [ancestor], or in global coordinates if [ancestor] is null.
  static Rect _getEditingRegion(RenderBox renderBox, {RenderObject? ancestor}) {
    return Rect.fromPoints(
      renderBox.localToGlobal(Offset.zero, ancestor: ancestor),
      renderBox.localToGlobal(renderBox.size.bottomRight(Offset.zero), ancestor: ancestor),
    );
  }

  /// Returns the [Rect] covering the given selection in the given [RenderBox]
  /// in the coordinate space of [ancestor], or in global coordinates if
  /// [ancestor] is null.
  static Rect getSelectionRect(
    RenderBox renderBox,
    double startGlyphHeight,
    double endGlyphHeight,
    List<TextSelectionPoint> selectionEndpoints, {
    RenderObject? ancestor,
  }) {
    final Rect editingRegion = _getEditingRegion(renderBox, ancestor: ancestor);

    if (editingRegion.left.isNaN ||
        editingRegion.top.isNaN ||
        editingRegion.right.isNaN ||
        editingRegion.bottom.isNaN) {
      return Rect.zero;
    }

    final bool isMultiline =
        selectionEndpoints.last.point.dy - selectionEndpoints.first.point.dy > endGlyphHeight / 2;

    return Rect.fromLTRB(
      isMultiline ? editingRegion.left : editingRegion.left + selectionEndpoints.first.point.dx,
      editingRegion.top + selectionEndpoints.first.point.dy - startGlyphHeight,
      isMultiline ? editingRegion.right : editingRegion.left + selectionEndpoints.last.point.dx,
      editingRegion.top + selectionEndpoints.last.point.dy,
    );
  }

  /// The location that the toolbar should attempt to position itself at.
  ///
  /// If the toolbar doesn't fit at this location, use [secondaryAnchor] if it
  /// exists.
  final Offset primaryAnchor;

  /// The fallback position that should be used if [primaryAnchor] doesn't work.
  final Offset? secondaryAnchor;
}
