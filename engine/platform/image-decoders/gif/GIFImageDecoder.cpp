/*
 * Copyright (C) 2006 Apple Computer, Inc.  All rights reserved.
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
#include "platform/image-decoders/gif/GIFImageDecoder.h"

#include <limits>
#include "platform/image-decoders/gif/GIFImageReader.h"
#include "wtf/NotFound.h"
#include "wtf/PassOwnPtr.h"

namespace blink {

GIFImageDecoder::GIFImageDecoder(ImageSource::AlphaOption alphaOption,
    ImageSource::GammaAndColorProfileOption gammaAndColorProfileOption,
    size_t maxDecodedBytes)
    : ImageDecoder(alphaOption, gammaAndColorProfileOption, maxDecodedBytes)
    , m_repetitionCount(cAnimationLoopOnce)
{
}

GIFImageDecoder::~GIFImageDecoder()
{
}

void GIFImageDecoder::setData(SharedBuffer* data, bool allDataReceived)
{
    if (failed())
        return;

    ImageDecoder::setData(data, allDataReceived);
    if (m_reader)
        m_reader->setData(data);
}

bool GIFImageDecoder::isSizeAvailable()
{
    if (!ImageDecoder::isSizeAvailable())
        parse(GIFSizeQuery);

    return ImageDecoder::isSizeAvailable();
}

size_t GIFImageDecoder::frameCount()
{
    parse(GIFFrameCountQuery);
    return m_frameBufferCache.size();
}

int GIFImageDecoder::repetitionCount() const
{
    // This value can arrive at any point in the image data stream.  Most GIFs
    // in the wild declare it near the beginning of the file, so it usually is
    // set by the time we've decoded the size, but (depending on the GIF and the
    // packets sent back by the webserver) not always.  If the reader hasn't
    // seen a loop count yet, it will return cLoopCountNotSeen, in which case we
    // should default to looping once (the initial value for
    // |m_repetitionCount|).
    //
    // There are some additional wrinkles here. First, ImageSource::clear()
    // may destroy the reader, making the result from the reader _less_
    // authoritative on future calls if the recreated reader hasn't seen the
    // loop count.  We don't need to special-case this because in this case the
    // new reader will once again return cLoopCountNotSeen, and we won't
    // overwrite the cached correct value.
    //
    // Second, a GIF might never set a loop count at all, in which case we
    // should continue to treat it as a "loop once" animation.  We don't need
    // special code here either, because in this case we'll never change
    // |m_repetitionCount| from its default value.
    //
    // Third, we use the same GIFImageReader for counting frames and we might
    // see the loop count and then encounter a decoding error which happens
    // later in the stream. It is also possible that no frames are in the
    // stream. In these cases we should just loop once.
    if (isAllDataReceived() && parseCompleted() && m_reader->imagesCount() == 1)
        m_repetitionCount = cAnimationNone;
    else if (failed() || (m_reader && (!m_reader->imagesCount())))
        m_repetitionCount = cAnimationLoopOnce;
    else if (m_reader && m_reader->loopCount() != cLoopCountNotSeen)
        m_repetitionCount = m_reader->loopCount();
    return m_repetitionCount;
}

ImageFrame* GIFImageDecoder::frameBufferAtIndex(size_t index)
{
    if (index >= frameCount())
        return 0;

    ImageFrame& frame = m_frameBufferCache[index];
    if (frame.status() != ImageFrame::FrameComplete) {
        decode(index);
    }

    frame.notifyBitmapIfPixelsChanged();
    return &frame;
}

bool GIFImageDecoder::frameIsCompleteAtIndex(size_t index) const
{
    return m_reader && (index < m_reader->imagesCount()) && m_reader->frameContext(index)->isComplete();
}

float GIFImageDecoder::frameDurationAtIndex(size_t index) const
{
    return (m_reader && (index < m_reader->imagesCount()) &&
        m_reader->frameContext(index)->isHeaderDefined()) ?
        m_reader->frameContext(index)->delayTime() : 0;
}

bool GIFImageDecoder::setFailed()
{
    m_reader.clear();
    return ImageDecoder::setFailed();
}

bool GIFImageDecoder::haveDecodedRow(size_t frameIndex, GIFRow::const_iterator rowBegin, size_t width, size_t rowNumber, unsigned repeatCount, bool writeTransparentPixels)
{
    const GIFFrameContext* frameContext = m_reader->frameContext(frameIndex);
    // The pixel data and coordinates supplied to us are relative to the frame's
    // origin within the entire image size, i.e.
    // (frameContext->xOffset, frameContext->yOffset). There is no guarantee
    // that width == (size().width() - frameContext->xOffset), so
    // we must ensure we don't run off the end of either the source data or the
    // row's X-coordinates.
    const int xBegin = frameContext->xOffset();
    const int yBegin = frameContext->yOffset() + rowNumber;
    const int xEnd = std::min(static_cast<int>(frameContext->xOffset() + width), size().width());
    const int yEnd = std::min(static_cast<int>(frameContext->yOffset() + rowNumber + repeatCount), size().height());
    if (!width || (xBegin < 0) || (yBegin < 0) || (xEnd <= xBegin) || (yEnd <= yBegin))
        return true;

    const GIFColorMap::Table& colorTable = frameContext->localColorMap().isDefined() ? frameContext->localColorMap().table() : m_reader->globalColorMap().table();

    if (colorTable.isEmpty())
        return true;

    GIFColorMap::Table::const_iterator colorTableIter = colorTable.begin();

    // Initialize the frame if necessary.
    ImageFrame& buffer = m_frameBufferCache[frameIndex];
    if ((buffer.status() == ImageFrame::FrameEmpty) && !initFrameBuffer(frameIndex))
        return false;

    const size_t transparentPixel = frameContext->transparentPixel();
    GIFRow::const_iterator rowEnd = rowBegin + (xEnd - xBegin);
    ImageFrame::PixelData* currentAddress = buffer.getAddr(xBegin, yBegin);

    // We may or may not need to write transparent pixels to the buffer.
    // If we're compositing against a previous image, it's wrong, and if
    // we're writing atop a cleared, fully transparent buffer, it's
    // unnecessary; but if we're decoding an interlaced gif and
    // displaying it "Haeberli"-style, we must write these for passes
    // beyond the first, or the initial passes will "show through" the
    // later ones.
    //
    // The loops below are almost identical. One writes a transparent pixel
    // and one doesn't based on the value of |writeTransparentPixels|.
    // The condition check is taken out of the loop to enhance performance.
    // This optimization reduces decoding time by about 15% for a 3MB image.
    if (writeTransparentPixels) {
        for (; rowBegin != rowEnd; ++rowBegin, ++currentAddress) {
            const size_t sourceValue = *rowBegin;
            if ((sourceValue != transparentPixel) && (sourceValue < colorTable.size())) {
                *currentAddress = colorTableIter[sourceValue];
            } else {
                *currentAddress = 0;
                m_currentBufferSawAlpha = true;
            }
        }
    } else {
        for (; rowBegin != rowEnd; ++rowBegin, ++currentAddress) {
            const size_t sourceValue = *rowBegin;
            if ((sourceValue != transparentPixel) && (sourceValue < colorTable.size()))
                *currentAddress = colorTableIter[sourceValue];
            else
                m_currentBufferSawAlpha = true;
        }
    }

    // Tell the frame to copy the row data if need be.
    if (repeatCount > 1)
        buffer.copyRowNTimes(xBegin, xEnd, yBegin, yEnd);

    buffer.setPixelsChanged(true);
    return true;
}

bool GIFImageDecoder::parseCompleted() const
{
    return m_reader && m_reader->parseCompleted();
}

bool GIFImageDecoder::frameComplete(size_t frameIndex)
{
    // Initialize the frame if necessary.  Some GIFs insert do-nothing frames,
    // in which case we never reach haveDecodedRow() before getting here.
    ImageFrame& buffer = m_frameBufferCache[frameIndex];
    if ((buffer.status() == ImageFrame::FrameEmpty) && !initFrameBuffer(frameIndex))
        return false; // initFrameBuffer() has already called setFailed().

    buffer.setStatus(ImageFrame::FrameComplete);

    if (!m_currentBufferSawAlpha) {
        // The whole frame was non-transparent, so it's possible that the entire
        // resulting buffer was non-transparent, and we can setHasAlpha(false).
        if (buffer.originalFrameRect().contains(IntRect(IntPoint(), size()))) {
            buffer.setHasAlpha(false);
            buffer.setRequiredPreviousFrameIndex(kNotFound);
        } else if (buffer.requiredPreviousFrameIndex() != kNotFound) {
            // Tricky case.  This frame does not have alpha only if everywhere
            // outside its rect doesn't have alpha.  To know whether this is
            // true, we check the start state of the frame -- if it doesn't have
            // alpha, we're safe.
            const ImageFrame* prevBuffer = &m_frameBufferCache[buffer.requiredPreviousFrameIndex()];
            ASSERT(prevBuffer->disposalMethod() != ImageFrame::DisposeOverwritePrevious);

            // Now, if we're at a DisposeNotSpecified or DisposeKeep frame, then
            // we can say we have no alpha if that frame had no alpha.  But
            // since in initFrameBuffer() we already copied that frame's alpha
            // state into the current frame's, we need do nothing at all here.
            //
            // The only remaining case is a DisposeOverwriteBgcolor frame.  If
            // it had no alpha, and its rect is contained in the current frame's
            // rect, we know the current frame has no alpha.
            if ((prevBuffer->disposalMethod() == ImageFrame::DisposeOverwriteBgcolor) && !prevBuffer->hasAlpha() && buffer.originalFrameRect().contains(prevBuffer->originalFrameRect()))
                buffer.setHasAlpha(false);
        }
    }

    return true;
}

size_t GIFImageDecoder::clearCacheExceptFrame(size_t clearExceptFrame)
{
    // We need to preserve frames such that:
    //  1. We don't clear |clearExceptFrame|;
    //  2. We don't clear any frame from which a future initFrameBuffer() call
    //     will copy bitmap data.
    // All other frames can be cleared.
    while ((clearExceptFrame < m_frameBufferCache.size()) && (m_frameBufferCache[clearExceptFrame].status() == ImageFrame::FrameEmpty))
        clearExceptFrame = m_frameBufferCache[clearExceptFrame].requiredPreviousFrameIndex();

    return ImageDecoder::clearCacheExceptFrame(clearExceptFrame);
}

void GIFImageDecoder::clearFrameBuffer(size_t frameIndex)
{
    if (m_reader && m_frameBufferCache[frameIndex].status() == ImageFrame::FramePartial) {
        // Reset the state of the partial frame in the reader so that the frame
        // can be decoded again when requested.
        m_reader->clearDecodeState(frameIndex);
    }
    ImageDecoder::clearFrameBuffer(frameIndex);
}

void GIFImageDecoder::parse(GIFParseQuery query)
{
    if (failed())
        return;

    if (!m_reader) {
        m_reader = adoptPtr(new GIFImageReader(this));
        m_reader->setData(m_data);
    }

    if (!m_reader->parse(query)) {
        setFailed();
        return;
    }

    const size_t oldSize = m_frameBufferCache.size();
    m_frameBufferCache.resize(m_reader->imagesCount());

    for (size_t i = oldSize; i < m_reader->imagesCount(); ++i) {
        ImageFrame& buffer = m_frameBufferCache[i];
        const GIFFrameContext* frameContext = m_reader->frameContext(i);
        buffer.setPremultiplyAlpha(m_premultiplyAlpha);
        buffer.setRequiredPreviousFrameIndex(findRequiredPreviousFrame(i, false));
        buffer.setDuration(frameContext->delayTime());
        buffer.setDisposalMethod(frameContext->disposalMethod());

        // Initialize the frame rect in our buffer.
        IntRect frameRect = frameContext->frameRect();

        // Make sure the frameRect doesn't extend outside the buffer.
        if (frameRect.maxX() > size().width())
            frameRect.setWidth(size().width() - frameRect.x());
        if (frameRect.maxY() > size().height())
            frameRect.setHeight(size().height() - frameRect.y());

        buffer.setOriginalFrameRect(frameRect);
    }
}

void GIFImageDecoder::decode(size_t frameIndex)
{
    parse(GIFFrameCountQuery);

    if (failed())
        return;

    Vector<size_t> framesToDecode;
    size_t frameToDecode = frameIndex;
    do {
        framesToDecode.append(frameToDecode);
        frameToDecode = m_frameBufferCache[frameToDecode].requiredPreviousFrameIndex();
    } while (frameToDecode != kNotFound && m_frameBufferCache[frameToDecode].status() != ImageFrame::FrameComplete);

    for (size_t i = framesToDecode.size(); i > 0; --i) {
        size_t frameIndex = framesToDecode[i - 1];
        if (!m_reader->decode(frameIndex)) {
            setFailed();
            return;
        }

        // We need more data to continue decoding.
        if (m_frameBufferCache[frameIndex].status() != ImageFrame::FrameComplete)
            break;
    }

    // It is also a fatal error if all data is received and we have decoded all
    // frames available but the file is truncated.
    if (frameIndex >= m_frameBufferCache.size() - 1 && isAllDataReceived() && m_reader && !m_reader->parseCompleted())
        setFailed();
}

bool GIFImageDecoder::initFrameBuffer(size_t frameIndex)
{
    // Initialize the frame rect in our buffer.
    ImageFrame* const buffer = &m_frameBufferCache[frameIndex];

    size_t requiredPreviousFrameIndex = buffer->requiredPreviousFrameIndex();
    if (requiredPreviousFrameIndex == kNotFound) {
        // This frame doesn't rely on any previous data.
        if (!buffer->setSize(size().width(), size().height()))
            return setFailed();
    } else {
        const ImageFrame* prevBuffer = &m_frameBufferCache[requiredPreviousFrameIndex];
        ASSERT(prevBuffer->status() == ImageFrame::FrameComplete);

        // Preserve the last frame as the starting state for this frame.
        if (!buffer->copyBitmapData(*prevBuffer))
            return setFailed();

        if (prevBuffer->disposalMethod() == ImageFrame::DisposeOverwriteBgcolor) {
            // We want to clear the previous frame to transparent, without
            // affecting pixels in the image outside of the frame.
            const IntRect& prevRect = prevBuffer->originalFrameRect();
            ASSERT(!prevRect.contains(IntRect(IntPoint(), size())));
            buffer->zeroFillFrameRect(prevRect);
        }
    }

    // Update our status to be partially complete.
    buffer->setStatus(ImageFrame::FramePartial);

    // Reset the alpha pixel tracker for this frame.
    m_currentBufferSawAlpha = false;
    return true;
}

} // namespace blink
