// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:ui/ui.dart' as ui;

import 'util.dart';

sealed class OcclusionMapNode {
  bool overlaps(ui.Rect rect);
  OcclusionMapNode insert(ui.Rect rect);
  ui.Rect get boundingBox;
}

class OcclusionMapEmpty implements OcclusionMapNode {
  @override
  ui.Rect get boundingBox => ui.Rect.zero;

  @override
  OcclusionMapNode insert(ui.Rect rect) => OcclusionMapLeaf(rect);

  @override
  bool overlaps(ui.Rect rect) => false;
}

class OcclusionMapLeaf implements OcclusionMapNode {
  OcclusionMapLeaf(this.rect);

  final ui.Rect rect;

  @override
  ui.Rect get boundingBox => rect;

  @override
  OcclusionMapNode insert(ui.Rect other) {
    if (rectContainsOther(rect, other)) {
      // `other` is fully contained within `rect`, so we don't need to change anything.
      return this;
    }
    if (rectContainsOther(other, rect)) {
      // `other` fully contains `rect`, so we replace `rect` with `other`.
      return OcclusionMapLeaf(other);
    }
    return OcclusionMapBranch(this, OcclusionMapLeaf(other));
  }

  @override
  bool overlaps(ui.Rect other) => rect.overlaps(other);
}

class OcclusionMapBranch implements OcclusionMapNode {
  OcclusionMapBranch(this.left, this.right)
    : boundingBox = left.boundingBox.expandToInclude(right.boundingBox);

  final OcclusionMapNode left;
  final OcclusionMapNode right;

  @override
  final ui.Rect boundingBox;

  double _areaOfUnion(ui.Rect first, ui.Rect second) {
    return (math.max(first.right, second.right) - math.min(first.left, second.left)) *
        (math.max(first.bottom, second.bottom) - math.min(first.top, second.top));
  }

  @override
  OcclusionMapNode insert(ui.Rect other) {
    // `other` fully contains the bounding box of the left and right nodes, so the entire branch is
    // replaced with a new leaf that only contains `other`.
    if (rectContainsOther(other, boundingBox)) {
      return OcclusionMapLeaf(other);
    }

    // Try to create nodes with the smallest possible area
    final double leftOtherArea = _areaOfUnion(left.boundingBox, other);
    final double rightOtherArea = _areaOfUnion(right.boundingBox, other);
    final double leftRightArea = boundingBox.width * boundingBox.height;
    if (leftOtherArea < rightOtherArea) {
      if (leftOtherArea < leftRightArea) {
        final OcclusionMapNode newLeft = left.insert(other);
        if (identical(newLeft, left)) {
          // `other` made no difference to `left`, so there's no need to change anything.
          return this;
        }
        return OcclusionMapBranch(newLeft, right);
      }
    } else {
      if (rightOtherArea < leftRightArea) {
        final OcclusionMapNode newRight = right.insert(other);
        if (identical(newRight, right)) {
          // `other` made no difference to `right`, so there's no need to change anything.
          return this;
        }
        return OcclusionMapBranch(left, newRight);
      }
    }
    return OcclusionMapBranch(this, OcclusionMapLeaf(other));
  }

  @override
  bool overlaps(ui.Rect rect) {
    if (!boundingBox.overlaps(rect)) {
      return false;
    }
    return left.overlaps(rect) || right.overlaps(rect);
  }
}

class OcclusionMap {
  OcclusionMapNode root = OcclusionMapEmpty();

  void addRect(ui.Rect rect) {
    if (rect.isEmpty) {
      // Empty rects don't overlap with anything, there's no need to add them.
      return;
    }
    root = root.insert(rect);
  }

  bool overlaps(ui.Rect rect) {
    if (rect.isEmpty) {
      // Empty rects don't overlap with anything, there's no need to check for overlaps.
      return false;
    }
    return root.overlaps(rect);
  }
}
