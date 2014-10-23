// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef HTMLImportTreeRoot_h
#define HTMLImportTreeRoot_h

#include "core/html/imports/HTMLImport.h"
#include "platform/Timer.h"
#include "wtf/PassOwnPtr.h"

namespace blink {

class HTMLImportChild;

class HTMLImportTreeRoot : public HTMLImport {
public:
    static PassOwnPtrWillBeRawPtr<HTMLImportTreeRoot> create(Document*);

    virtual ~HTMLImportTreeRoot();

    // HTMLImport
    virtual Document* document() const OVERRIDE;
    virtual bool isDone() const OVERRIDE;
    virtual void stateWillChange() OVERRIDE;
    virtual void stateDidChange() OVERRIDE;

    void scheduleRecalcState();

    HTMLImportChild* add(PassOwnPtrWillBeRawPtr<HTMLImportChild>);
    HTMLImportChild* find(const KURL&) const;

    virtual void trace(Visitor*) OVERRIDE;

private:
    explicit HTMLImportTreeRoot(Document*);

    void recalcTimerFired(Timer<HTMLImportTreeRoot>*);

    RawPtrWillBeMember<Document> m_document;
    Timer<HTMLImportTreeRoot> m_recalcTimer;

    // List of import which has been loaded or being loaded.
    typedef WillBeHeapVector<OwnPtrWillBeMember<HTMLImportChild> > ImportList;
    ImportList m_imports;
};

DEFINE_TYPE_CASTS(HTMLImportTreeRoot, HTMLImport, import, import->isRoot(), import.isRoot());

}

#endif
