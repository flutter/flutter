/*
 * Copyright (C) 2011 Nokia Inc. All rights reserved.
 * Copyright (C) 2012 Google Inc. All rights reserved.
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

#ifndef QuotesData_h
#define QuotesData_h

#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"
#include "wtf/Vector.h"
#include "wtf/text/WTFString.h"

namespace blink {

class QuotesData : public RefCounted<QuotesData> {
public:
    static PassRefPtr<QuotesData> create() { return adoptRef(new QuotesData()); }
    static PassRefPtr<QuotesData> create(const String open, const String close);
    static PassRefPtr<QuotesData> create(UChar open1, UChar close1, UChar open2, UChar close2);

    bool operator==(const QuotesData& o) const { return m_quotePairs == o.m_quotePairs; }
    bool operator!=(const QuotesData& o) const { return !(*this == o); }

    void addPair(const std::pair<String, String> quotePair);
    const String getOpenQuote(int index) const;
    const String getCloseQuote(int index) const;

private:
    QuotesData() { }

    Vector<std::pair<String, String> > m_quotePairs;
};

} // namespace blink

#endif // QuotesData_h
