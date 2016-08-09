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

#ifndef SKY_ENGINE_PUBLIC_PLATFORM_WEBPRIVATEPTR_H_
#define SKY_ENGINE_PUBLIC_PLATFORM_WEBPRIVATEPTR_H_

#include "flutter/sky/engine/public/platform/WebCommon.h"

#if INSIDE_BLINK
#include "flutter/sky/engine/platform/heap/Handle.h"
#include "flutter/sky/engine/wtf/PassRefPtr.h"
#include "flutter/sky/engine/wtf/TypeTraits.h"
#endif

namespace blink {

#if INSIDE_BLINK
template<typename T>
class PtrStorageImpl {
public:
    typedef PassRefPtr<T> BlinkPtrType;

    void assign(const BlinkPtrType& val)
    {
        release();
        m_ptr = val.leakRef();
    }

    void assign(const PtrStorageImpl& other)
    {
        release();
        T* val = other.get();
        WTF::refIfNotNull(val);
        m_ptr = val;
    }

    T* get() const { return m_ptr; }

    void release()
    {
        WTF::derefIfNotNull(m_ptr);
        m_ptr = 0;
    }

private:
    T* m_ptr;
};

template<typename T>
class PtrStorage : public PtrStorageImpl<T> {
public:
    static PtrStorage& fromSlot(void** slot)
    {
        COMPILE_ASSERT(sizeof(PtrStorage) == sizeof(void*), PtrStorage_must_be_pointer_size);
        return *reinterpret_cast<PtrStorage*>(slot);
    }

    static const PtrStorage& fromSlot(void* const* slot)
    {
        COMPILE_ASSERT(sizeof(PtrStorage) == sizeof(void*), PtrStorage_must_be_pointer_size);
        return *reinterpret_cast<const PtrStorage*>(slot);
    }

private:
    // Prevent construction via normal means.
    PtrStorage();
    PtrStorage(const PtrStorage&);
};
#endif


// This class is an implementation detail of the Blink API. It exists to help
// simplify the implementation of Blink interfaces that merely wrap a reference
// counted WebCore class.
//
// A typical implementation of a class which uses WebPrivatePtr might look like
// this:
//    class WebFoo {
//    public:
//        BLINK_EXPORT ~WebFoo();
//        WebFoo() { }
//        WebFoo(const WebFoo& other) { assign(other); }
//        WebFoo& operator=(const WebFoo& other)
//        {
//            assign(other);
//            return *this;
//        }
//        BLINK_EXPORT void assign(const WebFoo&);  // Implemented in the body.
//
//        // Methods that are exposed to Chromium and which are specific to
//        // WebFoo go here.
//        BLINK_EXPORT doWebFooThing();
//
//        // Methods that are used only by other Blink classes should only be
//        // declared when INSIDE_BLINK is set.
//    #if INSIDE_BLINK
//        WebFoo(const WTF::PassRefPtr<Foo>&);
//    #endif
//
//    private:
//        WebPrivatePtr<Foo> m_private;
//    };
//
//    // WebFoo.cpp
//    WebFoo::~WebFoo() { m_private.reset(); }
//    void WebFoo::assign(const WebFoo& other) { ... }
//
template <typename T>
class WebPrivatePtr {
public:
    WebPrivatePtr() : m_storage(0) { }
    ~WebPrivatePtr()
    {
        // We don't destruct the object pointed by m_ptr here because we don't
        // want to expose destructors of core classes to embedders. We should
        // call reset() manually in destructors of classes with WebPrivatePtr
        // members.
        BLINK_ASSERT(!m_storage);
    }

    bool isNull() const { return !m_storage; }

#if INSIDE_BLINK
    template<typename U>
    WebPrivatePtr(const U& ptr)
        : m_storage(0)
    {
        storage().assign(ptr);
    }

    void reset() { storage().release(); }

    WebPrivatePtr<T>& operator=(const WebPrivatePtr<T>& other)
    {
        storage().assign(other.storage());
        return *this;
    }

    template<typename U>
    WebPrivatePtr<T>& operator=(const U& ptr)
    {
        storage().assign(ptr);
        return *this;
    }

    T* get() const { return storage().get(); }

    T& operator*() const
    {
        ASSERT(m_storage);
        return *get();
    }

    T* operator->() const
    {
        ASSERT(m_storage);
        return get();
    }
#endif

private:
#if INSIDE_BLINK
    PtrStorage<T>& storage() { return PtrStorage<T>::fromSlot(&m_storage); }
    const PtrStorage<T>& storage() const { return PtrStorage<T>::fromSlot(&m_storage); }
#endif

#if !INSIDE_BLINK
    // Disable the assignment operator; we define it above for when
    // INSIDE_BLINK is set, but we need to make sure that it is not
    // used outside there; the compiler-provided version won't handle reference
    // counting properly.
    WebPrivatePtr<T>& operator=(const WebPrivatePtr<T>& other);
#endif
    // Disable the copy constructor; classes that contain a WebPrivatePtr
    // should implement their copy constructor using assign().
    WebPrivatePtr(const WebPrivatePtr<T>&);

    void* m_storage;
};

} // namespace blink

#endif  // SKY_ENGINE_PUBLIC_PLATFORM_WEBPRIVATEPTR_H_
