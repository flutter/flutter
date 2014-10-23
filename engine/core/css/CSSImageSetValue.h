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

#ifndef CSSImageSetValue_h
#define CSSImageSetValue_h

#include "core/css/CSSValueList.h"
#include "core/fetch/ResourceFetcher.h"
#include "platform/weborigin/Referrer.h"

namespace blink {

class ResourceFetcher;
class StyleFetchedImageSet;
class StyleImage;

class CSSImageSetValue : public CSSValueList {
public:

    static PassRefPtrWillBeRawPtr<CSSImageSetValue> create()
    {
        return adoptRefWillBeNoop(new CSSImageSetValue());
    }
    ~CSSImageSetValue();

    StyleFetchedImageSet* cachedImageSet(ResourceFetcher*, float deviceScaleFactor, const ResourceLoaderOptions&);
    StyleFetchedImageSet* cachedImageSet(ResourceFetcher*, float deviceScaleFactor);

    // Returns a StyleFetchedImageSet if the best fit image has been cached already, otherwise a StylePendingImage.
    StyleImage* cachedOrPendingImageSet(float);

    String customCSSText() const;

    bool isPending() const { return !m_accessedBestFitImage; }

    struct ImageWithScale {
        String imageURL;
        Referrer referrer;
        float scaleFactor;
    };

    bool hasFailedOrCanceledSubresources() const;

    PassRefPtrWillBeRawPtr<CSSImageSetValue> cloneForCSSOM() const;

    void traceAfterDispatch(Visitor* visitor) { CSSValueList::traceAfterDispatch(visitor); }

protected:
    ImageWithScale bestImageForScaleFactor();

private:
    CSSImageSetValue();
    explicit CSSImageSetValue(const CSSImageSetValue& cloneFrom);

    void fillImageSet();
    static inline bool compareByScaleFactor(ImageWithScale first, ImageWithScale second) { return first.scaleFactor < second.scaleFactor; }

    RefPtr<StyleImage> m_imageSet;
    bool m_accessedBestFitImage;

    // This represents the scale factor that we used to find the best fit image. It does not necessarily
    // correspond to the scale factor of the best fit image.
    float m_scaleFactor;

    Vector<ImageWithScale> m_imagesInSet;
};

DEFINE_CSS_VALUE_TYPE_CASTS(CSSImageSetValue, isImageSetValue());

} // namespace blink

#endif // CSSImageSetValue_h
