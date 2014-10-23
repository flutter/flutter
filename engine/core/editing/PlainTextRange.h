/*
 * Copyright (C) 2006, 2007, 2008 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
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

#ifndef PlainTextRange_h
#define PlainTextRange_h

#include "platform/heap/Handle.h"
#include "wtf/NotFound.h"
#include "wtf/PassRefPtr.h"

namespace blink {

class ContainerNode;
class Range;

class PlainTextRange {
public:
    PlainTextRange();
    PlainTextRange(const PlainTextRange&);
    explicit PlainTextRange(int location);
    PlainTextRange(int start, int end);

    size_t end() const { ASSERT(!isNull()); return m_end; }
    size_t start() const { ASSERT(!isNull()); return m_start; }
    bool isNull() const { return m_start == kNotFound; }
    bool isNotNull() const { return m_start != kNotFound; }
    size_t length() const { ASSERT(!isNull()); return m_end - m_start; }

    PassRefPtrWillBeRawPtr<Range> createRange(const ContainerNode& scope) const;
    PassRefPtrWillBeRawPtr<Range> createRangeForSelection(const ContainerNode& scope) const;

    static PlainTextRange create(const ContainerNode& scope, const Range&);

private:
    PlainTextRange& operator=(const PlainTextRange&)  WTF_DELETED_FUNCTION;

    enum GetRangeFor { ForGeneric, ForSelection };
    PassRefPtrWillBeRawPtr<Range> createRangeFor(const ContainerNode& scope, GetRangeFor) const;

    const size_t m_start;
    const size_t m_end;
};

} // namespace blink

#endif // PlainTextRange_h
