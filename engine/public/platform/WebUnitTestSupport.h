/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#ifndef WebUnitTestSupport_h
#define WebUnitTestSupport_h

#include "WebCommon.h"
#include "WebData.h"
#include "WebString.h"

namespace blink {

class WebLayerTreeView;
class WebURL;
class WebURLResponse;
struct WebURLError;

class WebUnitTestSupport {
public:
    virtual void registerMockedURL(const WebURL&, const WebURLResponse&, const WebString& filePath) { }

    // Registers the error to be returned when |url| is requested.
    virtual void registerMockedErrorURL(const WebURL&, const WebURLResponse&, const WebURLError&) { }

    // Unregisters URLs so they are no longer mocked.
    virtual void unregisterMockedURL(const WebURL&) { }
    virtual void unregisterAllMockedURLs() { }

    // Causes all pending asynchronous requests to be served. When this method
    // returns all the pending requests have been processed.
    virtual void serveAsynchronousMockedRequests() { }

    // Returns the root directory of the WebKit code.
    virtual WebString webKitRootDir() { return WebString(); }

    // Constructs a WebLayerTreeView set up with reasonable defaults for
    // testing.
    virtual WebLayerTreeView* createLayerTreeViewForTesting() { return 0; }

    virtual WebData readFromFile(const WebString& path) { return WebData(); }
};

}

#endif // WebUnitTestSupport_h
