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
    virtual bool isOverlay() const override;
    virtual int value() const override;
    virtual WebPoint location() const override;
    virtual WebSize size() const override;
    virtual bool enabled() const override;
    virtual int maximum() const override;
    virtual int totalSize() const override;
    virtual bool isScrollableAreaActive() const override;
    virtual ScrollbarPart pressedPart() const override;
    virtual ScrollbarPart hoveredPart() const override;
    virtual ScrollbarOverlayStyle scrollbarOverlayStyle() const override;
    virtual Orientation orientation() const override;
    virtual bool isLeftSideVerticalScrollbar() const override;

private:
    RefPtr<Scrollbar> m_scrollbar;
};

} // namespace blink

#endif
