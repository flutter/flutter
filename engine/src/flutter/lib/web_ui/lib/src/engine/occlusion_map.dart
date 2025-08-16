// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:ui/ui.dart' as ui;

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
  OcclusionMapNode insert(ui.Rect other) => OcclusionMapBranch(this, OcclusionMapLeaf(other));

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
    // Try to create nodes with the smallest possible area
    final double leftOtherArea = _areaOfUnion(left.boundingBox, other);
    final double rightOtherArea = _areaOfUnion(right.boundingBox, other);
    final double leftRightArea = boundingBox.width * boundingBox.height;
    if (leftOtherArea < rightOtherArea) {
      if (leftOtherArea < leftRightArea) {
        return OcclusionMapBranch(left.insert(other), right);
      }
    } else {
      if (rightOtherArea < leftRightArea) {
        return OcclusionMapBranch(left, right.insert(other));
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

  void addRect(ui.Rect rect) => root = root.insert(rect);

  bool overlaps(ui.Rect rect) => root.overlaps(rect);
}
