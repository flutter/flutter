// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IncrementLoadEventDelayCount_h
#define IncrementLoadEventDelayCount_h

#include "sky/engine/wtf/Noncopyable.h"
#include "sky/engine/wtf/PassOwnPtr.h"
#include "sky/engine/wtf/RefPtr.h"

namespace blink {

class Document;

// A helper class that will increment a document's loadEventDelayCount on
// contruction and decrement it on destruction (semantics similar to RefPtr).
class IncrementLoadEventDelayCount {
    WTF_MAKE_NONCOPYABLE(IncrementLoadEventDelayCount);

public:
    static PassOwnPtr<IncrementLoadEventDelayCount> create(Document&);
    ~IncrementLoadEventDelayCount();

    // Increments the new document's count and decrements the old count.
    void documentChanged(Document& newDocument);

private:
    IncrementLoadEventDelayCount(Document&);
    RefPtr<Document> m_document;
};
}

#endif
