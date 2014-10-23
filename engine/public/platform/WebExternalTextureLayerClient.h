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

#ifndef WebExternalTextureLayerClient_h
#define WebExternalTextureLayerClient_h

#include "WebCommon.h"
#include "WebSize.h"

namespace blink {

class WebGraphicsContext3D;
class WebExternalBitmap;
struct WebExternalTextureMailbox;

class BLINK_PLATFORM_EXPORT WebExternalTextureLayerClient {
public:
    // Returns true and provides a mailbox if a new frame is available. If the WebExternalBitmap
    // isn't 0, then it should also be filled in with the contents of this frame.
    // Returns false if no new data is available and the old mailbox and bitmap are to be reused.
    virtual bool prepareMailbox(WebExternalTextureMailbox*, WebExternalBitmap* = 0) = 0;

    // Notifies the client when a mailbox is no longer in use by the compositor and provides
    // a sync point to wait on before the mailbox could be consumes again by the client. The
    // boolean flag indicates if the mailbox resource is treated as lost by client.
    virtual void mailboxReleased(const WebExternalTextureMailbox&, bool lostResource) = 0;

protected:
    virtual ~WebExternalTextureLayerClient() { }
};

} // namespace blink

#endif // WebExternalTextureLayerClient_h
