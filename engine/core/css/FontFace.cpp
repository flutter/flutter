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

#include "sky/engine/core/css/FontFace.h"

#include "gen/sky/core/CSSValueKeywords.h"
#include "gen/sky/platform/FontFamilyNames.h"
#include "sky/engine/bindings/exception_state.h"
#include "sky/engine/core/css/BinaryDataFontFaceSource.h"
#include "sky/engine/core/css/CSSFontFace.h"
#include "sky/engine/core/css/CSSFontFaceSrcValue.h"
#include "sky/engine/core/css/CSSFontSelector.h"
#include "sky/engine/core/css/CSSPrimitiveValue.h"
#include "sky/engine/core/css/CSSUnicodeRangeValue.h"
#include "sky/engine/core/css/CSSValueList.h"
#include "sky/engine/core/css/LocalFontFaceSource.h"
#include "sky/engine/core/css/RemoteFontFaceSource.h"
#include "sky/engine/core/css/StylePropertySet.h"
#include "sky/engine/core/css/StyleRule.h"
#include "sky/engine/core/css/parser/BisonCSSParser.h"
#include "sky/engine/core/dom/DOMException.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/ExceptionCode.h"
#include "sky/engine/core/dom/StyleEngine.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/frame/Settings.h"
#include "sky/engine/platform/SharedBuffer.h"
#include "sky/engine/wtf/ArrayBufferView.h"

namespace blink {

static PassRefPtr<CSSValue> parseCSSValue(const Document* document, const String& s, CSSPropertyID propertyID)
{
    if (s.isEmpty())
        return nullptr;
    RefPtr<MutableStylePropertySet> parsedStyle = MutableStylePropertySet::create();
    BisonCSSParser::parseValue(parsedStyle.get(), propertyID, s, *document);
    return parsedStyle->getPropertyCSSValue(propertyID);
}

PassRefPtr<FontFace> FontFace::create(ExecutionContext* context, const AtomicString& family, const String& source)
{
    RefPtr<FontFace> fontFace = adoptRef(new FontFace(context, family));

    RefPtr<CSSValue> src = parseCSSValue(toDocument(context), source, CSSPropertySrc);
    if (!src || !src->isValueList())
        fontFace->setError(DOMException::create(SyntaxError, "The source provided ('" + source + "') could not be parsed as a value list."));

    fontFace->initCSSFontFace(toDocument(context), src);
    return fontFace.release();
}

PassRefPtr<FontFace> FontFace::create(ExecutionContext* context, const AtomicString& family, PassRefPtr<ArrayBuffer> source)
{
    RefPtr<FontFace> fontFace = adoptRef(new FontFace(context, family));
    fontFace->initCSSFontFace(static_cast<const unsigned char*>(source->data()), source->byteLength());
    return fontFace.release();
}

PassRefPtr<FontFace> FontFace::create(ExecutionContext* context, const AtomicString& family, PassRefPtr<ArrayBufferView> source)
{
    RefPtr<FontFace> fontFace = adoptRef(new FontFace(context, family));
    fontFace->initCSSFontFace(static_cast<const unsigned char*>(source->baseAddress()), source->byteLength());
    return fontFace.release();
}

PassRefPtr<FontFace> FontFace::create(Document* document, const StyleRuleFontFace* fontFaceRule)
{
    const StylePropertySet& properties = fontFaceRule->properties();

    // Obtain the font-family property and the src property. Both must be defined.
    RefPtr<CSSValue> family = properties.getPropertyCSSValue(CSSPropertyFontFamily);
    if (!family || !family->isValueList())
        return nullptr;
    RefPtr<CSSValue> src = properties.getPropertyCSSValue(CSSPropertySrc);
    if (!src || !src->isValueList())
        return nullptr;

    RefPtr<FontFace> fontFace = adoptRef(new FontFace());

    if (fontFace->setFamilyValue(toCSSValueList(family.get()))
        && fontFace->setPropertyFromStyle(properties, CSSPropertyFontStyle)
        && fontFace->setPropertyFromStyle(properties, CSSPropertyFontWeight)
        && fontFace->setPropertyFromStyle(properties, CSSPropertyFontStretch)
        && fontFace->setPropertyFromStyle(properties, CSSPropertyUnicodeRange)
        && fontFace->setPropertyFromStyle(properties, CSSPropertyFontVariant)
        && fontFace->setPropertyFromStyle(properties, CSSPropertyWebkitFontFeatureSettings)
        && !fontFace->family().isEmpty()
        && fontFace->traits().bitfield()) {
        fontFace->initCSSFontFace(document, src);
        return fontFace.release();
    }
    return nullptr;
}

FontFace::FontFace()
    : m_status(Unloaded)
{
}

FontFace::FontFace(ExecutionContext* context, const AtomicString& family)
    : m_family(family)
    , m_status(Unloaded)
{
}

FontFace::~FontFace()
{
}

String FontFace::style() const
{
    return m_style ? m_style->cssText() : "normal";
}

String FontFace::weight() const
{
    return m_weight ? m_weight->cssText() : "normal";
}

String FontFace::stretch() const
{
    return m_stretch ? m_stretch->cssText() : "normal";
}

String FontFace::unicodeRange() const
{
    return m_unicodeRange ? m_unicodeRange->cssText() : "U+0-10FFFF";
}

String FontFace::variant() const
{
    return m_variant ? m_variant->cssText() : "normal";
}

String FontFace::featureSettings() const
{
    return m_featureSettings ? m_featureSettings->cssText() : "normal";
}

void FontFace::setStyle(ExecutionContext* context, const String& s, ExceptionState& exceptionState)
{
    setPropertyFromString(toDocument(context), s, CSSPropertyFontStyle, &exceptionState);
}

void FontFace::setWeight(ExecutionContext* context, const String& s, ExceptionState& exceptionState)
{
    setPropertyFromString(toDocument(context), s, CSSPropertyFontWeight, &exceptionState);
}

void FontFace::setStretch(ExecutionContext* context, const String& s, ExceptionState& exceptionState)
{
    setPropertyFromString(toDocument(context), s, CSSPropertyFontStretch, &exceptionState);
}

void FontFace::setUnicodeRange(ExecutionContext* context, const String& s, ExceptionState& exceptionState)
{
    setPropertyFromString(toDocument(context), s, CSSPropertyUnicodeRange, &exceptionState);
}

void FontFace::setVariant(ExecutionContext* context, const String& s, ExceptionState& exceptionState)
{
    setPropertyFromString(toDocument(context), s, CSSPropertyFontVariant, &exceptionState);
}

void FontFace::setFeatureSettings(ExecutionContext* context, const String& s, ExceptionState& exceptionState)
{
    setPropertyFromString(toDocument(context), s, CSSPropertyWebkitFontFeatureSettings, &exceptionState);
}

void FontFace::setPropertyFromString(const Document* document, const String& s, CSSPropertyID propertyID, ExceptionState* exceptionState)
{
    RefPtr<CSSValue> value = parseCSSValue(document, s, propertyID);
    if (value && setPropertyValue(value, propertyID))
        return;

    String message = "Failed to set '" + s + "' as a property value.";
    if (exceptionState)
        exceptionState->ThrowDOMException(SyntaxError, message);
    else
        setError(DOMException::create(SyntaxError, message));
}

bool FontFace::setPropertyFromStyle(const StylePropertySet& properties, CSSPropertyID propertyID)
{
    return setPropertyValue(properties.getPropertyCSSValue(propertyID), propertyID);
}

bool FontFace::setPropertyValue(PassRefPtr<CSSValue> value, CSSPropertyID propertyID)
{
    switch (propertyID) {
    case CSSPropertyFontStyle:
        m_style = value;
        break;
    case CSSPropertyFontWeight:
        m_weight = value;
        break;
    case CSSPropertyFontStretch:
        m_stretch = value;
        break;
    case CSSPropertyUnicodeRange:
        if (value && !value->isValueList())
            return false;
        m_unicodeRange = value;
        break;
    case CSSPropertyFontVariant:
        m_variant = value;
        break;
    case CSSPropertyWebkitFontFeatureSettings:
        m_featureSettings = value;
        break;
    default:
        ASSERT_NOT_REACHED();
        return false;
    }
    return true;
}

bool FontFace::setFamilyValue(CSSValueList* familyList)
{
    // The font-family descriptor has to have exactly one family name.
    if (familyList->length() != 1)
        return false;

    CSSPrimitiveValue* familyValue = toCSSPrimitiveValue(familyList->item(0));
    AtomicString family;
    if (familyValue->isString()) {
        family = AtomicString(familyValue->getStringValue());
    } else if (familyValue->isValueID()) {
        // We need to use the raw text for all the generic family types, since @font-face is a way of actually
        // defining what font to use for those types.
        switch (familyValue->getValueID()) {
        case CSSValueSerif:
            family =  FontFamilyNames::webkit_serif;
            break;
        case CSSValueSansSerif:
            family =  FontFamilyNames::webkit_sans_serif;
            break;
        case CSSValueCursive:
            family =  FontFamilyNames::webkit_cursive;
            break;
        case CSSValueFantasy:
            family =  FontFamilyNames::webkit_fantasy;
            break;
        case CSSValueMonospace:
            family =  FontFamilyNames::webkit_monospace;
            break;
        case CSSValueWebkitPictograph:
            family =  FontFamilyNames::webkit_pictograph;
            break;
        default:
            return false;
        }
    }
    m_family = family;
    return true;
}

String FontFace::status() const
{
    switch (m_status) {
    case Unloaded:
        return "unloaded";
    case Loading:
        return "loading";
    case Loaded:
        return "loaded";
    case Error:
        return "error";
    default:
        ASSERT_NOT_REACHED();
    }
    return emptyString();
}

void FontFace::setLoadStatus(LoadStatus status)
{
    m_status = status;
    ASSERT(m_status != Error || m_error);

    if (m_status == Loaded || m_status == Error) {
        Vector<RefPtr<LoadFontCallback> > callbacks;
        m_callbacks.swap(callbacks);
        for (size_t i = 0; i < callbacks.size(); ++i) {
            if (m_status == Loaded)
                callbacks[i]->notifyLoaded(this);
            else
                callbacks[i]->notifyError(this);
        }
    }
}

void FontFace::setError(PassRefPtr<DOMException> error)
{
    if (!m_error)
        m_error = error ? error : DOMException::create(NetworkError);
    setLoadStatus(Error);
}

void FontFace::loadWithCallback(PassRefPtr<LoadFontCallback> callback, ExecutionContext* context)
{
    loadInternal(context);
    if (m_status == Loaded)
        callback->notifyLoaded(this);
    else if (m_status == Error)
        callback->notifyError(this);
    else
        m_callbacks.append(callback);
}

void FontFace::loadInternal(ExecutionContext* context)
{
    if (m_status != Unloaded)
        return;

    m_cssFontFace->load();
    toDocument(context)->styleEngine()->fontSelector()->fontLoader()->loadPendingFonts();
}

FontTraits FontFace::traits() const
{
    FontStyle style = FontStyleNormal;
    if (m_style) {
        if (!m_style->isPrimitiveValue())
            return 0;

        switch (toCSSPrimitiveValue(m_style.get())->getValueID()) {
        case CSSValueNormal:
            style = FontStyleNormal;
            break;
        case CSSValueItalic:
        case CSSValueOblique:
            style = FontStyleItalic;
            break;
        default:
            break;
        }
    }

    FontWeight weight = FontWeight400;
    if (m_weight) {
        if (!m_weight->isPrimitiveValue())
            return 0;

        switch (toCSSPrimitiveValue(m_weight.get())->getValueID()) {
        case CSSValueBold:
        case CSSValue700:
            weight = FontWeight700;
            break;
        case CSSValueNormal:
        case CSSValue400:
            weight = FontWeight400;
            break;
        case CSSValue900:
            weight = FontWeight900;
            break;
        case CSSValue800:
            weight = FontWeight800;
            break;
        case CSSValue600:
            weight = FontWeight600;
            break;
        case CSSValue500:
            weight = FontWeight500;
            break;
        case CSSValue300:
            weight = FontWeight300;
            break;
        case CSSValue200:
            weight = FontWeight200;
            break;
        case CSSValueLighter:
        case CSSValue100:
            weight = FontWeight100;
            break;
        default:
            ASSERT_NOT_REACHED();
            break;
        }
    }

    FontVariant variant = FontVariantNormal;
    if (RefPtr<CSSValue> fontVariant = m_variant) {
        // font-variant descriptor can be a value list.
        if (fontVariant->isPrimitiveValue()) {
            RefPtr<CSSValueList> list = CSSValueList::createCommaSeparated();
            list->append(fontVariant);
            fontVariant = list;
        } else if (!fontVariant->isValueList()) {
            return 0;
        }

        CSSValueList* variantList = toCSSValueList(fontVariant.get());
        unsigned numVariants = variantList->length();
        if (!numVariants)
            return 0;

        for (unsigned i = 0; i < numVariants; ++i) {
            switch (toCSSPrimitiveValue(variantList->item(i))->getValueID()) {
            case CSSValueNormal:
                variant = FontVariantNormal;
                break;
            case CSSValueSmallCaps:
                variant = FontVariantSmallCaps;
                break;
            default:
                break;
            }
        }
    }

    return FontTraits(style, variant, weight, FontStretchNormal);
}

static PassOwnPtr<CSSFontFace> createCSSFontFace(FontFace* fontFace, CSSValue* unicodeRange)
{
    Vector<CSSFontFace::UnicodeRange> ranges;
    if (CSSValueList* rangeList = toCSSValueList(unicodeRange)) {
        unsigned numRanges = rangeList->length();
        for (unsigned i = 0; i < numRanges; i++) {
            CSSUnicodeRangeValue* range = toCSSUnicodeRangeValue(rangeList->item(i));
            ranges.append(CSSFontFace::UnicodeRange(range->from(), range->to()));
        }
    }

    return adoptPtr(new CSSFontFace(fontFace, ranges));
}

void FontFace::initCSSFontFace(Document* document, PassRefPtr<CSSValue> src)
{
    m_cssFontFace = createCSSFontFace(this, m_unicodeRange.get());
    if (m_error)
        return;

    // Each item in the src property's list is a single CSSFontFaceSource. Put them all into a CSSFontFace.
    ASSERT(src);
    ASSERT(src->isValueList());
    CSSValueList* srcList = toCSSValueList(src.get());
    int srcLength = srcList->length();

    for (int i = 0; i < srcLength; i++) {
        // An item in the list either specifies a string (local font name) or a URL (remote font to download).
        CSSFontFaceSrcValue* item = toCSSFontFaceSrcValue(srcList->item(i));
        OwnPtr<CSSFontFaceSource> source = nullptr;

        if (!item->isLocal()) {
            Settings* settings = document ? document->frame() ? document->frame()->settings() : 0 : 0;
            bool allowDownloading = settings && settings->downloadableBinaryFontsEnabled();
            if (allowDownloading && item->isSupportedFormat() && document) {
                FontResource* fetched = item->fetch(document);
                if (fetched) {
                    FontLoader* fontLoader = document->styleEngine()->fontSelector()->fontLoader();
                    source = adoptPtr(new RemoteFontFaceSource(fetched, fontLoader));
                }
            }
        } else {
            source = adoptPtr(new LocalFontFaceSource(item->resource()));
        }

        if (source)
            m_cssFontFace->addSource(source.release());
    }
}

void FontFace::initCSSFontFace(const unsigned char* data, unsigned size)
{
    m_cssFontFace = createCSSFontFace(this, m_unicodeRange.get());
    if (m_error)
        return;

    RefPtr<SharedBuffer> buffer = SharedBuffer::create(data, size);
    OwnPtr<BinaryDataFontFaceSource> source = adoptPtr(new BinaryDataFontFaceSource(buffer.get()));
    if (source->isValid())
        setLoadStatus(Loaded);
    else
        setError(DOMException::create(SyntaxError, "Invalid font data in ArrayBuffer."));
    m_cssFontFace->addSource(source.release());
}

bool FontFace::hadBlankText() const
{
    return m_cssFontFace->hadBlankText();
}

} // namespace blink
