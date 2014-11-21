// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CompositingReasons_h
#define CompositingReasons_h

#include <stdint.h>
#include "sky/engine/platform/PlatformExport.h"
#include "sky/engine/wtf/MathExtras.h"

namespace blink {

const uint64_t CompositingReasonNone                                     = 0;
const uint64_t CompositingReasonAll                                      = ~static_cast<uint64_t>(0);

// FIXME(sky): Get rid of all this.

// Intrinsic reasons that can be known right away by the layer
const uint64_t CompositingReason3DTransform                              = UINT64_C(1) << 0;
const uint64_t CompositingReasonVideo                                    = UINT64_C(1) << 1;
const uint64_t CompositingReasonCanvas                                   = UINT64_C(1) << 2;
const uint64_t CompositingReasonIFrame                                   = UINT64_C(1) << 4;
const uint64_t CompositingReasonBackfaceVisibilityHidden                 = UINT64_C(1) << 5;
const uint64_t CompositingReasonActiveAnimation                          = UINT64_C(1) << 6;
const uint64_t CompositingReasonTransitionProperty                       = UINT64_C(1) << 7;
const uint64_t CompositingReasonOverflowScrollingTouch                   = UINT64_C(1) << 9;
const uint64_t CompositingReasonOverflowScrollingParent                  = UINT64_C(1) << 10;
const uint64_t CompositingReasonOutOfFlowClipping                        = UINT64_C(1) << 11;
const uint64_t CompositingReasonWillChangeCompositingHint                = UINT64_C(1) << 13;

// Overlap reasons that require knowing what's behind you in paint-order before knowing the answer
const uint64_t CompositingReasonAssumedOverlap                           = UINT64_C(1) << 14;
const uint64_t CompositingReasonOverlap                                  = UINT64_C(1) << 15;
const uint64_t CompositingReasonNegativeZIndexChildren                   = UINT64_C(1) << 16;
const uint64_t CompositingReasonScrollsWithRespectToSquashingLayer       = UINT64_C(1) << 17;
const uint64_t CompositingReasonSquashingClippingContainerMismatch       = UINT64_C(1) << 19;
const uint64_t CompositingReasonSquashingOpacityAncestorMismatch         = UINT64_C(1) << 20;
const uint64_t CompositingReasonSquashingTransformAncestorMismatch       = UINT64_C(1) << 21;
const uint64_t CompositingReasonSquashingFilterAncestorMismatch          = UINT64_C(1) << 22;
const uint64_t CompositingReasonSquashingWouldBreakPaintOrder            = UINT64_C(1) << 23;
const uint64_t CompositingReasonSquashingVideoIsDisallowed               = UINT64_C(1) << 24;
const uint64_t CompositingReasonSquashedLayerClipsCompositingDescendants = UINT64_C(1) << 25;

// Subtree reasons that require knowing what the status of your subtree is before knowing the answer
const uint64_t CompositingReasonTransformWithCompositedDescendants       = UINT64_C(1) << 28;
const uint64_t CompositingReasonOpacityWithCompositedDescendants         = UINT64_C(1) << 29;
const uint64_t CompositingReasonMaskWithCompositedDescendants            = UINT64_C(1) << 30;
const uint64_t CompositingReasonFilterWithCompositedDescendants          = UINT64_C(1) << 32;
// TODO(sky): Unused 33
const uint64_t CompositingReasonClipsCompositingDescendants              = UINT64_C(1) << 34;
const uint64_t CompositingReasonPerspectiveWith3DDescendants             = UINT64_C(1) << 35;
const uint64_t CompositingReasonPreserve3DWith3DDescendants              = UINT64_C(1) << 36;
// TODO(sky): Unused 37 & 38

// The root layer is a special case that may be forced to be a layer, but also it needs to be
// a layer if anything else in the subtree is composited.
const uint64_t CompositingReasonRoot                                     = UINT64_C(1) << 39;

// CompositedLayerMapping internal hierarchy reasons
const uint64_t CompositingReasonLayerForAncestorClip                     = UINT64_C(1) << 40;
const uint64_t CompositingReasonLayerForDescendantClip                   = UINT64_C(1) << 41;
const uint64_t CompositingReasonLayerForPerspective                      = UINT64_C(1) << 42;
// FIXME(sky): 43 is unused.
// FIXME(sky): 44 is unused.
const uint64_t CompositingReasonLayerForOverflowControlsHost             = UINT64_C(1) << 45;
// FIXME(sky): 46 is unused.
const uint64_t CompositingReasonLayerForSquashingContents                = UINT64_C(1) << 49;
const uint64_t CompositingReasonLayerForSquashingContainer               = UINT64_C(1) << 50;
const uint64_t CompositingReasonLayerForForeground                       = UINT64_C(1) << 51;
const uint64_t CompositingReasonLayerForBackground                       = UINT64_C(1) << 52;
const uint64_t CompositingReasonLayerForMask                             = UINT64_C(1) << 53;
const uint64_t CompositingReasonLayerForClippingMask                     = UINT64_C(1) << 54;
// FIXME(sky): 55 is unused.

// Composited elements with inline transforms trigger assumed overlap so that
// we can update their transforms quickly.
const uint64_t CompositingReasonInlineTransform                          = UINT64_C(1) << 56;

// Various combinations of compositing reasons are defined here also, for more intutive and faster bitwise logic.
const uint64_t CompositingReasonComboAllDirectReasons =
    CompositingReason3DTransform
    | CompositingReasonVideo
    | CompositingReasonCanvas
    | CompositingReasonIFrame
    | CompositingReasonBackfaceVisibilityHidden
    | CompositingReasonActiveAnimation
    | CompositingReasonTransitionProperty
    | CompositingReasonOverflowScrollingTouch
    | CompositingReasonOverflowScrollingParent
    | CompositingReasonOutOfFlowClipping
    | CompositingReasonWillChangeCompositingHint;

const uint64_t CompositingReasonComboAllDirectStyleDeterminedReasons =
    CompositingReason3DTransform
    | CompositingReasonBackfaceVisibilityHidden
    | CompositingReasonActiveAnimation
    | CompositingReasonTransitionProperty
    | CompositingReasonWillChangeCompositingHint;

const uint64_t CompositingReasonComboCompositedDescendants =
    CompositingReasonTransformWithCompositedDescendants
    | CompositingReasonOpacityWithCompositedDescendants
    | CompositingReasonMaskWithCompositedDescendants
    | CompositingReasonFilterWithCompositedDescendants
    | CompositingReasonClipsCompositingDescendants;

const uint64_t CompositingReasonCombo3DDescendants =
    CompositingReasonPreserve3DWith3DDescendants
    | CompositingReasonPerspectiveWith3DDescendants;

const uint64_t CompositingReasonComboAllStyleDeterminedReasons =
    CompositingReasonComboAllDirectStyleDeterminedReasons
    | CompositingReasonComboCompositedDescendants
    | CompositingReasonCombo3DDescendants
    | CompositingReasonInlineTransform;

const uint64_t CompositingReasonComboReasonsThatRequireOwnBacking =
    CompositingReasonComboAllDirectReasons
    | CompositingReasonOverlap
    | CompositingReasonAssumedOverlap
    | CompositingReasonNegativeZIndexChildren
    | CompositingReasonScrollsWithRespectToSquashingLayer
    | CompositingReasonSquashingClippingContainerMismatch
    | CompositingReasonSquashingOpacityAncestorMismatch
    | CompositingReasonSquashingTransformAncestorMismatch
    | CompositingReasonSquashingFilterAncestorMismatch
    | CompositingReasonSquashingWouldBreakPaintOrder
    | CompositingReasonSquashingVideoIsDisallowed
    | CompositingReasonSquashedLayerClipsCompositingDescendants
    | CompositingReasonTransformWithCompositedDescendants
    | CompositingReasonOpacityWithCompositedDescendants
    | CompositingReasonMaskWithCompositedDescendants
    | CompositingReasonFilterWithCompositedDescendants
    | CompositingReasonPreserve3DWith3DDescendants; // preserve-3d has to create backing store to ensure that 3d-transformed elements intersect.

const uint64_t CompositingReasonComboSquashableReasons =
    CompositingReasonOverlap
    | CompositingReasonAssumedOverlap
    | CompositingReasonOverflowScrollingParent;

typedef uint64_t CompositingReasons;

// Any reasons other than overlap or assumed overlap will require the layer to be separately compositing.
inline bool requiresCompositing(CompositingReasons reasons)
{
    return reasons & ~CompositingReasonComboSquashableReasons;
}

// If the layer has overlap or assumed overlap, but no other reasons, then it should be squashed.
inline bool requiresSquashing(CompositingReasons reasons)
{
    return !requiresCompositing(reasons) && (reasons & CompositingReasonComboSquashableReasons);
}

struct CompositingReasonStringMap {
    CompositingReasons reason;
    const char* shortName;
    const char* description;
};

PLATFORM_EXPORT extern const CompositingReasonStringMap kCompositingReasonStringMap[];
PLATFORM_EXPORT extern size_t kNumberOfCompositingReasons;

} // namespace blink

#endif // CompositingReasons_h
