// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/css/MediaQueryList.h"

#include "core/css/MediaList.h"
#include "core/css/MediaQueryListListener.h"
#include "core/css/MediaQueryMatcher.h"
#include "core/dom/Document.h"
#include <gtest/gtest.h>

namespace {

class TestListener : public blink::MediaQueryListListener {
public:
    virtual void notifyMediaQueryChanged() override { }
};

}

namespace blink {

TEST(MediaQueryListTest, CrashInStop)
{
    RefPtrWillBeRawPtr<Document> document = Document::create();
    RefPtrWillBeRawPtr<MediaQueryList> list = MediaQueryList::create(document.get(), MediaQueryMatcher::create(*document), MediaQuerySet::create());
    list->addListener(adoptRefWillBeNoop(new TestListener()));
    list->stop();
    // This test passes if it's not crashed.
}

}
