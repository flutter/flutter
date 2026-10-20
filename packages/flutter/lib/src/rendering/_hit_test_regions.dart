// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';

import 'box.dart';
import 'object.dart';
import 'platform_view.dart';
import 'proxy_box.dart';

typedef _PlatformViewHitTestGroup = ({int viewId, Rect pvRect, List<Rect> rects});

/// Walks the render tree rooted at [root] in paint order and encodes the
/// bounding rectangles (in physical device pixels) of render objects that paint
/// on top of one or more [PlatformViewRenderBox] instances and claim pointer
/// events.
///
/// Returns `null` if no [PlatformViewRenderBox] with a non-empty size is
/// encountered during the walk.
Float64List? computeHitTestRegions(RenderObject root) {
  final groups = <_PlatformViewHitTestGroup>[];

  void addClaimedRect(RenderBox node, Matrix4 transform, Rect? clip) {
    Rect claimedRect = MatrixUtils.transformRect(transform, Offset.zero & node.size);
    if (clip != null) {
      claimedRect = claimedRect.intersect(clip);
    }
    if (claimedRect.isEmpty || claimedRect.width <= 0.0 || claimedRect.height <= 0.0) {
      return;
    }
    var overlapsAnyPlatformView = false;
    for (final group in groups) {
      final Rect pvRect = group.pvRect;
      if (!pvRect.isEmpty &&
          pvRect.width > 0.0 &&
          pvRect.height > 0.0 &&
          claimedRect.overlaps(pvRect)) {
        overlapsAnyPlatformView = true;
        break;
      }
    }
    if (overlapsAnyPlatformView) {
      groups.last.rects.add(claimedRect);
    }
  }

  void visit(RenderObject node, Matrix4 transform, Rect? clip, {required bool ignoringPointers}) {
    if (node is RenderOffstage && node.offstage) {
      return;
    }

    final bool childIgnoringPointers =
        ignoringPointers || (node is RenderIgnorePointer && node.ignoring);

    if (node is PlatformViewRenderBox) {
      if (node.hasSize && !node.size.isEmpty) {
        Rect pvRect = MatrixUtils.transformRect(transform, Offset.zero & node.size);
        if (clip != null) {
          pvRect = pvRect.intersect(clip);
        }
        groups.add((viewId: node.controller.viewId, pvRect: pvRect, rects: <Rect>[]));
      }
      return;
    }

    if (groups.isNotEmpty &&
        !childIgnoringPointers &&
        node is RenderBox &&
        node.hasSize &&
        !node.size.isEmpty) {
      if (node is RenderAbsorbPointer) {
        if (node.absorbing) {
          addClaimedRect(node, transform, clip);
          return;
        }
      } else if (
      // ignore: invalid_use_of_protected_member
      node.hitTestSelf(node.size.center(Offset.zero))) {
        addClaimedRect(node, transform, clip);
      }
    }

    node.visitChildren((RenderObject child) {
      var childClip = clip;
      final Rect? localClip = node.describeApproximatePaintClip(child);
      if (localClip != null) {
        final Rect globalClip = MatrixUtils.transformRect(transform, localClip);
        childClip = childClip == null ? globalClip : childClip.intersect(globalClip);
      }
      final Matrix4 childTransform = transform.clone();
      node.applyPaintTransform(child, childTransform);
      visit(child, childTransform, childClip, ignoringPointers: childIgnoringPointers);
    });
  }

  visit(root, Matrix4.identity(), null, ignoringPointers: false);

  if (groups.isEmpty) {
    return null;
  }

  var totalFloats = 0;
  for (final group in groups) {
    totalFloats += 2 + group.rects.length * 4;
  }

  final payload = Float64List(totalFloats);
  var index = 0;
  for (final group in groups) {
    payload[index++] = group.viewId.toDouble();
    payload[index++] = group.rects.length.toDouble();
    for (final Rect rect in group.rects) {
      payload[index++] = rect.left;
      payload[index++] = rect.top;
      payload[index++] = rect.right;
      payload[index++] = rect.bottom;
    }
  }
  return payload;
}
