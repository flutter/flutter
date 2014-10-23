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

#ifndef NinePieceImage_h
#define NinePieceImage_h

#include "core/rendering/style/BorderImageLengthBox.h"
#include "core/rendering/style/DataRef.h"
#include "core/rendering/style/StyleImage.h"
#include "platform/LayoutUnit.h"
#include "platform/LengthBox.h"

namespace blink {

enum ENinePieceImageRule {
    StretchImageRule, RoundImageRule, SpaceImageRule, RepeatImageRule
};

class NinePieceImageData : public RefCounted<NinePieceImageData> {
public:
    static PassRefPtr<NinePieceImageData> create() { return adoptRef(new NinePieceImageData); }
    PassRefPtr<NinePieceImageData> copy() const { return adoptRef(new NinePieceImageData(*this)); }

    bool operator==(const NinePieceImageData&) const;
    bool operator!=(const NinePieceImageData& o) const { return !(*this == o); }

    bool fill : 1;
    unsigned horizontalRule : 2; // ENinePieceImageRule
    unsigned verticalRule : 2; // ENinePieceImageRule
    RefPtr<StyleImage> image;
    LengthBox imageSlices;
    BorderImageLengthBox borderSlices;
    BorderImageLengthBox outset;

private:
    NinePieceImageData();
    NinePieceImageData(const NinePieceImageData&);
};

class NinePieceImage {
public:
    NinePieceImage();
    NinePieceImage(PassRefPtr<StyleImage>, LengthBox imageSlices, bool fill, const BorderImageLengthBox& borderSlices,
        const BorderImageLengthBox& outset, ENinePieceImageRule horizontalRule, ENinePieceImageRule verticalRule);

    bool operator==(const NinePieceImage& other) const { return m_data == other.m_data; }
    bool operator!=(const NinePieceImage& other) const { return m_data != other.m_data; }

    bool hasImage() const { return m_data->image; }
    StyleImage* image() const { return m_data->image.get(); }
    void setImage(PassRefPtr<StyleImage> image) { m_data.access()->image = image; }

    const LengthBox& imageSlices() const { return m_data->imageSlices; }
    void setImageSlices(const LengthBox& slices) { m_data.access()->imageSlices = slices; }

    bool fill() const { return m_data->fill; }
    void setFill(bool fill) { m_data.access()->fill = fill; }

    const BorderImageLengthBox& borderSlices() const { return m_data->borderSlices; }
    void setBorderSlices(const BorderImageLengthBox& slices) { m_data.access()->borderSlices = slices; }

    const BorderImageLengthBox& outset() const { return m_data->outset; }
    void setOutset(const BorderImageLengthBox& outset) { m_data.access()->outset = outset; }

    ENinePieceImageRule horizontalRule() const { return static_cast<ENinePieceImageRule>(m_data->horizontalRule); }
    void setHorizontalRule(ENinePieceImageRule rule) { m_data.access()->horizontalRule = rule; }

    ENinePieceImageRule verticalRule() const { return static_cast<ENinePieceImageRule>(m_data->verticalRule); }
    void setVerticalRule(ENinePieceImageRule rule) { m_data.access()->verticalRule = rule; }

    void copyImageSlicesFrom(const NinePieceImage& other)
    {
        m_data.access()->imageSlices = other.m_data->imageSlices;
        m_data.access()->fill = other.m_data->fill;
    }

    void copyBorderSlicesFrom(const NinePieceImage& other)
    {
        m_data.access()->borderSlices = other.m_data->borderSlices;
    }

    void copyOutsetFrom(const NinePieceImage& other)
    {
        m_data.access()->outset = other.m_data->outset;
    }

    void copyRepeatFrom(const NinePieceImage& other)
    {
        m_data.access()->horizontalRule = other.m_data->horizontalRule;
        m_data.access()->verticalRule = other.m_data->verticalRule;
    }

    void setMaskDefaults()
    {
        m_data.access()->imageSlices = LengthBox(0);
        m_data.access()->fill = true;
        m_data.access()->borderSlices = BorderImageLengthBox(Length(Auto));
    }

    static LayoutUnit computeOutset(const BorderImageLength& outsetSide, LayoutUnit borderSide)
    {
        if (outsetSide.isNumber())
            return outsetSide.number() * borderSide;
        return outsetSide.length().value();
    }

private:
    DataRef<NinePieceImageData> m_data;
};

} // namespace blink

#endif // NinePieceImage_h
