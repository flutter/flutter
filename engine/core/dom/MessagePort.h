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

#ifndef MessagePort_h
#define MessagePort_h

#include "core/dom/ActiveDOMObject.h"
#include "core/events/EventListener.h"
#include "core/events/EventTarget.h"
#include "public/platform/WebMessagePortChannel.h"
#include "public/platform/WebMessagePortChannelClient.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"
#include "wtf/RefPtr.h"
#include "wtf/Vector.h"
#include "wtf/WeakPtr.h"

namespace blink {

class ExceptionState;
class MessagePort;
class ExecutionContext;
class SerializedScriptValue;

// The overwhelmingly common case is sending a single port, so handle that efficiently with an inline buffer of size 1.
typedef WillBeHeapVector<RefPtrWillBeMember<MessagePort>, 1> MessagePortArray;

// Not to be confused with WebMessagePortChannelArray; this one uses Vector and OwnPtr instead of WebVector and raw pointers.
typedef Vector<OwnPtr<WebMessagePortChannel>, 1> MessagePortChannelArray;

class MessagePort FINAL : public RefCountedWillBeGarbageCollectedFinalized<MessagePort>
    , public ActiveDOMObject
    , public EventTargetWithInlineData
    , public WebMessagePortChannelClient {
    DEFINE_WRAPPERTYPEINFO();
    REFCOUNTED_EVENT_TARGET(MessagePort);
    WILL_BE_USING_GARBAGE_COLLECTED_MIXIN(MessagePort);
public:
    static PassRefPtrWillBeRawPtr<MessagePort> create(ExecutionContext&);
    virtual ~MessagePort();

    void postMessage(ExecutionContext*, PassRefPtr<SerializedScriptValue> message, const MessagePortArray*, ExceptionState&);

    void start();
    void close();

    void entangle(PassOwnPtr<WebMessagePortChannel>);
    PassOwnPtr<WebMessagePortChannel> disentangle();

    static PassOwnPtr<WebMessagePortChannelArray> toWebMessagePortChannelArray(PassOwnPtr<MessagePortChannelArray>);
    static PassOwnPtrWillBeRawPtr<MessagePortArray> toMessagePortArray(ExecutionContext*, const WebMessagePortChannelArray&);

    // Returns 0 if there is an exception, or if the passed-in array is 0/empty.
    static PassOwnPtr<MessagePortChannelArray> disentanglePorts(const MessagePortArray*, ExceptionState&);

    // Returns 0 if the passed array is 0/empty.
    static PassOwnPtrWillBeRawPtr<MessagePortArray> entanglePorts(ExecutionContext&, PassOwnPtr<MessagePortChannelArray>);

    bool started() const { return m_started; }

    virtual const AtomicString& interfaceName() const OVERRIDE;
    virtual ExecutionContext* executionContext() const OVERRIDE { return ActiveDOMObject::executionContext(); }
    virtual MessagePort* toMessagePort() OVERRIDE { return this; }

    // ActiveDOMObject implementation.
    virtual bool hasPendingActivity() const OVERRIDE;
    virtual void stop() OVERRIDE { close(); }

    void setOnmessage(PassRefPtr<EventListener> listener)
    {
        setAttributeEventListener(EventTypeNames::message, listener);
        start();
    }
    EventListener* onmessage() { return getAttributeEventListener(EventTypeNames::message); }

    // A port starts out its life entangled, and remains entangled until it is closed or is cloned.
    bool isEntangled() const { return !m_closed && !isNeutered(); }

    // A port gets neutered when it is transferred to a new owner via postMessage().
    bool isNeutered() const { return !m_entangledChannel; }

private:
    explicit MessagePort(ExecutionContext&);

    // WebMessagePortChannelClient implementation.
    virtual void messageAvailable() OVERRIDE;
    void dispatchMessages();

    OwnPtr<WebMessagePortChannel> m_entangledChannel;

    bool m_started;
    bool m_closed;

    WeakPtrFactory<MessagePort> m_weakFactory;
};

} // namespace blink

#endif // MessagePort_h
