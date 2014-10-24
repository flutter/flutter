/*
 * Copyright (C) 2011 Adobe Systems Incorporated. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer.
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER “AS IS” AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#ifndef CSSBasicShapes_h
#define CSSBasicShapes_h

#include "core/css/CSSPrimitiveValue.h"
#include "platform/graphics/GraphicsTypes.h"
#include "wtf/RefPtr.h"
#include "wtf/Vector.h"
#include "wtf/text/WTFString.h"

namespace blink {

class CSSBasicShape : public RefCountedWillBeGarbageCollected<CSSBasicShape> {
    DECLARE_EMPTY_VIRTUAL_DESTRUCTOR_WILL_BE_REMOVED(CSSBasicShape);
public:
    enum Type {
        CSSBasicShapeEllipseType,
        CSSBasicShapePolygonType,
        CSSBasicShapeCircleType,
        CSSBasicShapeInsetType
    };

    virtual Type type() const = 0;
    virtual String cssText() const = 0;
    virtual bool equals(const CSSBasicShape&) const = 0;

    CSSPrimitiveValue* referenceBox() const { return m_referenceBox.get(); }
    void setReferenceBox(PassRefPtrWillBeRawPtr<CSSPrimitiveValue> referenceBox) { m_referenceBox = referenceBox; }

    virtual void trace(Visitor* visitor) { visitor->trace(m_referenceBox); }

protected:
    CSSBasicShape() { }
    RefPtrWillBeMember<CSSPrimitiveValue> m_referenceBox;
};

class CSSBasicShapeCircle final : public CSSBasicShape {
public:
    static PassRefPtrWillBeRawPtr<CSSBasicShapeCircle> create() { return adoptRefWillBeNoop(new CSSBasicShapeCircle); }

    virtual Type type() const override { return CSSBasicShapeCircleType; }
    virtual String cssText() const override;
    virtual bool equals(const CSSBasicShape&) const override;

    CSSPrimitiveValue* centerX() const { return m_centerX.get(); }
    CSSPrimitiveValue* centerY() const { return m_centerY.get(); }
    CSSPrimitiveValue* radius() const { return m_radius.get(); }

    void setCenterX(PassRefPtrWillBeRawPtr<CSSPrimitiveValue> centerX) { m_centerX = centerX; }
    void setCenterY(PassRefPtrWillBeRawPtr<CSSPrimitiveValue> centerY) { m_centerY = centerY; }
    void setRadius(PassRefPtrWillBeRawPtr<CSSPrimitiveValue> radius) { m_radius = radius; }

    virtual void trace(Visitor*);

private:
    CSSBasicShapeCircle() { }

    RefPtrWillBeMember<CSSPrimitiveValue> m_centerX;
    RefPtrWillBeMember<CSSPrimitiveValue> m_centerY;
    RefPtrWillBeMember<CSSPrimitiveValue> m_radius;
};

class CSSBasicShapeEllipse final : public CSSBasicShape {
public:
    static PassRefPtrWillBeRawPtr<CSSBasicShapeEllipse> create() { return adoptRefWillBeNoop(new CSSBasicShapeEllipse); }

    virtual Type type() const override { return CSSBasicShapeEllipseType; }
    virtual String cssText() const override;
    virtual bool equals(const CSSBasicShape&) const override;

    CSSPrimitiveValue* centerX() const { return m_centerX.get(); }
    CSSPrimitiveValue* centerY() const { return m_centerY.get(); }
    CSSPrimitiveValue* radiusX() const { return m_radiusX.get(); }
    CSSPrimitiveValue* radiusY() const { return m_radiusY.get(); }

    void setCenterX(PassRefPtrWillBeRawPtr<CSSPrimitiveValue> centerX) { m_centerX = centerX; }
    void setCenterY(PassRefPtrWillBeRawPtr<CSSPrimitiveValue> centerY) { m_centerY = centerY; }
    void setRadiusX(PassRefPtrWillBeRawPtr<CSSPrimitiveValue> radiusX) { m_radiusX = radiusX; }
    void setRadiusY(PassRefPtrWillBeRawPtr<CSSPrimitiveValue> radiusY) { m_radiusY = radiusY; }

    virtual void trace(Visitor*);

private:
    CSSBasicShapeEllipse() { }

    RefPtrWillBeMember<CSSPrimitiveValue> m_centerX;
    RefPtrWillBeMember<CSSPrimitiveValue> m_centerY;
    RefPtrWillBeMember<CSSPrimitiveValue> m_radiusX;
    RefPtrWillBeMember<CSSPrimitiveValue> m_radiusY;
};

class CSSBasicShapePolygon final : public CSSBasicShape {
public:
    static PassRefPtrWillBeRawPtr<CSSBasicShapePolygon> create() { return adoptRefWillBeNoop(new CSSBasicShapePolygon); }

    void appendPoint(PassRefPtrWillBeRawPtr<CSSPrimitiveValue> x, PassRefPtrWillBeRawPtr<CSSPrimitiveValue> y)
    {
        m_values.append(x);
        m_values.append(y);
    }

    PassRefPtrWillBeRawPtr<CSSPrimitiveValue> getXAt(unsigned i) const { return m_values.at(i * 2); }
    PassRefPtrWillBeRawPtr<CSSPrimitiveValue> getYAt(unsigned i) const { return m_values.at(i * 2 + 1); }
    const WillBeHeapVector<RefPtrWillBeMember<CSSPrimitiveValue> >& values() const { return m_values; }

    void setWindRule(WindRule w) { m_windRule = w; }
    WindRule windRule() const { return m_windRule; }

    virtual Type type() const override { return CSSBasicShapePolygonType; }
    virtual String cssText() const override;
    virtual bool equals(const CSSBasicShape&) const override;

    virtual void trace(Visitor*);

private:
    CSSBasicShapePolygon()
        : m_windRule(RULE_NONZERO)
    {
    }

    WillBeHeapVector<RefPtrWillBeMember<CSSPrimitiveValue> > m_values;
    WindRule m_windRule;
};

class CSSBasicShapeInset : public CSSBasicShape {
public:
    static PassRefPtrWillBeRawPtr<CSSBasicShapeInset> create() { return adoptRefWillBeNoop(new CSSBasicShapeInset); }

    CSSPrimitiveValue* top() const { return m_top.get(); }
    CSSPrimitiveValue* right() const { return m_right.get(); }
    CSSPrimitiveValue* bottom() const { return m_bottom.get(); }
    CSSPrimitiveValue* left() const { return m_left.get(); }

    CSSPrimitiveValue* topLeftRadius() const { return m_topLeftRadius.get(); }
    CSSPrimitiveValue* topRightRadius() const { return m_topRightRadius.get(); }
    CSSPrimitiveValue* bottomRightRadius() const { return m_bottomRightRadius.get(); }
    CSSPrimitiveValue* bottomLeftRadius() const { return m_bottomLeftRadius.get(); }

    void setTop(PassRefPtrWillBeRawPtr<CSSPrimitiveValue> top) { m_top = top; }
    void setRight(PassRefPtrWillBeRawPtr<CSSPrimitiveValue> right) { m_right = right; }
    void setBottom(PassRefPtrWillBeRawPtr<CSSPrimitiveValue> bottom) { m_bottom = bottom; }
    void setLeft(PassRefPtrWillBeRawPtr<CSSPrimitiveValue> left) { m_left = left; }

    void updateShapeSize4Values(CSSPrimitiveValue* top, CSSPrimitiveValue* right, CSSPrimitiveValue* bottom, CSSPrimitiveValue* left)
    {
        setTop(top);
        setRight(right);
        setBottom(bottom);
        setLeft(left);
    }

    void updateShapeSize1Value(CSSPrimitiveValue* value1)
    {
        updateShapeSize4Values(value1, value1, value1, value1);
    }

    void updateShapeSize2Values(CSSPrimitiveValue* value1,  CSSPrimitiveValue* value2)
    {
        updateShapeSize4Values(value1, value2, value1, value2);
    }

    void updateShapeSize3Values(CSSPrimitiveValue* value1, CSSPrimitiveValue* value2,  CSSPrimitiveValue* value3)
    {
        updateShapeSize4Values(value1, value2, value3, value2);
    }


    void setTopLeftRadius(PassRefPtrWillBeRawPtr<CSSPrimitiveValue> radius) { m_topLeftRadius = radius; }
    void setTopRightRadius(PassRefPtrWillBeRawPtr<CSSPrimitiveValue> radius) { m_topRightRadius = radius; }
    void setBottomRightRadius(PassRefPtrWillBeRawPtr<CSSPrimitiveValue> radius) { m_bottomRightRadius = radius; }
    void setBottomLeftRadius(PassRefPtrWillBeRawPtr<CSSPrimitiveValue> radius) { m_bottomLeftRadius = radius; }

    virtual Type type() const override { return CSSBasicShapeInsetType; }
    virtual String cssText() const override;
    virtual bool equals(const CSSBasicShape&) const override;

    virtual void trace(Visitor*);

private:
    CSSBasicShapeInset() { }

    RefPtrWillBeMember<CSSPrimitiveValue> m_top;
    RefPtrWillBeMember<CSSPrimitiveValue> m_right;
    RefPtrWillBeMember<CSSPrimitiveValue> m_bottom;
    RefPtrWillBeMember<CSSPrimitiveValue> m_left;

    RefPtrWillBeMember<CSSPrimitiveValue> m_topLeftRadius;
    RefPtrWillBeMember<CSSPrimitiveValue> m_topRightRadius;
    RefPtrWillBeMember<CSSPrimitiveValue> m_bottomRightRadius;
    RefPtrWillBeMember<CSSPrimitiveValue> m_bottomLeftRadius;
};

} // namespace blink

#endif // CSSBasicShapes_h
