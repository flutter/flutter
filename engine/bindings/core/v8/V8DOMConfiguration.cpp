/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 3.  Neither the name of Apple Computer, Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "sky/engine/config.h"
#include "sky/engine/bindings/core/v8/V8DOMConfiguration.h"

#include "sky/engine/bindings/core/v8/V8ObjectConstructor.h"
#include "sky/engine/platform/TraceEvent.h"

namespace blink {

void V8DOMConfiguration::installAttributes(v8::Handle<v8::ObjectTemplate> instanceTemplate, v8::Handle<v8::ObjectTemplate> prototype, const AttributeConfiguration* attributes, size_t attributeCount, v8::Isolate* isolate)
{
    for (size_t i = 0; i < attributeCount; ++i)
        installAttribute(instanceTemplate, prototype, attributes[i], isolate);
}

void V8DOMConfiguration::installAccessors(v8::Handle<v8::ObjectTemplate> prototype, v8::Handle<v8::Signature> signature, const AccessorConfiguration* accessors, size_t accessorCount, v8::Isolate* isolate)
{
    DOMWrapperWorld& world = DOMWrapperWorld::current(isolate);
    for (size_t i = 0; i < accessorCount; ++i) {
        v8::FunctionCallback getterCallback = accessors[i].getter;
        v8::FunctionCallback setterCallback = accessors[i].setter;
        if (world.isMainWorld()) {
            if (accessors[i].getterForMainWorld)
                getterCallback = accessors[i].getterForMainWorld;
            if (accessors[i].setterForMainWorld)
                setterCallback = accessors[i].setterForMainWorld;
        }

        v8::Local<v8::FunctionTemplate> getter;
        if (getterCallback) {
            getter = v8::FunctionTemplate::New(isolate, getterCallback, v8::External::New(isolate, const_cast<WrapperTypeInfo*>(accessors[i].data)), signature, 0);
            getter->RemovePrototype();
        }
        v8::Local<v8::FunctionTemplate> setter;
        if (setterCallback) {
            setter = v8::FunctionTemplate::New(isolate, setterCallback, v8::External::New(isolate, const_cast<WrapperTypeInfo*>(accessors[i].data)), signature, 1);
            setter->RemovePrototype();
        }
        prototype->SetAccessorProperty(v8AtomicString(isolate, accessors[i].name), getter, setter, accessors[i].attribute, accessors[i].settings);
    }
}

void V8DOMConfiguration::installConstants(v8::Handle<v8::FunctionTemplate> functionDescriptor, v8::Handle<v8::ObjectTemplate> prototype, const ConstantConfiguration* constants, size_t constantCount, v8::Isolate* isolate)
{
    for (size_t i = 0; i < constantCount; ++i) {
        const ConstantConfiguration* constant = &constants[i];
        v8::Handle<v8::String> constantName = v8AtomicString(isolate, constant->name);
        switch (constant->type) {
        case ConstantTypeShort:
        case ConstantTypeLong:
        case ConstantTypeUnsignedShort:
            functionDescriptor->Set(constantName, v8::Integer::New(isolate, constant->ivalue), static_cast<v8::PropertyAttribute>(v8::ReadOnly | v8::DontDelete));
            prototype->Set(constantName, v8::Integer::New(isolate, constant->ivalue), static_cast<v8::PropertyAttribute>(v8::ReadOnly | v8::DontDelete));
            break;
        case ConstantTypeUnsignedLong:
            functionDescriptor->Set(constantName, v8::Integer::NewFromUnsigned(isolate, constant->ivalue), static_cast<v8::PropertyAttribute>(v8::ReadOnly | v8::DontDelete));
            prototype->Set(constantName, v8::Integer::NewFromUnsigned(isolate, constant->ivalue), static_cast<v8::PropertyAttribute>(v8::ReadOnly | v8::DontDelete));
            break;
        case ConstantTypeFloat:
        case ConstantTypeDouble:
            functionDescriptor->Set(constantName, v8::Number::New(isolate, constant->dvalue), static_cast<v8::PropertyAttribute>(v8::ReadOnly | v8::DontDelete));
            prototype->Set(constantName, v8::Number::New(isolate, constant->dvalue), static_cast<v8::PropertyAttribute>(v8::ReadOnly | v8::DontDelete));
            break;
        case ConstantTypeString:
            functionDescriptor->Set(constantName, v8::String::NewFromUtf8(isolate, constant->svalue), static_cast<v8::PropertyAttribute>(v8::ReadOnly | v8::DontDelete));
            prototype->Set(constantName, v8::String::NewFromUtf8(isolate, constant->svalue), static_cast<v8::PropertyAttribute>(v8::ReadOnly | v8::DontDelete));
            break;
        default:
            ASSERT_NOT_REACHED();
        }
    }
}

void V8DOMConfiguration::installMethods(v8::Handle<v8::ObjectTemplate> prototype, v8::Handle<v8::Signature> signature, v8::PropertyAttribute attributes, const MethodConfiguration* callbacks, size_t callbackCount, v8::Isolate* isolate)
{
    for (size_t i = 0; i < callbackCount; ++i)
        installMethod(prototype, signature, attributes, callbacks[i], isolate);
}

v8::Handle<v8::FunctionTemplate> V8DOMConfiguration::functionTemplateForCallback(v8::Handle<v8::Signature> signature, v8::FunctionCallback callback, int length, v8::Isolate* isolate)
{
    v8::Local<v8::FunctionTemplate> functionTemplate = v8::FunctionTemplate::New(isolate, callback, v8Undefined(), signature, length);
    functionTemplate->RemovePrototype();
    return functionTemplate;
}

v8::Local<v8::Signature> V8DOMConfiguration::installDOMClassTemplate(v8::Handle<v8::FunctionTemplate> functionDescriptor, const char* interfaceName, v8::Handle<v8::FunctionTemplate> parentClass, size_t fieldCount,
    const AttributeConfiguration* attributes, size_t attributeCount,
    const AccessorConfiguration* accessors, size_t accessorCount,
    const MethodConfiguration* callbacks, size_t callbackCount,
    v8::Isolate* isolate)
{
    functionDescriptor->SetClassName(v8AtomicString(isolate, interfaceName));
    v8::Local<v8::ObjectTemplate> instanceTemplate = functionDescriptor->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(fieldCount);
    if (!parentClass.IsEmpty()) {
        functionDescriptor->Inherit(parentClass);
        // Marks the prototype object as one of native-backed objects.
        // This is needed since bug 110436 asks WebKit to tell native-initiated prototypes from pure-JS ones.
        // This doesn't mark kinds "root" classes like Node, where setting this changes prototype chain structure.
        v8::Local<v8::ObjectTemplate> prototype = functionDescriptor->PrototypeTemplate();
        prototype->SetInternalFieldCount(v8PrototypeInternalFieldcount);
    }

    v8::Local<v8::Signature> defaultSignature = v8::Signature::New(isolate, functionDescriptor);
    if (attributeCount)
        installAttributes(instanceTemplate, functionDescriptor->PrototypeTemplate(), attributes, attributeCount, isolate);
    if (accessorCount)
        installAccessors(functionDescriptor->PrototypeTemplate(), defaultSignature, accessors, accessorCount, isolate);
    if (callbackCount)
        installMethods(functionDescriptor->PrototypeTemplate(), defaultSignature, static_cast<v8::PropertyAttribute>(v8::DontDelete), callbacks, callbackCount, isolate);
    return defaultSignature;
}

v8::Handle<v8::FunctionTemplate> V8DOMConfiguration::domClassTemplate(v8::Isolate* isolate, WrapperTypeInfo* wrapperTypeInfo, void (*configureDOMClassTemplate)(v8::Handle<v8::FunctionTemplate>, v8::Isolate*))
{
    V8PerIsolateData* data = V8PerIsolateData::from(isolate);
    v8::Local<v8::FunctionTemplate> result = data->existingDOMTemplate(wrapperTypeInfo);
    if (!result.IsEmpty())
        return result;

    TRACE_EVENT_SCOPED_SAMPLING_STATE("blink", "BuildDOMTemplate");
    result = v8::FunctionTemplate::New(isolate, V8ObjectConstructor::isValidConstructorMode);
    configureDOMClassTemplate(result, isolate);
    data->setDOMTemplate(wrapperTypeInfo, result);
    return result;
}

} // namespace blink
