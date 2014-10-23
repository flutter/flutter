/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef WebMessagePortChannel_h
#define WebMessagePortChannel_h

#include "WebCommon.h"
#include "WebVector.h"

namespace blink {

class WebMessagePortChannelClient;
class WebString;

typedef WebVector<class WebMessagePortChannel*> WebMessagePortChannelArray;

// Provides an interface to a Message Port Channel implementation. The object owns itself and
// is signalled that its not needed anymore with the destroy() call.
class WebMessagePortChannel {
public:
    virtual void setClient(WebMessagePortChannelClient*) = 0;
    virtual void destroy() = 0;
    // Callee receives ownership of the passed vector.
    // FIXME: Blob refs should be passed to maintain ref counts. crbug.com/351753
    virtual void postMessage(const WebString&, WebMessagePortChannelArray*) = 0;
    virtual bool tryGetMessage(WebString*, WebMessagePortChannelArray&) = 0;

protected:
    ~WebMessagePortChannel() { }
};

} // namespace blink

#if INSIDE_BLINK

namespace WTF {

template<typename T> struct OwnedPtrDeleter;
template<> struct OwnedPtrDeleter<blink::WebMessagePortChannel> {
    static void deletePtr(blink::WebMessagePortChannel* channel)
    {
        if (channel)
            channel->destroy();
    }
};

} // namespace WTF

#endif // INSIDE_BLINK

#endif // WebMessagePortChannel_h
