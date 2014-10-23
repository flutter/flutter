// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef DeferredLegacyStyleInterpolation_h
#define DeferredLegacyStyleInterpolation_h

#include "core/animation/StyleInterpolation.h"
#include "core/css/CSSValue.h"

namespace blink {

class CSSBasicShape;
class CSSImageValue;
class CSSPrimitiveValue;
class CSSShadowValue;
class CSSValueList;

class DeferredLegacyStyleInterpolation : public StyleInterpolation {
public:
    static PassRefPtrWillBeRawPtr<DeferredLegacyStyleInterpolation> create(PassRefPtrWillBeRawPtr<CSSValue> start, PassRefPtrWillBeRawPtr<CSSValue> end, CSSPropertyID id)
    {
        return adoptRefWillBeNoop(new DeferredLegacyStyleInterpolation(start, end, id));
    }

    virtual void apply(StyleResolverState&) const OVERRIDE;

    virtual void trace(Visitor*) OVERRIDE;

    static bool interpolationRequiresStyleResolve(const CSSValue&);
    static bool interpolationRequiresStyleResolve(const CSSPrimitiveValue&);
    static bool interpolationRequiresStyleResolve(const CSSImageValue&);
    static bool interpolationRequiresStyleResolve(const CSSShadowValue&);
    static bool interpolationRequiresStyleResolve(const CSSValueList&);
    static bool interpolationRequiresStyleResolve(const CSSBasicShape&);

private:
    DeferredLegacyStyleInterpolation(PassRefPtrWillBeRawPtr<CSSValue> start, PassRefPtrWillBeRawPtr<CSSValue> end, CSSPropertyID id)
        : StyleInterpolation(InterpolableNumber::create(0), InterpolableNumber::create(1), id)
        , m_startCSSValue(start)
        , m_endCSSValue(end)
    {
    }

    RefPtrWillBeMember<CSSValue> m_startCSSValue;
    RefPtrWillBeMember<CSSValue> m_endCSSValue;
};

}

#endif
