/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2012 Google Inc. All rights reserved.
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
 */

#ifndef CSSToStyleMap_h
#define CSSToStyleMap_h

#include "core/CSSPropertyNames.h"
#include "core/animation/Timing.h"
#include "core/animation/css/CSSTransitionData.h"
#include "core/css/resolver/ElementStyleResources.h"
#include "core/rendering/style/RenderStyleConstants.h"
#include "platform/animation/TimingFunction.h"
#include "wtf/Noncopyable.h"

namespace blink {

class FillLayer;
class CSSToLengthConversionData;
class CSSValue;
class RenderStyle;
class StyleImage;
class StyleResolverState;
class NinePieceImage;
class BorderImageLengthBox;

// CSSToStyleMap is a short-lived helper object which
// given the current StyleResolverState can map
// CSSValue objects into their RenderStyle equivalents.

class CSSToStyleMap {
    STACK_ALLOCATED();
    WTF_MAKE_NONCOPYABLE(CSSToStyleMap);
public:
    CSSToStyleMap(const StyleResolverState& state, ElementStyleResources& elementStyleResources) : m_state(state), m_elementStyleResources(elementStyleResources) { }
    void mapFillAttachment(FillLayer*, CSSValue*) const;
    void mapFillClip(FillLayer*, CSSValue*) const;
    void mapFillComposite(FillLayer*, CSSValue*) const;
    void mapFillBlendMode(FillLayer*, CSSValue*) const;
    void mapFillOrigin(FillLayer*, CSSValue*) const;
    void mapFillImage(FillLayer*, CSSValue*);
    void mapFillRepeatX(FillLayer*, CSSValue*) const;
    void mapFillRepeatY(FillLayer*, CSSValue*) const;
    void mapFillSize(FillLayer*, CSSValue*) const;
    void mapFillXPosition(FillLayer*, CSSValue*) const;
    void mapFillYPosition(FillLayer*, CSSValue*) const;
    void mapFillMaskSourceType(FillLayer*, CSSValue*) const;

    static double mapAnimationDelay(CSSValue*);
    static Timing::PlaybackDirection mapAnimationDirection(CSSValue*);
    static double mapAnimationDuration(CSSValue*);
    static Timing::FillMode mapAnimationFillMode(CSSValue*);
    static double mapAnimationIterationCount(CSSValue*);
    static AtomicString mapAnimationName(CSSValue*);
    static EAnimPlayState mapAnimationPlayState(CSSValue*);
    static CSSTransitionData::TransitionProperty mapAnimationProperty(CSSValue*);
    static PassRefPtr<TimingFunction> mapAnimationTimingFunction(CSSValue*, bool allowStepMiddle = false);

    void mapNinePieceImage(RenderStyle* mutableStyle, CSSPropertyID, CSSValue*, NinePieceImage&);
    void mapNinePieceImageSlice(CSSValue*, NinePieceImage&) const;
    BorderImageLengthBox mapNinePieceImageQuad(CSSValue*) const;
    void mapNinePieceImageRepeat(CSSValue*, NinePieceImage&) const;

private:
    const CSSToLengthConversionData& cssToLengthConversionData() const;

    PassRefPtr<StyleImage> styleImage(CSSPropertyID, CSSValue*);

    // FIXME: Consider passing a StyleResolverState (or ElementResolveState)
    // as an argument instead of caching it on this object.
    const StyleResolverState& m_state;
    ElementStyleResources& m_elementStyleResources;
};

}

#endif
