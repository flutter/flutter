/*
 * Copyright (C) 2006, 2007, 2008, 2009 Google Inc. All rights reserved.
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

#ifndef V8LazyEventListener_h
#define V8LazyEventListener_h

#include "bindings/core/v8/V8AbstractEventListener.h"
#include "wtf/PassRefPtr.h"
#include "wtf/text/TextPosition.h"
#include "wtf/text/WTFString.h"
#include <v8.h>

namespace blink {

class Event;
class LocalFrame;
class Node;

// V8LazyEventListener is a wrapper for a JavaScript code string that is compiled and evaluated when an event is fired.
// A V8LazyEventListener is either a HTML or SVG event handler.
class V8LazyEventListener FINAL : public V8AbstractEventListener {
public:
    static PassRefPtr<V8LazyEventListener> create(const AtomicString& functionName, const AtomicString& eventParameterName, const String& code, const String& sourceURL, const TextPosition& position, Node* node, v8::Isolate* isolate)
    {
        return adoptRef(new V8LazyEventListener(functionName, eventParameterName, code, sourceURL, position, node, isolate));
    }

    virtual bool isLazy() const OVERRIDE { return true; }
    // V8LazyEventListener is always for the main world.
    virtual DOMWrapperWorld& world() const OVERRIDE { return DOMWrapperWorld::mainWorld(); }

    virtual void handleEvent(ExecutionContext*, Event*) OVERRIDE;

protected:
    virtual void prepareListenerObject(ExecutionContext*) OVERRIDE;

private:
    V8LazyEventListener(const AtomicString& functionName, const AtomicString& eventParameterName, const String& code, const String sourceURL, const TextPosition&, Node*, v8::Isolate*);

    virtual v8::Local<v8::Value> callListenerFunction(v8::Handle<v8::Value> jsEvent, Event*) OVERRIDE;

    // Needs to return true for all event handlers implemented in JavaScript so that
    // the SVG code does not add the event handler in both
    // SVGUseElement::buildShadowTree and again in
    // SVGUseElement::transferEventListenersToShadowTree
    virtual bool wasCreatedFromMarkup() const OVERRIDE { return true; }

    AtomicString m_functionName;
    AtomicString m_eventParameterName;
    String m_code;
    String m_sourceURL;
    Node* m_node;
    TextPosition m_position;
};

} // namespace blink

#endif // V8LazyEventListener_h
