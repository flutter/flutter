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

#ifndef SKY_ENGINE_PLATFORM_WEBORIGIN_SECURITYPOLICY_H_
#define SKY_ENGINE_PLATFORM_WEBORIGIN_SECURITYPOLICY_H_

#include "sky/engine/platform/PlatformExport.h"
#include "sky/engine/platform/weborigin/ReferrerPolicy.h"
#include "sky/engine/wtf/text/WTFString.h"

namespace blink {

class KURL;

class PLATFORM_EXPORT SecurityPolicy {
public:
    // True if the referrer should be omitted according to the
    // ReferrerPolicyDefault. If you intend to send a referrer header, you
    // should use generateReferrerHeader instead.
    static bool shouldHideReferrer(const KURL&, const String& referrer);

    // Returns the referrer modified according to the referrer policy for a
    // navigation to a given URL. If the referrer returned is empty, the
    // referrer header should be omitted.
    static String generateReferrerHeader(ReferrerPolicy, const KURL&, const String& referrer);
};

} // namespace blink

#endif  // SKY_ENGINE_PLATFORM_WEBORIGIN_SECURITYPOLICY_H_
