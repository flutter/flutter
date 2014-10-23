/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003, 2005, 2006, 2007, 2008 Apple Inc. All rights reserved.
 * Copyright (C) 2006 Graham Dennis (graham.dennis@gmail.com)
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

#ifndef TransformOperations_h
#define TransformOperations_h

#include "platform/geometry/LayoutSize.h"
#include "platform/transforms/TransformOperation.h"
#include "wtf/RefPtr.h"
#include "wtf/Vector.h"

namespace blink {
class FloatBox;
class PLATFORM_EXPORT TransformOperations {
    WTF_MAKE_FAST_ALLOCATED;
public:
    explicit TransformOperations(bool makeIdentity = false);

    bool operator==(const TransformOperations& o) const;
    bool operator!=(const TransformOperations& o) const
    {
        return !(*this == o);
    }

    void apply(const FloatSize& sz, TransformationMatrix& t) const
    {
        for (unsigned i = 0; i < m_operations.size(); ++i)
            m_operations[i]->apply(t, sz);
    }

    // Return true if any of the operation types are 3D operation types (even if the
    // values describe affine transforms)
    bool has3DOperation() const
    {
        for (unsigned i = 0; i < m_operations.size(); ++i)
            if (m_operations[i]->is3DOperation())
                return true;
        return false;
    }

    bool dependsOnBoxSize() const
    {
        for (unsigned i = 0; i < m_operations.size(); ++i) {
            if (m_operations[i]->dependsOnBoxSize())
                return true;
        }
        return false;
    }

    bool operationsMatch(const TransformOperations&) const;

    void clear()
    {
        m_operations.clear();
    }

    Vector<RefPtr<TransformOperation> >& operations() { return m_operations; }
    const Vector<RefPtr<TransformOperation> >& operations() const { return m_operations; }

    size_t size() const { return m_operations.size(); }
    const TransformOperation* at(size_t index) const { return index < m_operations.size() ? m_operations.at(index).get() : 0; }

    bool blendedBoundsForBox(const FloatBox&, const TransformOperations& from, const double& minProgress, const double& maxProgress, FloatBox* bounds) const;
    TransformOperations blendByMatchingOperations(const TransformOperations& from, const double& progress) const;
    TransformOperations blendByUsingMatrixInterpolation(const TransformOperations& from, double progress) const;
    TransformOperations blend(const TransformOperations& from, double progress) const;
    TransformOperations add(const TransformOperations& addend) const;

private:
    Vector<RefPtr<TransformOperation> > m_operations;
};

} // namespace blink

#endif // TransformOperations_h
