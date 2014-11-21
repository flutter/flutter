// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_BINDINGS_CORE_V8_SCRIPTPROMISEPROPERTY_H_
#define SKY_ENGINE_BINDINGS_CORE_V8_SCRIPTPROMISEPROPERTY_H_

#include "sky/engine/bindings/core/v8/ScriptPromise.h"
#include "sky/engine/bindings/core/v8/ScriptPromisePropertyBase.h"
#include "sky/engine/bindings/core/v8/V8Binding.h"
#include "sky/engine/wtf/Noncopyable.h"
#include "sky/engine/wtf/PassRefPtr.h"

namespace blink {

class ExecutionContext;

// ScriptPromiseProperty is a helper for implementing a DOM method or
// attribute whose value is a Promise, and the same Promise must be
// returned each time.
//
// ScriptPromiseProperty does not keep Promises or worlds alive to
// deliver Promise resolution/rejection to them; the Promise
// resolution/rejections are delivered if the holder's wrapper is
// alive. This is achieved by keeping a weak reference from
// ScriptPromiseProperty to the holder's wrapper, and references in
// hidden values from the wrapper to the promise and resolver
// (coincidentally the Resolver and Promise may be the same object,
// but that is an implementation detail of v8.)
//
//                                             ----> Resolver
//                                            /
// ScriptPromiseProperty - - -> Holder Wrapper ----> Promise
//
// To avoid exposing the action of the garbage collector to script,
// you should keep the wrapper alive as long as a promise may be
// settled.
//
// To avoid clobbering hidden values, a holder should only have one
// ScriptPromiseProperty object for a given name at a time. See reset.
template<typename HolderType, typename ResolvedType, typename RejectedType>
class ScriptPromiseProperty : public ScriptPromisePropertyBase {
    WTF_MAKE_NONCOPYABLE(ScriptPromiseProperty);
public:
    // Creates a ScriptPromiseProperty that will create Promises in
    // the specified ExecutionContext for a property of 'holder'
    // (typically ScriptPromiseProperty should be a member of the
    // property holder).
    //
    // When implementing a ScriptPromiseProperty add the property name
    // to ScriptPromiseProperties.h and pass
    // ScriptPromiseProperty::Foo to create. The name must be unique
    // per kind of holder.
    template<typename PassHolderType>
    ScriptPromiseProperty(ExecutionContext*, PassHolderType, Name);

    virtual ~ScriptPromiseProperty() { }

    template<typename PassResolvedType>
    void resolve(PassResolvedType);

    template<typename PassRejectedType>
    void reject(PassRejectedType);

    // Resets this property by unregistering the Promise property from the
    // holder wrapper. Resets the internal state to Pending and clears the
    // resolved and the rejected values.
    // This method keeps the holder object and the property name.
    void reset();

private:
    virtual v8::Handle<v8::Object> holder(v8::Handle<v8::Object> creationContext, v8::Isolate*) override;
    virtual v8::Handle<v8::Value> resolvedValue(v8::Handle<v8::Object> creationContext, v8::Isolate*) override;
    virtual v8::Handle<v8::Value> rejectedValue(v8::Handle<v8::Object> creationContext, v8::Isolate*) override;

    HolderType m_holder;
    ResolvedType m_resolved;
    RejectedType m_rejected;
};

template<typename HolderType, typename ResolvedType, typename RejectedType>
template<typename PassHolderType>
ScriptPromiseProperty<HolderType, ResolvedType, RejectedType>::ScriptPromiseProperty(ExecutionContext* executionContext, PassHolderType holder, Name name)
    : ScriptPromisePropertyBase(executionContext, name)
    , m_holder(holder)
{
}

template<typename HolderType, typename ResolvedType, typename RejectedType>
template<typename PassResolvedType>
void ScriptPromiseProperty<HolderType, ResolvedType, RejectedType>::resolve(PassResolvedType value)
{
    if (state() != Pending) {
        ASSERT_NOT_REACHED();
        return;
    }
    if (!executionContext() || executionContext()->activeDOMObjectsAreStopped())
        return;
    m_resolved = value;
    resolveOrReject(Resolved);
}

template<typename HolderType, typename ResolvedType, typename RejectedType>
template<typename PassRejectedType>
void ScriptPromiseProperty<HolderType, ResolvedType, RejectedType>::reject(PassRejectedType value)
{
    if (state() != Pending) {
        ASSERT_NOT_REACHED();
        return;
    }
    if (!executionContext() || executionContext()->activeDOMObjectsAreStopped())
        return;
    m_rejected = value;
    resolveOrReject(Rejected);
}

template<typename HolderType, typename ResolvedType, typename RejectedType>
v8::Handle<v8::Object> ScriptPromiseProperty<HolderType, ResolvedType, RejectedType>::holder(v8::Handle<v8::Object> creationContext, v8::Isolate* isolate)
{
    v8::Handle<v8::Value> value = V8ValueTraits<HolderType>::toV8Value(m_holder, creationContext, isolate);
    return value.As<v8::Object>();
}

template<typename HolderType, typename ResolvedType, typename RejectedType>
v8::Handle<v8::Value> ScriptPromiseProperty<HolderType, ResolvedType, RejectedType>::resolvedValue(v8::Handle<v8::Object> creationContext, v8::Isolate* isolate)
{
    ASSERT(state() == Resolved);
    return V8ValueTraits<ResolvedType>::toV8Value(m_resolved, creationContext, isolate);
}

template<typename HolderType, typename ResolvedType, typename RejectedType>
v8::Handle<v8::Value> ScriptPromiseProperty<HolderType, ResolvedType, RejectedType>::rejectedValue(v8::Handle<v8::Object> creationContext, v8::Isolate* isolate)
{
    ASSERT(state() == Rejected);
    return V8ValueTraits<RejectedType>::toV8Value(m_rejected, creationContext, isolate);
}

template<typename HolderType, typename ResolvedType, typename RejectedType>
void ScriptPromiseProperty<HolderType, ResolvedType, RejectedType>::reset()
{
    resetBase();
    m_resolved = ResolvedType();
    m_rejected = RejectedType();
}

} // namespace blink

#endif  // SKY_ENGINE_BINDINGS_CORE_V8_SCRIPTPROMISEPROPERTY_H_
