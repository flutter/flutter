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

#include "config.h"
#include "bindings/core/v8/V8LazyEventListener.h"

#include "bindings/core/v8/ScriptController.h"
#include "bindings/core/v8/ScriptSourceCode.h"
#include "bindings/core/v8/V8Binding.h"
#include "bindings/core/v8/V8DOMWrapper.h"
#include "bindings/core/v8/V8Document.h"
#include "bindings/core/v8/V8HiddenValue.h"
#include "bindings/core/v8/V8Node.h"
#include "bindings/core/v8/V8ScriptRunner.h"
#include "core/dom/Document.h"
#include "core/dom/Node.h"
#include "core/frame/LocalFrame.h"
#include "core/html/HTMLElement.h"

#include "wtf/StdLibExtras.h"

namespace blink {

V8LazyEventListener::V8LazyEventListener(const AtomicString& functionName, const AtomicString& eventParameterName, const String& code, const String sourceURL, const TextPosition& position, Node* node, v8::Isolate* isolate)
    : V8AbstractEventListener(true, isolate)
    , m_functionName(functionName)
    , m_eventParameterName(eventParameterName)
    , m_code(code)
    , m_sourceURL(sourceURL)
    , m_node(node)
    , m_position(position)
{
}

template<typename T>
v8::Handle<v8::Object> toObjectWrapper(T* domObject, ScriptState* scriptState)
{
    if (!domObject)
        return v8::Object::New(scriptState->isolate());
    v8::Handle<v8::Value> value = toV8(domObject, scriptState->context()->Global(), scriptState->isolate());
    if (value.IsEmpty())
        return v8::Object::New(scriptState->isolate());
    return v8::Local<v8::Object>::New(scriptState->isolate(), value.As<v8::Object>());
}

v8::Local<v8::Value> V8LazyEventListener::callListenerFunction(v8::Handle<v8::Value> jsEvent, Event* event)
{
    v8::Local<v8::Object> listenerObject = getListenerObject(scriptState()->executionContext());
    if (listenerObject.IsEmpty())
        return v8::Local<v8::Value>();

    v8::Local<v8::Function> handlerFunction = listenerObject.As<v8::Function>();
    v8::Local<v8::Object> receiver = getReceiverObject(event);
    if (handlerFunction.IsEmpty() || receiver.IsEmpty())
        return v8::Local<v8::Value>();

    if (!scriptState()->executionContext()->isDocument())
        return v8::Local<v8::Value>();

    LocalFrame* frame = toDocument(scriptState()->executionContext())->frame();
    if (!frame)
        return v8::Local<v8::Value>();

    v8::Handle<v8::Value> parameters[1] = { jsEvent };
    return frame->script().callFunction(handlerFunction, receiver, WTF_ARRAY_LENGTH(parameters), parameters);
}

static void V8LazyEventListenerToString(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    v8SetReturnValue(info, V8HiddenValue::getHiddenValue(info.GetIsolate(), info.Holder(), V8HiddenValue::toStringString(info.GetIsolate())));
}

void V8LazyEventListener::handleEvent(ExecutionContext* context, Event* event)
{
    v8::HandleScope handleScope(toIsolate(context));
    // V8LazyEventListener doesn't know the associated context when created.
    // Thus we lazily get the associated context and set a ScriptState on V8AbstractEventListener.
    v8::Local<v8::Context> v8Context = toV8Context(context, world());
    if (v8Context.IsEmpty())
        return;
    setScriptState(ScriptState::from(v8Context));

    V8AbstractEventListener::handleEvent(context, event);
}

void V8LazyEventListener::prepareListenerObject(ExecutionContext* context)
{
    v8::HandleScope handleScope(toIsolate(context));
    // V8LazyEventListener doesn't know the associated context when created.
    // Thus we lazily get the associated context and set a ScriptState on V8AbstractEventListener.
    v8::Local<v8::Context> v8Context = toV8Context(context, world());
    if (v8Context.IsEmpty())
        return;
    setScriptState(ScriptState::from(v8Context));

    if (context->isDocument()) {
        clearListenerObject();
        return;
    }

    if (hasExistingListenerObject())
        return;

    ASSERT(context->isDocument());

    ScriptState::Scope scope(scriptState());

    // FIXME: Remove the following 'with' hack.
    //
    // Nodes other than the document object, when executing inline event
    // handlers push document, form owner, and the target node on the scope chain.
    // We do this by using 'with' statement.
    // See chrome/fast/forms/form-action.html
    //     chrome/fast/forms/selected-index-value.html
    //     base/fast/overflow/onscroll-layer-self-destruct.html
    //
    // Don't use new lines so that lines in the modified handler
    // have the same numbers as in the original code.
    // FIXME: V8 does not allow us to programmatically create object environments so
    //        we have to do this hack! What if m_code escapes to run arbitrary script?
    //
    // Call with 4 arguments instead of 3, pass additional null as the last parameter.
    // By calling the function with 4 arguments, we create a setter on arguments object
    // which would shadow property "3" on the prototype.
    String code = "(function() {"
        "with (this[1]) {"
        "with (this[0]) {"
            "return function(" + m_eventParameterName + ") {" +
                m_code + "\n" // Insert '\n' otherwise //-style comments could break the handler.
            "};"
        "}}})";

    v8::Handle<v8::String> codeExternalString = v8String(isolate(), code);

    v8::Local<v8::Value> result = V8ScriptRunner::compileAndRunInternalScript(codeExternalString, isolate(), m_sourceURL, m_position);
    if (result.IsEmpty())
        return;

    // Call the outer function to get the inner function.
    ASSERT(result->IsFunction());
    v8::Local<v8::Function> intermediateFunction = result.As<v8::Function>();

    v8::Handle<v8::Object> nodeWrapper = toObjectWrapper<Node>(m_node, scriptState());
    v8::Handle<v8::Object> documentWrapper = toObjectWrapper<Document>(m_node ? m_node->ownerDocument() : 0, scriptState());

    v8::Local<v8::Object> thisObject = v8::Object::New(isolate());
    if (thisObject.IsEmpty())
        return;
    if (!thisObject->ForceSet(v8::Integer::New(isolate(), 0), nodeWrapper))
        return;
    if (!thisObject->ForceSet(v8::Integer::New(isolate(), 1), documentWrapper))
        return;

    // FIXME: Remove this code when we stop doing the 'with' hack above.
    v8::Local<v8::Value> innerValue = V8ScriptRunner::callInternalFunction(intermediateFunction, thisObject, 0, 0, isolate());
    if (innerValue.IsEmpty() || !innerValue->IsFunction())
        return;

    v8::Local<v8::Function> wrappedFunction = innerValue.As<v8::Function>();

    // Change the toString function on the wrapper function to avoid it
    // returning the source for the actual wrapper function. Instead it
    // returns source for a clean wrapper function with the event
    // argument wrapping the event source code. The reason for this is
    // that some web sites use toString on event functions and eval the
    // source returned (sometimes a RegExp is applied as well) for some
    // other use. That fails miserably if the actual wrapper source is
    // returned.
    v8::Local<v8::Function> toStringFunction = v8::Function::New(isolate(), V8LazyEventListenerToString);
    ASSERT(!toStringFunction.IsEmpty());
    String toStringString = "function " + m_functionName + "(" + m_eventParameterName + ") {\n  " + m_code + "\n}";
    V8HiddenValue::setHiddenValue(isolate(), wrappedFunction, V8HiddenValue::toStringString(isolate()), v8String(isolate(), toStringString));
    wrappedFunction->Set(v8AtomicString(isolate(), "toString"), toStringFunction);
    wrappedFunction->SetName(v8String(isolate(), m_functionName));

    // FIXME: Remove the following comment-outs.
    // See https://bugs.webkit.org/show_bug.cgi?id=85152 for more details.
    //
    // For the time being, we comment out the following code since the
    // second parsing can happen.
    // // Since we only parse once, there's no need to keep data used for parsing around anymore.
    // m_functionName = String();
    // m_code = String();
    // m_eventParameterName = String();
    // m_sourceURL = String();

    setListenerObject(wrappedFunction);
}

} // namespace blink
