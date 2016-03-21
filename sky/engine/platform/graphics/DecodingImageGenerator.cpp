/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
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

#include "sky/engine/platform/graphics/DecodingImageGenerator.h"

#include "sky/engine/platform/SharedBuffer.h"
#include "sky/engine/platform/TraceEvent.h"
#include "sky/engine/platform/graphics/ImageFrameGenerator.h"
#include "third_party/skia/include/core/SkData.h"
#include "third_party/skia/include/core/SkImageInfo.h"

namespace blink {

DecodingImageGenerator::DecodingImageGenerator(PassRefPtr<ImageFrameGenerator> frameGenerator, const SkImageInfo& info, size_t index)
    : SkImageGenerator(info)
    , m_frameGenerator(frameGenerator)
    , m_frameIndex(index)
    , m_generationId(0)
{
}

DecodingImageGenerator::~DecodingImageGenerator()
{
}

SkData* DecodingImageGenerator::onRefEncodedData(GrContext* ctx)
{
    // FIXME: If the image has been clipped or scaled, do not return the original
    // encoded data, since on playback it will not be known how the clipping/scaling
    // was done.
    RefPtr<SharedBuffer> buffer = nullptr;
    bool allDataReceived = false;
    m_frameGenerator->copyData(&buffer, &allDataReceived);
    if (buffer && allDataReceived)
        return SkData::NewWithCopy(buffer->data(), buffer->size());
    return 0;
}

bool DecodingImageGenerator::onGetPixels(const SkImageInfo& info, void* pixels, size_t rowBytes, SkPMColor ctable[], int* ctableCount)
{
    TRACE_EVENT1("blink", "DecodingImageGenerator::getPixels", "index", static_cast<int>(m_frameIndex));

    // Implementation doesn't support scaling yet so make sure we're not given a different size.
    if (info.width() != info.width() || info.height() != info.height() || info.colorType() != info.colorType()) {
        // ImageFrame may have changed the owning SkBitmap to kOpaque_SkAlphaType after sniffing the encoded data, so if we see a request
        // for opaque, that is ok even if our initial alphatype was not opaque.
        return false;
    }

    return m_frameGenerator->decodeAndScale(info, m_frameIndex, pixels, rowBytes);
}

bool DecodingImageGenerator::onGetYUV8Planes(const SkYUVSizeInfo& sizeInfo, void* planes[3])
{
    return false;
}

} // namespace blink
