/*
 * Copyright (C) 2007, 2008, 2009, 2010 Apple Inc.  All rights reserved.
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

#include "core/rendering/RenderVideo.h"

#include "core/dom/Document.h"
#include "core/frame/FrameView.h"
#include "core/frame/LocalFrame.h"
#include "core/html/HTMLVideoElement.h"
#include "core/rendering/PaintInfo.h"
#include "platform/graphics/media/MediaPlayer.h"
#include "public/platform/WebLayer.h"

namespace blink {

RenderVideo::RenderVideo(HTMLVideoElement* video)
    : RenderMedia(video)
{
    setIntrinsicSize(calculateIntrinsicSize());
}

RenderVideo::~RenderVideo()
{
}

IntSize RenderVideo::defaultSize()
{
    return IntSize(defaultWidth, defaultHeight);
}

void RenderVideo::intrinsicSizeChanged()
{
    if (videoElement()->shouldDisplayPosterImage())
        RenderMedia::intrinsicSizeChanged();
    updateIntrinsicSize();
}

void RenderVideo::updateIntrinsicSize()
{
    LayoutSize size = calculateIntrinsicSize();
    size.scale(style()->effectiveZoom());

    if (size == intrinsicSize())
        return;

    setIntrinsicSize(size);
    setPreferredLogicalWidthsDirty();
    setNeedsLayoutAndFullPaintInvalidation();
}

LayoutSize RenderVideo::calculateIntrinsicSize()
{
    HTMLVideoElement* video = videoElement();

    // Spec text from 4.8.6
    //
    // The intrinsic width of a video element's playback area is the intrinsic width
    // of the video resource, if that is available; otherwise it is the intrinsic
    // width of the poster frame, if that is available; otherwise it is 300 CSS pixels.
    //
    // The intrinsic height of a video element's playback area is the intrinsic height
    // of the video resource, if that is available; otherwise it is the intrinsic
    // height of the poster frame, if that is available; otherwise it is 150 CSS pixels.
    WebMediaPlayer* webMediaPlayer = mediaElement()->webMediaPlayer();
    if (webMediaPlayer && video->readyState() >= HTMLVideoElement::HAVE_METADATA) {
        IntSize size = webMediaPlayer->naturalSize();
        if (!size.isEmpty())
            return size;
    }

    if (video->shouldDisplayPosterImage() && !m_cachedImageSize.isEmpty() && !imageResource()->errorOccurred())
        return m_cachedImageSize;

    return defaultSize();
}

void RenderVideo::imageChanged(WrappedImagePtr newImage, const IntRect* rect)
{
    RenderMedia::imageChanged(newImage, rect);

    // Cache the image intrinsic size so we can continue to use it to draw the image correctly
    // even if we know the video intrinsic size but aren't able to draw video frames yet
    // (we don't want to scale the poster to the video size without keeping aspect ratio).
    if (videoElement()->shouldDisplayPosterImage())
        m_cachedImageSize = intrinsicSize();

    // The intrinsic size is now that of the image, but in case we already had the
    // intrinsic size of the video we call this here to restore the video size.
    updateIntrinsicSize();
}

IntRect RenderVideo::videoBox() const
{
    const LayoutSize* overriddenIntrinsicSize = 0;
    if (videoElement()->shouldDisplayPosterImage())
        overriddenIntrinsicSize = &m_cachedImageSize;

    return pixelSnappedIntRect(replacedContentRect(overriddenIntrinsicSize));
}

bool RenderVideo::shouldDisplayVideo() const
{
    return !videoElement()->shouldDisplayPosterImage();
}

void RenderVideo::paintReplaced(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
{
    MediaPlayer* mediaPlayer = mediaElement()->player();
    bool displayingPoster = videoElement()->shouldDisplayPosterImage();
    if (!displayingPoster && !mediaPlayer)
        return;

    LayoutRect rect = videoBox();
    if (rect.isEmpty())
        return;
    rect.moveBy(paintOffset);

    LayoutRect contentRect = contentBoxRect();
    contentRect.moveBy(paintOffset);
    GraphicsContext* context = paintInfo.context;
    bool clip = !contentRect.contains(rect);
    if (clip) {
        context->save();
        context->clip(contentRect);
    }

    if (displayingPoster)
        paintIntoRect(context, rect);
    else if ((document().view() && document().view()->paintBehavior() & PaintBehaviorFlattenCompositingLayers) || !acceleratedRenderingInUse())
        videoElement()->paintCurrentFrameInContext(context, pixelSnappedIntRect(rect));

    if (clip)
        context->restore();
}

bool RenderVideo::acceleratedRenderingInUse()
{
    WebLayer* webLayer = mediaElement()->platformLayer();
    return webLayer && !webLayer->isOrphan();
}

void RenderVideo::layout()
{
    updatePlayer();
    RenderMedia::layout();
}

HTMLVideoElement* RenderVideo::videoElement() const
{
    return toHTMLVideoElement(node());
}

void RenderVideo::updateFromElement()
{
    RenderMedia::updateFromElement();
    updatePlayer();
}

void RenderVideo::updatePlayer()
{
    updateIntrinsicSize();

    MediaPlayer* mediaPlayer = mediaElement()->player();
    if (!mediaPlayer)
        return;

    if (!videoElement()->isActive())
        return;

    videoElement()->setNeedsCompositingUpdate();
}

LayoutUnit RenderVideo::computeReplacedLogicalWidth(ShouldComputePreferred shouldComputePreferred) const
{
    return RenderReplaced::computeReplacedLogicalWidth(shouldComputePreferred);
}

LayoutUnit RenderVideo::computeReplacedLogicalHeight() const
{
    return RenderReplaced::computeReplacedLogicalHeight();
}

LayoutUnit RenderVideo::minimumReplacedHeight() const
{
    return RenderReplaced::minimumReplacedHeight();
}

bool RenderVideo::supportsAcceleratedRendering() const
{
    return !!mediaElement()->platformLayer();
}

CompositingReasons RenderVideo::additionalCompositingReasons() const
{
    if (RuntimeEnabledFeatures::overlayFullscreenVideoEnabled()) {
        HTMLMediaElement* media = toHTMLMediaElement(node());
        if (media->isFullscreen())
            return CompositingReasonVideo;
    }

    if (shouldDisplayVideo() && supportsAcceleratedRendering())
        return CompositingReasonVideo;

    return CompositingReasonNone;
}

} // namespace blink
