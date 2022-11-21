// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

import 'text_selection_toolbar_layout_delegate.dart';

/// Positions the toolbar below [anchor] or adjusts it higher to fit above
/// the bottom view insets, if applicable.
///
/// See also:
///
///   * [MaterialSpellCheckSuggestionsToolbar], which uses this to position itself.
class SpellCheckSuggestionsToolbarLayoutDelegate extends SingleChildLayoutDelegate {
  /// Creates an instance of [SpellCheckSuggestionsToolbarLayoutDelegate].
  SpellCheckSuggestionsToolbarLayoutDelegate({
    required this.anchor,
    required this.heightOffset,
  });

  /// {@macro flutter.material.MaterialSpellCheckSuggestionsToolbar.anchor}
  ///
  /// Should be provided in local coordinates.
  final Offset anchor;

  /// The height to adjust the toolbar position by if it were to overlap with
  /// the bottom view insets without adjustment.
  final double heightOffset;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen();
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return Offset(
      TextSelectionToolbarLayoutDelegate.centerOn(
        anchor.dx,
        childSize.width,
        size.width,
      ),
      anchor.dy + heightOffset,
    );
  }

  @override
  bool shouldRelayout(SpellCheckSuggestionsToolbarLayoutDelegate oldDelegate) {
    return anchor != oldDelegate.anchor;
  }
}
