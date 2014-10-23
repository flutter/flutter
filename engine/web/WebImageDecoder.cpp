/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
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

#include "config.h"
#include "public/web/WebImageDecoder.h"

#include "platform/SharedBuffer.h"
#include "platform/image-decoders/bmp/BMPImageDecoder.h"
#include "platform/image-decoders/ico/ICOImageDecoder.h"
#include "public/platform/Platform.h"
#include "public/platform/WebData.h"
#include "public/platform/WebImage.h"
#include "public/platform/WebSize.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/PassRefPtr.h"

namespace blink {

void WebImageDecoder::reset()
{
    delete m_private;
}

void WebImageDecoder::init(Type type)
{
    size_t maxDecodedBytes = Platform::current()->maxDecodedImageBytes();

    switch (type) {
    case TypeBMP:
        m_private = new BMPImageDecoder(ImageSource::AlphaPremultiplied, ImageSource::GammaAndColorProfileApplied, maxDecodedBytes);
        break;
    case TypeICO:
        m_private = new ICOImageDecoder(ImageSource::AlphaPremultiplied, ImageSource::GammaAndColorProfileApplied, maxDecodedBytes);
        break;
    }
}

void WebImageDecoder::setData(const WebData& data, bool allDataReceived)
{
    ASSERT(m_private);
    m_private->setData(PassRefPtr<SharedBuffer>(data).get(), allDataReceived);
}

bool WebImageDecoder::isFailed() const
{
    ASSERT(m_private);
    return m_private->failed();
}

bool WebImageDecoder::isSizeAvailable() const
{
    ASSERT(m_private);
    return m_private->isSizeAvailable();
}

WebSize WebImageDecoder::size() const
{
    ASSERT(m_private);
    return m_private->size();
}

size_t WebImageDecoder::frameCount() const
{
    ASSERT(m_private);
    return m_private->frameCount();
}

bool WebImageDecoder::isFrameCompleteAtIndex(int index) const
{
    ASSERT(m_private);
    ImageFrame* const frameBuffer = m_private->frameBufferAtIndex(index);
    if (!frameBuffer)
        return false;
    return frameBuffer->status() == ImageFrame::FrameComplete;
}

WebImage WebImageDecoder::getFrameAtIndex(int index = 0) const
{
    ASSERT(m_private);
    ImageFrame* const frameBuffer = m_private->frameBufferAtIndex(index);
    if (!frameBuffer)
        return WebImage();
    RefPtr<NativeImageSkia> image = frameBuffer->asNewNativeImage();
    return WebImage(image->bitmap());
}

} // namespace blink
