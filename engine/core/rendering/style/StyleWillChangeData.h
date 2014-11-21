// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef StyleWillChangeData_h
#define StyleWillChangeData_h

#include "gen/sky/core/CSSPropertyNames.h"
#include "gen/sky/core/CSSValueKeywords.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/Vector.h"

namespace blink {

class StyleWillChangeData : public RefCounted<StyleWillChangeData> {
public:
    static PassRefPtr<StyleWillChangeData> create() { return adoptRef(new StyleWillChangeData); }
    PassRefPtr<StyleWillChangeData> copy() const { return adoptRef(new StyleWillChangeData(*this)); }

    bool operator==(const StyleWillChangeData& o) const
    {
        return m_properties == o.m_properties && m_contents == o.m_contents && m_scrollPosition == o.m_scrollPosition;
    }

    bool operator!=(const StyleWillChangeData& o) const
    {
        return !(*this == o);
    }

    Vector<CSSPropertyID> m_properties;
    unsigned m_contents : 1;
    unsigned m_scrollPosition : 1;

private:
    StyleWillChangeData();
    StyleWillChangeData(const StyleWillChangeData&);
};

} // namespace blink

#endif // StyleWillChangeData_h
