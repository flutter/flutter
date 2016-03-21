/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_PLATFORM_GRAPHICS_DECODINGIMAGEGENERATOR_H_
#define SKY_ENGINE_PLATFORM_GRAPHICS_DECODINGIMAGEGENERATOR_H_

#include "sky/engine/wtf/RefPtr.h"
#include "third_party/skia/include/core/SkImageGenerator.h"
#include "third_party/skia/include/core/SkImageInfo.h"

class SkData;

namespace blink {

class ImageFrameGenerator;

// Implements SkImageGenerator and used by SkPixelRef to populate a discardable
// memory with decoded pixels.
//
// This class does not own an ImageDecode. It does not own encoded data. It serves
// as an adapter to ImageFrameGenerator which actually performs decoding.
class DecodingImageGenerator final : public SkImageGenerator {
public:
    DecodingImageGenerator(PassRefPtr<ImageFrameGenerator>, const SkImageInfo&, size_t index);
    virtual ~DecodingImageGenerator();

    void setGenerationId(size_t id) { m_generationId = id; }

protected:
    virtual SkData* onRefEncodedData(GrContext* ctx = nullptr) override;
    virtual bool onGetPixels(const SkImageInfo&, void* pixels, size_t rowBytes, SkPMColor ctable[], int* ctableCount) override;
    virtual bool onGetYUV8Planes(const SkYUVSizeInfo&, void* planes[3]) override;

private:
    RefPtr<ImageFrameGenerator> m_frameGenerator;
    size_t m_frameIndex;
    size_t m_generationId;
};

} // namespace blink

#endif  // SKY_ENGINE_PLATFORM_GRAPHICS_DECODINGIMAGEGENERATOR_H_
