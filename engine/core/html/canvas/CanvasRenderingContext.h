/*
 * Copyright (C) 2009 Apple Inc. All rights reserved.
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

#ifndef CanvasRenderingContext_h
#define CanvasRenderingContext_h

#include "core/html/HTMLCanvasElement.h"
#include "platform/heap/Handle.h"
#include "wtf/HashSet.h"
#include "wtf/Noncopyable.h"
#include "wtf/text/StringHash.h"

namespace blink { class WebLayer; }

namespace blink {

class CanvasImageSource;
class HTMLCanvasElement;
class KURL;
class WebGLObject;

class CanvasRenderingContext {
    WTF_MAKE_NONCOPYABLE(CanvasRenderingContext);
    WTF_MAKE_FAST_ALLOCATED;
public:
    virtual ~CanvasRenderingContext() { }

#if !ENABLE(OILPAN)
    void ref() { m_canvas->ref(); }
    void deref() { m_canvas->deref(); }
#endif

    HTMLCanvasElement* canvas() const { return m_canvas; }

    virtual bool is2d() const { return false; }
    virtual bool is3d() const { return false; }
    virtual bool isAccelerated() const { return false; }
    virtual bool hasAlpha() const { return true; }
    virtual void setIsHidden(bool) = 0;

    virtual void paintRenderingResultsToCanvas() {}

    virtual blink::WebLayer* platformLayer() const { return 0; }

protected:
    CanvasRenderingContext(HTMLCanvasElement*);

private:
    RawPtr<HTMLCanvasElement> m_canvas;
    HashSet<String> m_cleanURLs;
    HashSet<String> m_dirtyURLs;
};

} // namespace blink

#endif
