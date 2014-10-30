/*
 * Copyright (C) 2011 Apple Inc. All rights reserved.
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
#include "core/rendering/RenderCombineText.h"

#include "core/rendering/TextRunConstructor.h"

namespace blink {

RenderCombineText::RenderCombineText(Node* node, PassRefPtr<StringImpl> string)
     : RenderText(node, string)
     , m_combinedTextWidth(0)
     , m_isCombined(false)
     , m_needsFontUpdate(false)
{
}

void RenderCombineText::styleDidChange(StyleDifference diff, const RenderStyle* oldStyle)
{
    setStyleInternal(RenderStyle::clone(style()));
    RenderText::styleDidChange(diff, oldStyle);

    if (m_isCombined) {
        RenderText::setTextInternal(originalText()); // This RenderCombineText has been combined once. Restore the original text for the next combineText().
        m_isCombined = false;
    }

    m_needsFontUpdate = true;
}

void RenderCombineText::setTextInternal(PassRefPtr<StringImpl> text)
{
    RenderText::setTextInternal(text);

    m_needsFontUpdate = true;
}

float RenderCombineText::width(unsigned from, unsigned length, const Font& font, float xPosition, TextDirection direction, HashSet<const SimpleFontData*>* fallbackFonts, GlyphOverflow* glyphOverflow) const
{
    if (!length)
        return 0;

    if (hasEmptyText())
        return 0;

    if (m_isCombined)
        return font.fontDescription().computedSize();

    return RenderText::width(from, length, font, xPosition, direction, fallbackFonts, glyphOverflow);
}

void RenderCombineText::adjustTextOrigin(FloatPoint& textOrigin, const FloatRect& boxRect) const
{
    if (m_isCombined)
        textOrigin.move(boxRect.height() / 2 - ceilf(m_combinedTextWidth) / 2, style()->font().fontDescription().computedPixelSize());
}

void RenderCombineText::getStringToRender(int start, StringView& string, int& length) const
{
    ASSERT(start >= 0);
    if (m_isCombined) {
        string = StringView(m_renderingText.impl());
        length = string.length();
        return;
    }

    string = text().createView(start, length);
}

void RenderCombineText::combineText()
{
    if (!m_needsFontUpdate)
        return;

    m_isCombined = false;
    m_needsFontUpdate = false;

    // CSS3 spec says text-combine works only in vertical writing mode.
    // FIXME(sky): Remove
}

} // namespace blink
