/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * 1. Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY GOOGLE INC. AND ITS CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL GOOGLE INC.
 * OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef PageOverlayList_h
#define PageOverlayList_h

#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/Vector.h"

namespace blink {

class GraphicsContext;
class GraphicsLayer;
class PageOverlay;
class WebPageOverlay;
class WebViewImpl;

class PageOverlayList {
public:
    static PassOwnPtr<PageOverlayList> create(WebViewImpl*);

    ~PageOverlayList();

    bool empty() const { return !m_pageOverlays.size(); }

    // Adds/removes a PageOverlay for given client.
    // Returns true if a PageOverlay is added/removed.
    bool add(WebPageOverlay*, int /* zOrder */);
    bool remove(WebPageOverlay*);

    void update();
    void paintWebFrame(GraphicsContext&);

    size_t findGraphicsLayer(GraphicsLayer*);

private:
    typedef Vector<OwnPtr<PageOverlay>, 2> PageOverlays;

    explicit PageOverlayList(WebViewImpl*);

    // Returns the index of the client found. Otherwise, returns WTF::kNotFound.
    size_t find(WebPageOverlay*);

    WebViewImpl* m_viewImpl;
    PageOverlays m_pageOverlays;
};

} // namespace blink

#endif // PageOverlayList_h
