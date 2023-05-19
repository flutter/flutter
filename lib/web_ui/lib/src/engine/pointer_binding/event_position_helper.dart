// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/src/engine/embedder.dart';
import 'package:ui/src/engine/text_editing/text_editing.dart';
import 'package:ui/src/engine/vector_math.dart';
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

  // On one of our text-editing nodes
  final bool isInput = flutterViewEmbedder.textEditingHostNode.contains(event.target! as DomNode);
  if (isInput) {
    final EditableTextGeometry? inputGeometry = textEditing.strategy.geometry;
    if (inputGeometry != null) {
      return _computeOffsetForInputs(event, inputGeometry);
    }
  }

  // On another DOM Element (normally a platform view)
  final bool isTargetOutsideOfShadowDOM = event.target != actualTarget;
  if (isTargetOutsideOfShadowDOM) {
    final DomRect origin = actualTarget.getBoundingClientRect();
    // event.clientX/Y and origin.x/y are relative **to the viewport**.
    // (This doesn't work with 3D translations of the parent element.)
    // TODO(dit): Make this understand 3D transforms, https://github.com/flutter/flutter/issues/117091
    return ui.Offset(event.clientX - origin.x, event.clientY - origin.y);
  }

  // Return the offsetX/Y in the normal case.
  // (This works with 3D translations of the parent element.)
  return ui.Offset(event.offsetX, event.offsetY);
}

/// Computes the offsets for input nodes, which live outside of the shadowDOM.
/// Since inputs can be transformed (scaled, translated, etc), we can't rely on
/// `_computeOffsetRelativeToActualTarget` to calculate accurate coordinates, as
/// it only handles the case where inputs are translated, but will have issues
/// for scaled inputs (see: https://github.com/flutter/flutter/issues/125948).
///
/// We compute the offsets here by using the text input geometry data that is
/// sent from the framework, which includes information on how to transform the
/// underlying input element. We transform the `event.offset` points we receive
/// using the values from the input's transform matrix.
ui.Offset _computeOffsetForInputs(DomMouseEvent event, EditableTextGeometry inputGeometry) {
  final DomElement targetElement = event.target! as DomHTMLElement;
  final DomHTMLElement domElement = textEditing.strategy.activeDomElement;
  assert(targetElement == domElement, 'The targeted input element must be the active input element');
  final Float32List transformValues = inputGeometry.globalTransform;
  assert(transformValues.length == 16);
  final Matrix4 transform = Matrix4.fromFloat32List(transformValues);
  final Vector3 transformedPoint = transform.perspectiveTransform(x: event.offsetX, y: event.offsetY, z: 0);

  return ui.Offset(transformedPoint.x, transformedPoint.y);
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
