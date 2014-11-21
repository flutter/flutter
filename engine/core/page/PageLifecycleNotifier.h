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

#ifndef SKY_ENGINE_CORE_PAGE_PAGELIFECYCLENOTIFIER_H_
#define SKY_ENGINE_CORE_PAGE_PAGELIFECYCLENOTIFIER_H_

#include "sky/engine/core/page/PageLifecycleObserver.h"
#include "sky/engine/platform/LifecycleNotifier.h"
#include "sky/engine/wtf/PassOwnPtr.h"
#include "sky/engine/wtf/TemporaryChange.h"

namespace blink {

class Page;
class LocalFrame;

class PageLifecycleNotifier final : public LifecycleNotifier<Page> {
public:
    static PassOwnPtr<PageLifecycleNotifier> create(Page*);

    void notifyPageVisibilityChanged();
    void notifyDidCommitLoad(LocalFrame*);

    virtual void addObserver(Observer*) override;
    virtual void removeObserver(Observer*) override;

private:
    explicit PageLifecycleNotifier(Page*);

    typedef HashSet<PageLifecycleObserver*> PageObserverSet;
    PageObserverSet m_pageObservers;
};

inline PassOwnPtr<PageLifecycleNotifier> PageLifecycleNotifier::create(Page* context)
{
    return adoptPtr(new PageLifecycleNotifier(context));
}

inline void PageLifecycleNotifier::notifyPageVisibilityChanged()
{
    TemporaryChange<IterationType> scope(this->m_iterating, IteratingOverPageObservers);
    for (PageObserverSet::iterator it = m_pageObservers.begin(); it != m_pageObservers.end(); ++it)
        (*it)->pageVisibilityChanged();
}

inline void PageLifecycleNotifier::notifyDidCommitLoad(LocalFrame* frame)
{
    TemporaryChange<IterationType> scope(this->m_iterating, IteratingOverPageObservers);
    for (PageObserverSet::iterator it = m_pageObservers.begin(); it != m_pageObservers.end(); ++it)
        (*it)->didCommitLoad(frame);
}

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAGE_PAGELIFECYCLENOTIFIER_H_
