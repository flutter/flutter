/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer
 *    in the documentation and/or other materials provided with the
 *    distribution.
 * 3. Neither the name of Google Inc. nor the names of its contributors
 *    may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
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

#ifndef CustomElementMicrotaskImportStep_h
#define CustomElementMicrotaskImportStep_h

#include "core/dom/custom/CustomElementMicrotaskStep.h"
#include "platform/heap/Handle.h"
#include "wtf/Noncopyable.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefPtr.h"
#include "wtf/WeakPtr.h"

namespace blink {

class CustomElementSyncMicrotaskQueue;
class HTMLImportChild;

// Processes the Custom Elements in an HTML Import. This is a
// composite step which processes the Custom Elements created by
// parsing the import, and its sub-imports.
//
// This step blocks further Custom Element microtask processing if its
// import isn't "ready" (finished parsing and running script.)
class CustomElementMicrotaskImportStep : public CustomElementMicrotaskStep {
    WTF_MAKE_NONCOPYABLE(CustomElementMicrotaskImportStep);
public:
    static PassOwnPtrWillBeRawPtr<CustomElementMicrotaskImportStep> create(HTMLImportChild*);
    virtual ~CustomElementMicrotaskImportStep();

    // API for HTML Imports
    void invalidate();
    void importDidFinishLoading();
#if !ENABLE(OILPAN)
    WeakPtr<CustomElementMicrotaskImportStep> weakPtr() { return m_weakFactory.createWeakPtr(); }
#endif

    virtual void trace(Visitor*) OVERRIDE;

private:
    explicit CustomElementMicrotaskImportStep(HTMLImportChild*);

    void didUpgradeAllCustomElements();
    bool shouldWaitForImport() const;

    // CustomElementMicrotaskStep
    virtual Result process() OVERRIDE FINAL;

#if !defined(NDEBUG)
    virtual void show(unsigned indent) OVERRIDE;
#endif
    WeakPtrWillBeWeakMember<HTMLImportChild> m_import;
#if !ENABLE(OILPAN)
    WeakPtrFactory<CustomElementMicrotaskImportStep> m_weakFactory;
#endif
    RefPtrWillBeMember<CustomElementSyncMicrotaskQueue> m_queue;
};

}

#endif // CustomElementMicrotaskImportStep_h
