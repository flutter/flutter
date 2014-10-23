/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"

#include "platform/exported/WebScrollbarThemeGeometryNative.h"

#include "platform/scroll/Scrollbar.h"
#include "public/platform/WebScrollbar.h"

namespace blink {

PassOwnPtr<WebScrollbarThemeGeometryNative> WebScrollbarThemeGeometryNative::create(Scrollbar* scrollbar)
{
    return adoptPtr(new WebScrollbarThemeGeometryNative(scrollbar));
}

WebScrollbarThemeGeometryNative::WebScrollbarThemeGeometryNative(Scrollbar* scrollbar)
    : m_scrollbar(scrollbar)
{
}

WebScrollbarThemeGeometryNative* WebScrollbarThemeGeometryNative::clone() const
{
    return new WebScrollbarThemeGeometryNative(m_scrollbar);
}

int WebScrollbarThemeGeometryNative::thumbPosition()
{
    return m_scrollbar->thumbPosition();
}

int WebScrollbarThemeGeometryNative::thumbLength()
{
    return m_scrollbar->thumbLength();
}

int WebScrollbarThemeGeometryNative::trackPosition()
{
    return m_scrollbar->trackPosition();
}

int WebScrollbarThemeGeometryNative::trackLength()
{
    return m_scrollbar->trackLength();
}

WebRect WebScrollbarThemeGeometryNative::trackRect()
{
    return m_scrollbar->trackRect();
}

WebRect WebScrollbarThemeGeometryNative::thumbRect()
{
    return m_scrollbar->thumbRect();
}

int WebScrollbarThemeGeometryNative::minimumThumbLength()
{
    return m_scrollbar->minimumThumbLength();
}

int WebScrollbarThemeGeometryNative::scrollbarThickness()
{
    return m_scrollbar->scrollbarThickness();
}

void WebScrollbarThemeGeometryNative::splitTrack(const WebRect& webTrack, WebRect& webStartTrack, WebRect& webThumb, WebRect& webEndTrack)
{
    IntRect track(webTrack);
    IntRect startTrack;
    IntRect thumb;
    IntRect endTrack;
    m_scrollbar->splitTrack(track, startTrack, thumb, endTrack);

    webStartTrack = startTrack;
    webThumb = thumb;
    webEndTrack = endTrack;
}

} // namespace blink
