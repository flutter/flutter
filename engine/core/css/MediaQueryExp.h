/*
 * CSS Media Query
 *
 * Copyright (C) 2006 Kimmo Kinnunen <kimmo.t.kinnunen@nokia.com>.
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef MediaQueryExp_h
#define MediaQueryExp_h

#include "core/CSSValueKeywords.h"
#include "core/MediaFeatureNames.h"
#include "core/css/CSSPrimitiveValue.h"
#include "core/css/CSSValue.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/RefPtr.h"

namespace blink {
class CSSParserValueList;

struct MediaQueryExpValue {
    CSSValueID id;
    double value;
    CSSPrimitiveValue::UnitType unit;
    unsigned numerator;
    unsigned denominator;

    bool isID;
    bool isValue;
    bool isRatio;

    MediaQueryExpValue()
        : id(CSSValueInvalid)
        , value(0)
        , unit(CSSPrimitiveValue::CSS_UNKNOWN)
        , numerator(0)
        , denominator(1)
        , isID(false)
        , isValue(false)
        , isRatio(false)
    {
    }

    bool isValid() const { return (isID || isValue || isRatio); }
    String cssText() const;
    bool equals(const MediaQueryExpValue& expValue) const
    {
        if (isID)
            return (id == expValue.id);
        if (isValue)
            return (value == expValue.value);
        if (isRatio)
            return (numerator == expValue.numerator && denominator == expValue.denominator);
        return !expValue.isValid();
    }
};

class MediaQueryExp  : public NoBaseWillBeGarbageCollectedFinalized<MediaQueryExp> {
    WTF_MAKE_FAST_ALLOCATED_WILL_BE_REMOVED;
public:
    static PassOwnPtrWillBeRawPtr<MediaQueryExp> createIfValid(const String& mediaFeature, CSSParserValueList*);
    ~MediaQueryExp();

    const String& mediaFeature() const { return m_mediaFeature; }

    MediaQueryExpValue expValue() const { return m_expValue; }

    bool operator==(const MediaQueryExp& other) const;

    bool isViewportDependent() const;

    String serialize() const;

    PassOwnPtrWillBeRawPtr<MediaQueryExp> copy() const { return adoptPtrWillBeNoop(new MediaQueryExp(*this)); }

    MediaQueryExp(const MediaQueryExp& other);

    void trace(Visitor* visitor) { }

private:
    MediaQueryExp(const String&, const MediaQueryExpValue&);

    String m_mediaFeature;
    MediaQueryExpValue m_expValue;
};

} // namespace

#endif
