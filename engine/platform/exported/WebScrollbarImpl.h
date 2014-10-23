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

#ifndef WebScrollbarImpl_h
#define WebScrollbarImpl_h

#include "platform/PlatformExport.h"
#include "public/platform/WebScrollbar.h"

namespace blink {

class Scrollbar;
class PLATFORM_EXPORT WebScrollbarImpl : public WebScrollbar {
public:
    explicit WebScrollbarImpl(Scrollbar*);

    // Implement WebScrollbar methods
    virtual bool isOverlay() const OVERRIDE;
    virtual int value() const OVERRIDE;
    virtual WebPoint location() const OVERRIDE;
    virtual WebSize size() const OVERRIDE;
    virtual bool enabled() const OVERRIDE;
    virtual int maximum() const OVERRIDE;
    virtual int totalSize() const OVERRIDE;
    virtual bool isScrollViewScrollbar() const OVERRIDE;
    virtual bool isScrollableAreaActive() const OVERRIDE;
    virtual void getTickmarks(WebVector<WebRect>& tickmarks) const OVERRIDE;
    virtual ScrollbarPart pressedPart() const OVERRIDE;
    virtual ScrollbarPart hoveredPart() const OVERRIDE;
    virtual ScrollbarOverlayStyle scrollbarOverlayStyle() const OVERRIDE;
    virtual bool isCustomScrollbar() const OVERRIDE;
    virtual Orientation orientation() const OVERRIDE;
    virtual bool isLeftSideVerticalScrollbar() const OVERRIDE;
    virtual bool isAlphaLocked() const OVERRIDE;
    virtual void setIsAlphaLocked(bool) OVERRIDE;

private:
    RefPtr<Scrollbar> m_scrollbar;
};

} // namespace blink

#endif
