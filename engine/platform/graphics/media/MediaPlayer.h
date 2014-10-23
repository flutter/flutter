/*
 * Copyright (C) 2007, 2008, 2009, 2010, 2011, 2012, 2013 Apple Inc. All rights reserved.
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

#ifndef MediaPlayer_h
#define MediaPlayer_h

#include "public/platform/WebMediaPlayer.h"
#include "wtf/Forward.h"
#include "wtf/Noncopyable.h"

namespace blink {

class KURL;
class MediaPlayer;
class WebLayer;
class WebMediaSource;

class MediaPlayerClient {
public:
    virtual ~MediaPlayerClient() { }

    // the network state has changed
    virtual void mediaPlayerNetworkStateChanged() = 0;

    // the ready state has changed
    virtual void mediaPlayerReadyStateChanged() = 0;

    // time has jumped, eg. not as a result of normal playback
    virtual void mediaPlayerTimeChanged() = 0;

    // the media file duration has changed, or is now known
    virtual void mediaPlayerDurationChanged() = 0;

    // the play/pause status changed
    virtual void mediaPlayerPlaybackStateChanged() = 0;

    virtual void mediaPlayerRequestFullscreen() = 0;

    virtual void mediaPlayerRequestSeek(double) = 0;

    // The URL for video poster image.
    // FIXME: Remove this when WebMediaPlayerClientImpl::loadInternal does not depend on it.
    virtual KURL mediaPlayerPosterURL() = 0;

// Presentation-related methods
    // a new frame of video is available
    virtual void mediaPlayerRepaint() = 0;

    // the movie size has changed
    virtual void mediaPlayerSizeChanged() = 0;

    virtual void mediaPlayerSetWebLayer(WebLayer*) = 0;

    virtual void mediaPlayerMediaSourceOpened(WebMediaSource*) = 0;
};

typedef PassOwnPtr<MediaPlayer> (*CreateMediaEnginePlayer)(MediaPlayerClient*);

class PLATFORM_EXPORT MediaPlayer {
    WTF_MAKE_NONCOPYABLE(MediaPlayer);
public:
    static PassOwnPtr<MediaPlayer> create(MediaPlayerClient*);
    static void setMediaEngineCreateFunction(CreateMediaEnginePlayer);

    static double invalidTime() { return -1.0; }

    MediaPlayer() { }
    virtual ~MediaPlayer() { }

    virtual void load(WebMediaPlayer::LoadType, const String& url, WebMediaPlayer::CORSMode) = 0;

    enum Preload { None, MetaData, Auto };
    virtual void setPreload(Preload) = 0;

    virtual WebMediaPlayer* webMediaPlayer() const = 0;
};

} // namespace blink

#endif // MediaPlayer_h
