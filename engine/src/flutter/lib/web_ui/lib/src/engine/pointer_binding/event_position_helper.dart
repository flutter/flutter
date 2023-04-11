// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui show Offset;

import '../dom.dart';
import '../semantics.dart' show EngineSemanticsOwner;

/// Returns an [ui.Offset] of the position of [event], relative to the position of [actualTarget].
///
/// The offset is *not* multiplied by DPR or anything else, it's the closest
/// to what the DOM would return if we had currentTarget readily available.
///
/// This needs an `actualTarget`, because the `event.currentTarget` (which is what
/// this would really need to use) gets lost when the `event` comes from a "coalesced"
/// event.
///
/// It also takes into account semantics being enabled to fix the case where
/// offsetX, offsetY == 0 (TalkBack events).
ui.Offset computeEventOffsetToTarget(DomMouseEvent event, DomElement actualTarget) {
  // On a TalkBack event
  if (EngineSemanticsOwner.instance.semanticsEnabled && event.offsetX == 0 && event.offsetY == 0) {
    return _computeOffsetForTalkbackEvent(event, actualTarget);
  }

  final bool isTargetOutsideOfShadowDOM = event.target != actualTarget;
  if (isTargetOutsideOfShadowDOM) {
    return _computeOffsetRelativeToActualTarget(event, actualTarget);
  }
  // Return the offsetX/Y in the normal case.
  // (This works with 3D translations of the parent element.)
  return ui.Offset(event.offsetX, event.offsetY);
}

/// Computes the event offset when hovering over any nodes that don't exist in
/// the shadowDOM such as platform views or text editing nodes.
///
/// This still uses offsetX/Y, but adds the offset from the top/left corner of the
/// platform view to the Flutter View (`actualTarget`).
///
///  ×--FlutterView(actualTarget)--------------+
///  |\                                        |
///  | x1,y1                                   |
///  |                                         |
///  |                                         |
///  |     ×-PlatformView(target)---------+    |
///  |     |\                             |    |
///  |     | x2,y2                        |    |
///  |     |                              |    |
///  |     |      × (event)               |    |
///  |     |       \                      |    |
///  |     |        offsetX, offsetY      |    |
///  |     |  (Relative to PlatformView)  |    |
///  |     +------------------------------+    |
///  +-----------------------------------------+
///
/// Offset between PlatformView and FlutterView (xP, yP) = (x2 - x1, y2 - y1)
///
/// Event offset relative to FlutterView = (offsetX + xP, offsetY + yP)
// TODO(dit): Make this understand 3D transforms, https://github.com/flutter/flutter/issues/117091
ui.Offset _computeOffsetRelativeToActualTarget(DomMouseEvent event, DomElement actualTarget) {
  final DomElement target = event.target! as DomElement;
  final DomRect targetRect = target.getBoundingClientRect();
  final DomRect actualTargetRect = actualTarget.getBoundingClientRect();
  final double offsetTop = targetRect.y - actualTargetRect.y;
  final double offsetLeft = targetRect.x - actualTargetRect.x;
  return ui.Offset(event.offsetX + offsetLeft, event.offsetY + offsetTop);
}

/// Computes the event offset when TalkBack is firing the event.
///
/// In this case, we need to use the clientX/Y position of the event (which are
/// relative to the absolute top-left corner of the page, including scroll), then
/// deduct the offsetLeft/Top from every offsetParent of the `actualTarget`.
///
///  ×-Page----║-------------------------------+
///  |         ║                               |
///  | ×-------║--------offsetParent(s)-----+  |
///  | |\                                   |  |
///  | | offsetLeft, offsetTop              |  |
///  | |                                    |  |
///  | |                                    |  |
///  | | ×-----║-------------actualTarget-+ |  |
///  | | |                                | |  |
///  ═════     × ─ (scrollLeft, scrollTop)═ ═  ═
///  | | |                                | |  |
///  | | |           ×                    | |  |
///  | | |            \                   | |  |
///  | | |             clientX, clientY   | |  |
///  | | |   (Relative to Page + Scroll)  | |  |
///  | | +-----║--------------------------+ |  |
///  | +-------║----------------------------+  |
///  +---------║-------------------------------+
///
/// Computing the offset of the event relative to the actualTarget requires to
/// compute the clientX, clientY of the actualTarget. To do that, we iterate
/// up the offsetParent elements of actualTarget adding their offset and scroll
/// positions. Finally, we deduct that from clientX, clientY of the event.
// TODO(dit): Make this understand 3D transforms, https://github.com/flutter/flutter/issues/117091
ui.Offset _computeOffsetForTalkbackEvent(DomMouseEvent event, DomElement actualTarget) {
  assert(EngineSemanticsOwner.instance.semanticsEnabled);
  // Use clientX/clientY as the position of the event (this is relative to
  // the top left of the page, including scroll)
  double offsetX = event.clientX;
  double offsetY = event.clientY;
  // Compute the scroll offset of actualTarget
  DomHTMLElement parent = actualTarget as DomHTMLElement;
  while(parent.offsetParent != null){
    offsetX -= parent.offsetLeft - parent.scrollLeft;
    offsetY -= parent.offsetTop - parent.scrollTop;
    parent = parent.offsetParent!;
  }
  return ui.Offset(offsetX, offsetY);
}
