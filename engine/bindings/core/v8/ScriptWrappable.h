/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
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

#ifndef ScriptWrappable_h
#define ScriptWrappable_h

#include "bindings/core/v8/WrapperTypeInfo.h"
#include "platform/ScriptForbiddenScope.h"
#include "platform/heap/Handle.h"
#include <v8.h>

namespace blink {

/**
 * The base class of all wrappable objects.
 *
 * This class provides the internal pointer to be stored in the wrapper objects,
 * and its conversions from / to the DOM instances.
 *
 * Note that this class must not have vtbl (any virtual function) or any member
 * variable which increase the size of instances. Some of the classes sensitive
 * to the size inherit from this class. So this class must be zero size.
 */
#if COMPILER(MSVC)
// VC++ 2013 doesn't support EBCO (Empty Base Class Optimization). It causes
// that not always pointers to an empty base class are aligned to 4 byte
// alignment. For example,
//
//   class EmptyBase1 {};
//   class EmptyBase2 {};
//   class Derived : public EmptyBase1, public EmptyBase2 {};
//   Derived d;
//   // &d                           == 0x1000
//   // static_cast<EmptyBase1*>(&d) == 0x1000
//   // static_cast<EmptyBase2*>(&d) == 0x1001  // Not 4 byte alignment!
//
// This doesn't happen with other compilers which support EBCO. All the
// addresses in the above example will be 0x1000 with EBCO supported.
//
// Since v8::Object::SetAlignedPointerInInternalField requires the pointers to
// be aligned, we need a hack to specify at least 4 byte alignment to MSVC.
__declspec(align(4))
#endif
class ScriptWrappableBase {
public:
    template<typename T>
    T* toImpl()
    {
        // Check if T* is castable to ScriptWrappableBase*, which means T
        // doesn't have two or more ScriptWrappableBase as superclasses.
        // If T has two ScriptWrappableBase as superclasses, conversions
        // from T* to ScriptWrappableBase* are ambiguous.
        ASSERT(static_cast<ScriptWrappableBase*>(static_cast<T*>(this)));
        // The internal pointers must be aligned to at least 4 byte alignment.
        ASSERT((reinterpret_cast<intptr_t>(this) & 0x3) == 0);
        return static_cast<T*>(this);
    }
    ScriptWrappableBase* toScriptWrappableBase()
    {
        // The internal pointers must be aligned to at least 4 byte alignment.
        ASSERT((reinterpret_cast<intptr_t>(this) & 0x3) == 0);
        return this;
    }

    void assertWrapperSanity(v8::Local<v8::Object> object)
    {
        RELEASE_ASSERT_WITH_SECURITY_IMPLICATION(object.IsEmpty()
            || object->GetAlignedPointerFromInternalField(v8DOMWrapperObjectIndex) == toScriptWrappableBase());
    }
};

/**
 * ScriptWrappable wraps a V8 object and its WrapperTypeInfo.
 *
 * ScriptWrappable acts much like a v8::Persistent<> in that it keeps a
 * V8 object alive.
 *
 *  The state transitions are:
 *  - new: an empty ScriptWrappable.
 *  - setWrapper: install a v8::Persistent (or empty)
 *  - disposeWrapper (via setWeakCallback, triggered by V8 garbage collecter):
 *        remove v8::Persistent and become empty.
 */
class ScriptWrappable : public ScriptWrappableBase {
public:
    ScriptWrappable() { }

    // Returns the WrapperTypeInfo of the instance.
    //
    // This method must be overridden by DEFINE_WRAPPERTYPEINFO macro.
    virtual const WrapperTypeInfo* wrapperTypeInfo() const = 0;

    // Creates and returns a new wrapper object.
    virtual v8::Handle<v8::Object> wrap(v8::Handle<v8::Object> creationContext, v8::Isolate*);

    // Associates the instance with the existing wrapper. Returns |wrapper|.
    virtual v8::Handle<v8::Object> associateWithWrapper(const WrapperTypeInfo*, v8::Handle<v8::Object> wrapper, v8::Isolate*);

    void setWrapper(v8::Handle<v8::Object> wrapper, v8::Isolate* isolate, const WrapperTypeInfo* wrapperTypeInfo)
    {
        ASSERT(!containsWrapper());
        if (!*wrapper)
            return;
        m_wrapper.Reset(isolate, wrapper);
        wrapperTypeInfo->configureWrapper(&m_wrapper);
        m_wrapper.SetWeak(this, &setWeakCallback);
        ASSERT(containsWrapper());
    }

    v8::Local<v8::Object> newLocalWrapper(v8::Isolate* isolate) const
    {
        return v8::Local<v8::Object>::New(isolate, m_wrapper);
    }

    bool isEqualTo(const v8::Local<v8::Object>& other) const
    {
        return m_wrapper == other;
    }

    static bool wrapperCanBeStoredInObject(const void*) { return false; }
    static bool wrapperCanBeStoredInObject(const ScriptWrappable*) { return true; }

    static ScriptWrappable* fromObject(const void*)
    {
        ASSERT_NOT_REACHED();
        return 0;
    }

    static ScriptWrappable* fromObject(ScriptWrappable* object)
    {
        return object;
    }

    bool setReturnValue(v8::ReturnValue<v8::Value> returnValue)
    {
        returnValue.Set(m_wrapper);
        return containsWrapper();
    }

    void markAsDependentGroup(ScriptWrappable* groupRoot, v8::Isolate* isolate)
    {
        ASSERT(containsWrapper());
        ASSERT(groupRoot && groupRoot->containsWrapper());

        // FIXME: There has to be a better way.
        v8::UniqueId groupId(*reinterpret_cast<intptr_t*>(&groupRoot->m_wrapper));
        m_wrapper.MarkPartiallyDependent();
        isolate->SetObjectGroupId(v8::Persistent<v8::Value>::Cast(m_wrapper), groupId);
    }

    void setReference(const v8::Persistent<v8::Object>& parent, v8::Isolate* isolate)
    {
        isolate->SetReference(parent, m_wrapper);
    }

    template<typename V8T, typename T>
    static void assertWrapperSanity(v8::Local<v8::Object> object, T* objectAsT)
    {
        ASSERT(objectAsT);
        RELEASE_ASSERT_WITH_SECURITY_IMPLICATION(object.IsEmpty()
            || object->GetAlignedPointerFromInternalField(v8DOMWrapperObjectIndex) == V8T::toScriptWrappableBase(objectAsT));
    }

    template<typename V8T, typename T>
    static void assertWrapperSanity(void* object, T* objectAsT)
    {
        ASSERT_NOT_REACHED();
    }

    template<typename V8T, typename T>
    static void assertWrapperSanity(ScriptWrappable* object, T* objectAsT)
    {
        ASSERT(object);
        ASSERT(objectAsT);
        RELEASE_ASSERT_WITH_SECURITY_IMPLICATION(object->m_wrapper.IsEmpty()
            || v8::Object::GetAlignedPointerFromInternalField(object->m_wrapper, v8DOMWrapperObjectIndex) == V8T::toScriptWrappableBase(objectAsT));
    }

    using ScriptWrappableBase::assertWrapperSanity;

    bool containsWrapper() const { return !m_wrapper.IsEmpty(); }

#if !ENABLE(OILPAN)
protected:
    virtual ~ScriptWrappable()
    {
        // We must not get deleted as long as we contain a wrapper. If this happens, we screwed up ref
        // counting somewhere. Crash here instead of crashing during a later gc cycle.
        RELEASE_ASSERT_WITH_SECURITY_IMPLICATION(!containsWrapper());
    }
#endif
    // With Oilpan we don't need a ScriptWrappable destructor.
    //
    // - 'RELEASE_ASSERT_WITH_SECURITY_IMPLICATION(!containsWrapper())' is not needed
    // because Oilpan is not using reference counting at all. If containsWrapper() is true,
    // it means that ScriptWrappable still has a wrapper. In this case, the destructor
    // must not be called since the wrapper has a persistent handle back to this ScriptWrappable object.
    // Assuming that Oilpan's GC is correct (If we cannot assume this, a lot of more things are
    // already broken), we must not hit the RELEASE_ASSERT.

private:
    void disposeWrapper(v8::Local<v8::Object> wrapper)
    {
        ASSERT(containsWrapper());
        ASSERT(wrapper == m_wrapper);
        m_wrapper.Reset();
    }

    static void setWeakCallback(const v8::WeakCallbackData<v8::Object, ScriptWrappable>& data)
    {
        data.GetParameter()->disposeWrapper(data.GetValue());

        // FIXME: I noticed that 50%~ of minor GC cycle times can be consumed
        // inside data.GetParameter()->deref(), which causes Node destructions. We should
        // make Node destructions incremental.
        releaseObject(data.GetValue());
    }

    v8::Persistent<v8::Object> m_wrapper;
};

// Defines 'wrapperTypeInfo' virtual method which returns the WrapperTypeInfo of
// the instance. Also declares a static member of type WrapperTypeInfo, of which
// the definition is given by the IDL code generator.
//
// Every DOM Class T must meet either of the following conditions:
// - T.idl inherits from [NotScriptWrappable].
// - T inherits from ScriptWrappable and has DEFINE_WRAPPERTYPEINFO().
//
// If a DOM class T does not inherit from ScriptWrappable, you have to write
// [NotScriptWrappable] in the IDL file as an extended attribute in order to let
// IDL code generator know that T does not inherit from ScriptWrappable. Note
// that [NotScriptWrappable] is inheritable.
//
// All the derived classes of ScriptWrappable, regardless of directly or
// indirectly, must write this macro in the class definition.
#define DEFINE_WRAPPERTYPEINFO() \
public: \
    virtual const WrapperTypeInfo* wrapperTypeInfo() const override \
    { \
        return &s_wrapperTypeInfo; \
    } \
private: \
    static const WrapperTypeInfo& s_wrapperTypeInfo

} // namespace blink

#endif // ScriptWrappable_h
