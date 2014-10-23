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

#ifndef StyleTransformData_h
#define StyleTransformData_h

#include "platform/Length.h"
#include "platform/transforms/TransformOperations.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"

namespace blink {

class StyleTransformData : public RefCounted<StyleTransformData> {
public:
    static PassRefPtr<StyleTransformData> create() { return adoptRef(new StyleTransformData); }
    PassRefPtr<StyleTransformData> copy() const { return adoptRef(new StyleTransformData(*this)); }

    bool operator==(const StyleTransformData& o) const;
    bool operator!=(const StyleTransformData& o) const
    {
        return !(*this == o);
    }

    TransformOperations m_operations;
    Length m_x;
    Length m_y;
    float m_z;

private:
    StyleTransformData();
    StyleTransformData(const StyleTransformData&);
};

} // namespace blink

#endif // StyleTransformData_h
