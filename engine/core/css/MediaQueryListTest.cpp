// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/css/MediaQueryList.h"

#include <gtest/gtest.h>
#include "sky/engine/core/css/MediaList.h"
#include "sky/engine/core/css/MediaQueryListListener.h"
#include "sky/engine/core/css/MediaQueryMatcher.h"
#include "sky/engine/core/dom/Document.h"

namespace {

class TestListener : public blink::MediaQueryListListener {
public:
    virtual void notifyMediaQueryChanged() override { }
};

}

namespace blink {

TEST(MediaQueryListTest, CrashInStop)
{
    RefPtr<Document> document = Document::create();
    RefPtr<MediaQueryList> list = MediaQueryList::create(document.get(), MediaQueryMatcher::create(*document), MediaQuerySet::create());
    list->addListener(adoptRef(new TestListener()));
    list->stop();
    // This test passes if it's not crashed.
}

}
