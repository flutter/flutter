/*
 * Copyright (C) 2007, 2009, 2010 Apple Inc. All rights reserved.
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

#ifndef RenderVideo_h
#define RenderVideo_h

#include "core/rendering/RenderMedia.h"

namespace blink {

class HTMLVideoElement;

class RenderVideo final : public RenderMedia {
public:
    RenderVideo(HTMLVideoElement*);
    virtual ~RenderVideo();

    IntRect videoBox() const;

    static IntSize defaultSize();

    bool supportsAcceleratedRendering() const;

    bool shouldDisplayVideo() const;

private:
    virtual void updateFromElement() override;
    inline HTMLVideoElement* videoElement() const;

    virtual void intrinsicSizeChanged() override;
    LayoutSize calculateIntrinsicSize();
    void updateIntrinsicSize();

    virtual void imageChanged(WrappedImagePtr, const IntRect*) override;

    virtual const char* renderName() const override { return "RenderVideo"; }

    virtual bool isVideo() const override { return true; }

    virtual void paintReplaced(PaintInfo&, const LayoutPoint&) override;

    virtual void layout() override;

    virtual LayoutUnit computeReplacedLogicalWidth(ShouldComputePreferred  = ComputeActual) const override;
    virtual LayoutUnit computeReplacedLogicalHeight() const override;
    virtual LayoutUnit minimumReplacedHeight() const override;

    virtual CompositingReasons additionalCompositingReasons() const override;

    void updatePlayer();

    bool acceleratedRenderingInUse();

    LayoutSize m_cachedImageSize;
};

DEFINE_RENDER_OBJECT_TYPE_CASTS(RenderVideo, isVideo());

} // namespace blink

#endif // RenderVideo_h
