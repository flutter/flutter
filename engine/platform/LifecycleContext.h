
/*
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

#ifndef LifecycleContext_h
#define LifecycleContext_h

#include "platform/LifecycleNotifier.h"
#include "platform/LifecycleObserver.h"
#include "wtf/HashSet.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"

namespace blink {

class Visitor;

template <typename T>
class LifecycleContext {
public:
    typedef LifecycleNotifier<T> Notifier;
    typedef LifecycleObserver<T> Observer;

    LifecycleContext() { }
    virtual ~LifecycleContext() { }

    virtual bool isContextThread() const { return true; }

    // Called from the constructor of observers.
    void wasObservedBy(Observer*);

    // Called from the destructor of observers.
    void wasUnobservedBy(Observer*);

    virtual void trace(Visitor*) { }

protected:
    Notifier& lifecycleNotifier();

private:
    PassOwnPtr<Notifier> createLifecycleNotifier();

    OwnPtr<Notifier> m_lifecycleNotifier;
};

template<typename T>
inline void LifecycleContext<T>::wasObservedBy(typename LifecycleContext<T>::Observer* observer)
{
    ASSERT(isContextThread());
    lifecycleNotifier().addObserver(observer);
}

template<typename T>
inline void LifecycleContext<T>::wasUnobservedBy(typename LifecycleContext<T>::Observer* observer)
{
    ASSERT(isContextThread());
    lifecycleNotifier().removeObserver(observer);
}

template<typename T>
inline typename LifecycleContext<T>::Notifier& LifecycleContext<T>::lifecycleNotifier()
{
    if (!m_lifecycleNotifier)
        m_lifecycleNotifier = static_cast<T*>(this)->createLifecycleNotifier();
    return *m_lifecycleNotifier;
}

template<typename T>
inline PassOwnPtr<typename LifecycleContext<T>::Notifier> LifecycleContext<T>::createLifecycleNotifier()
{
    return LifecycleContext<T>::Notifier::create(static_cast<T*>(this));
}

} // namespace blink

#endif // LifecycleContext_h
