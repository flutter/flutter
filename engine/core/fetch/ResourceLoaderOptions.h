/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_FETCH_RESOURCELOADEROPTIONS_H_
#define SKY_ENGINE_CORE_FETCH_RESOURCELOADEROPTIONS_H_

#include "sky/engine/core/fetch/FetchInitiatorInfo.h"

namespace blink {

enum DataBufferingPolicy {
    BufferData,
    DoNotBufferData
};

enum RequestInitiatorContext {
    DocumentContext,
};

enum StoredCredentials {
    AllowStoredCredentials,
    DoNotAllowStoredCredentials
};

// APIs like XMLHttpRequest and EventSource let the user decide
// whether to send credentials, but they're always sent for
// same-origin requests. Additional information is needed to handle
// cross-origin redirects correctly.
enum CredentialRequest {
    ClientRequestedCredentials,
    ClientDidNotRequestCredentials
};

// FIXME(sky): remove
enum SynchronousPolicy {
    RequestAsynchronously
};

// A resource fetch can be marked as being CORS enabled. The loader
// must perform an access check upon seeing the response.
enum CORSEnabled {
    NotCORSEnabled,
    IsCORSEnabled
};

struct ResourceLoaderOptions {
    ResourceLoaderOptions()
        : dataBufferingPolicy(BufferData)
        , allowCredentials(DoNotAllowStoredCredentials)
        , credentialsRequested(ClientDidNotRequestCredentials)
        , requestInitiatorContext(DocumentContext)
        , synchronousPolicy(RequestAsynchronously)
        , corsEnabled(NotCORSEnabled)
    {
    }

    ResourceLoaderOptions(
        DataBufferingPolicy dataBufferingPolicy,
        StoredCredentials allowCredentials,
        CredentialRequest credentialsRequested,
        RequestInitiatorContext requestInitiatorContext)
        : dataBufferingPolicy(dataBufferingPolicy)
        , allowCredentials(allowCredentials)
        , credentialsRequested(credentialsRequested)
        , requestInitiatorContext(requestInitiatorContext)
        , synchronousPolicy(RequestAsynchronously)
        , corsEnabled(NotCORSEnabled)
    {
    }

    // Answers the question "can a separate request with these
    // different options be re-used" (e.g. preload request)
    // The safe (but possibly slow) answer is always false.
    bool canReuseRequest(const ResourceLoaderOptions& other) const
    {
        // dataBufferingPolicy differences are believed to be safe for re-use.
        // FIXME: check allowCredentials.
        // FIXME: check credentialsRequested.
        // FIXME: check contentSecurityPolicyOption.
        // initiatorInfo is purely informational and should be benign for re-use.
        // requestInitiatorContext is benign (indicates document vs. worker)
        // synchronousPolicy (safe to re-use an async XHR response for sync, etc.)
        return corsEnabled == other.corsEnabled;
    }

    DataBufferingPolicy dataBufferingPolicy;
    StoredCredentials allowCredentials; // Whether HTTP credentials and cookies are sent with the request.
    CredentialRequest credentialsRequested; // Whether the client (e.g. XHR) wanted credentials in the first place.
    FetchInitiatorInfo initiatorInfo;
    RequestInitiatorContext requestInitiatorContext;
    SynchronousPolicy synchronousPolicy;
    CORSEnabled corsEnabled; // If the resource is loaded out-of-origin, whether or not to use CORS.
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_FETCH_RESOURCELOADEROPTIONS_H_
