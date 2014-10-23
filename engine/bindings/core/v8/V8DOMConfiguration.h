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

#ifndef V8DOMConfiguration_h
#define V8DOMConfiguration_h

#include "bindings/core/v8/V8Binding.h"
#include "bindings/core/v8/V8DOMWrapper.h"
#include <v8.h>

namespace blink {

class V8DOMConfiguration {
public:
    // The following Configuration structs and install methods are used for
    // setting multiple properties on an ObjectTemplate, used from the
    // generated bindings initialization (ConfigureXXXTemplate). This greatly
    // reduces the binary size by moving from code driven setup to data table
    // driven setup.

    enum ExposeConfiguration {
        ExposedToAllScripts,
    };

    enum InstanceOrPrototypeConfiguration {
        OnInstance,
        OnPrototype,
    };

    // AttributeConfiguration translates into calls to SetAccessor() on either
    // the instance or the prototype ObjectTemplate, based on |instanceOrPrototypeConfiguration|.
    struct AttributeConfiguration {
        const char* const name;
        v8::AccessorGetterCallback getter;
        v8::AccessorSetterCallback setter;
        v8::AccessorGetterCallback getterForMainWorld;
        v8::AccessorSetterCallback setterForMainWorld;
        const WrapperTypeInfo* data;
        v8::AccessControl settings;
        v8::PropertyAttribute attribute;
        ExposeConfiguration exposeConfiguration;
        InstanceOrPrototypeConfiguration instanceOrPrototypeConfiguration;
    };

    // AccessorConfiguration translates into calls to SetAccessorProperty()
    // on prototype ObjectTemplate.
    struct AccessorConfiguration {
        const char* const name;
        v8::FunctionCallback getter;
        v8::FunctionCallback setter;
        v8::FunctionCallback getterForMainWorld;
        v8::FunctionCallback setterForMainWorld;
        const WrapperTypeInfo* data;
        v8::AccessControl settings;
        v8::PropertyAttribute attribute;
        ExposeConfiguration exposeConfiguration;
    };

    static void installAttributes(v8::Handle<v8::ObjectTemplate>, v8::Handle<v8::ObjectTemplate>, const AttributeConfiguration*, size_t attributeCount, v8::Isolate*);

    template<class ObjectOrTemplate>
    static inline void installAttribute(v8::Handle<ObjectOrTemplate> instanceTemplate, v8::Handle<ObjectOrTemplate> prototype, const AttributeConfiguration& attribute, v8::Isolate* isolate)
    {
        DOMWrapperWorld& world = DOMWrapperWorld::current(isolate);
        v8::AccessorGetterCallback getter = attribute.getter;
        v8::AccessorSetterCallback setter = attribute.setter;
        if (world.isMainWorld()) {
            if (attribute.getterForMainWorld)
                getter = attribute.getterForMainWorld;
            if (attribute.setterForMainWorld)
                setter = attribute.setterForMainWorld;
        }
        (attribute.instanceOrPrototypeConfiguration == OnPrototype ? prototype : instanceTemplate)->SetAccessor(v8AtomicString(isolate, attribute.name),
            getter,
            setter,
            v8::External::New(isolate, const_cast<WrapperTypeInfo*>(attribute.data)),
            attribute.settings,
            attribute.attribute);
    }

    enum ConstantType {
        ConstantTypeShort,
        ConstantTypeLong,
        ConstantTypeUnsignedShort,
        ConstantTypeUnsignedLong,
        ConstantTypeFloat,
        ConstantTypeDouble,
        ConstantTypeString
    };

    // ConstantConfiguration translates into calls to Set() for setting up an
    // object's constants. It sets the constant on both the FunctionTemplate and
    // the ObjectTemplate. PropertyAttributes is always ReadOnly.
    struct ConstantConfiguration {
        const char* const name;
        int ivalue;
        double dvalue;
        const char* const svalue;
        ConstantType type;
    };

    static void installConstants(v8::Handle<v8::FunctionTemplate>, v8::Handle<v8::ObjectTemplate>, const ConstantConfiguration*, size_t constantCount, v8::Isolate*);

    // MethodConfiguration translates into calls to Set() for setting up an
    // object's callbacks. It sets the method on both the FunctionTemplate or
    // the ObjectTemplate.
    struct MethodConfiguration {
        v8::Local<v8::Name> methodName(v8::Isolate* isolate) const { return v8AtomicString(isolate, name); }
        v8::FunctionCallback callbackForWorld(const DOMWrapperWorld& world) const
        {
            return world.isMainWorld() && callbackForMainWorld ? callbackForMainWorld : callback;
        }

        const char* const name;
        v8::FunctionCallback callback;
        v8::FunctionCallback callbackForMainWorld;
        int length;
        ExposeConfiguration exposeConfiguration;
    };

    struct SymbolKeyedMethodConfiguration {
        v8::Local<v8::Name> methodName(v8::Isolate* isolate) const { return getSymbol(isolate); }
        v8::FunctionCallback callbackForWorld(const DOMWrapperWorld&) const
        {
            return callback;
        }

        v8::Local<v8::Symbol> (*getSymbol)(v8::Isolate*);
        v8::FunctionCallback callback;
        // SymbolKeyedMethodConfiguration doesn't support per-world bindings.
        int length;
        ExposeConfiguration exposeConfiguration;
    };

    static void installMethods(v8::Handle<v8::ObjectTemplate>, v8::Handle<v8::Signature>, v8::PropertyAttribute, const MethodConfiguration*, size_t callbackCount, v8::Isolate*);

    template <class ObjectOrTemplate, class Configuration>
    static void installMethod(v8::Handle<ObjectOrTemplate> objectOrTemplate, v8::Handle<v8::Signature> signature, v8::PropertyAttribute attribute, const Configuration& callback, v8::Isolate* isolate)
    {
        DOMWrapperWorld& world = DOMWrapperWorld::current(isolate);
        v8::Local<v8::FunctionTemplate> functionTemplate = functionTemplateForCallback(signature, callback.callbackForWorld(world), callback.length, isolate);
        setMethod(objectOrTemplate, callback.methodName(isolate), functionTemplate, attribute);
    }

    static void installAccessors(v8::Handle<v8::ObjectTemplate>, v8::Handle<v8::Signature>, const AccessorConfiguration*, size_t accessorCount, v8::Isolate*);

    static v8::Local<v8::Signature> installDOMClassTemplate(v8::Handle<v8::FunctionTemplate>, const char* interfaceName, v8::Handle<v8::FunctionTemplate> parentClass, size_t fieldCount,
        const AttributeConfiguration*, size_t attributeCount,
        const AccessorConfiguration*, size_t accessorCount,
        const MethodConfiguration*, size_t callbackCount,
        v8::Isolate*);

    static v8::Handle<v8::FunctionTemplate> domClassTemplate(v8::Isolate*, WrapperTypeInfo*, void (*)(v8::Handle<v8::FunctionTemplate>, v8::Isolate*));

private:
    static void setMethod(v8::Handle<v8::Object> target, v8::Handle<v8::Name> name, v8::Handle<v8::FunctionTemplate> functionTemplate, v8::PropertyAttribute attribute)
    {
        target->Set(name, functionTemplate->GetFunction());
    }
    static void setMethod(v8::Handle<v8::FunctionTemplate> target, v8::Handle<v8::Name> name, v8::Handle<v8::FunctionTemplate> functionTemplate, v8::PropertyAttribute attribute)
    {
        target->Set(name, functionTemplate, attribute);
    }
    static void setMethod(v8::Handle<v8::ObjectTemplate> target, v8::Handle<v8::Name> name, v8::Handle<v8::FunctionTemplate> functionTemplate, v8::PropertyAttribute attribute)
    {
        target->Set(name, functionTemplate, attribute);
    }

    static v8::Handle<v8::FunctionTemplate> functionTemplateForCallback(v8::Handle<v8::Signature>, v8::FunctionCallback, int length, v8::Isolate*);
};

} // namespace blink

#endif // V8DOMConfiguration_h
