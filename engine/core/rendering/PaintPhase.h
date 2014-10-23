/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 *           (C) 2004 Allan Sandfeld Jensen (kde@carewolf.com)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
 * Copyright (C) 2009 Google Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 */

#ifndef PaintPhase_h
#define PaintPhase_h

namespace blink {

/*
 *  The painting of a layer occurs in three distinct phases.  Each phase involves
 *  a recursive descent into the layer's render objects. The first phase is the background phase.
 *  The backgrounds and borders of all blocks are painted.  Inlines are not painted at all.
 *  Floats must paint above block backgrounds but entirely below inline content that can overlap them.
 *  In the foreground phase, all inlines are fully painted.  Inline replaced elements will get all
 *  three phases invoked on them during this phase.
 */

enum PaintPhase {
    PaintPhaseBlockBackground,
    PaintPhaseChildBlockBackground,
    PaintPhaseChildBlockBackgrounds,
    PaintPhaseFloat,
    PaintPhaseForeground,
    PaintPhaseOutline,
    PaintPhaseChildOutlines,
    PaintPhaseSelfOutline,
    PaintPhaseSelection,
    PaintPhaseCollapsedTableBorders,
    PaintPhaseTextClip,
    PaintPhaseMask,
    PaintPhaseClippingMask,
};

enum PaintBehaviorFlags {
    PaintBehaviorNormal = 0,
    PaintBehaviorSelectionOnly = 1 << 0,
    PaintBehaviorForceBlackText = 1 << 1,
    PaintBehaviorFlattenCompositingLayers = 1 << 2,
    PaintBehaviorRenderingSVGMask = 1 << 3,
    PaintBehaviorSkipRootBackground = 1 << 4,
    PaintBehaviorRootBackgroundOnly = 1 << 5
};

typedef unsigned PaintBehavior;

} // namespace blink

#endif // PaintPhase_h
