// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef StyleDifference_h
#define StyleDifference_h

#include "wtf/Assertions.h"

namespace blink {

class StyleDifference {
public:
    enum PropertyDifference {
        TransformChanged = 1 << 0,
        OpacityChanged = 1 << 1,
        ZIndexChanged = 1 << 2,
        FilterChanged = 1 << 3,
        // The object needs to issue paint invalidations if it contains text or properties dependent on color (e.g., border or outline).
        TextOrColorChanged = 1 << 4,
    };

    StyleDifference()
        : m_paintInvalidationType(NoPaintInvalidation)
        , m_layoutType(NoLayout)
        , m_propertySpecificDifferences(0)
    { }

    bool hasDifference() const { return m_paintInvalidationType || m_layoutType || m_propertySpecificDifferences; }

    bool hasAtMostPropertySpecificDifferences(unsigned propertyDifferences) const
    {
        return !m_paintInvalidationType && !m_layoutType && !(m_propertySpecificDifferences & ~propertyDifferences);
    }

    bool needsPaintInvalidation() const { return m_paintInvalidationType != NoPaintInvalidation; }
    void clearNeedsPaintInvalidation() { m_paintInvalidationType = NoPaintInvalidation; }

    // The object just needs to issue paint invalidations.
    bool needsPaintInvalidationObject() const { return m_paintInvalidationType == PaintInvalidationObject; }
    void setNeedsPaintInvalidationObject()
    {
        ASSERT(!needsPaintInvalidationLayer());
        m_paintInvalidationType = PaintInvalidationObject;
    }

    // The layer and its descendant layers need to issue paint invalidations.
    bool needsPaintInvalidationLayer() const { return m_paintInvalidationType == PaintInvalidationLayer; }
    void setNeedsPaintInvalidationLayer() { m_paintInvalidationType = PaintInvalidationLayer; }

    bool needsLayout() const { return m_layoutType != NoLayout; }
    void clearNeedsLayout() { m_layoutType = NoLayout; }

    // The offset of this positioned object has been updated.
    bool needsPositionedMovementLayout() const { return m_layoutType == PositionedMovement; }
    void setNeedsPositionedMovementLayout()
    {
        ASSERT(!needsFullLayout());
        m_layoutType = PositionedMovement;
    }

    bool needsFullLayout() const { return m_layoutType == FullLayout; }
    void setNeedsFullLayout() { m_layoutType = FullLayout; }

    bool transformChanged() const { return m_propertySpecificDifferences & TransformChanged; }
    void setTransformChanged() { m_propertySpecificDifferences |= TransformChanged; }

    bool opacityChanged() const { return m_propertySpecificDifferences & OpacityChanged; }
    void setOpacityChanged() { m_propertySpecificDifferences |= OpacityChanged; }

    bool zIndexChanged() const { return m_propertySpecificDifferences & ZIndexChanged; }
    void setZIndexChanged() { m_propertySpecificDifferences |= ZIndexChanged; }

    bool filterChanged() const { return m_propertySpecificDifferences & FilterChanged; }
    void setFilterChanged() { m_propertySpecificDifferences |= FilterChanged; }

    bool textOrColorChanged() const { return m_propertySpecificDifferences & TextOrColorChanged; }
    void setTextOrColorChanged() { m_propertySpecificDifferences |= TextOrColorChanged; }

private:
    enum PaintInvalidationType {
        NoPaintInvalidation = 0,
        PaintInvalidationObject,
        PaintInvalidationLayer
    };
    unsigned m_paintInvalidationType : 2;

    enum LayoutType {
        NoLayout = 0,
        PositionedMovement,
        FullLayout
    };
    unsigned m_layoutType : 2;

    unsigned m_propertySpecificDifferences : 5;
};

} // namespace blink

#endif // StyleDifference_h
