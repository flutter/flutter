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

#include "config.h"

#include "public/platform/WebMediaDeviceInfo.h"

#include "public/platform/WebString.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"

namespace blink {

class WebMediaDeviceInfoPrivate final : public RefCounted<WebMediaDeviceInfoPrivate> {
public:
    static PassRefPtr<WebMediaDeviceInfoPrivate> create(const WebString& deviceId, WebMediaDeviceInfo::MediaDeviceKind, const WebString& label, const WebString& groupId);

    const WebString& deviceId() const { return m_deviceId; }
    WebMediaDeviceInfo::MediaDeviceKind kind() const { return m_kind; }
    const WebString& label() const { return m_label; }
    const WebString& groupId() const { return m_groupId; }

private:
    WebMediaDeviceInfoPrivate(const WebString& deviceId, WebMediaDeviceInfo::MediaDeviceKind, const WebString& label, const WebString& groupId);

    WebString m_deviceId;
    WebMediaDeviceInfo::MediaDeviceKind m_kind;
    WebString m_label;
    WebString m_groupId;
};

PassRefPtr<WebMediaDeviceInfoPrivate> WebMediaDeviceInfoPrivate::create(const WebString& deviceId, WebMediaDeviceInfo::MediaDeviceKind kind, const WebString& label, const WebString& groupId)
{
    return adoptRef(new WebMediaDeviceInfoPrivate(deviceId, kind, label, groupId));
}

WebMediaDeviceInfoPrivate::WebMediaDeviceInfoPrivate(const WebString& deviceId, WebMediaDeviceInfo::MediaDeviceKind kind, const WebString& label, const WebString& groupId)
    : m_deviceId(deviceId)
    , m_kind(kind)
    , m_label(label)
    , m_groupId(groupId)
{
}

void WebMediaDeviceInfo::assign(const WebMediaDeviceInfo& other)
{
    m_private = other.m_private;
}

void WebMediaDeviceInfo::reset()
{
    m_private.reset();
}

void WebMediaDeviceInfo::initialize(const WebString& deviceId, WebMediaDeviceInfo::MediaDeviceKind kind, const WebString& label, const WebString& groupId)
{
    m_private = WebMediaDeviceInfoPrivate::create(deviceId, kind, label, groupId);
}

WebString WebMediaDeviceInfo::deviceId() const
{
    ASSERT(!m_private.isNull());
    return m_private->deviceId();
}

WebMediaDeviceInfo::MediaDeviceKind WebMediaDeviceInfo::kind() const
{
    ASSERT(!m_private.isNull());
    return m_private->kind();
}

WebString WebMediaDeviceInfo::label() const
{
    ASSERT(!m_private.isNull());
    return m_private->label();
}

WebString WebMediaDeviceInfo::groupId() const
{
    ASSERT(!m_private.isNull());
    return m_private->groupId();
}

} // namespace blink

