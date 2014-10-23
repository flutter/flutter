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
#include "core/dom/MessagePort.h"

#include "bindings/core/v8/ExceptionState.h"
#include "bindings/core/v8/ExceptionStatePlaceholder.h"
#include "bindings/core/v8/SerializedScriptValue.h"
#include "core/dom/ExceptionCode.h"
#include "core/dom/ExecutionContext.h"
#include "core/events/MessageEvent.h"
#include "core/frame/LocalDOMWindow.h"
#include "public/platform/WebString.h"
#include "wtf/Functional.h"
#include "wtf/text/AtomicString.h"

namespace blink {

PassRefPtrWillBeRawPtr<MessagePort> MessagePort::create(ExecutionContext& executionContext)
{
    RefPtrWillBeRawPtr<MessagePort> port = adoptRefWillBeNoop(new MessagePort(executionContext));
    port->suspendIfNeeded();
    return port.release();
}

MessagePort::MessagePort(ExecutionContext& executionContext)
    : ActiveDOMObject(&executionContext)
    , m_started(false)
    , m_closed(false)
    , m_weakFactory(this)
{
    ScriptWrappable::init(this);
}

MessagePort::~MessagePort()
{
    close();
}

void MessagePort::postMessage(ExecutionContext*, PassRefPtr<SerializedScriptValue> message, const MessagePortArray* ports, ExceptionState& exceptionState)
{
    if (!isEntangled())
        return;
    ASSERT(executionContext());
    ASSERT(m_entangledChannel);

    OwnPtr<MessagePortChannelArray> channels;
    // Make sure we aren't connected to any of the passed-in ports.
    if (ports) {
        for (unsigned i = 0; i < ports->size(); ++i) {
            MessagePort* dataPort = (*ports)[i].get();
            if (dataPort == this) {
                exceptionState.throwDOMException(DataCloneError, "Port at index " + String::number(i) + " contains the source port.");
                return;
            }
        }
        channels = MessagePort::disentanglePorts(ports, exceptionState);
        if (exceptionState.hadException())
            return;
    }

    WebString messageString = message->toWireString();
    OwnPtr<WebMessagePortChannelArray> webChannels = toWebMessagePortChannelArray(channels.release());
    m_entangledChannel->postMessage(messageString, webChannels.leakPtr());
}

// static
PassOwnPtr<WebMessagePortChannelArray> MessagePort::toWebMessagePortChannelArray(PassOwnPtr<MessagePortChannelArray> channels)
{
    OwnPtr<WebMessagePortChannelArray> webChannels;
    if (channels && channels->size()) {
        webChannels = adoptPtr(new WebMessagePortChannelArray(channels->size()));
        for (size_t i = 0; i < channels->size(); ++i)
            (*webChannels)[i] = (*channels)[i].leakPtr();
    }
    return webChannels.release();
}

// static
PassOwnPtrWillBeRawPtr<MessagePortArray> MessagePort::toMessagePortArray(ExecutionContext* context, const WebMessagePortChannelArray& webChannels)
{
    OwnPtrWillBeRawPtr<MessagePortArray> ports = nullptr;
    if (!webChannels.isEmpty()) {
        OwnPtr<MessagePortChannelArray> channels = adoptPtr(new MessagePortChannelArray(webChannels.size()));
        for (size_t i = 0; i < webChannels.size(); ++i)
            (*channels)[i] = adoptPtr(webChannels[i]);
        ports = MessagePort::entanglePorts(*context, channels.release());
    }
    return ports.release();
}

PassOwnPtr<WebMessagePortChannel> MessagePort::disentangle()
{
    ASSERT(m_entangledChannel);
    m_entangledChannel->setClient(0);
    return m_entangledChannel.release();
}

// Invoked to notify us that there are messages available for this port.
// This code may be called from another thread, and so should not call any non-threadsafe APIs (i.e. should not call into the entangled channel or access mutable variables).
void MessagePort::messageAvailable()
{
    callOnMainThread(bind(&MessagePort::dispatchMessages, m_weakFactory.createWeakPtr()));
}

void MessagePort::start()
{
    // Do nothing if we've been cloned or closed.
    if (!isEntangled())
        return;

    ASSERT(executionContext());
    if (m_started)
        return;

    m_started = true;
    messageAvailable();
}

void MessagePort::close()
{
    if (isEntangled())
        m_entangledChannel->setClient(0);
    m_closed = true;
}

void MessagePort::entangle(PassOwnPtr<WebMessagePortChannel> remote)
{
    // Only invoked to set our initial entanglement.
    ASSERT(!m_entangledChannel);
    ASSERT(executionContext());

    m_entangledChannel = remote;
    m_entangledChannel->setClient(this);
}

const AtomicString& MessagePort::interfaceName() const
{
    return EventTargetNames::MessagePort;
}

static bool tryGetMessageFrom(WebMessagePortChannel& webChannel, RefPtr<SerializedScriptValue>& message, OwnPtr<MessagePortChannelArray>& channels)
{
    WebString messageString;
    WebMessagePortChannelArray webChannels;
    if (!webChannel.tryGetMessage(&messageString, webChannels))
        return false;

    if (webChannels.size()) {
        channels = adoptPtr(new MessagePortChannelArray(webChannels.size()));
        for (size_t i = 0; i < webChannels.size(); ++i)
            (*channels)[i] = adoptPtr(webChannels[i]);
    }
    message = SerializedScriptValue::createFromWire(messageString);
    return true;
}

void MessagePort::dispatchMessages()
{
    // Messages for contexts that are not fully active get dispatched too, but JSAbstractEventListener::handleEvent() doesn't call handlers for these.
    // The HTML5 spec specifies that any messages sent to a document that is not fully active should be dropped, so this behavior is OK.
    if (!started())
        return;

    RefPtr<SerializedScriptValue> message;
    OwnPtr<MessagePortChannelArray> channels;
    while (m_entangledChannel && tryGetMessageFrom(*m_entangledChannel, message, channels)) {
        OwnPtrWillBeRawPtr<MessagePortArray> ports = MessagePort::entanglePorts(*executionContext(), channels.release());
        RefPtrWillBeRawPtr<Event> evt = MessageEvent::create(ports.release(), message.release());

        dispatchEvent(evt.release(), ASSERT_NO_EXCEPTION);
    }
}

bool MessagePort::hasPendingActivity() const
{
    // The spec says that entangled message ports should always be treated as if they have a strong reference.
    // We'll also stipulate that the queue needs to be open (if the app drops its reference to the port before start()-ing it, then it's not really entangled as it's unreachable).
    return m_started && isEntangled();
}

PassOwnPtr<MessagePortChannelArray> MessagePort::disentanglePorts(const MessagePortArray* ports, ExceptionState& exceptionState)
{
    if (!ports || !ports->size())
        return nullptr;

    // HashSet used to efficiently check for duplicates in the passed-in array.
    HashSet<MessagePort*> portSet;

    // Walk the incoming array - if there are any duplicate ports, or null ports or cloned ports, throw an error (per section 8.3.3 of the HTML5 spec).
    for (unsigned i = 0; i < ports->size(); ++i) {
        MessagePort* port = (*ports)[i].get();
        if (!port || port->isNeutered() || portSet.contains(port)) {
            String type;
            if (!port)
                type = "null";
            else if (port->isNeutered())
                type = "already neutered";
            else
                type = "a duplicate";
            exceptionState.throwDOMException(DataCloneError, "Port at index "  + String::number(i) + " is " + type + ".");
            return nullptr;
        }
        portSet.add(port);
    }

    // Passed-in ports passed validity checks, so we can disentangle them.
    OwnPtr<MessagePortChannelArray> portArray = adoptPtr(new MessagePortChannelArray(ports->size()));
    for (unsigned i = 0; i < ports->size(); ++i)
        (*portArray)[i] = (*ports)[i]->disentangle();
    return portArray.release();
}

PassOwnPtrWillBeRawPtr<MessagePortArray> MessagePort::entanglePorts(ExecutionContext& context, PassOwnPtr<MessagePortChannelArray> channels)
{
    if (!channels || !channels->size())
        return nullptr;

    OwnPtrWillBeRawPtr<MessagePortArray> portArray = adoptPtrWillBeNoop(new MessagePortArray(channels->size()));
    for (unsigned i = 0; i < channels->size(); ++i) {
        RefPtrWillBeRawPtr<MessagePort> port = MessagePort::create(context);
        port->entangle((*channels)[i].release());
        (*portArray)[i] = port.release();
    }
    return portArray.release();
}

} // namespace blink
