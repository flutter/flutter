// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SizesCalcParser_h
#define SizesCalcParser_h

#include "core/css/MediaValues.h"
#include "core/css/parser/MediaQueryToken.h"
#include "wtf/text/WTFString.h"

namespace blink {

struct SizesCalcValue {
    double value;
    bool isLength;
    UChar operation;

    SizesCalcValue()
        : value(0)
        , isLength(false)
        , operation(0)
    {
    }

    SizesCalcValue(double numericValue, bool length)
        : value(numericValue)
        , isLength(length)
        , operation(0)
    {
    }
};

class SizesCalcParser {

public:
    SizesCalcParser(MediaQueryTokenIterator start, MediaQueryTokenIterator end, PassRefPtr<MediaValues>);

    bool viewportDependant() const { return m_viewportDependant; }
    unsigned result() const;
    bool isValid() const { return m_isValid; }

private:
    bool calcToReversePolishNotation(MediaQueryTokenIterator start, MediaQueryTokenIterator end);
    bool calculate();
    void appendNumber(const MediaQueryToken&);
    bool appendLength(const MediaQueryToken&);
    bool handleOperator(Vector<MediaQueryToken>& stack, const MediaQueryToken&);
    void appendOperator(const MediaQueryToken&);

    Vector<SizesCalcValue> m_valueList;
    RefPtr<MediaValues> m_mediaValues;
    bool m_viewportDependant;
    bool m_isValid;
    unsigned m_result;
};

} // namespace blink

#endif // SizesCalcParser_h

