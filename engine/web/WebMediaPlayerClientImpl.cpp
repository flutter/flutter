// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "web/WebMediaPlayerClientImpl.h"

#include "core/frame/LocalFrame.h"
#include "core/html/HTMLMediaElement.h"
#include "core/html/TimeRanges.h"
#include "core/rendering/RenderView.h"
#include "core/rendering/compositing/RenderLayerCompositor.h"
#include "platform/geometry/IntSize.h"
#include "platform/graphics/GraphicsContext.h"
#include "platform/graphics/GraphicsLayer.h"
#include "platform/graphics/gpu/Extensions3DUtil.h"
#include "platform/graphics/media/MediaPlayer.h"
#include "platform/graphics/skia/GaneshUtils.h"
#include "public/platform/Platform.h"
#include "public/platform/WebCString.h"
#include "public/platform/WebCanvas.h"
#include "public/platform/WebCompositorSupport.h"
#include "public/platform/WebGraphicsContext3DProvider.h"
#include "public/platform/WebMediaPlayer.h"
#include "public/platform/WebRect.h"
#include "public/platform/WebString.h"
#include "public/platform/WebURL.h"
#include "public/web/WebDocument.h"
#include "public/web/WebFrameClient.h"
#include "web/WebLocalFrameImpl.h"
#include "web/WebViewImpl.h"

#if OS(ANDROID)
#include "GrContext.h"
#include "GrTypes.h"
#include "SkCanvas.h"
#include "SkGrPixelRef.h"
#endif


#include "wtf/Assertions.h"
#include "wtf/text/CString.h"

namespace blink {

static PassOwnPtr<WebMediaPlayer> createWebMediaPlayer(WebMediaPlayerClient* client, const WebURL& url, LocalFrame* frame)
{
    WebLocalFrameImpl* webFrame = WebLocalFrameImpl::fromFrame(frame);

    if (!webFrame || !webFrame->client())
        return nullptr;
    return adoptPtr(webFrame->client()->createMediaPlayer(webFrame, url, client));
}

WebMediaPlayer* WebMediaPlayerClientImpl::webMediaPlayer() const
{
    return m_webMediaPlayer.get();
}

// WebMediaPlayerClient --------------------------------------------------------

WebMediaPlayerClientImpl::~WebMediaPlayerClientImpl()
{
    // Explicitly destroy the WebMediaPlayer to allow verification of tear down.
    m_webMediaPlayer.clear();
}

void WebMediaPlayerClientImpl::networkStateChanged()
{
    m_client->mediaPlayerNetworkStateChanged();
}

void WebMediaPlayerClientImpl::readyStateChanged()
{
    m_client->mediaPlayerReadyStateChanged();
}

void WebMediaPlayerClientImpl::timeChanged()
{
    m_client->mediaPlayerTimeChanged();
}

void WebMediaPlayerClientImpl::repaint()
{
    m_client->mediaPlayerRepaint();
}

void WebMediaPlayerClientImpl::durationChanged()
{
    m_client->mediaPlayerDurationChanged();
}

void WebMediaPlayerClientImpl::sizeChanged()
{
    m_client->mediaPlayerSizeChanged();
}

void WebMediaPlayerClientImpl::playbackStateChanged()
{
    m_client->mediaPlayerPlaybackStateChanged();
}

void WebMediaPlayerClientImpl::keyAdded(const WebString& keySystem, const WebString& sessionId)
{
}

void WebMediaPlayerClientImpl::keyError(const WebString& keySystem, const WebString& sessionId, MediaKeyErrorCode errorCode, unsigned short systemCode)
{
}

void WebMediaPlayerClientImpl::keyMessage(const WebString& keySystem, const WebString& sessionId, const unsigned char* message, unsigned messageLength, const WebURL& defaultURL)
{
}

void WebMediaPlayerClientImpl::keyNeeded(const WebString& contentType, const unsigned char* initData, unsigned initDataLength)
{
}

void WebMediaPlayerClientImpl::setWebLayer(WebLayer* layer)
{
    m_client->mediaPlayerSetWebLayer(layer);
}

void WebMediaPlayerClientImpl::mediaSourceOpened(WebMediaSource* webMediaSource)
{
    ASSERT(webMediaSource);
    m_client->mediaPlayerMediaSourceOpened(webMediaSource);
}

void WebMediaPlayerClientImpl::requestFullscreen()
{
    m_client->mediaPlayerRequestFullscreen();
}

void WebMediaPlayerClientImpl::requestSeek(double time)
{
    m_client->mediaPlayerRequestSeek(time);
}

// MediaPlayer -------------------------------------------------
void WebMediaPlayerClientImpl::load(WebMediaPlayer::LoadType loadType, const WTF::String& url, WebMediaPlayer::CORSMode corsMode)
{
    ASSERT(!m_webMediaPlayer);

    // FIXME: Remove this cast
    LocalFrame* frame = mediaElement().document().frame();

    WebURL poster = m_client->mediaPlayerPosterURL();

    KURL kurl(ParsedURLString, url);
    m_webMediaPlayer = createWebMediaPlayer(this, kurl, frame);
    if (!m_webMediaPlayer)
        return;

    m_webMediaPlayer->setVolume(mediaElement().effectiveMediaVolume());

    m_webMediaPlayer->setPoster(poster);

    // Tell WebMediaPlayer about any connected CDM (may be null).
    m_webMediaPlayer->load(loadType, kurl, corsMode);
}

void WebMediaPlayerClientImpl::setPreload(MediaPlayer::Preload preload)
{
    if (m_webMediaPlayer)
        m_webMediaPlayer->setPreload(static_cast<WebMediaPlayer::Preload>(preload));
}

PassOwnPtr<MediaPlayer> WebMediaPlayerClientImpl::create(MediaPlayerClient* client)
{
    return adoptPtr(new WebMediaPlayerClientImpl(client));
}

WebMediaPlayerClientImpl::WebMediaPlayerClientImpl(MediaPlayerClient* client)
    : m_client(client)
{
    ASSERT(m_client);
}

HTMLMediaElement& WebMediaPlayerClientImpl::mediaElement() const
{
    return *static_cast<HTMLMediaElement*>(m_client);
}

} // namespace blink
