/*
 * Copyright (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008 Apple Inc. All rights reserved.
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

#include "config.h"
#include "core/rendering/style/FillLayer.h"

#include "core/rendering/style/DataEquivalency.h"

namespace blink {

struct SameSizeAsFillLayer {
    FillLayer* m_next;

    RefPtr<StyleImage> m_image;

    Length m_xPosition;
    Length m_yPosition;

    LengthSize m_sizeLength;

    unsigned m_bitfields1;
    unsigned m_bitfields2;
};

COMPILE_ASSERT(sizeof(FillLayer) == sizeof(SameSizeAsFillLayer), FillLayer_should_stay_small);

FillLayer::FillLayer(EFillLayerType type, bool useInitialValues)
    : m_next(0)
    , m_image(FillLayer::initialFillImage(type))
    , m_xPosition(FillLayer::initialFillXPosition(type))
    , m_yPosition(FillLayer::initialFillYPosition(type))
    , m_sizeLength(FillLayer::initialFillSizeLength(type))
    , m_attachment(FillLayer::initialFillAttachment(type))
    , m_clip(FillLayer::initialFillClip(type))
    , m_origin(FillLayer::initialFillOrigin(type))
    , m_repeatX(FillLayer::initialFillRepeatX(type))
    , m_repeatY(FillLayer::initialFillRepeatY(type))
    , m_composite(FillLayer::initialFillComposite(type))
    , m_sizeType(useInitialValues ? FillLayer::initialFillSizeType(type) : SizeNone)
    , m_blendMode(FillLayer::initialFillBlendMode(type))
    , m_maskSourceType(FillLayer::initialFillMaskSourceType(type))
    , m_backgroundXOrigin(LeftEdge)
    , m_backgroundYOrigin(TopEdge)
    , m_imageSet(useInitialValues)
    , m_attachmentSet(useInitialValues)
    , m_clipSet(useInitialValues)
    , m_originSet(useInitialValues)
    , m_repeatXSet(useInitialValues)
    , m_repeatYSet(useInitialValues)
    , m_xPosSet(useInitialValues)
    , m_yPosSet(useInitialValues)
    , m_backgroundXOriginSet(false)
    , m_backgroundYOriginSet(false)
    , m_compositeSet(useInitialValues || type == MaskFillLayer)
    , m_blendModeSet(useInitialValues)
    , m_maskSourceTypeSet(useInitialValues)
    , m_type(type)
{
}

FillLayer::FillLayer(const FillLayer& o)
    : m_next(o.m_next ? new FillLayer(*o.m_next) : 0)
    , m_image(o.m_image)
    , m_xPosition(o.m_xPosition)
    , m_yPosition(o.m_yPosition)
    , m_sizeLength(o.m_sizeLength)
    , m_attachment(o.m_attachment)
    , m_clip(o.m_clip)
    , m_origin(o.m_origin)
    , m_repeatX(o.m_repeatX)
    , m_repeatY(o.m_repeatY)
    , m_composite(o.m_composite)
    , m_sizeType(o.m_sizeType)
    , m_blendMode(o.m_blendMode)
    , m_maskSourceType(o.m_maskSourceType)
    , m_backgroundXOrigin(o.m_backgroundXOrigin)
    , m_backgroundYOrigin(o.m_backgroundYOrigin)
    , m_imageSet(o.m_imageSet)
    , m_attachmentSet(o.m_attachmentSet)
    , m_clipSet(o.m_clipSet)
    , m_originSet(o.m_originSet)
    , m_repeatXSet(o.m_repeatXSet)
    , m_repeatYSet(o.m_repeatYSet)
    , m_xPosSet(o.m_xPosSet)
    , m_yPosSet(o.m_yPosSet)
    , m_backgroundXOriginSet(o.m_backgroundXOriginSet)
    , m_backgroundYOriginSet(o.m_backgroundYOriginSet)
    , m_compositeSet(o.m_compositeSet)
    , m_blendModeSet(o.m_blendModeSet)
    , m_maskSourceTypeSet(o.m_maskSourceTypeSet)
    , m_type(o.m_type)
{
}

FillLayer::~FillLayer()
{
    delete m_next;
}

FillLayer& FillLayer::operator=(const FillLayer& o)
{
    if (m_next != o.m_next) {
        delete m_next;
        m_next = o.m_next ? new FillLayer(*o.m_next) : 0;
    }

    m_image = o.m_image;
    m_xPosition = o.m_xPosition;
    m_yPosition = o.m_yPosition;
    m_backgroundXOrigin = o.m_backgroundXOrigin;
    m_backgroundYOrigin = o.m_backgroundYOrigin;
    m_backgroundXOriginSet = o.m_backgroundXOriginSet;
    m_backgroundYOriginSet = o.m_backgroundYOriginSet;
    m_sizeLength = o.m_sizeLength;
    m_attachment = o.m_attachment;
    m_clip = o.m_clip;
    m_composite = o.m_composite;
    m_blendMode = o.m_blendMode;
    m_origin = o.m_origin;
    m_repeatX = o.m_repeatX;
    m_repeatY = o.m_repeatY;
    m_sizeType = o.m_sizeType;
    m_maskSourceType = o.m_maskSourceType;

    m_imageSet = o.m_imageSet;
    m_attachmentSet = o.m_attachmentSet;
    m_clipSet = o.m_clipSet;
    m_compositeSet = o.m_compositeSet;
    m_blendModeSet = o.m_blendModeSet;
    m_originSet = o.m_originSet;
    m_repeatXSet = o.m_repeatXSet;
    m_repeatYSet = o.m_repeatYSet;
    m_xPosSet = o.m_xPosSet;
    m_yPosSet = o.m_yPosSet;
    m_maskSourceTypeSet = o.m_maskSourceTypeSet;

    m_type = o.m_type;

    return *this;
}

bool FillLayer::operator==(const FillLayer& o) const
{
    // We do not check the "isSet" booleans for each property, since those are only used during initial construction
    // to propagate patterns into layers.  All layer comparisons happen after values have all been filled in anyway.
    return dataEquivalent(m_image, o.m_image) && m_xPosition == o.m_xPosition && m_yPosition == o.m_yPosition
            && m_backgroundXOrigin == o.m_backgroundXOrigin && m_backgroundYOrigin == o.m_backgroundYOrigin
            && m_attachment == o.m_attachment && m_clip == o.m_clip && m_composite == o.m_composite
            && m_blendMode == o.m_blendMode && m_origin == o.m_origin && m_repeatX == o.m_repeatX
            && m_repeatY == o.m_repeatY && m_sizeType == o.m_sizeType && m_maskSourceType == o.m_maskSourceType
            && m_sizeLength == o.m_sizeLength && m_type == o.m_type
            && ((m_next && o.m_next) ? *m_next == *o.m_next : m_next == o.m_next);
}

void FillLayer::fillUnsetProperties()
{
    FillLayer* curr;
    for (curr = this; curr && curr->isXPositionSet(); curr = curr->next()) { }
    if (curr && curr != this) {
        // We need to fill in the remaining values with the pattern specified.
        for (FillLayer* pattern = this; curr; curr = curr->next()) {
            curr->m_xPosition = pattern->m_xPosition;
            if (pattern->isBackgroundXOriginSet())
                curr->m_backgroundXOrigin = pattern->m_backgroundXOrigin;
            if (pattern->isBackgroundYOriginSet())
                curr->m_backgroundYOrigin = pattern->m_backgroundYOrigin;
            pattern = pattern->next();
            if (pattern == curr || !pattern)
                pattern = this;
        }
    }

    for (curr = this; curr && curr->isYPositionSet(); curr = curr->next()) { }
    if (curr && curr != this) {
        // We need to fill in the remaining values with the pattern specified.
        for (FillLayer* pattern = this; curr; curr = curr->next()) {
            curr->m_yPosition = pattern->m_yPosition;
            if (pattern->isBackgroundXOriginSet())
                curr->m_backgroundXOrigin = pattern->m_backgroundXOrigin;
            if (pattern->isBackgroundYOriginSet())
                curr->m_backgroundYOrigin = pattern->m_backgroundYOrigin;
            pattern = pattern->next();
            if (pattern == curr || !pattern)
                pattern = this;
        }
    }

    for (curr = this; curr && curr->isAttachmentSet(); curr = curr->next()) { }
    if (curr && curr != this) {
        // We need to fill in the remaining values with the pattern specified.
        for (FillLayer* pattern = this; curr; curr = curr->next()) {
            curr->m_attachment = pattern->m_attachment;
            pattern = pattern->next();
            if (pattern == curr || !pattern)
                pattern = this;
        }
    }

    for (curr = this; curr && curr->isClipSet(); curr = curr->next()) { }
    if (curr && curr != this) {
        // We need to fill in the remaining values with the pattern specified.
        for (FillLayer* pattern = this; curr; curr = curr->next()) {
            curr->m_clip = pattern->m_clip;
            pattern = pattern->next();
            if (pattern == curr || !pattern)
                pattern = this;
        }
    }

    for (curr = this; curr && curr->isCompositeSet(); curr = curr->next()) { }
    if (curr && curr != this) {
        // We need to fill in the remaining values with the pattern specified.
        for (FillLayer* pattern = this; curr; curr = curr->next()) {
            curr->m_composite = pattern->m_composite;
            pattern = pattern->next();
            if (pattern == curr || !pattern)
                pattern = this;
        }
    }

    for (curr = this; curr && curr->isBlendModeSet(); curr = curr->next()) { }
    if (curr && curr != this) {
        // We need to fill in the remaining values with the pattern specified.
        for (FillLayer* pattern = this; curr; curr = curr->next()) {
            curr->m_blendMode = pattern->m_blendMode;
            pattern = pattern->next();
            if (pattern == curr || !pattern)
                pattern = this;
        }
    }

    for (curr = this; curr && curr->isOriginSet(); curr = curr->next()) { }
    if (curr && curr != this) {
        // We need to fill in the remaining values with the pattern specified.
        for (FillLayer* pattern = this; curr; curr = curr->next()) {
            curr->m_origin = pattern->m_origin;
            pattern = pattern->next();
            if (pattern == curr || !pattern)
                pattern = this;
        }
    }

    for (curr = this; curr && curr->isRepeatXSet(); curr = curr->next()) { }
    if (curr && curr != this) {
        // We need to fill in the remaining values with the pattern specified.
        for (FillLayer* pattern = this; curr; curr = curr->next()) {
            curr->m_repeatX = pattern->m_repeatX;
            pattern = pattern->next();
            if (pattern == curr || !pattern)
                pattern = this;
        }
    }

    for (curr = this; curr && curr->isRepeatYSet(); curr = curr->next()) { }
    if (curr && curr != this) {
        // We need to fill in the remaining values with the pattern specified.
        for (FillLayer* pattern = this; curr; curr = curr->next()) {
            curr->m_repeatY = pattern->m_repeatY;
            pattern = pattern->next();
            if (pattern == curr || !pattern)
                pattern = this;
        }
    }

    for (curr = this; curr && curr->isSizeSet(); curr = curr->next()) { }
    if (curr && curr != this) {
        // We need to fill in the remaining values with the pattern specified.
        for (FillLayer* pattern = this; curr; curr = curr->next()) {
            curr->m_sizeType = pattern->m_sizeType;
            curr->m_sizeLength = pattern->m_sizeLength;
            pattern = pattern->next();
            if (pattern == curr || !pattern)
                pattern = this;
        }
    }
}

void FillLayer::cullEmptyLayers()
{
    FillLayer* next;
    for (FillLayer* p = this; p; p = next) {
        next = p->m_next;
        if (next && !next->isImageSet()) {
            delete next;
            p->m_next = 0;
            break;
        }
    }
}

static EFillBox clipMax(EFillBox clipA, EFillBox clipB)
{
    if (clipA == BorderFillBox || clipB == BorderFillBox)
        return BorderFillBox;
    if (clipA == PaddingFillBox || clipB == PaddingFillBox)
        return PaddingFillBox;
    if (clipA == ContentFillBox || clipB == ContentFillBox)
        return ContentFillBox;
    return TextFillBox;
}

void FillLayer::computeClipMax() const
{
    if (m_next) {
        m_next->computeClipMax();
        m_clipMax = clipMax(clip(), m_next->clip());
    } else
        m_clipMax = m_clip;
}

bool FillLayer::clipOccludesNextLayers(bool firstLayer) const
{
    if (firstLayer)
        computeClipMax();
    return m_clip == m_clipMax;
}

bool FillLayer::containsImage(StyleImage* s) const
{
    if (!s)
        return false;
    if (m_image && *s == *m_image)
        return true;
    if (m_next)
        return m_next->containsImage(s);
    return false;
}

bool FillLayer::imagesAreLoaded() const
{
    const FillLayer* curr;
    for (curr = this; curr; curr = curr->next()) {
        if (curr->m_image && !curr->m_image->isLoaded())
            return false;
    }

    return true;
}

bool FillLayer::hasOpaqueImage(const RenderObject* renderer) const
{
    if (!m_image)
        return false;

    if (m_composite == CompositeClear || m_composite == CompositeCopy)
        return true;

    if (m_blendMode != WebBlendModeNormal)
        return false;

    if (m_composite == CompositeSourceOver)
        return m_image->knownToBeOpaque(renderer);

    return false;
}

bool FillLayer::hasRepeatXY() const
{
    return m_repeatX == RepeatFill && m_repeatY == RepeatFill;
}

} // namespace blink
