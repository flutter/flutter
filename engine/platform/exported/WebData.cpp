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

#include "config.h"
#include "public/platform/WebData.h"

#include "platform/SharedBuffer.h"

namespace blink {

void WebData::reset()
{
    m_private.reset();
}

void WebData::assign(const WebData& other)
{
    m_private = other.m_private;
}

void WebData::assign(const char* data, size_t size)
{
    m_private = SharedBuffer::create(data, size);
}

size_t WebData::size() const
{
    if (m_private.isNull())
        return 0;
    return m_private->size();
}

const char* WebData::data() const
{
    if (m_private.isNull())
        return 0;
    return m_private->data();
}

WebData::WebData(const PassRefPtr<SharedBuffer>& buffer)
    : m_private(buffer)
{
}

WebData& WebData::operator=(const PassRefPtr<SharedBuffer>& buffer)
{
    m_private = buffer;
    return *this;
}

WebData::operator PassRefPtr<SharedBuffer>() const
{
    return PassRefPtr<SharedBuffer>(m_private.get());
}

} // namespace blink
