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

#include "config.h"
#include "core/html/HTMLVideoElement.h"

#include "bindings/core/v8/ExceptionState.h"
#include "core/CSSPropertyNames.h"
#include "core/HTMLNames.h"
#include "core/dom/Attribute.h"
#include "core/dom/Document.h"
#include "core/dom/ExceptionCode.h"
#include "core/frame/Settings.h"
#include "core/html/HTMLImageLoader.h"
#include "core/html/canvas/CanvasRenderingContext.h"
#include "core/html/parser/HTMLParserIdioms.h"
#include "core/rendering/RenderImage.h"
#include "core/rendering/RenderVideo.h"
#include "platform/UserGestureIndicator.h"
#include "platform/graphics/GraphicsContext.h"
#include "platform/graphics/gpu/Extensions3DUtil.h"
#include "public/platform/WebCanvas.h"
#include "public/platform/WebGraphicsContext3D.h"

namespace blink {

inline HTMLVideoElement::HTMLVideoElement(Document& document)
    : HTMLMediaElement(HTMLNames::videoTag, document)
{
    ScriptWrappable::init(this);
    if (document.settings())
        m_defaultPosterURL = AtomicString(document.settings()->defaultVideoPosterURL());
}

PassRefPtr<HTMLVideoElement> HTMLVideoElement::create(Document& document)
{
    RefPtr<HTMLVideoElement> video = adoptRef(new HTMLVideoElement(document));
    video->suspendIfNeeded();
    return video.release();
}

void HTMLVideoElement::trace(Visitor* visitor)
{
    visitor->trace(m_imageLoader);
    HTMLMediaElement::trace(visitor);
}

bool HTMLVideoElement::rendererIsNeeded(const RenderStyle& style)
{
    return HTMLElement::rendererIsNeeded(style);
}

RenderObject* HTMLVideoElement::createRenderer(RenderStyle*)
{
    return new RenderVideo(this);
}

void HTMLVideoElement::attach(const AttachContext& context)
{
    HTMLMediaElement::attach(context);

    updateDisplayState();
    if (shouldDisplayPosterImage()) {
        if (!m_imageLoader)
            m_imageLoader = HTMLImageLoader::create(this);
        m_imageLoader->updateFromElement();
        if (renderer())
            toRenderImage(renderer())->imageResource()->setImageResource(m_imageLoader->image());
    }
}

void HTMLVideoElement::parseAttribute(const QualifiedName& name, const AtomicString& value)
{
    if (name == HTMLNames::posterAttr) {
        // Force a poster recalc by setting m_displayMode to Unknown directly before calling updateDisplayState.
        HTMLMediaElement::setDisplayMode(Unknown);
        updateDisplayState();
        if (shouldDisplayPosterImage()) {
            if (!m_imageLoader)
                m_imageLoader = HTMLImageLoader::create(this);
            m_imageLoader->updateFromElement(ImageLoader::UpdateIgnorePreviousError);
        } else {
            if (renderer())
                toRenderImage(renderer())->imageResource()->setImageResource(0);
        }
        // Notify the player when the poster image URL changes.
        if (webMediaPlayer())
            webMediaPlayer()->setPoster(posterImageURL());
    } else
        HTMLMediaElement::parseAttribute(name, value);
}

unsigned HTMLVideoElement::videoWidth() const
{
    if (!webMediaPlayer())
        return 0;
    return webMediaPlayer()->naturalSize().width;
}

unsigned HTMLVideoElement::videoHeight() const
{
    if (!webMediaPlayer())
        return 0;
    return webMediaPlayer()->naturalSize().height;
}

bool HTMLVideoElement::isURLAttribute(const Attribute& attribute) const
{
    return attribute.name() == HTMLNames::posterAttr || HTMLMediaElement::isURLAttribute(attribute);
}

const AtomicString HTMLVideoElement::imageSourceURL() const
{
    const AtomicString& url = getAttribute(HTMLNames::posterAttr);
    if (!stripLeadingAndTrailingHTMLSpaces(url).isEmpty())
        return url;
    return m_defaultPosterURL;
}

void HTMLVideoElement::setDisplayMode(DisplayMode mode)
{
    DisplayMode oldMode = displayMode();
    KURL poster = posterImageURL();

    if (!poster.isEmpty()) {
        // We have a poster path, but only show it until the user triggers display by playing or seeking and the
        // media engine has something to display.
        // Don't show the poster if there is a seek operation or
        // the video has restarted because of loop attribute
        if (mode == Video && oldMode == Poster && !hasAvailableVideoFrame())
            mode = PosterWaitingForVideo;
    }

    HTMLMediaElement::setDisplayMode(mode);

    if (renderer() && displayMode() != oldMode)
        renderer()->updateFromElement();
}

void HTMLVideoElement::updateDisplayState()
{
    if (posterImageURL().isEmpty())
        setDisplayMode(Video);
    else if (displayMode() < Poster)
        setDisplayMode(Poster);
}

void HTMLVideoElement::paintCurrentFrameInContext(GraphicsContext* context, const IntRect& destRect) const
{
    if (!webMediaPlayer())
        return;

    WebCanvas* canvas = context->canvas();
    SkXfermode::Mode mode = WebCoreCompositeToSkiaComposite(context->compositeOperation(), context->blendModeOperation());
    webMediaPlayer()->paint(canvas, destRect, context->getNormalizedAlpha(), mode);
}

bool HTMLVideoElement::copyVideoTextureToPlatformTexture(WebGraphicsContext3D* context, Platform3DObject texture, GLint level, GLenum internalFormat, GLenum type, bool premultiplyAlpha, bool flipY)
{
    if (!webMediaPlayer())
        return false;

    if (!Extensions3DUtil::canUseCopyTextureCHROMIUM(internalFormat, type, level))
        return false;

    return webMediaPlayer()->copyVideoTextureToPlatformTexture(context, texture, level, internalFormat, type, premultiplyAlpha, flipY);
}

bool HTMLVideoElement::hasAvailableVideoFrame() const
{
    if (!webMediaPlayer())
        return false;

    return webMediaPlayer()->hasVideo() && webMediaPlayer()->readyState() >= blink::WebMediaPlayer::ReadyStateHaveCurrentData;
}

void HTMLVideoElement::didMoveToNewDocument(Document& oldDocument)
{
    if (m_imageLoader)
        m_imageLoader->elementDidMoveToNewDocument();
    HTMLMediaElement::didMoveToNewDocument(oldDocument);
}

KURL HTMLVideoElement::posterImageURL() const
{
    String url = stripLeadingAndTrailingHTMLSpaces(imageSourceURL());
    if (url.isEmpty())
        return KURL();
    return document().completeURL(url);
}

KURL HTMLVideoElement::mediaPlayerPosterURL()
{
    return posterImageURL();
}

PassRefPtr<Image> HTMLVideoElement::getSourceImageForCanvas(SourceImageMode mode, SourceImageStatus* status) const
{
    if (!hasAvailableVideoFrame()) {
        *status = InvalidSourceImageStatus;
        return nullptr;
    }

    IntSize intrinsicSize(videoWidth(), videoHeight());
    OwnPtr<ImageBuffer> imageBuffer = ImageBuffer::create(intrinsicSize);
    if (!imageBuffer) {
        *status = InvalidSourceImageStatus;
        return nullptr;
    }

    paintCurrentFrameInContext(imageBuffer->context(), IntRect(IntPoint(0, 0), intrinsicSize));

    *status = NormalSourceImageStatus;
    return imageBuffer->copyImage(mode == CopySourceImageIfVolatile ? CopyBackingStore : DontCopyBackingStore, Unscaled);
}

FloatSize HTMLVideoElement::sourceSize() const
{
    return FloatSize(videoWidth(), videoHeight());
}

}
