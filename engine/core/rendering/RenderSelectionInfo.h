/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 *           (C) 2004 Allan Sandfeld Jensen (kde@carewolf.com)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
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

#ifndef RenderSelectionInfo_h
#define RenderSelectionInfo_h

#include "core/rendering/RenderBox.h"
#include "platform/geometry/IntRect.h"

namespace blink {

class RenderSelectionInfoBase : public NoBaseWillBeGarbageCollected<RenderSelectionInfoBase> {
    WTF_MAKE_NONCOPYABLE(RenderSelectionInfoBase); WTF_MAKE_FAST_ALLOCATED_WILL_BE_REMOVED;
public:
    RenderSelectionInfoBase()
        : m_object(nullptr)
        , m_paintInvalidationContainer(nullptr)
        , m_state(RenderObject::SelectionNone)
    {
    }

    RenderSelectionInfoBase(RenderObject* o)
        : m_object(o)
        , m_paintInvalidationContainer(o->containerForPaintInvalidation())
        , m_state(o->selectionState())
    {
    }

    void trace(Visitor* visitor)
    {
        visitor->trace(m_object);
        visitor->trace(m_paintInvalidationContainer);
    }

    RenderObject* object() const { return m_object; }
    const RenderLayerModelObject* paintInvalidationContainer() const { return m_paintInvalidationContainer; }
    RenderObject::SelectionState state() const { return m_state; }

protected:
    RawPtrWillBeMember<RenderObject> m_object;
    RawPtrWillBeMember<const RenderLayerModelObject> m_paintInvalidationContainer;
    RenderObject::SelectionState m_state;
};

// This struct is used when the selection changes to cache the old and new state of the selection for each RenderObject.
class RenderSelectionInfo FINAL : public RenderSelectionInfoBase {
public:
    RenderSelectionInfo(RenderObject* o, bool clipToVisibleContent)
        : RenderSelectionInfoBase(o)
    {
        if (o->canUpdateSelectionOnRootLineBoxes()) {
            m_rect = o->selectionRectForPaintInvalidation(m_paintInvalidationContainer, clipToVisibleContent);
            // FIXME: groupedMapping() leaks the squashing abstraction. See RenderBlockSelectionInfo for more details.
            if (m_paintInvalidationContainer && m_paintInvalidationContainer->layer()->groupedMapping())
                RenderLayer::mapRectToPaintBackingCoordinates(m_paintInvalidationContainer, m_rect);
        } else {
            m_rect = LayoutRect();
        }
    }

    void invalidatePaint()
    {
        m_object->invalidatePaintUsingContainer(m_paintInvalidationContainer, enclosingIntRect(m_rect), InvalidationSelection);
    }

    LayoutRect rect() const { return m_rect; }

private:
    LayoutRect m_rect; // relative to paint invalidation container
};

// This struct is used when the selection changes to cache the old and new state of the selection for each RenderBlock.
class RenderBlockSelectionInfo FINAL : public RenderSelectionInfoBase {
public:
    RenderBlockSelectionInfo(RenderBlock* b)
        : RenderSelectionInfoBase(b)
    {
        if (b->canUpdateSelectionOnRootLineBoxes())
            m_rects = block()->selectionGapRectsForPaintInvalidation(m_paintInvalidationContainer);
        else
            m_rects = GapRects();
    }

    void invalidatePaint()
    {
        LayoutRect paintInvalidationRect = m_rects;
        // FIXME: this is leaking the squashing abstraction. However, removing the groupedMapping() condiitional causes
        // RenderBox::mapRectToPaintInvalidationBacking to get called, which makes rect adjustments even if you pass the same
        // paintInvalidationContainer as the render object. Find out why it does that and fix.
        if (m_paintInvalidationContainer && m_paintInvalidationContainer->layer()->groupedMapping())
            RenderLayer::mapRectToPaintBackingCoordinates(m_paintInvalidationContainer, paintInvalidationRect);
        m_object->invalidatePaintUsingContainer(m_paintInvalidationContainer, enclosingIntRect(paintInvalidationRect), InvalidationSelection);
    }

    RenderBlock* block() const { return toRenderBlock(m_object); }
    GapRects rects() const { return m_rects; }

private:
    GapRects m_rects; // relative to paint invalidation container
};

} // namespace blink


#endif // RenderSelectionInfo_h
