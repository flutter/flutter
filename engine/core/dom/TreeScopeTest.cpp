// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/dom/TreeScope.h"

#include <gtest/gtest.h>
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/dom/shadow/ShadowRoot.h"

using namespace blink;

namespace {

TEST(TreeScopeTest, CommonAncestorOfSameTrees)
{
    RefPtr<Document> document = Document::create();
    EXPECT_EQ(document.get(), document->commonAncestorTreeScope(*document));

    RefPtr<Element> html = document->createElement("html", nullAtom, ASSERT_NO_EXCEPTION);
    document->appendChild(html, ASSERT_NO_EXCEPTION);
    RefPtr<ShadowRoot> shadowRoot = html->createShadowRoot(ASSERT_NO_EXCEPTION);
    EXPECT_EQ(shadowRoot.get(), shadowRoot->commonAncestorTreeScope(*shadowRoot));
}

TEST(TreeScopeTest, CommonAncestorOfInclusiveTrees)
{
    //  document
    //     |      : Common ancestor is document.
    // shadowRoot

    RefPtr<Document> document = Document::create();
    RefPtr<Element> html = document->createElement("html", nullAtom, ASSERT_NO_EXCEPTION);
    document->appendChild(html, ASSERT_NO_EXCEPTION);
    RefPtr<ShadowRoot> shadowRoot = html->createShadowRoot(ASSERT_NO_EXCEPTION);

    EXPECT_EQ(document.get(), document->commonAncestorTreeScope(*shadowRoot));
    EXPECT_EQ(document.get(), shadowRoot->commonAncestorTreeScope(*document));
}

TEST(TreeScopeTest, CommonAncestorOfSiblingTrees)
{
    //  document
    //   /    \  : Common ancestor is document.
    //  A      B

    RefPtr<Document> document = Document::create();
    RefPtr<Element> html = document->createElement("html", nullAtom, ASSERT_NO_EXCEPTION);
    document->appendChild(html, ASSERT_NO_EXCEPTION);
    RefPtr<Element> head = document->createElement("head", nullAtom, ASSERT_NO_EXCEPTION);
    html->appendChild(head);
    RefPtr<Element> body = document->createElement("body", nullAtom, ASSERT_NO_EXCEPTION);
    html->appendChild(body);

    RefPtr<ShadowRoot> shadowRootA = head->createShadowRoot(ASSERT_NO_EXCEPTION);
    RefPtr<ShadowRoot> shadowRootB = body->createShadowRoot(ASSERT_NO_EXCEPTION);

    EXPECT_EQ(document.get(), shadowRootA->commonAncestorTreeScope(*shadowRootB));
    EXPECT_EQ(document.get(), shadowRootB->commonAncestorTreeScope(*shadowRootA));
}

TEST(TreeScopeTest, CommonAncestorOfTreesAtDifferentDepths)
{
    //  document
    //    / \    : Common ancestor is document.
    //   Y   B
    //  /
    // A

    RefPtr<Document> document = Document::create();
    RefPtr<Element> html = document->createElement("html", nullAtom, ASSERT_NO_EXCEPTION);
    document->appendChild(html, ASSERT_NO_EXCEPTION);
    RefPtr<Element> head = document->createElement("head", nullAtom, ASSERT_NO_EXCEPTION);
    html->appendChild(head);
    RefPtr<Element> body = document->createElement("body", nullAtom, ASSERT_NO_EXCEPTION);
    html->appendChild(body);

    RefPtr<ShadowRoot> shadowRootY = head->createShadowRoot(ASSERT_NO_EXCEPTION);
    RefPtr<ShadowRoot> shadowRootB = body->createShadowRoot(ASSERT_NO_EXCEPTION);

    RefPtr<Element> divInY = document->createElement("div", nullAtom, ASSERT_NO_EXCEPTION);
    shadowRootY->appendChild(divInY);
    RefPtr<ShadowRoot> shadowRootA = divInY->createShadowRoot(ASSERT_NO_EXCEPTION);

    EXPECT_EQ(document.get(), shadowRootA->commonAncestorTreeScope(*shadowRootB));
    EXPECT_EQ(document.get(), shadowRootB->commonAncestorTreeScope(*shadowRootA));
}

TEST(TreeScopeTest, CommonAncestorOfTreesInDifferentDocuments)
{
    RefPtr<Document> document1 = Document::create();
    RefPtr<Document> document2 = Document::create();
    EXPECT_EQ(0, document1->commonAncestorTreeScope(*document2));
    EXPECT_EQ(0, document2->commonAncestorTreeScope(*document1));
}

} // namespace
