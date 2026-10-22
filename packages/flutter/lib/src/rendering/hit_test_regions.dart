// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/services.dart';
///
/// @docImport 'stack.dart';
/// @docImport 'view.dart';
library;

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';

import 'box.dart';
import 'object.dart';
import 'platform_view.dart';
import 'proxy_box.dart';

/// The hit-test regions collected for a single [PlatformViewRenderBox].
///
/// One group is created for every non-empty platform view encountered during
/// the paint-order walk in [computeHitTestRegions].
///
/// * `viewId` is the [PlatformViewController.viewId] of the platform view, so
///   the engine can tell which platform view the regions sit on top of.
/// * `platformViewRect` is the platform view's bounds in the root coordinate space,
///   intersected with any ancestor paint clip. It is used to decide whether a
///   render object painted later actually covers a platform view.
/// * `rects` are the bounds, in the root coordinate space, of the render
///   objects painted after this platform view (and before the next one) that
///   overlap a platform view and accept pointer events.
typedef _PlatformViewHitTestGroup = ({int viewId, Rect platformViewRect, List<Rect> rects});

/// Walks the render tree rooted at [root] in (approximate) paint order and
/// encodes the bounding rectangles of render objects that paint on top of one
/// or more [PlatformViewRenderBox] instances and claim pointer events.
///
/// The rectangles are in [root]'s coordinate space, which is physical pixels
/// when [root] is a [RenderView].
///
/// On the web, a platform view is a DOM element that sits on top of (or
/// between) Flutter's canvases, so the browser routes pointer events over it
/// to the platform view rather than to Flutter, even where Flutter paints a
/// widget (for example, a button or a dialog) over it. The regions returned
/// here tell the engine where Flutter content that wants pointer events covers
/// a platform view, so that the engine can claim those events for Flutter.
///
/// ## How the regions are collected
///
/// In one sentence: walk the render tree in child order, tracking the
/// accumulated paint transform and clip; every time a platform view is
/// painted, start a new group for it, and every render box painted after that
/// which would accept a pointer event and overlaps any platform view painted
/// so far contributes its clipped, transformed bounds to the most recent group.
///
/// In more detail:
///
/// * The walk follows [RenderObject.visitChildren] and treats anything visited
///   after a platform view as painting on top of it. Child order matches paint
///   order for most render objects, but not all: for example, viewports may
///   paint their slivers in reverse order, and [RenderIndexedStack] lays out
///   (and so is visited for) children that it does not paint. Such render
///   objects are not handled specially yet, so regions under them may be
///   missing or spurious.
/// * Each child's transform is computed with [RenderObject.applyPaintTransform]
///   and each child's clip with [RenderObject.describeApproximatePaintClip],
///   so the rectangles are in the same coordinate space as the root (physical
///   pixels when [root] is a [RenderView]).
/// * Subtrees that cannot receive pointer events are skipped: offstage
///   subtrees ([RenderOffstage]) are not visited at all, and render objects
///   under an ignoring [RenderIgnorePointer] or an absorbing
///   [RenderAbsorbPointer] never claim a region. A platform view in such a
///   subtree still starts a group, because the browser still delivers pointer
///   events to it.
/// * A render box claims its bounds if it is an absorbing
///   [RenderAbsorbPointer] (its subtree is still visited, as described above,
///   so that platform views inside it start their own groups), or if
///   [RenderBox.hitTestSelf] returns true at its center. Boxes that only
///   forward hits to their children do not claim a region themselves; their
///   children are visited instead.
/// * A claimed rectangle is kept only if it is non-empty after clipping and
///   overlaps at least one platform view painted before it. It is attributed
///   to the most recently painted platform view (even if it only overlaps an
///   earlier one), because that is the platform view directly beneath it in
///   paint order.
/// * Platform views themselves are leaves of the walk; their children (if any)
///   are not visited.
///
/// ## Encoding
///
/// The groups are flattened into a single [Float64List] so the payload can be
/// handed to the engine without allocating an object per rectangle. Groups
/// appear in paint order, and each group is encoded as:
///
/// ```csv
/// [viewId, rectCount, left0, top0, right0, bottom0, ..., leftN, topN, rightN, bottomN]
/// ```
///
/// That is, two values (the platform view ID and the number of rectangles
/// that follow) and then four values (left, top, right, bottom) per rectangle.
/// A group with `rectCount == 0` means the platform view is present but no
/// Flutter content claims pointer events on top of it.
///
/// Returns `null` if no [PlatformViewRenderBox] with a non-empty size is
/// encountered during the walk.
Float64List? computeHitTestRegions(RenderObject root) {
  final groups = <_PlatformViewHitTestGroup>[];

  // Records [node]'s bounds as a hit-test region if they cover a platform
  // view that has already been painted.
  void addClaimedRect(RenderBox node, Matrix4 transform, Rect? clip) {
    // Map the node's local bounds into the root coordinate space and clip them
    // to what is actually visible.
    Rect claimedRect = MatrixUtils.transformRect(transform, Offset.zero & node.size);
    if (clip != null) {
      claimedRect = claimedRect.intersect(clip);
    }
    if (!claimedRect.isFinite || claimedRect.isEmpty) {
      return;
    }
    // Only content that covers a platform view needs a region; everywhere
    // else Flutter already receives the pointer events.
    var overlapsAnyPlatformView = false;
    for (final group in groups) {
      final Rect platformViewRect = group.platformViewRect;
      if (platformViewRect.isFinite &&
          !platformViewRect.isEmpty &&
          claimedRect.overlaps(platformViewRect)) {
        overlapsAnyPlatformView = true;
        break;
      }
    }
    if (overlapsAnyPlatformView) {
      // Attribute the region to the topmost platform view painted so far.
      groups.last.rects.add(claimedRect);
    }
  }

  // Visits [node] and its descendants in child order (see above). [transform] maps
  // [node]'s local coordinates to the root's, [clip] is the accumulated paint
  // clip in root coordinates (or null if unclipped), and [ignoringPointers] is
  // true when an ancestor [RenderIgnorePointer] is ignoring pointer events or an
  // ancestor [RenderAbsorbPointer] is absorbing them.
  void visit(RenderObject node, Matrix4 transform, Rect? clip, {required bool ignoringPointers}) {
    // Offstage subtrees are neither painted nor hit tested.
    if (node is RenderOffstage && node.offstage) {
      return;
    }

    // A render object under (or itself being) an ignoring IgnorePointer never
    // claims a region.
    final bool selfIgnoringPointers =
        ignoringPointers || (node is RenderIgnorePointer && node.ignoring);
    // An absorbing AbsorbPointer swallows every pointer event within its
    // bounds, so nothing in its subtree can receive pointer events either;
    // its subtree is treated as if it were under an ignoring IgnorePointer.
    final bool childIgnoringPointers =
        selfIgnoringPointers || (node is RenderAbsorbPointer && node.absorbing);

    // A platform view starts a new group. Everything visited after this point
    // paints on top of it.
    if (node is PlatformViewRenderBox) {
      if (node.hasSize && !node.size.isEmpty) {
        Rect platformViewRect = MatrixUtils.transformRect(transform, Offset.zero & node.size);
        if (clip != null) {
          platformViewRect = platformViewRect.intersect(clip);
        }
        groups.add((
          viewId: node.controller.viewId,
          platformViewRect: platformViewRect,
          rects: <Rect>[],
        ));
      }
      return;
    }

    // Nothing can cover a platform view until one has been painted, and
    // render objects that ignore pointers never claim a region.
    if (groups.isNotEmpty &&
        !selfIgnoringPointers &&
        node is RenderBox &&
        node.hasSize &&
        !node.size.isEmpty) {
      if (node is RenderAbsorbPointer) {
        // An absorbing AbsorbPointer claims its own bounds. Its subtree is
        // still visited (with pointers ignored) so that platform views inside
        // it start their own groups.
        if (node.absorbing) {
          addClaimedRect(node, transform, clip);
        }
      } else {
        // hitTestSelf is protected, but asking whether a box would accept a
        // pointer event at its center is exactly the question this pass needs
        // answered, without running a full hit test.
        // ignore: invalid_use_of_protected_member
        final bool hitsSelf = node.hitTestSelf(node.size.center(Offset.zero));
        if (hitsSelf) {
          // The box itself accepts pointer events (for example, it paints an
          // opaque background or handles gestures), so its bounds are a
          // region.
          addClaimedRect(node, transform, clip);
        }
      }
    }

    // Descend into the children in child order, accumulating each child's
    // paint transform and clip.
    node.visitChildren((RenderObject child) {
      var childClip = clip;
      final Rect? localClip = node.describeApproximatePaintClip(child);
      if (localClip != null) {
        final Rect globalClip = localClip.isEmpty
            ? Rect.zero
            : MatrixUtils.transformRect(transform, localClip);
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

  // Flatten the groups into the encoding described above: for each group,
  // [viewId, rectCount] followed by rectCount * [left, top, right, bottom].
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
