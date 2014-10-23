/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef OrderIterator_h
#define OrderIterator_h

#include "wtf/Noncopyable.h"

#include <set>

namespace blink {

class RenderBox;

class OrderIterator {
    WTF_MAKE_NONCOPYABLE(OrderIterator);
public:
    friend class OrderIteratorPopulator;

    OrderIterator(const RenderBox*);

    RenderBox* currentChild() const { return m_currentChild; }
    RenderBox* first();
    RenderBox* next();
    void reset();

private:
    const RenderBox* m_containerBox;

    RenderBox* m_currentChild;

    typedef std::set<int> OrderValues;
    OrderValues m_orderValues;
    OrderValues::const_iterator m_orderValuesIterator;
    bool m_isReset;
};

class OrderIteratorPopulator {
public:
    explicit OrderIteratorPopulator(OrderIterator& iterator)
        : m_iterator(iterator)
    {
        m_iterator.m_orderValues.clear();
    }

    ~OrderIteratorPopulator();

    void collectChild(const RenderBox*);

private:
    OrderIterator& m_iterator;
};

} // namespace blink

#endif //  OrderIterator_h
