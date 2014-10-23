/*
 * Copyright (C) 2007 Henry Mason (hmason@mac.com)
 * Copyright (C) 2003, 2005, 2006, 2007, 2008 Apple Inc. All rights reserved.
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
#include "core/events/MessageEvent.h"

#include "bindings/core/v8/ExceptionMessages.h"
#include "bindings/core/v8/ExceptionState.h"
#include "bindings/core/v8/custom/V8ArrayBufferCustom.h"

namespace blink {

static inline bool isValidSource(EventTarget* source)
{
    return !source || source->toDOMWindow() || source->toMessagePort();
}

MessageEventInit::MessageEventInit()
{
}

MessageEvent::MessageEvent()
    : m_dataType(DataTypeScriptValue)
{
    ScriptWrappable::init(this);
}

MessageEvent::MessageEvent(const AtomicString& type, const MessageEventInit& initializer)
    : Event(type, initializer)
    , m_dataType(DataTypeScriptValue)
    , m_origin(initializer.origin)
    , m_lastEventId(initializer.lastEventId)
    , m_source(isValidSource(initializer.source.get()) ? initializer.source : nullptr)
    , m_ports(adoptPtrWillBeNoop(new MessagePortArray(initializer.ports)))
{
    ScriptWrappable::init(this);
    ASSERT(isValidSource(m_source.get()));
}

MessageEvent::MessageEvent(const String& origin, const String& lastEventId, PassRefPtrWillBeRawPtr<EventTarget> source, PassOwnPtrWillBeRawPtr<MessagePortArray> ports)
    : Event(EventTypeNames::message, false, false)
    , m_dataType(DataTypeScriptValue)
    , m_origin(origin)
    , m_lastEventId(lastEventId)
    , m_source(source)
    , m_ports(ports)
{
    ScriptWrappable::init(this);
    ASSERT(isValidSource(m_source.get()));
}

MessageEvent::MessageEvent(PassRefPtr<SerializedScriptValue> data, const String& origin, const String& lastEventId, PassRefPtrWillBeRawPtr<EventTarget> source, PassOwnPtrWillBeRawPtr<MessagePortArray> ports)
    : Event(EventTypeNames::message, false, false)
    , m_dataType(DataTypeSerializedScriptValue)
    , m_dataAsSerializedScriptValue(data)
    , m_origin(origin)
    , m_lastEventId(lastEventId)
    , m_source(source)
    , m_ports(ports)
{
    ScriptWrappable::init(this);
    if (m_dataAsSerializedScriptValue)
        m_dataAsSerializedScriptValue->registerMemoryAllocatedWithCurrentScriptContext();
    ASSERT(isValidSource(m_source.get()));
}

MessageEvent::MessageEvent(PassRefPtr<SerializedScriptValue> data, const String& origin, const String& lastEventId, PassRefPtrWillBeRawPtr<EventTarget> source, PassOwnPtr<MessagePortChannelArray> channels)
    : Event(EventTypeNames::message, false, false)
    , m_dataType(DataTypeSerializedScriptValue)
    , m_dataAsSerializedScriptValue(data)
    , m_origin(origin)
    , m_lastEventId(lastEventId)
    , m_source(source)
    , m_channels(channels)
{
    ScriptWrappable::init(this);
    if (m_dataAsSerializedScriptValue)
        m_dataAsSerializedScriptValue->registerMemoryAllocatedWithCurrentScriptContext();
    ASSERT(isValidSource(m_source.get()));
}

MessageEvent::MessageEvent(const String& data, const String& origin)
    : Event(EventTypeNames::message, false, false)
    , m_dataType(DataTypeString)
    , m_dataAsString(data)
    , m_origin(origin)
{
    ScriptWrappable::init(this);
}

MessageEvent::MessageEvent(PassRefPtr<ArrayBuffer> data, const String& origin)
    : Event(EventTypeNames::message, false, false)
    , m_dataType(DataTypeArrayBuffer)
    , m_dataAsArrayBuffer(data)
    , m_origin(origin)
{
    ScriptWrappable::init(this);
}

MessageEvent::~MessageEvent()
{
}

PassRefPtrWillBeRawPtr<MessageEvent> MessageEvent::create(const AtomicString& type, const MessageEventInit& initializer, ExceptionState& exceptionState)
{
    if (initializer.source.get() && !isValidSource(initializer.source.get())) {
        exceptionState.throwTypeError("The optional 'source' property is neither a Window nor MessagePort.");
        return nullptr;
    }
    return adoptRefWillBeNoop(new MessageEvent(type, initializer));
}

void MessageEvent::initMessageEvent(const AtomicString& type, bool canBubble, bool cancelable, const String& origin, const String& lastEventId, LocalDOMWindow* source, PassOwnPtrWillBeRawPtr<MessagePortArray> ports)
{
    if (dispatched())
        return;

    initEvent(type, canBubble, cancelable);

    m_dataType = DataTypeScriptValue;
    m_origin = origin;
    m_lastEventId = lastEventId;
    m_source = source;
    m_ports = ports;
}

void MessageEvent::initMessageEvent(const AtomicString& type, bool canBubble, bool cancelable, PassRefPtr<SerializedScriptValue> data, const String& origin, const String& lastEventId, LocalDOMWindow* source, PassOwnPtrWillBeRawPtr<MessagePortArray> ports)
{
    if (dispatched())
        return;

    initEvent(type, canBubble, cancelable);

    m_dataType = DataTypeSerializedScriptValue;
    m_dataAsSerializedScriptValue = data;
    m_origin = origin;
    m_lastEventId = lastEventId;
    m_source = source;
    m_ports = ports;

    if (m_dataAsSerializedScriptValue)
        m_dataAsSerializedScriptValue->registerMemoryAllocatedWithCurrentScriptContext();
}

const AtomicString& MessageEvent::interfaceName() const
{
    return EventNames::MessageEvent;
}

void MessageEvent::entangleMessagePorts(ExecutionContext* context)
{
    m_ports = MessagePort::entanglePorts(*context, m_channels.release());
}

void MessageEvent::trace(Visitor* visitor)
{
    visitor->trace(m_source);
#if ENABLE(OILPAN)
    visitor->trace(m_ports);
#endif
    Event::trace(visitor);
}

v8::Handle<v8::Object> MessageEvent::wrap(v8::Handle<v8::Object> creationContext, v8::Isolate* isolate)
{
    v8::Handle<v8::Object> wrapper = Event::wrap(creationContext, isolate);

    switch (dataType()) {
    case MessageEvent::DataTypeScriptValue:
    case MessageEvent::DataTypeSerializedScriptValue:
        break;
    case MessageEvent::DataTypeString:
        V8HiddenValue::setHiddenValue(isolate, wrapper, V8HiddenValue::stringData(isolate), v8String(isolate, dataAsString()));
        break;
    case MessageEvent::DataTypeArrayBuffer:
        V8HiddenValue::setHiddenValue(isolate, wrapper, V8HiddenValue::arrayBufferData(isolate), toV8(dataAsArrayBuffer(), wrapper, isolate));
        break;
    }

    return wrapper;
}

} // namespace blink
