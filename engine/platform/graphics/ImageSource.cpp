/*
 * Copyright (C) 2006 Apple Computer, Inc.  All rights reserved.
 * Copyright (C) 2007 Alp Toker <alp.toker@collabora.co.uk>
 * Copyright (C) 2008, Google Inc. All rights reserved.
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

#include "config.h"
#include "platform/graphics/ImageSource.h"

#include "platform/graphics/DeferredImageDecoder.h"
#include "platform/image-decoders/ImageDecoder.h"

namespace blink {

ImageSource::ImageSource(ImageSource::AlphaOption alphaOption, ImageSource::GammaAndColorProfileOption gammaAndColorProfileOption)
    : m_alphaOption(alphaOption)
    , m_gammaAndColorProfileOption(gammaAndColorProfileOption)
{
}

ImageSource::~ImageSource()
{
}

size_t ImageSource::clearCacheExceptFrame(size_t clearExceptFrame)
{
    return m_decoder ? m_decoder->clearCacheExceptFrame(clearExceptFrame) : 0;
}

bool ImageSource::initialized() const
{
    return m_decoder;
}

void ImageSource::resetDecoder()
{
    m_decoder.clear();
}

void ImageSource::setData(SharedBuffer& data, bool allDataReceived)
{
    // Create a decoder by sniffing the encoded data. If insufficient data bytes are available to
    // determine the encoded image type, no decoder is created.
    if (!m_decoder)
        m_decoder = DeferredImageDecoder::create(data, m_alphaOption, m_gammaAndColorProfileOption);

    if (m_decoder)
        m_decoder->setData(data, allDataReceived);
}

String ImageSource::filenameExtension() const
{
    return m_decoder ? m_decoder->filenameExtension() : String();
}

bool ImageSource::isSizeAvailable()
{
    return m_decoder && m_decoder->isSizeAvailable();
}

bool ImageSource::hasColorProfile() const
{
    return m_decoder && m_decoder->hasColorProfile();
}

IntSize ImageSource::size(RespectImageOrientationEnum shouldRespectOrientation) const
{
    return frameSizeAtIndex(0, shouldRespectOrientation);
}

IntSize ImageSource::frameSizeAtIndex(size_t index, RespectImageOrientationEnum shouldRespectOrientation) const
{
    if (!m_decoder)
        return IntSize();

    IntSize size = m_decoder->frameSizeAtIndex(index);
    if ((shouldRespectOrientation == RespectImageOrientation) && m_decoder->orientation().usesWidthAsHeight())
        return IntSize(size.height(), size.width());

    return size;
}

bool ImageSource::getHotSpot(IntPoint& hotSpot) const
{
    return m_decoder ? m_decoder->hotSpot(hotSpot) : false;
}

int ImageSource::repetitionCount()
{
    return m_decoder ? m_decoder->repetitionCount() : cAnimationNone;
}

size_t ImageSource::frameCount() const
{
    return m_decoder ? m_decoder->frameCount() : 0;
}

PassRefPtr<NativeImageSkia> ImageSource::createFrameAtIndex(size_t index)
{
    if (!m_decoder)
        return nullptr;

    ImageFrame* buffer = m_decoder->frameBufferAtIndex(index);
    if (!buffer || buffer->status() == ImageFrame::FrameEmpty)
        return nullptr;

    // Zero-height images can cause problems for some ports.  If we have an
    // empty image dimension, just bail.
    if (size().isEmpty())
        return nullptr;

    // Return the buffer contents as a native image.  For some ports, the data
    // is already in a native container, and this just increments its refcount.
    return buffer->asNewNativeImage();
}

float ImageSource::frameDurationAtIndex(size_t index) const
{
    if (!m_decoder)
        return 0;

    // Many annoying ads specify a 0 duration to make an image flash as quickly as possible.
    // We follow Firefox's behavior and use a duration of 100 ms for any frames that specify
    // a duration of <= 10 ms. See <rdar://problem/7689300> and <http://webkit.org/b/36082>
    // for more information.
    const float duration = m_decoder->frameDurationAtIndex(index) / 1000.0f;
    if (duration < 0.011f)
        return 0.100f;
    return duration;
}

ImageOrientation ImageSource::orientationAtIndex(size_t) const
{
    return m_decoder ? m_decoder->orientation() : DefaultImageOrientation;
}

bool ImageSource::frameHasAlphaAtIndex(size_t index) const
{
    return !m_decoder || m_decoder->frameHasAlphaAtIndex(index);
}

bool ImageSource::frameIsCompleteAtIndex(size_t index) const
{
    return m_decoder && m_decoder->frameIsCompleteAtIndex(index);
}

unsigned ImageSource::frameBytesAtIndex(size_t index) const
{
    return m_decoder ? m_decoder->frameBytesAtIndex(index) : 0;
}

} // namespace blink
