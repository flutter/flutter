// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/dom/IncrementLoadEventDelayCount.h"

#include "core/dom/Document.h"

namespace blink {

PassOwnPtr<IncrementLoadEventDelayCount> IncrementLoadEventDelayCount::create(Document& document)
{
    return adoptPtr(new IncrementLoadEventDelayCount(document));
}

IncrementLoadEventDelayCount::IncrementLoadEventDelayCount(Document& document)
    : m_document(&document)
{
    document.incrementLoadEventDelayCount();
}

IncrementLoadEventDelayCount::~IncrementLoadEventDelayCount()
{
    m_document->decrementLoadEventDelayCount();
}

void IncrementLoadEventDelayCount::documentChanged(Document& newDocument)
{
    newDocument.incrementLoadEventDelayCount();
    m_document->decrementLoadEventDelayCount();
    m_document = &newDocument;
}
}
