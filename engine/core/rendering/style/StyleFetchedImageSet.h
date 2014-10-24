/*
 * Copyright (C) 2012 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef StyleFetchedImageSet_h
#define StyleFetchedImageSet_h

#include "core/fetch/ImageResourceClient.h"
#include "core/fetch/ResourcePtr.h"
#include "core/rendering/style/StyleImage.h"
#include "platform/geometry/LayoutSize.h"

namespace blink {

class ImageResource;
class CSSImageSetValue;

// This class keeps one cached image and has access to a set of alternatives.

class StyleFetchedImageSet final : public StyleImage, private ImageResourceClient {
    WTF_MAKE_FAST_ALLOCATED;
public:
    static PassRefPtr<StyleFetchedImageSet> create(ImageResource* image, float imageScaleFactor, CSSImageSetValue* value)
    {
        return adoptRef(new StyleFetchedImageSet(image, imageScaleFactor, value));
    }
    virtual ~StyleFetchedImageSet();

    virtual PassRefPtrWillBeRawPtr<CSSValue> cssValue() const override;

    // FIXME: This is used by StyleImage for equals comparison, but this implementation
    // only looks at the image from the set that we have loaded. I'm not sure if that is
    // meaningful enough or not.
    virtual WrappedImagePtr data() const override { return m_bestFitImage.get(); }

    void clearImageSetValue() { m_imageSetValue = 0; }

    virtual bool canRender(const RenderObject&, float multiplier) const override;
    virtual bool isLoaded() const override;
    virtual bool errorOccurred() const override;
    virtual LayoutSize imageSize(const RenderObject*, float multiplier) const override;
    virtual bool imageHasRelativeWidth() const override;
    virtual bool imageHasRelativeHeight() const override;
    virtual void computeIntrinsicDimensions(const RenderObject*, Length& intrinsicWidth, Length& intrinsicHeight, FloatSize& intrinsicRatio) override;
    virtual bool usesImageContainerSize() const override;
    virtual void setContainerSizeForRenderer(const RenderObject*, const IntSize&, float) override;
    virtual void addClient(RenderObject*) override;
    virtual void removeClient(RenderObject*) override;
    virtual PassRefPtr<Image> image(RenderObject*, const IntSize&) const override;
    virtual float imageScaleFactor() const override { return m_imageScaleFactor; }
    virtual bool knownToBeOpaque(const RenderObject*) const override;
    virtual ImageResource* cachedImage() const override { return m_bestFitImage.get(); }

private:
    StyleFetchedImageSet(ImageResource*, float imageScaleFactor, CSSImageSetValue*);

    ResourcePtr<ImageResource> m_bestFitImage;
    float m_imageScaleFactor;

    // FIXME: oilpan: Change to RawPtrWillBeMember when moving this class onto oilpan heap.
    // Also add "if !ENABLE(OILPAN)" around clearImageSetValue above as well as around its
    // caller since it should not be needed once both of the objects are on the heap and
    // oilpan is enabled.
    CSSImageSetValue* m_imageSetValue; // Not retained; it owns us.
};

DEFINE_STYLE_IMAGE_TYPE_CASTS(StyleFetchedImageSet, isImageResourceSet());

} // namespace blink

#endif // StyleFetchedImageSet_h
