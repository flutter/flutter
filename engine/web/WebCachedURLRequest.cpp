/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
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

#include "config.h"
#include "public/web/WebCachedURLRequest.h"

#include "core/fetch/FetchRequest.h"
#include "platform/exported/WrappedResourceRequest.h"
#include "public/platform/WebURLRequest.h"

namespace blink {

void WebCachedURLRequest::reset()
{
    m_resourceRequestWrapper.reset(0);
    m_private = 0;
}

const WebURLRequest& WebCachedURLRequest::urlRequest() const
{
    if (!m_resourceRequestWrapper.get())
        m_resourceRequestWrapper.reset(new WrappedResourceRequest(m_private->resourceRequest()));
    else
        m_resourceRequestWrapper->bind(m_private->resourceRequest());
    return *m_resourceRequestWrapper.get();
}

WebString WebCachedURLRequest::charset() const
{
    return WebString(m_private->charset());
}

bool WebCachedURLRequest::forPreload() const
{
    return m_private->forPreload();
}

WebString WebCachedURLRequest::initiatorName() const
{
    return WebString(m_private->options().initiatorInfo.name);
}

WebCachedURLRequest::WebCachedURLRequest(FetchRequest* request)
    : m_private(request)
{
}

} // namespace blink
