/*
 * Copyright (C) 2010 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
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

#ifndef StylePendingImage_h
#define StylePendingImage_h

#include "core/css/CSSCursorImageValue.h"
#include "core/css/CSSImageGeneratorValue.h"
#include "core/css/CSSImageSetValue.h"
#include "core/css/CSSImageValue.h"
#include "core/rendering/style/StyleImage.h"
#include "platform/graphics/Image.h"

namespace blink {

// StylePendingImage is a placeholder StyleImage that is entered into the RenderStyle during
// style resolution, in order to avoid loading images that are not referenced by the final style.
// They should never exist in a RenderStyle after it has been returned from the style selector.

class StylePendingImage final : public StyleImage {
public:
    static PassRefPtr<StylePendingImage> create(CSSValue* value) { return adoptRef(new StylePendingImage(value)); }

    virtual WrappedImagePtr data() const override { return m_value; }

    virtual PassRefPtrWillBeRawPtr<CSSValue> cssValue() const override { return m_value; }
    CSSImageValue* cssImageValue() const { return m_value->isImageValue() ? toCSSImageValue(m_value) : 0; }
    CSSImageGeneratorValue* cssImageGeneratorValue() const { return m_value->isImageGeneratorValue() ? toCSSImageGeneratorValue(m_value) : 0; }
    CSSCursorImageValue* cssCursorImageValue() const { return m_value->isCursorImageValue() ? toCSSCursorImageValue(m_value) : 0; }
    CSSImageSetValue* cssImageSetValue() const { return m_value->isImageSetValue() ? toCSSImageSetValue(m_value) : 0; }

    virtual LayoutSize imageSize(const RenderObject*, float /*multiplier*/) const override { return LayoutSize(); }
    virtual bool imageHasRelativeWidth() const override { return false; }
    virtual bool imageHasRelativeHeight() const override { return false; }
    virtual void computeIntrinsicDimensions(const RenderObject*, Length& /* intrinsicWidth */ , Length& /* intrinsicHeight */, FloatSize& /* intrinsicRatio */) override { }
    virtual bool usesImageContainerSize() const override { return false; }
    virtual void setContainerSizeForRenderer(const RenderObject*, const IntSize&, float) override { }
    virtual void addClient(RenderObject*) override { }
    virtual void removeClient(RenderObject*) override { }
    virtual PassRefPtr<Image> image(RenderObject*, const IntSize&) const override
    {
        ASSERT_NOT_REACHED();
        return nullptr;
    }
    virtual bool knownToBeOpaque(const RenderObject*) const override { return false; }

private:
    StylePendingImage(CSSValue* value)
        : m_value(value)
    {
        m_isPendingImage = true;
    }

    CSSValue* m_value; // Not retained; it owns us.
};

DEFINE_STYLE_IMAGE_TYPE_CASTS(StylePendingImage, isPendingImage());

}
#endif
