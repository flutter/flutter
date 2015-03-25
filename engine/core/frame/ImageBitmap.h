// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_FRAME_IMAGEBITMAP_H_
#define SKY_ENGINE_CORE_FRAME_IMAGEBITMAP_H_

#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/core/html/HTMLImageElement.h"
#include "sky/engine/platform/geometry/IntRect.h"
#include "sky/engine/platform/graphics/Image.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"

namespace blink {

class ImageData;

class ImageBitmap final : public RefCounted<ImageBitmap>, public DartWrappable, public ImageLoaderClient {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<ImageBitmap> create(HTMLImageElement*, const IntRect&);
    static PassRefPtr<ImageBitmap> create(ImageData*, const IntRect&);
    static PassRefPtr<ImageBitmap> create(ImageBitmap*, const IntRect&);
    static PassRefPtr<ImageBitmap> create(Image*, const IntRect&);

    PassRefPtr<Image> bitmapImage() const;
    PassRefPtr<HTMLImageElement> imageElement() const { return m_imageElement; }

    IntRect bitmapRect() const { return m_bitmapRect; }

    int width() const { return m_cropRect.width(); }
    int height() const { return m_cropRect.height(); }
    IntSize size() const { return m_cropRect.size(); }

    virtual ~ImageBitmap();

private:
    ImageBitmap(HTMLImageElement*, const IntRect&);
    ImageBitmap(ImageData*, const IntRect&);
    ImageBitmap(ImageBitmap*, const IntRect&);
    ImageBitmap(Image*, const IntRect&);

    // ImageLoaderClient
    virtual void notifyImageSourceChanged() override;
    virtual bool requestsHighLiveResourceCachePriority() override { return true; }

    // ImageBitmaps constructed from HTMLImageElements hold a reference to the HTMLImageElement until
    // the image source changes.
    RefPtr<HTMLImageElement> m_imageElement;
    RefPtr<Image> m_bitmap;

    IntRect m_bitmapRect; // The rect where the underlying Image should be placed in reference to the ImageBitmap.
    IntRect m_cropRect;

    // The offset by which the desired Image is stored internally.
    // ImageBitmaps constructed from HTMLImageElements reference the entire ImageResource and may have a non-zero bitmap offset.
    // ImageBitmaps not constructed from HTMLImageElements always pre-crop and store the image at (0, 0).
    IntPoint m_bitmapOffset;

};

} // namespace blink

#endif  // SKY_ENGINE_CORE_FRAME_IMAGEBITMAP_H_
