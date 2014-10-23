/*
 * Copyright (C) 2011 Apple Inc. All rights reserved.
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

#ifndef FilterOperations_h
#define FilterOperations_h

#include "platform/PlatformExport.h"
#include "platform/geometry/IntRectExtent.h"
#include "platform/graphics/filters/FilterOperation.h"
#include "wtf/RefPtr.h"
#include "wtf/Vector.h"

namespace blink {

typedef IntRectExtent FilterOutsets;

class PLATFORM_EXPORT FilterOperations {
    WTF_MAKE_FAST_ALLOCATED;
public:
    FilterOperations();
    FilterOperations(const FilterOperations& other) { *this = other; }

    FilterOperations& operator=(const FilterOperations&);

    bool operator==(const FilterOperations&) const;
    bool operator!=(const FilterOperations& o) const
    {
        return !(*this == o);
    }

    void clear()
    {
        m_operations.clear();
    }

    Vector<RefPtr<FilterOperation> >& operations() { return m_operations; }
    const Vector<RefPtr<FilterOperation> >& operations() const { return m_operations; }

    bool isEmpty() const { return !m_operations.size(); }
    size_t size() const { return m_operations.size(); }
    const FilterOperation* at(size_t index) const { return index < m_operations.size() ? m_operations.at(index).get() : 0; }

    bool canInterpolateWith(const FilterOperations&) const;

    bool hasOutsets() const;
    FilterOutsets outsets() const;

    bool hasFilterThatAffectsOpacity() const;
    bool hasFilterThatMovesPixels() const;

    bool hasReferenceFilter() const;
private:
    Vector<RefPtr<FilterOperation> > m_operations;
};

} // namespace blink


#endif // FilterOperations_h
