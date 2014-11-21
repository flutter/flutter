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

#ifndef SKY_ENGINE_PUBLIC_WEB_WEBSECURITYPOLICY_H_
#define SKY_ENGINE_PUBLIC_WEB_WEBSECURITYPOLICY_H_

#include "../platform/WebCommon.h"
#include "../platform/WebReferrerPolicy.h"

namespace blink {

class WebString;
class WebURL;

class WebSecurityPolicy {
public:
    // Registers a URL scheme to be treated as a local scheme (i.e., with the
    // same security rules as those applied to "file" URLs). This means that
    // normal pages cannot link to or access URLs of this scheme.
    BLINK_EXPORT static void registerURLSchemeAsLocal(const WebString&);

    // Registers a URL scheme to be treated as a noAccess scheme. This means
    // that pages loaded with this URL scheme cannot access pages loaded with
    // any other URL scheme.
    BLINK_EXPORT static void registerURLSchemeAsNoAccess(const WebString&);

    // Registers a URL scheme to be treated as display-isolated. This means
    // that pages cannot display these URLs unless they are from the same
    // scheme. For example, pages in other origin cannot create iframes or
    // hyperlinks to URLs with the scheme.
    BLINK_EXPORT static void registerURLSchemeAsDisplayIsolated(const WebString&);

    // Registers a URL scheme to not generate mixed content warnings when
    // included by an HTTPS page.
    BLINK_EXPORT static void registerURLSchemeAsSecure(const WebString&);

    // Registers a non-HTTP URL scheme which can be sent CORS requests.
    BLINK_EXPORT static void registerURLSchemeAsCORSEnabled(const WebString&);

    // Registers a URL scheme as strictly empty documents, allowing them to
    // commit synchronously.
    BLINK_EXPORT static void registerURLSchemeAsEmptyDocument(const WebString&);

    // Returns the referrer modified according to the referrer policy for a
    // navigation to a given URL. If the referrer returned is empty, the
    // referrer header should be omitted.
    BLINK_EXPORT static WebString generateReferrerHeader(WebReferrerPolicy, const WebURL&, const WebString& referrer);

private:
    WebSecurityPolicy();
};

} // namespace blink

#endif  // SKY_ENGINE_PUBLIC_WEB_WEBSECURITYPOLICY_H_
