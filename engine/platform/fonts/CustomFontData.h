/*
 * Copyright (C) 2013 Google, Inc.
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

#ifndef CustomFontData_h
#define CustomFontData_h

#include "platform/PlatformExport.h"
#include "platform/fonts/Glyph.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"
#include <unicode/uchar.h>

namespace blink {

struct GlyphData;
class GlyphPage;
class SimpleFontData;
struct WidthIterator;

class PLATFORM_EXPORT CustomFontData : public RefCounted<CustomFontData> {
public:
    static PassRefPtr<CustomFontData> create() { return adoptRef(new CustomFontData()); }

    virtual ~CustomFontData() { }

    virtual void beginLoadIfNeeded() const { };
    virtual bool isLoading() const { return false; }
    virtual bool isLoadingFallback() const { return false; }
    virtual bool shouldSkipDrawing() const { return false; }
    virtual void clearFontFaceSource() { }

    virtual bool isSVGFont() const { return false; }
    virtual void initializeFontData(SimpleFontData*, float) { }

protected:
    CustomFontData() { }
};

#define DEFINE_CUSTOM_FONT_DATA_TYPE_CASTS(thisType, predicate) \
    template<typename T> inline thisType* to##thisType(const RefPtr<T>& customFontData) { return to##thisType(customFontData.get()); } \
    DEFINE_TYPE_CASTS(thisType, CustomFontData, customFontData, customFontData->predicate, customFontData.predicate)

} // namespace blink

#endif // CustomFontData_h
