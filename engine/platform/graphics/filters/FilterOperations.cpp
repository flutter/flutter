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

#include "config.h"
#include "platform/graphics/filters/FilterOperations.h"

#include "platform/LengthFunctions.h"
#include "platform/geometry/IntSize.h"
#include "platform/graphics/filters/FEGaussianBlur.h"

namespace blink {

static inline IntSize outsetSizeForBlur(float stdDeviation)
{
    IntSize kernelSize = FEGaussianBlur::calculateUnscaledKernelSize(FloatPoint(stdDeviation, stdDeviation));

    IntSize outset;
    // We take the half kernel size and multiply it with three, because we run box blur three times.
    outset.setWidth(3 * kernelSize.width() * 0.5f);
    outset.setHeight(3 * kernelSize.height() * 0.5f);

    return outset;
}

FilterOperations::FilterOperations()
{
}

FilterOperations& FilterOperations::operator=(const FilterOperations& other)
{
    m_operations = other.m_operations;
    return *this;
}

bool FilterOperations::operator==(const FilterOperations& o) const
{
    if (m_operations.size() != o.m_operations.size())
        return false;

    unsigned s = m_operations.size();
    for (unsigned i = 0; i < s; i++) {
        if (*m_operations[i] != *o.m_operations[i])
            return false;
    }

    return true;
}

bool FilterOperations::canInterpolateWith(const FilterOperations& other) const
{
    for (size_t i = 0; i < operations().size(); ++i) {
        if (!FilterOperation::canInterpolate(operations()[i]->type()))
            return false;
    }

    for (size_t i = 0; i < other.operations().size(); ++i) {
        if (!FilterOperation::canInterpolate(other.operations()[i]->type()))
            return false;
    }

    size_t commonSize = std::min(operations().size(), other.operations().size());
    for (size_t i = 0; i < commonSize; ++i) {
        if (!operations()[i]->isSameType(*other.operations()[i]))
            return false;
    }
    return true;
}

bool FilterOperations::hasReferenceFilter() const
{
    for (size_t i = 0; i < m_operations.size(); ++i) {
        if (m_operations.at(i)->type() == FilterOperation::REFERENCE)
            return true;
    }
    return false;
}

bool FilterOperations::hasOutsets() const
{
    for (size_t i = 0; i < m_operations.size(); ++i) {
        FilterOperation::OperationType operationType = m_operations.at(i)->type();
        if (operationType == FilterOperation::BLUR || operationType == FilterOperation::DROP_SHADOW || operationType == FilterOperation::REFERENCE)
            return true;
    }
    return false;
}

FilterOutsets FilterOperations::outsets() const
{
    FilterOutsets totalOutsets;
    for (size_t i = 0; i < m_operations.size(); ++i) {
        FilterOperation* filterOperation = m_operations.at(i).get();
        switch (filterOperation->type()) {
        case FilterOperation::BLUR: {
            BlurFilterOperation* blurOperation = toBlurFilterOperation(filterOperation);
            float stdDeviation = floatValueForLength(blurOperation->stdDeviation(), 0);
            IntSize outsetSize = outsetSizeForBlur(stdDeviation);
            FilterOutsets outsets(outsetSize.height(), outsetSize.width(), outsetSize.height(), outsetSize.width());
            totalOutsets += outsets;
            break;
        }
        case FilterOperation::DROP_SHADOW: {
            DropShadowFilterOperation* dropShadowOperation = toDropShadowFilterOperation(filterOperation);
            IntSize outsetSize = outsetSizeForBlur(dropShadowOperation->stdDeviation());
            FilterOutsets outsets(
                std::max(0, outsetSize.height() - dropShadowOperation->y()),
                std::max(0, outsetSize.width() + dropShadowOperation->x()),
                std::max(0, outsetSize.height() + dropShadowOperation->y()),
                std::max(0, outsetSize.width() - dropShadowOperation->x())
            );
            totalOutsets += outsets;
            break;
        }
        case FilterOperation::REFERENCE: {
            ReferenceFilterOperation* referenceOperation = toReferenceFilterOperation(filterOperation);
            if (referenceOperation->filter() && referenceOperation->filter()->lastEffect()) {
                FloatRect outsetRect(0, 0, 1, 1);
                outsetRect = referenceOperation->filter()->lastEffect()->mapRectRecursive(outsetRect);
                FilterOutsets outsets(
                    std::max(0.0f, -outsetRect.y()),
                    std::max(0.0f, outsetRect.x() + outsetRect.width() - 1),
                    std::max(0.0f, outsetRect.y() + outsetRect.height() - 1),
                    std::max(0.0f, -outsetRect.x())
                );
                totalOutsets += outsets;
            }
            break;
        }
        default:
            break;
        }
    }
    return totalOutsets;
}

bool FilterOperations::hasFilterThatAffectsOpacity() const
{
    for (size_t i = 0; i < m_operations.size(); ++i)
        if (m_operations[i]->affectsOpacity())
            return true;
    return false;
}

bool FilterOperations::hasFilterThatMovesPixels() const
{
    for (size_t i = 0; i < m_operations.size(); ++i)
        if (m_operations[i]->movesPixels())
            return true;
    return false;
}

} // namespace blink

