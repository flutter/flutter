/*
 * Copyright (C) 2013 Google, Inc. All Rights Reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef WTF_WeakPtr_h
#define WTF_WeakPtr_h

#include "wtf/Noncopyable.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefPtr.h"
#include "wtf/ThreadSafeRefCounted.h"
#include "wtf/Threading.h"

namespace WTF {

template<typename T>
class WeakReference : public ThreadSafeRefCounted<WeakReference<T> > {
    WTF_MAKE_NONCOPYABLE(WeakReference<T>);
    WTF_MAKE_FAST_ALLOCATED;
public:
    static PassRefPtr<WeakReference<T> > create(T* ptr) { return adoptRef(new WeakReference(ptr)); }
    static PassRefPtr<WeakReference<T> > createUnbound() { return adoptRef(new WeakReference()); }

    T* get() const
    {
        ASSERT(m_boundThread == currentThread());
        return m_ptr;
    }

    void clear()
    {
        ASSERT(m_boundThread == currentThread());
        m_ptr = 0;
    }

    void bindTo(T* ptr)
    {
        ASSERT(!m_ptr);
#if ENABLE(ASSERT)
        m_boundThread = currentThread();
#endif
        m_ptr = ptr;
    }

private:
    WeakReference() : m_ptr(0) { }

    explicit WeakReference(T* ptr)
        : m_ptr(ptr)
#if ENABLE(ASSERT)
        , m_boundThread(currentThread())
#endif
    {
    }

    T* m_ptr;
#if ENABLE(ASSERT)
    ThreadIdentifier m_boundThread;
#endif
};

template<typename T>
class WeakPtr {
    WTF_MAKE_FAST_ALLOCATED;
public:
    WeakPtr() { }
    WeakPtr(std::nullptr_t) { }
    WeakPtr(PassRefPtr<WeakReference<T> > ref) : m_ref(ref) { }

    T* get() const { return m_ref ? m_ref->get() : 0; }
    void clear() { m_ref.clear(); }

    T* operator->() const
    {
        ASSERT(get());
        return get();
    }

    typedef RefPtr<WeakReference<T> > (WeakPtr::*UnspecifiedBoolType);
    operator UnspecifiedBoolType() const { return get() ? &WeakPtr::m_ref : 0; }

private:
    RefPtr<WeakReference<T> > m_ref;
};

template<typename T, typename U> inline bool operator==(const WeakPtr<T>& a, const WeakPtr<U>& b)
{
    return a.get() == b.get();
}

template<typename T, typename U> inline bool operator!=(const WeakPtr<T>& a, const WeakPtr<U>& b)
{
    return a.get() != b.get();
}

template<typename T>
class WeakPtrFactory {
    WTF_MAKE_NONCOPYABLE(WeakPtrFactory<T>);
    WTF_MAKE_FAST_ALLOCATED;
public:
    explicit WeakPtrFactory(T* ptr) : m_ref(WeakReference<T>::create(ptr)) { }

    WeakPtrFactory(PassRefPtr<WeakReference<T> > ref, T* ptr)
        : m_ref(ref)
    {
        m_ref->bindTo(ptr);
    }

    ~WeakPtrFactory() { m_ref->clear(); }

    // We should consider having createWeakPtr populate m_ref the first time createWeakPtr is called.
    WeakPtr<T> createWeakPtr() { return WeakPtr<T>(m_ref); }

    void revokeAll()
    {
        T* ptr = m_ref->get();
        m_ref->clear();
        // We create a new WeakReference so that future calls to createWeakPtr() create nonzero WeakPtrs.
        m_ref = WeakReference<T>::create(ptr);
    }

private:
    RefPtr<WeakReference<T> > m_ref;
};

} // namespace WTF

using WTF::WeakPtr;
using WTF::WeakPtrFactory;
using WTF::WeakReference;

#endif
