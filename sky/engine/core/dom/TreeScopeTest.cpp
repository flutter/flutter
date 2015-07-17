// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/dom/TreeScope.h"

#include <gtest/gtest.h>
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Element.h"

using namespace blink;

namespace {

TEST(TreeScopeTest, CommonAncestorOfSameTrees)
{
    RefPtr<Document> document = Document::create();
    EXPECT_EQ(document.get(), document->commonAncestorTreeScope(*document));

    RefPtr<Element> html = document->createElement("html", nullAtom, ASSERT_NO_EXCEPTION);
    document->appendChild(html, ASSERT_NO_EXCEPTION);
}

TEST(TreeScopeTest, CommonAncestorOfTreesInDifferentDocuments)
{
    RefPtr<Document> document1 = Document::create();
    RefPtr<Document> document2 = Document::create();
    EXPECT_EQ(0, document1->commonAncestorTreeScope(*document2));
    EXPECT_EQ(0, document2->commonAncestorTreeScope(*document1));
}

} // namespace
