/*
 * Copyright (C) 2014 Google Inc. All rights reserved.
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

#include "platform/ScriptForbiddenScope.h"
#include "platform/heap/Handle.h"
#include <v8.h>
#include "wtf/Assertions.h"

// Helper to call webCoreInitializeScriptWrappableForInterface in the global namespace.
template <class C> inline void initializeScriptWrappableHelper(C* object)
{
    void webCoreInitializeScriptWrappableForInterface(C*);
    webCoreInitializeScriptWrappableForInterface(object);
}

namespace blink {

// Forward declarations.
class DartWrapperInfo;
class DartMultiWrapperInfo;
struct WrapperTypeInfo;

/**
 * The base class of all wrappable objects.
 *
 * This class provides the internal pointer to be stored in the wrapper objects,
 * and its conversions from / to the DOM instances.
 *
 * Note that this class must not have vtbl (any virtual function) or any member
 * variable which increase the size of instances.  Some of the classes sensitive
 * to the size inherit from this class.  So this class must be zero size.
 */
class ScriptWrappableBase {
public:
    template <class T> static T* fromInternalPointer(ScriptWrappableBase* internalPointer)
    {
        // Check if T* is castable to ScriptWrappableBase*, which means T
        // doesn't have two or more ScriptWrappableBase as superclasses.
        // If T has two ScriptWrappableBase as superclasses, conversions
        // from T* to ScriptWrappableBase* are ambiguous.
        ASSERT(static_cast<ScriptWrappableBase*>(static_cast<T*>(internalPointer)));
        return static_cast<T*>(internalPointer);
    }
    ScriptWrappableBase* toInternalPointer() { return this; }
};

// An optimization to avoid in the common case the cost of map lookups when
// finding the V8 or Dart wrapper for a Blink object and to quickly find the
// most specific V8 or Dart wrapper type for a Blink object.
class ScriptWrappable : public ScriptWrappableBase {
public:
    class TaggedPointer {
    private:
        enum {
            kTypeInfoTag = 0x0,
            kV8WrapperTag = 0x1,
            kDartWrapperTag = 0x2,
            kMultiWrapperTag = 0x3
        };
        static const intptr_t kWrappableBitMask = 0x3;

        uintptr_t m_ptr;

    public:
        TaggedPointer() : m_ptr(0) { }

        explicit TaggedPointer(const WrapperTypeInfo* info) : m_ptr(reinterpret_cast<uintptr_t>(info) | kTypeInfoTag)
        {
            // Assert incoming pointer is non-null and 4-byte aligned.
            ASSERT(info && ((reinterpret_cast<uintptr_t>(info) & kWrappableBitMask) == 0));
        }

        explicit TaggedPointer(v8::Object* info) : m_ptr(reinterpret_cast<uintptr_t>(info) | kV8WrapperTag)
        {
            // Assert incoming pointer is non-null and 4-byte aligned.
            ASSERT(info && ((reinterpret_cast<uintptr_t>(info) & kWrappableBitMask) == 0));
        }

        explicit TaggedPointer(DartWrapperInfo* info) : m_ptr(reinterpret_cast<uintptr_t>(info) | kDartWrapperTag)
        {
            // Assert incoming pointer is non-null and 4-byte aligned.
            ASSERT(info && ((reinterpret_cast<uintptr_t>(info) & kWrappableBitMask) == 0));
        }

        explicit TaggedPointer(DartMultiWrapperInfo* info) : m_ptr(reinterpret_cast<uintptr_t>(info) | kMultiWrapperTag)
        {
            // Assert incoming pointer is non-null and 4-byte aligned.
            ASSERT(info && ((reinterpret_cast<uintptr_t>(info) & kWrappableBitMask) == 0));
        }

        inline bool isEmpty() const
        {
            return !m_ptr;
        }

        inline bool isWrapperTypeInfo() const
        {
            return (m_ptr & kWrappableBitMask) == kTypeInfoTag;
        }

        inline bool isV8Wrapper() const
        {
            return (m_ptr & kWrappableBitMask) == kV8WrapperTag;
        }

        inline bool isDartWrapperInfo() const
        {
            return (m_ptr & kWrappableBitMask) == kDartWrapperTag;
        }

        inline bool isDartMultiWrapperInfo() const
        {
            return (m_ptr & kWrappableBitMask) == kMultiWrapperTag;
        }

        inline const WrapperTypeInfo* wrapperTypeInfo() const
        {
            return reinterpret_cast<const WrapperTypeInfo*>(m_ptr & ~kWrappableBitMask);
        }

        inline v8::Object* v8Wrapper() const
        {
            return reinterpret_cast<v8::Object*>(m_ptr & ~kWrappableBitMask);
        }

        inline DartWrapperInfo* dartWrapperInfo() const
        {
            return reinterpret_cast<DartWrapperInfo*>(m_ptr & ~kWrappableBitMask);
        }

        inline DartMultiWrapperInfo* dartMultiWrapperInfo() const
        {
            return reinterpret_cast<DartMultiWrapperInfo*>(m_ptr & ~kWrappableBitMask);
        }

        inline void clear()
        {
            m_ptr = 0;
        }
    };

    COMPILE_ASSERT(sizeof(TaggedPointer) == sizeof(void*), taggedPointerIsNotOneWord);

public:
    ScriptWrappable() : m_v8WrapperOrTypeInfo(), m_dartWrapperInfo() { }

    // Wrappables need to be initialized with their most derived type for which
    // bindings exist, in much the same way that certain other types need to be
    // adopted and so forth. The overloaded initializeScriptWrappableForInterface()
    // functions are implemented by the generated V8 bindings code. Declaring the
    // extern function in the template avoids making a centralized header of all
    // the bindings in the universe. C++11's extern template feature may provide
    // a cleaner solution someday.
    // FIXME: Also initialize Dart type info.
    template <class C> static void init(C* object)
    {
        initializeScriptWrappableHelper(object);
    }

    inline const WrapperTypeInfo* getTypeInfo() const;
    inline void setTypeInfo(const WrapperTypeInfo* info);

    inline bool containsV8Wrapper() const;
    inline void setV8Wrapper(v8::Object* wrapper);
    inline v8::Object* getV8Wrapper() const;
    inline void clearV8Wrapper(v8::Local<v8::Object> wrapper, v8::Persistent<v8::Object>* persistent);

    inline void setDartWrapper(void* domData, void* wrapper);
    inline void* getDartWrapper(void * domData) const;
    inline void clearDartWrapper(void* domData);

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

#if !ENABLE(OILPAN)
protected:
    virtual ~ScriptWrappable()
    {
        // We must not get deleted as long as we contain a wrapper. If this happens, we screwed up ref
        // counting somewhere. Crash here instead of crashing during a later gc cycle.
        RELEASE_ASSERT_WITH_SECURITY_IMPLICATION(m_v8WrapperOrTypeInfo.isWrapperTypeInfo());
        RELEASE_ASSERT_WITH_SECURITY_IMPLICATION(m_dartWrapperInfo.isEmpty());
        // Assert initialization via init() even if not subsequently wrapped.
        ASSERT(!m_v8WrapperOrTypeInfo.isEmpty());
        // Break UAF attempts to wrap.
        m_v8WrapperOrTypeInfo.clear();
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
    //
    // - 'm_wrapperOrTypeInfo = 0' is not needed because Oilpan's GC zeroes out memory when
    // the memory is collected and added to a free list.

private:
    // A tagged pointer to this object's V8 or Dart peer. It may contain:
    // -- nothing, transiently during construction/destruction
    // -- WrapperTypeInfo, if this object has no peers
    // -- v8::Object, if this object has a V8 peer in the main world and no Dart
    //    peer
    // -- DartWrapperInfo, if this object has one Dart peer and possibly a V8
    //    peer in the main world
    // -- DartMultiWrapperInfo, if this object has more than one Dart peer and
    //    possibly a V8 peer in the main world
    TaggedPointer m_v8WrapperOrTypeInfo;
    TaggedPointer m_dartWrapperInfo;
};

} // namespace blink

#include "bindings/core/dart/DartScriptWrappable.h"
#include "bindings/core/v8/V8ScriptWrappable.h"

#endif // ScriptWrappable_h
