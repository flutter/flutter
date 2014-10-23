/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
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

#ifndef WebImage_h
#define WebImage_h

#include "WebCommon.h"
#include "WebVector.h"

#include "third_party/skia/include/core/SkBitmap.h"

#if INSIDE_BLINK
namespace WTF { template <typename T> class PassRefPtr; }
#endif

namespace blink {

class Image;
class WebData;
struct WebSize;

// A container for an ARGB bitmap.
class WebImage {
public:
    ~WebImage() { reset(); }

    WebImage() { init(); }
    WebImage(const WebImage& image)
    {
        init();
        assign(image);
    }

    WebImage& operator=(const WebImage& image)
    {
        assign(image);
        return *this;
    }

    // Decodes the given image data. If the image has multiple frames,
    // then the frame whose size is desiredSize is returned. Otherwise,
    // the first frame is returned.
    BLINK_PLATFORM_EXPORT static WebImage fromData(const WebData&, const WebSize& desiredSize);

    // Returns a list of all frames in the image. Only the first frame at each pixel
    // size will be returned.
    BLINK_PLATFORM_EXPORT static WebVector<WebImage> framesFromData(const WebData&);

    BLINK_PLATFORM_EXPORT void reset();
    BLINK_PLATFORM_EXPORT void assign(const WebImage&);

    BLINK_PLATFORM_EXPORT bool isNull() const;
    BLINK_PLATFORM_EXPORT WebSize size() const;

#if INSIDE_BLINK
    BLINK_PLATFORM_EXPORT WebImage(const WTF::PassRefPtr<Image>&);
    BLINK_PLATFORM_EXPORT WebImage& operator=(const WTF::PassRefPtr<Image>&);
#endif

    WebImage(const SkBitmap& bitmap) : m_bitmap(bitmap) { }

    WebImage& operator=(const SkBitmap& bitmap)
    {
        m_bitmap = bitmap;
        return *this;
    }

    SkBitmap& getSkBitmap() { return m_bitmap; }
    const SkBitmap& getSkBitmap() const { return m_bitmap; }

private:
    void init() { }
    SkBitmap m_bitmap;
};

} // namespace blink

#endif
