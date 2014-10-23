/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
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
 * 3.  Neither the name of Google, Inc. ("Google") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY GOOGLE AND ITS CONTRIBUTORS "AS IS" AND ANY
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

#include "config.h"
#include "platform/weborigin/SecurityPolicy.h"

#include "platform/weborigin/KURL.h"
#include "wtf/HashMap.h"
#include "wtf/MainThread.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/text/StringHash.h"

namespace blink {

bool SecurityPolicy::shouldHideReferrer(const KURL& url, const String& referrer)
{
    bool referrerIsSecureURL = protocolIs(referrer, "https");
    bool referrerIsWebURL = referrerIsSecureURL || protocolIs(referrer, "http");

    if (!referrerIsWebURL)
        return true;

    if (!referrerIsSecureURL)
        return false;

    bool URLIsSecureURL = url.protocolIs("https");

    return !URLIsSecureURL;
}

String SecurityPolicy::generateReferrerHeader(ReferrerPolicy referrerPolicy, const KURL& url, const String& referrer)
{
    if (referrer.isEmpty())
        return String();

    if (!(protocolIs(referrer, "https") || protocolIs(referrer, "http")))
        return String();

    switch (referrerPolicy) {
    case ReferrerPolicyNever:
        return String();
    case ReferrerPolicyAlways:
        return referrer;
    case ReferrerPolicyOrigin: {
        return String();
    }
    case ReferrerPolicyDefault:
        break;
    }

    return shouldHideReferrer(url, referrer) ? String() : referrer;
}

} // namespace blink
