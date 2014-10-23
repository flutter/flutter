/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003, 2005, 2006, 2007, 2008, 2013 Apple Inc. All rights reserved.
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

#include "config.h"
#include "core/rendering/style/NinePieceImage.h"

#include "core/rendering/style/DataEquivalency.h"

namespace blink {

static DataRef<NinePieceImageData>& defaultData()
{
    static DataRef<NinePieceImageData>* data = new DataRef<NinePieceImageData>;
    if (!data->get())
        data->init();
    return *data;
}

NinePieceImage::NinePieceImage()
    : m_data(defaultData())
{
}

NinePieceImage::NinePieceImage(PassRefPtr<StyleImage> image, LengthBox imageSlices, bool fill, const BorderImageLengthBox& borderSlices, const BorderImageLengthBox& outset, ENinePieceImageRule horizontalRule, ENinePieceImageRule verticalRule)
{
    m_data.init();
    m_data.access()->image = image;
    m_data.access()->imageSlices = imageSlices;
    m_data.access()->borderSlices = borderSlices;
    m_data.access()->outset = outset;
    m_data.access()->fill = fill;
    m_data.access()->horizontalRule = horizontalRule;
    m_data.access()->verticalRule = verticalRule;
}

NinePieceImageData::NinePieceImageData()
    : fill(false)
    , horizontalRule(StretchImageRule)
    , verticalRule(StretchImageRule)
    , image(nullptr)
    , imageSlices(Length(100, Percent), Length(100, Percent), Length(100, Percent), Length(100, Percent))
    , borderSlices(1.0, 1.0, 1.0, 1.0)
    , outset(Length(0, Fixed), Length(0, Fixed), Length(0, Fixed), Length(0, Fixed))
{
}

NinePieceImageData::NinePieceImageData(const NinePieceImageData& other)
    : RefCounted<NinePieceImageData>()
    , fill(other.fill)
    , horizontalRule(other.horizontalRule)
    , verticalRule(other.verticalRule)
    , image(other.image)
    , imageSlices(other.imageSlices)
    , borderSlices(other.borderSlices)
    , outset(other.outset)
{
}

bool NinePieceImageData::operator==(const NinePieceImageData& other) const
{
    return dataEquivalent(image, other.image)
        && imageSlices == other.imageSlices
        && fill == other.fill
        && borderSlices == other.borderSlices
        && outset == other.outset
        && horizontalRule == other.horizontalRule
        && verticalRule == other.verticalRule;
}

}
