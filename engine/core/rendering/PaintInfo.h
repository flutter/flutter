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

#ifndef PaintInfo_h
#define PaintInfo_h

#include <limits>
#include "core/rendering/PaintPhase.h"
#include "platform/geometry/IntRect.h"
#include "platform/geometry/LayoutRect.h"
#include "platform/graphics/GraphicsContext.h"
#include "platform/transforms/AffineTransform.h"
#include "wtf/HashMap.h"
#include "wtf/ListHashSet.h"

namespace blink {

class RenderInline;
class RenderLayerModelObject;
class RenderObject;
class RenderWidget;

typedef HashMap<RenderWidget*, IntRect> OverlapTestRequestMap;

/*
 * Paint the object and its children, clipped by (x|y|w|h).
 * (tx|ty) is the calculated position of the parent
 */
struct PaintInfo {
    PaintInfo(GraphicsContext* newContext, const IntRect& newRect, PaintPhase newPhase, PaintBehavior newPaintBehavior,
        RenderObject* newPaintingRoot = 0, ListHashSet<RenderInline*>* newOutlineObjects = 0,
        const RenderLayerModelObject* newPaintContainer = 0)
        : context(newContext)
        , rect(newRect)
        , phase(newPhase)
        , paintBehavior(newPaintBehavior)
        , paintingRoot(newPaintingRoot)
        , m_paintContainer(newPaintContainer)
        , m_outlineObjects(newOutlineObjects)
    {
    }

    void updatePaintingRootForChildren(const RenderObject* renderer)
    {
        if (!paintingRoot)
            return;

        // If we're the painting root, kids draw normally, and see root of 0.
        if (paintingRoot == renderer) {
            paintingRoot = 0;
            return;
        }
    }

    bool shouldPaintWithinRoot(const RenderObject* renderer) const
    {
        return !paintingRoot || paintingRoot == renderer;
    }

    bool forceBlackText() const { return paintBehavior & PaintBehaviorForceBlackText; }

    bool skipRootBackground() const { return paintBehavior & PaintBehaviorSkipRootBackground; }
    bool paintRootBackgroundOnly() const { return paintBehavior & PaintBehaviorRootBackgroundOnly; }

    void applyTransform(const AffineTransform& localToAncestorTransform, bool identityStatusUnknown = true)
    {
        if (identityStatusUnknown && localToAncestorTransform.isIdentity())
            return;

        context->concatCTM(localToAncestorTransform);

        if (rect == infiniteRect())
            return;

        if (localToAncestorTransform.isInvertible())
            rect = localToAncestorTransform.inverse().mapRect(rect);
        else
            rect.setSize(IntSize(0, 0));
    }

    static IntRect infiniteRect() { return IntRect(LayoutRect::infiniteRect()); }
    const RenderLayerModelObject* paintContainer() const { return m_paintContainer; }

    ListHashSet<RenderInline*>* outlineObjects() { return m_outlineObjects; }
    void setOutlineObjects(ListHashSet<RenderInline*>* objects) { m_outlineObjects = objects; }

    // FIXME: Introduce setters/getters at some point. Requires a lot of changes throughout rendering/.
    GraphicsContext* context;
    IntRect rect;
    PaintPhase phase;
    PaintBehavior paintBehavior;
    RenderObject* paintingRoot; // used to draw just one element and its visual kids

private:
    const RenderLayerModelObject* m_paintContainer; // the layer object that originates the current painting
    ListHashSet<RenderInline*>* m_outlineObjects; // used to list outlines that should be painted by a block with inline children
};

} // namespace blink

#endif // PaintInfo_h
