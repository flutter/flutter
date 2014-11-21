// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_HTML_IMPORTS_HTMLIMPORTTREEROOT_H_
#define SKY_ENGINE_CORE_HTML_IMPORTS_HTMLIMPORTTREEROOT_H_

#include "sky/engine/core/html/imports/HTMLImport.h"
#include "sky/engine/platform/Timer.h"
#include "sky/engine/wtf/PassOwnPtr.h"

namespace blink {

class HTMLImportChild;

class HTMLImportTreeRoot : public HTMLImport {
public:
    static PassOwnPtr<HTMLImportTreeRoot> create(Document*);

    virtual ~HTMLImportTreeRoot();

    // HTMLImport
    virtual Document* document() const override;
    virtual bool isDone() const override;
    virtual void stateWillChange() override;
    virtual void stateDidChange() override;

    void scheduleRecalcState();

    HTMLImportChild* add(PassOwnPtr<HTMLImportChild>);
    HTMLImportChild* find(const KURL&) const;

private:
    explicit HTMLImportTreeRoot(Document*);

    void recalcTimerFired(Timer<HTMLImportTreeRoot>*);

    RawPtr<Document> m_document;
    Timer<HTMLImportTreeRoot> m_recalcTimer;

    // List of import which has been loaded or being loaded.
    typedef Vector<OwnPtr<HTMLImportChild> > ImportList;
    ImportList m_imports;
};

DEFINE_TYPE_CASTS(HTMLImportTreeRoot, HTMLImport, import, import->isRoot(), import.isRoot());

}

#endif  // SKY_ENGINE_CORE_HTML_IMPORTS_HTMLIMPORTTREEROOT_H_
