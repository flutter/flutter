/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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
#include "platform/graphics/GraphicsContextRecorder.h"

#include "platform/graphics/ImageBuffer.h"
#include "platform/graphics/ImageSource.h"
#include "platform/graphics/LoggingCanvas.h"
#include "platform/graphics/ProfilingCanvas.h"
#include "platform/graphics/ReplayingCanvas.h"
#include "platform/image-decoders/ImageDecoder.h"
#include "platform/image-decoders/ImageFrame.h"
#include "platform/image-encoders/skia/PNGImageEncoder.h"
#include "third_party/skia/include/core/SkBitmapDevice.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"
#include "third_party/skia/include/core/SkStream.h"
#include "wtf/HexNumber.h"
#include "wtf/text/Base64.h"
#include "wtf/text/TextEncoding.h"

namespace blink {

GraphicsContext* GraphicsContextRecorder::record(const IntSize& size, bool isCertainlyOpaque)
{
    ASSERT(!m_picture);
    ASSERT(!m_recorder);
    ASSERT(!m_context);
    m_isCertainlyOpaque = isCertainlyOpaque;
    m_recorder = adoptPtr(new SkPictureRecorder);
    SkCanvas* canvas = m_recorder->beginRecording(size.width(), size.height(), 0, 0);
    m_context = adoptPtr(new GraphicsContext(canvas));
    m_context->setRegionTrackingMode(isCertainlyOpaque ? GraphicsContext::RegionTrackingOpaque : GraphicsContext::RegionTrackingDisabled);
    m_context->setCertainlyOpaque(isCertainlyOpaque);
    return m_context.get();
}

PassRefPtr<GraphicsContextSnapshot> GraphicsContextRecorder::stop()
{
    m_context.clear();
    m_picture = adoptRef(m_recorder->endRecording());
    m_recorder.clear();
    return adoptRef(new GraphicsContextSnapshot(m_picture.release()));
}

GraphicsContextSnapshot::GraphicsContextSnapshot(PassRefPtr<SkPicture> picture)
    : m_picture(picture)
{
}

static bool decodeBitmap(const void* data, size_t length, SkBitmap* result)
{
    RefPtr<SharedBuffer> buffer = SharedBuffer::create(static_cast<const char*>(data), length);
    OwnPtr<ImageDecoder> imageDecoder = ImageDecoder::create(*buffer, ImageSource::AlphaPremultiplied, ImageSource::GammaAndColorProfileIgnored);
    if (!imageDecoder)
        return false;
    imageDecoder->setData(buffer.get(), true);
    ImageFrame* frame = imageDecoder->frameBufferAtIndex(0);
    if (!frame)
        return true;
    *result = frame->getSkBitmap();
    return true;
}

PassRefPtr<GraphicsContextSnapshot> GraphicsContextSnapshot::load(const char* data, size_t size)
{
    SkMemoryStream stream(data, size);
    RefPtr<SkPicture> picture = adoptRef(SkPicture::CreateFromStream(&stream, decodeBitmap));
    if (!picture)
        return nullptr;
    return adoptRef(new GraphicsContextSnapshot(picture));
}

PassOwnPtr<Vector<char> > GraphicsContextSnapshot::replay(unsigned fromStep, unsigned toStep, double scale) const
{
    int width = ceil(scale * m_picture->width());
    int height = ceil(scale * m_picture->height());
    SkBitmap bitmap;
    bitmap.allocPixels(SkImageInfo::MakeN32Premul(width, height));
    {
        ReplayingCanvas canvas(bitmap, fromStep, toStep);
        canvas.scale(scale, scale);
        canvas.resetStepCount();
        m_picture->draw(&canvas, &canvas);
    }
    OwnPtr<Vector<char> > base64Data = adoptPtr(new Vector<char>());
    Vector<char> encodedImage;
    if (!PNGImageEncoder::encode(bitmap, reinterpret_cast<Vector<unsigned char>*>(&encodedImage)))
        return nullptr;
    base64Encode(encodedImage, *base64Data);
    return base64Data.release();
}

PassOwnPtr<GraphicsContextSnapshot::Timings> GraphicsContextSnapshot::profile(unsigned minRepeatCount, double minDuration) const
{
    OwnPtr<GraphicsContextSnapshot::Timings> timings = adoptPtr(new GraphicsContextSnapshot::Timings());
    timings->reserveCapacity(minRepeatCount);
    SkBitmap bitmap;
    bitmap.allocPixels(SkImageInfo::MakeN32Premul(m_picture->width(), m_picture->height()));
    OwnPtr<ProfilingCanvas> canvas = adoptPtr(new ProfilingCanvas(bitmap));

    double now = WTF::monotonicallyIncreasingTime();
    double stopTime = now + minDuration;
    for (unsigned step = 0; step < minRepeatCount || now < stopTime; ++step) {
        timings->append(Vector<double>());
        Vector<double>* currentTimings = &timings->last();
        if (timings->size() > 1)
            currentTimings->reserveCapacity(timings->begin()->size());
        if (step)
            canvas = adoptPtr(new ProfilingCanvas(bitmap));
        canvas->setTimings(currentTimings);
        m_picture->draw(canvas.get());
        now = WTF::monotonicallyIncreasingTime();
    }
    return timings.release();
}

PassRefPtr<JSONArray> GraphicsContextSnapshot::snapshotCommandLog() const
{
    LoggingCanvas canvas(m_picture->width(), m_picture->height());
    m_picture->draw(&canvas);
    return canvas.log();
}

} // namespace blink
