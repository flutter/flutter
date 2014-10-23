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

#ifndef WrappedResourceResponse_h
#define WrappedResourceResponse_h

#include "platform/exported/WebURLResponsePrivate.h"
#include "public/platform/WebURLResponse.h"

namespace blink {

class WrappedResourceResponse : public WebURLResponse {
public:
    ~WrappedResourceResponse()
    {
        reset(); // Need to drop reference to m_handle
    }

    WrappedResourceResponse() { }

    WrappedResourceResponse(ResourceResponse& resourceResponse)
    {
        bind(resourceResponse);
    }

    WrappedResourceResponse(const ResourceResponse& resourceResponse)
    {
        bind(resourceResponse);
    }

    void bind(ResourceResponse& resourceResponse)
    {
        m_handle.m_resourceResponse = &resourceResponse;
        assign(&m_handle);
    }

    void bind(const ResourceResponse& resourceResponse)
    {
        bind(*const_cast<ResourceResponse*>(&resourceResponse));
    }

private:
    class Handle : public WebURLResponsePrivate {
    public:
        virtual void dispose() { m_resourceResponse = 0; }
    };

    Handle m_handle;
};

} // namespace blink

#endif
