/*
 * Copyright (C) 2014 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY GOOGLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL GOOGLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef WebMediaDevicesRequest_h
#define WebMediaDevicesRequest_h

#include "public/platform/WebCommon.h"
#include "public/platform/WebPrivatePtr.h"
#include "public/platform/WebString.h"

namespace blink {

class WebDocument;
class WebMediaDeviceInfo;
template <typename T> class WebVector;

class WebMediaDevicesRequest {
public:
    WebMediaDevicesRequest() { }
    WebMediaDevicesRequest(const WebMediaDevicesRequest& request) { assign(request); }
    ~WebMediaDevicesRequest() { reset(); }

    WebMediaDevicesRequest& operator=(const WebMediaDevicesRequest& other)
    {
        assign(other);
        return *this;
    }

    BLINK_EXPORT void reset();
    bool isNull() const { return true; }
    BLINK_EXPORT bool equals(const WebMediaDevicesRequest&) const;
    BLINK_EXPORT void assign(const WebMediaDevicesRequest&);

    BLINK_EXPORT WebDocument ownerDocument() const;

    BLINK_EXPORT void requestSucceeded(WebVector<WebMediaDeviceInfo>);
};

inline bool operator==(const WebMediaDevicesRequest& a, const WebMediaDevicesRequest& b)
{
    return a.equals(b);
}

} // namespace blink

#endif // WebMediaDevicesRequest_h
