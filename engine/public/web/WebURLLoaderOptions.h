/*
 * Copyright (C) 2009, 2011 Google Inc. All rights reserved.
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

#ifndef WebURLLoaderOptions_h
#define WebURLLoaderOptions_h

namespace blink {

struct WebURLLoaderOptions {

    enum CrossOriginRequestPolicy {
        CrossOriginRequestPolicyDeny,
        CrossOriginRequestPolicyUseAccessControl,
        CrossOriginRequestPolicyAllow
    };

    enum PreflightPolicy {
        ConsiderPreflight,
        ForcePreflight,
        PreventPreflight
    };

    WebURLLoaderOptions()
        : allowCredentials(false)
        , exposeAllResponseHeaders(false)
        , preflightPolicy(ConsiderPreflight)
        , crossOriginRequestPolicy(CrossOriginRequestPolicyDeny)
        { }

    bool allowCredentials; // Whether to send HTTP credentials and cookies with the request.
    bool exposeAllResponseHeaders; // If policy is to use access control, whether to expose non-whitelisted response headers to the client.
    PreflightPolicy preflightPolicy;
    CrossOriginRequestPolicy crossOriginRequestPolicy;
};

} // namespace blink

#endif
