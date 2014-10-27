/*
 * Copyright (C) 2007, 2008, 2009, 2010 Apple Inc. All rights reserved.
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

#ifndef HTMLVideoElement_h
#define HTMLVideoElement_h

#include "core/html/HTMLMediaElement.h"
#include "core/html/canvas/CanvasImageSource.h"
#include "platform/graphics/GraphicsTypes3D.h"

namespace blink {
class WebGraphicsContext3D;
}

namespace blink {

class ExceptionState;
class HTMLImageLoader;
class GraphicsContext;

// GL types as defined in OpenGL ES 2.0 header file gl2.h from khronos.org.
// That header cannot be included directly due to a conflict with NPAPI headers.
// See crbug.com/328085.
typedef unsigned GLenum;
typedef int GC3Dint;

class HTMLVideoElement final : public HTMLMediaElement, public CanvasImageSource {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<HTMLVideoElement> create(Document&);
    virtual void trace(Visitor*) override;

    unsigned videoWidth() const;
    unsigned videoHeight() const;

    // Used by canvas to gain raw pixel access
    void paintCurrentFrameInContext(GraphicsContext*, const IntRect&) const;

    // Used by WebGL to do GPU-GPU textures copy if possible.
    // See more details at MediaPlayer::copyVideoTextureToPlatformTexture() defined in engine/WebCore/platform/graphics/MediaPlayer.h.
    bool copyVideoTextureToPlatformTexture(WebGraphicsContext3D*, Platform3DObject texture, GC3Dint level, GLenum internalFormat, GLenum type, bool premultiplyAlpha, bool flipY);

    bool shouldDisplayPosterImage() const { return displayMode() == Poster || displayMode() == PosterWaitingForVideo; }

    KURL posterImageURL() const;

    // FIXME: Remove this when WebMediaPlayerClientImpl::loadInternal does not depend on it.
    virtual KURL mediaPlayerPosterURL() override;

    // CanvasImageSource implementation
    virtual PassRefPtr<Image> getSourceImageForCanvas(SourceImageMode, SourceImageStatus*) const override;
    virtual bool isVideoElement() const override { return true; }
    virtual FloatSize sourceSize() const override;
    virtual const KURL& sourceURL() const override { return currentSrc(); }

    virtual bool isHTMLVideoElement() const override { return true; }

private:
    HTMLVideoElement(Document&);

    virtual bool rendererIsNeeded(const RenderStyle&) override;
    virtual RenderObject* createRenderer(RenderStyle*) override;
    virtual void attach(const AttachContext& = AttachContext()) override;
    virtual void parseAttribute(const QualifiedName&, const AtomicString&) override;
    virtual bool hasVideo() const override { return webMediaPlayer() && webMediaPlayer()->hasVideo(); }
    virtual bool isURLAttribute(const Attribute&) const override;
    virtual const AtomicString imageSourceURL() const override;

    bool hasAvailableVideoFrame() const;
    virtual void updateDisplayState() override;
    virtual void didMoveToNewDocument(Document& oldDocument) override;
    virtual void setDisplayMode(DisplayMode) override;

    OwnPtr<HTMLImageLoader> m_imageLoader;

    AtomicString m_defaultPosterURL;
};

} // namespace blink

#endif // HTMLVideoElement_h
