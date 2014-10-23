/*
 * Copyright (C) 2008 Apple Inc. All Rights Reserved.
 * Copyright (C) 2013 Google Inc. All Rights Reserved.
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
#ifndef LifecycleNotifier_h
#define LifecycleNotifier_h

#include "platform/LifecycleObserver.h"
#include "wtf/HashSet.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/TemporaryChange.h"

namespace blink {

template<typename T>
class LifecycleNotifier {
public:
    typedef LifecycleObserver<T> Observer;
    typedef T Context;

    static PassOwnPtr<LifecycleNotifier> create(Context* context)
    {
        return adoptPtr(new LifecycleNotifier(context));
    }


    virtual ~LifecycleNotifier();


    // FIXME: this won't need to be virtual anymore.
    virtual void addObserver(Observer*);
    virtual void removeObserver(Observer*);

    bool isIteratingOverObservers() const { return m_iterating != IteratingNone; }

protected:
    explicit LifecycleNotifier(Context* context)
        : m_iterating(IteratingNone)
        , m_context(context)
    {
    }

    Context* context() const { return m_context; }

    enum IterationType {
        IteratingNone,
        IteratingOverAll,
        IteratingOverActiveDOMObjects,
        IteratingOverContextObservers,
        IteratingOverDocumentObservers,
        IteratingOverPageObservers,
        IteratingOverDOMWindowObservers
    };

    IterationType m_iterating;

private:
    typedef HashSet<Observer*> ObserverSet;

    ObserverSet m_observers;
    Context* m_context;
};

template<typename T>
inline LifecycleNotifier<T>::~LifecycleNotifier()
{
    TemporaryChange<IterationType> scope(this->m_iterating, IteratingOverAll);
    for (typename ObserverSet::iterator it = m_observers.begin(); it != m_observers.end(); it = m_observers.begin()) {
        Observer* observer = *it;
        m_observers.remove(observer);
        ASSERT(observer->lifecycleContext() == m_context);
        observer->contextDestroyed();
    }
}

template<typename T>
inline void LifecycleNotifier<T>::addObserver(typename LifecycleNotifier<T>::Observer* observer)
{
    RELEASE_ASSERT(m_iterating != IteratingOverAll);
    m_observers.add(observer);
}

template<typename T>
inline void LifecycleNotifier<T>::removeObserver(typename LifecycleNotifier<T>::Observer* observer)
{
    RELEASE_ASSERT(m_iterating != IteratingOverAll);
    m_observers.remove(observer);
}



} // namespace blink

#endif // LifecycleNotifier_h
