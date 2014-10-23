/*
 * Copyright (C) 2011 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
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

#ifndef CSSCrossfadeValue_h
#define CSSCrossfadeValue_h

#include "core/css/CSSImageGeneratorValue.h"
#include "core/css/CSSPrimitiveValue.h"
#include "core/fetch/ImageResource.h"
#include "core/fetch/ImageResourceClient.h"
#include "core/fetch/ResourcePtr.h"
#include "platform/graphics/Image.h"

namespace blink {

class ImageResource;
class CrossfadeSubimageObserverProxy;
class RenderObject;
class Document;

class CSSCrossfadeValue : public CSSImageGeneratorValue {
    friend class CrossfadeSubimageObserverProxy;
public:
    static PassRefPtrWillBeRawPtr<CSSCrossfadeValue> create(PassRefPtrWillBeRawPtr<CSSValue> fromValue, PassRefPtrWillBeRawPtr<CSSValue> toValue)
    {
        return adoptRefWillBeNoop(new CSSCrossfadeValue(fromValue, toValue));
    }

    ~CSSCrossfadeValue();

    String customCSSText() const;

    PassRefPtr<Image> image(RenderObject*, const IntSize&);
    bool isFixedSize() const { return true; }
    IntSize fixedSize(const RenderObject*);

    bool isPending() const;
    bool knownToBeOpaque(const RenderObject*) const;

    void loadSubimages(ResourceFetcher*);

    void setPercentage(PassRefPtrWillBeRawPtr<CSSPrimitiveValue> percentageValue) { m_percentageValue = percentageValue; }

    bool hasFailedOrCanceledSubresources() const;

    bool equals(const CSSCrossfadeValue&) const;

    void traceAfterDispatch(Visitor*);

private:
    CSSCrossfadeValue(PassRefPtrWillBeRawPtr<CSSValue> fromValue, PassRefPtrWillBeRawPtr<CSSValue> toValue)
        : CSSImageGeneratorValue(CrossfadeClass)
        , m_fromValue(fromValue)
        , m_toValue(toValue)
        , m_cachedFromImage(0)
        , m_cachedToImage(0)
        , m_crossfadeSubimageObserver(this) { }

    class CrossfadeSubimageObserverProxy FINAL : public ImageResourceClient {
    public:
        CrossfadeSubimageObserverProxy(CSSCrossfadeValue* ownerValue)
        : m_ownerValue(ownerValue)
        , m_ready(false) { }

        virtual ~CrossfadeSubimageObserverProxy() { }
        virtual void imageChanged(ImageResource*, const IntRect* = 0) OVERRIDE;
        void setReady(bool ready) { m_ready = ready; }
    private:
        CSSCrossfadeValue* m_ownerValue;
        bool m_ready;
    };

    void crossfadeChanged(const IntRect&);

    RefPtrWillBeMember<CSSValue> m_fromValue;
    RefPtrWillBeMember<CSSValue> m_toValue;
    RefPtrWillBeMember<CSSPrimitiveValue> m_percentageValue;

    ResourcePtr<ImageResource> m_cachedFromImage;
    ResourcePtr<ImageResource> m_cachedToImage;

    RefPtr<Image> m_generatedImage;

    CrossfadeSubimageObserverProxy m_crossfadeSubimageObserver;
};

DEFINE_CSS_VALUE_TYPE_CASTS(CSSCrossfadeValue, isCrossfadeValue());

} // namespace blink

#endif // CSSCrossfadeValue_h
