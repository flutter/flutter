/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#ifndef StyleBuilderConverter_h
#define StyleBuilderConverter_h

#include "sky/engine/core/css/CSSValue.h"
#include "sky/engine/core/css/CSSValueList.h"
#include "sky/engine/core/css/resolver/StyleResolverState.h"
#include "sky/engine/core/rendering/RenderView.h"
#include "sky/engine/core/rendering/style/QuotesData.h"
#include "sky/engine/core/rendering/style/ShadowList.h"
#include "sky/engine/platform/LengthSize.h"
#include "sky/engine/platform/fonts/FontDescription.h"

namespace blink {

// Note that we assume the parser only allows valid CSSValue types.

class StyleBuilderConverter {
public:
    static AtomicString convertFragmentIdentifier(StyleResolverState&, CSSValue*);
    static Color convertColor(StyleResolverState&, CSSValue*);
    template <typename T> static T convertComputedLength(StyleResolverState&, CSSValue*);
    static LengthBox convertClip(StyleResolverState&, CSSValue*);
    template <typename T> static T convertFlags(StyleResolverState&, CSSValue*);
    static PassRefPtr<FontFeatureSettings> convertFontFeatureSettings(StyleResolverState&, CSSValue*);
    static FontWeight convertFontWeight(StyleResolverState&, CSSValue*);
    static FontDescription::VariantLigatures convertFontVariantLigatures(StyleResolverState&, CSSValue*);
    template <typename T> static T convertLineWidth(StyleResolverState&, CSSValue*);
    static Length convertLength(StyleResolverState&, CSSValue*);
    static Length convertLengthOrAuto(StyleResolverState&, CSSValue*);
    static Length convertLengthSizing(StyleResolverState&, CSSValue*);
    static Length convertLengthMaxSizing(StyleResolverState&, CSSValue*);
    static LengthPoint convertLengthPoint(StyleResolverState&, CSSValue*);
    static LineBoxContain convertLineBoxContain(StyleResolverState&, CSSValue*);
    static float convertNumberOrPercentage(StyleResolverState&, CSSValue*);
    static PassRefPtr<QuotesData> convertQuotes(StyleResolverState&, CSSValue*);
    static LengthSize convertRadius(StyleResolverState&, CSSValue*);
    static PassRefPtr<ShadowList> convertShadow(StyleResolverState&, CSSValue*);
    static float convertSpacing(StyleResolverState&, CSSValue*);
    template <CSSValueID IdForNone> static AtomicString convertString(StyleResolverState&, CSSValue*);
    static float convertTextStrokeWidth(StyleResolverState&, CSSValue*);
};

template <typename T>
T StyleBuilderConverter::convertComputedLength(StyleResolverState& state, CSSValue* value)
{
    return toCSSPrimitiveValue(value)->computeLength<T>(state.cssToLengthConversionData());
}

template <typename T>
T StyleBuilderConverter::convertFlags(StyleResolverState& state, CSSValue* value)
{
    T flags = static_cast<T>(0);
    for (CSSValueListIterator i(value); i.hasMore(); i.advance())
        flags |= *toCSSPrimitiveValue(i.value());
    return flags;
}

template <typename T>
T StyleBuilderConverter::convertLineWidth(StyleResolverState& state, CSSValue* value)
{
    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    CSSValueID valueID = primitiveValue->getValueID();
    if (valueID == CSSValueThin)
        return 1;
    if (valueID == CSSValueMedium)
        return 3;
    if (valueID == CSSValueThick)
        return 5;
    if (valueID == CSSValueInvalid) {
        // Any original result that was >= 1 should not be allowed to fall below 1.
        // This keeps border lines from vanishing.
        return primitiveValue->computeLength<T>(state.cssToLengthConversionData());
    }
    ASSERT_NOT_REACHED();
    return 0;
}

template <CSSValueID IdForNone>
AtomicString StyleBuilderConverter::convertString(StyleResolverState&, CSSValue* value)
{
    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    if (primitiveValue->getValueID() == IdForNone)
        return nullAtom;
    return AtomicString(primitiveValue->getStringValue());
}

} // namespace blink

#endif
