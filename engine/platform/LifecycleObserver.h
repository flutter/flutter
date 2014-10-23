/*
 * Copyright (C) 2008 Apple Inc. All Rights Reserved.
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

#ifndef LifecycleObserver_h
#define LifecycleObserver_h

#include "wtf/Assertions.h"

namespace blink {

template<typename T>
class LifecycleObserver {
public:
    typedef T Context;

    enum Type {
        ActiveDOMObjectType,
        DocumentLifecycleObserverType,
        GenericType,
        PageLifecycleObserverType,
        DOMWindowLifecycleObserverType
    };

    explicit LifecycleObserver(Context* context, Type type = GenericType)
        : m_lifecycleContext(0)
        , m_observerType(type)
    {
        observeContext(context);
    }

    virtual ~LifecycleObserver()
    {
        observeContext(0);
    }

    virtual void contextDestroyed() { m_lifecycleContext = 0; }


    Context* lifecycleContext() const { return m_lifecycleContext; }
    Type observerType() const { return m_observerType; }

protected:
    void observeContext(Context*);

    Context* m_lifecycleContext;
    Type m_observerType;
};

//
// These functions should be specialized for each LifecycleObserver instances.
//
template<typename T> void observerContext(T*, LifecycleObserver<T>*) { ASSERT_NOT_REACHED(); }
template<typename T> void unobserverContext(T*, LifecycleObserver<T>*) { ASSERT_NOT_REACHED(); }


template<typename T>
inline void LifecycleObserver<T>::observeContext(typename LifecycleObserver<T>::Context* context)
{
    if (m_lifecycleContext)
        unobserverContext(m_lifecycleContext, this);

    m_lifecycleContext = context;

    if (m_lifecycleContext)
        observerContext(m_lifecycleContext, this);
}

} // namespace blink

#endif // LifecycleObserver_h
