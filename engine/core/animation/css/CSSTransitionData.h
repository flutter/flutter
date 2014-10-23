// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CSSTransitionData_h
#define CSSTransitionData_h

#include "core/CSSPropertyNames.h"
#include "core/animation/css/CSSTimingData.h"
#include "wtf/Vector.h"

namespace blink {

class CSSTransitionData FINAL : public CSSTimingData {
public:
    enum TransitionPropertyType {
        TransitionNone,
        TransitionSingleProperty,
        TransitionUnknown,
        TransitionAll
    };

    // FIXME: We shouldn't allow 'none' to be used alongside other properties.
    struct TransitionProperty {
        TransitionProperty(CSSPropertyID id)
            : propertyType(TransitionSingleProperty)
            , propertyId(id)
        {
            ASSERT(id != CSSPropertyInvalid);
        }

        TransitionProperty(const String& string)
            : propertyType(TransitionUnknown)
            , propertyId(CSSPropertyInvalid)
            , propertyString(string)
        {
        }

        TransitionProperty(TransitionPropertyType type)
            : propertyType(type)
            , propertyId(CSSPropertyInvalid)
        {
            ASSERT(type == TransitionNone || type == TransitionAll);
        }

        bool operator==(const TransitionProperty& other) const { return propertyType == other.propertyType && propertyId == other.propertyId && propertyString == other.propertyString; }

        TransitionPropertyType propertyType;
        CSSPropertyID propertyId;
        String propertyString;
    };

    static PassOwnPtrWillBeRawPtr<CSSTransitionData> create()
    {
        return adoptPtrWillBeNoop(new CSSTransitionData);
    }

    static PassOwnPtrWillBeRawPtr<CSSTransitionData> create(const CSSTransitionData& transitionData)
    {
        return adoptPtrWillBeNoop(new CSSTransitionData(transitionData));
    }

    bool transitionsMatchForStyleRecalc(const CSSTransitionData& other) const;

    Timing convertToTiming(size_t index) const;

    const Vector<TransitionProperty>& propertyList() const { return m_propertyList; }
    Vector<TransitionProperty>& propertyList() { return m_propertyList; }

    static TransitionProperty initialProperty() { return TransitionProperty(TransitionAll); }

private:
    CSSTransitionData();
    explicit CSSTransitionData(const CSSTransitionData&);

    Vector<TransitionProperty> m_propertyList;
};

} // namespace blink

#endif // CSSTransitionData_h
