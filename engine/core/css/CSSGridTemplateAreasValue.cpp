/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#include "config.h"
#include "core/css/CSSGridTemplateAreasValue.h"

#include "wtf/text/StringBuilder.h"

namespace blink {

CSSGridTemplateAreasValue::CSSGridTemplateAreasValue(const NamedGridAreaMap& gridAreaMap, size_t rowCount, size_t columnCount)
    : CSSValue(GridTemplateAreasClass)
    , m_gridAreaMap(gridAreaMap)
    , m_rowCount(rowCount)
    , m_columnCount(columnCount)
{
    ASSERT(m_rowCount);
    ASSERT(m_columnCount);
}

static String stringForPosition(const NamedGridAreaMap& gridAreaMap, size_t row, size_t column)
{
    Vector<String> candidates;

    NamedGridAreaMap::const_iterator end = gridAreaMap.end();
    for (NamedGridAreaMap::const_iterator it = gridAreaMap.begin(); it != end; ++it) {
        const GridCoordinate& coordinate = it->value;
        if (row >= coordinate.rows.resolvedInitialPosition.toInt() && row <= coordinate.rows.resolvedFinalPosition.toInt())
            candidates.append(it->key);
    }

    end = gridAreaMap.end();
    for (NamedGridAreaMap::const_iterator it = gridAreaMap.begin(); it != end; ++it) {
        const GridCoordinate& coordinate = it->value;
        if (column >= coordinate.columns.resolvedInitialPosition.toInt() && column <= coordinate.columns.resolvedFinalPosition.toInt() && candidates.contains(it->key))
            return it->key;
    }

    return ".";
}

String CSSGridTemplateAreasValue::customCSSText() const
{
    StringBuilder builder;
    for (size_t row = 0; row < m_rowCount; ++row) {
        builder.append('\"');
        for (size_t column = 0; column < m_columnCount; ++column) {
            builder.append(stringForPosition(m_gridAreaMap, row, column));
            if (column != m_columnCount - 1)
                builder.append(' ');
        }
        builder.append('\"');
        if (row != m_rowCount - 1)
            builder.append(' ');
    }
    return builder.toString();
}

} // namespace blink
