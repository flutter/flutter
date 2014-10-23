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

#ifndef WebMediaDeviceInfo_h
#define WebMediaDeviceInfo_h

#include "WebCommon.h"
#include "WebNonCopyable.h"
#include "WebPrivatePtr.h"
#include "WebString.h"

namespace blink {

class WebMediaDeviceInfoPrivate;

class WebMediaDeviceInfo {
public:
    enum MediaDeviceKind {
        MediaDeviceKindAudioInput,
        MediaDeviceKindAudioOutput,
        MediaDeviceKindVideoInput
    };

    WebMediaDeviceInfo() { }
    WebMediaDeviceInfo(const WebMediaDeviceInfo& other) { assign(other); }
    ~WebMediaDeviceInfo() { reset(); }

    WebMediaDeviceInfo& operator=(const WebMediaDeviceInfo& other)
    {
        assign(other);
        return *this;
    }

    BLINK_PLATFORM_EXPORT void assign(const WebMediaDeviceInfo&);

    BLINK_PLATFORM_EXPORT void initialize(const WebString& deviceId, MediaDeviceKind, const WebString& label, const WebString& groupId);
    BLINK_PLATFORM_EXPORT void reset();
    bool isNull() const { return m_private.isNull(); }

    BLINK_PLATFORM_EXPORT WebString deviceId() const;
    BLINK_PLATFORM_EXPORT MediaDeviceKind kind() const;
    BLINK_PLATFORM_EXPORT WebString label() const;
    BLINK_PLATFORM_EXPORT WebString groupId() const;

private:
    WebPrivatePtr<WebMediaDeviceInfoPrivate> m_private;
};

} // namespace blink

#endif // WebMediaDeviceInfo_h
