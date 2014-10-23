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

#ifndef WebScrollbarThemePainter_h
#define WebScrollbarThemePainter_h

#include "WebCanvas.h"

namespace blink {

class Scrollbar;
class WebScrollbar;
struct WebRect;

class WebScrollbarThemePainter {
public:
    WebScrollbarThemePainter() : m_scrollbar(0) { }
    WebScrollbarThemePainter(const WebScrollbarThemePainter& painter) { assign(painter); }
    virtual ~WebScrollbarThemePainter() { }
    WebScrollbarThemePainter& operator=(const WebScrollbarThemePainter& painter)
    {
        assign(painter);
        return *this;
    }

    BLINK_EXPORT void assign(const WebScrollbarThemePainter&);

    BLINK_EXPORT void paintThumb(WebCanvas*, const WebRect&);

#if BLINK_IMPLEMENTATION
    WebScrollbarThemePainter(Scrollbar*);
#endif

private:
    // It is assumed that the constructor of this paint object is responsible
    // for the lifetime of this scrollbar. The painter has to use the real
    // scrollbar (and not a WebScrollbar wrapper) due to static_casts for
    // RenderScrollbar and pointer-based HashMap lookups for Lion scrollbars.
    Scrollbar* m_scrollbar;
};

} // namespace blink

#endif
