/*
 * Copyright (C) 2008 Apple Inc. All Rights Reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#include "config.h"
#include "core/dom/MessageChannel.h"

#include "core/dom/MessagePort.h"
#include "public/platform/Platform.h"
#include "public/platform/WebMessagePortChannel.h"

namespace blink {

DEFINE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(MessageChannel);

static void createChannel(MessagePort* port1, MessagePort* port2)
{
    WebMessagePortChannel* channel1;
    WebMessagePortChannel* channel2;
    Platform::current()->createMessageChannel(&channel1, &channel2);
    ASSERT(channel1 && channel2);

    // Now entangle the proxies with the appropriate local ports.
    port1->entangle(adoptPtr(channel2));
    port2->entangle(adoptPtr(channel1));
}

MessageChannel::MessageChannel(ExecutionContext* context)
    : m_port1(MessagePort::create(*context))
    , m_port2(MessagePort::create(*context))
{
    ScriptWrappable::init(this);
    createChannel(m_port1.get(), m_port2.get());
}

void MessageChannel::trace(Visitor* visitor)
{
    visitor->trace(m_port1);
    visitor->trace(m_port2);
}

} // namespace blink
