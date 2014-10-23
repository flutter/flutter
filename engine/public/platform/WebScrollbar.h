/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef WebScrollbar_h
#define WebScrollbar_h

#include "WebPoint.h"
#include "WebRect.h"
#include "WebSize.h"
#include "WebVector.h"
#if INSIDE_BLINK
#include "wtf/PassOwnPtr.h"
#endif

namespace blink {

// A const accessor interface for a WebKit scrollbar
class BLINK_PLATFORM_EXPORT WebScrollbar {
public:
    enum Orientation {
        Horizontal,
        Vertical
    };

    enum ScrollDirection {
        ScrollBackward,
        ScrollForward
    };

    enum ScrollGranularity {
        ScrollByLine,
        ScrollByPage,
        ScrollByDocument,
        ScrollByPixel
    };

    enum ScrollbarPart {
        NoPart,
        BackTrackPart,
        ThumbPart,
        ForwardTrackPart,
    };

    enum ScrollbarOverlayStyle {
        ScrollbarOverlayStyleDefault,
        ScrollbarOverlayStyleLight
    };

    virtual ~WebScrollbar() { }

    // Return true if this is an overlay scrollbar.
    virtual bool isOverlay() const = 0;

    // Gets the current value (i.e. position inside the region).
    virtual int value() const = 0;

    virtual WebPoint location() const = 0;
    virtual WebSize size() const = 0;
    virtual bool enabled() const = 0;
    virtual int maximum() const = 0;
    virtual int totalSize() const = 0;
    virtual bool isScrollViewScrollbar() const = 0;
    virtual bool isScrollableAreaActive() const = 0;
    virtual void getTickmarks(WebVector<WebRect>& tickmarks) const = 0;
    virtual ScrollbarPart pressedPart() const = 0;
    virtual ScrollbarPart hoveredPart() const = 0;
    virtual ScrollbarOverlayStyle scrollbarOverlayStyle() const = 0;
    virtual bool isCustomScrollbar() const = 0;
    virtual Orientation orientation() const = 0;
    virtual bool isLeftSideVerticalScrollbar() const = 0;
    virtual bool isAlphaLocked() const { return false; }
    virtual void setIsAlphaLocked(bool) { }
};

} // namespace blink

#endif
