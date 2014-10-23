/*
 * Copyright (C) 2011 Brent Fulgham
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
#include "platform/fonts/FontPlatformData.h"

#include "wtf/HashMap.h"
#include "wtf/text/StringHash.h"
#include "wtf/text/WTFString.h"

#if OS(MACOSX)
#include "platform/fonts/harfbuzz/HarfBuzzFace.h"
#endif

namespace blink {

FontPlatformData::FontPlatformData(WTF::HashTableDeletedValueType)
    : m_syntheticBold(false)
    , m_syntheticOblique(false)
    , m_orientation(Horizontal)
    , m_size(0)
    , m_widthVariant(RegularWidth)
#if OS(MACOSX)
    , m_font(hashTableDeletedFontValue())
#endif
    , m_isColorBitmapFont(false)
    , m_isCompositeFontReference(false)
{
}

FontPlatformData::FontPlatformData()
    : m_syntheticBold(false)
    , m_syntheticOblique(false)
    , m_orientation(Horizontal)
    , m_size(0)
    , m_widthVariant(RegularWidth)
#if OS(MACOSX)
    , m_font(0)
#endif
    , m_isColorBitmapFont(false)
    , m_isCompositeFontReference(false)
{
}

FontPlatformData::FontPlatformData(float size, bool syntheticBold, bool syntheticOblique, FontOrientation orientation, FontWidthVariant widthVariant)
    : m_syntheticBold(syntheticBold)
    , m_syntheticOblique(syntheticOblique)
    , m_orientation(orientation)
    , m_size(size)
    , m_widthVariant(widthVariant)
#if OS(MACOSX)
    , m_font(0)
#endif
    , m_isColorBitmapFont(false)
    , m_isCompositeFontReference(false)
{
}

#if OS(MACOSX)
FontPlatformData::FontPlatformData(CGFontRef cgFont, float size, bool syntheticBold, bool syntheticOblique, FontOrientation orientation, FontWidthVariant widthVariant)
    : m_syntheticBold(syntheticBold)
    , m_syntheticOblique(syntheticOblique)
    , m_orientation(orientation)
    , m_size(size)
    , m_widthVariant(widthVariant)
    , m_font(0)
    , m_cgFont(cgFont)
    , m_isColorBitmapFont(false)
    , m_isCompositeFontReference(false)
{
}
#endif

FontPlatformData::FontPlatformData(const FontPlatformData& source)
    : m_syntheticBold(source.m_syntheticBold)
    , m_syntheticOblique(source.m_syntheticOblique)
    , m_orientation(source.m_orientation)
    , m_size(source.m_size)
    , m_widthVariant(source.m_widthVariant)
    , m_isColorBitmapFont(source.m_isColorBitmapFont)
    , m_isCompositeFontReference(source.m_isCompositeFontReference)
{
    platformDataInit(source);
}

const FontPlatformData& FontPlatformData::operator=(const FontPlatformData& other)
{
    // Check for self-assignment.
    if (this == &other)
        return *this;

    m_syntheticBold = other.m_syntheticBold;
    m_syntheticOblique = other.m_syntheticOblique;
    m_orientation = other.m_orientation;
    m_size = other.m_size;
    m_widthVariant = other.m_widthVariant;
    m_isColorBitmapFont = other.m_isColorBitmapFont;
    m_isCompositeFontReference = other.m_isCompositeFontReference;

    return platformDataAssign(other);
}

} // namespace blink
