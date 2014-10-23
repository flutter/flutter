// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/dom/TreeScope.h"

#include "core/dom/Document.h"
#include "core/dom/Element.h"
#include "core/dom/shadow/ShadowRoot.h"
#include <gtest/gtest.h>

using namespace blink;

namespace {

TEST(TreeScopeTest, CommonAncestorOfSameTrees)
{
    RefPtrWillBeRawPtr<Document> document = Document::create();
    EXPECT_EQ(document.get(), document->commonAncestorTreeScope(*document));

    RefPtrWillBeRawPtr<Element> html = document->createElement("html", nullAtom, ASSERT_NO_EXCEPTION);
    document->appendChild(html, ASSERT_NO_EXCEPTION);
    RefPtrWillBeRawPtr<ShadowRoot> shadowRoot = html->createShadowRoot(ASSERT_NO_EXCEPTION);
    EXPECT_EQ(shadowRoot.get(), shadowRoot->commonAncestorTreeScope(*shadowRoot));
}

TEST(TreeScopeTest, CommonAncestorOfInclusiveTrees)
{
    //  document
    //     |      : Common ancestor is document.
    // shadowRoot

    RefPtrWillBeRawPtr<Document> document = Document::create();
    RefPtrWillBeRawPtr<Element> html = document->createElement("html", nullAtom, ASSERT_NO_EXCEPTION);
    document->appendChild(html, ASSERT_NO_EXCEPTION);
    RefPtrWillBeRawPtr<ShadowRoot> shadowRoot = html->createShadowRoot(ASSERT_NO_EXCEPTION);

    EXPECT_EQ(document.get(), document->commonAncestorTreeScope(*shadowRoot));
    EXPECT_EQ(document.get(), shadowRoot->commonAncestorTreeScope(*document));
}

TEST(TreeScopeTest, CommonAncestorOfSiblingTrees)
{
    //  document
    //   /    \  : Common ancestor is document.
    //  A      B

    RefPtrWillBeRawPtr<Document> document = Document::create();
    RefPtrWillBeRawPtr<Element> html = document->createElement("html", nullAtom, ASSERT_NO_EXCEPTION);
    document->appendChild(html, ASSERT_NO_EXCEPTION);
    RefPtrWillBeRawPtr<Element> head = document->createElement("head", nullAtom, ASSERT_NO_EXCEPTION);
    html->appendChild(head);
    RefPtrWillBeRawPtr<Element> body = document->createElement("body", nullAtom, ASSERT_NO_EXCEPTION);
    html->appendChild(body);

    RefPtrWillBeRawPtr<ShadowRoot> shadowRootA = head->createShadowRoot(ASSERT_NO_EXCEPTION);
    RefPtrWillBeRawPtr<ShadowRoot> shadowRootB = body->createShadowRoot(ASSERT_NO_EXCEPTION);

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

    RefPtrWillBeRawPtr<Document> document = Document::create();
    RefPtrWillBeRawPtr<Element> html = document->createElement("html", nullAtom, ASSERT_NO_EXCEPTION);
    document->appendChild(html, ASSERT_NO_EXCEPTION);
    RefPtrWillBeRawPtr<Element> head = document->createElement("head", nullAtom, ASSERT_NO_EXCEPTION);
    html->appendChild(head);
    RefPtrWillBeRawPtr<Element> body = document->createElement("body", nullAtom, ASSERT_NO_EXCEPTION);
    html->appendChild(body);

    RefPtrWillBeRawPtr<ShadowRoot> shadowRootY = head->createShadowRoot(ASSERT_NO_EXCEPTION);
    RefPtrWillBeRawPtr<ShadowRoot> shadowRootB = body->createShadowRoot(ASSERT_NO_EXCEPTION);

    RefPtrWillBeRawPtr<Element> divInY = document->createElement("div", nullAtom, ASSERT_NO_EXCEPTION);
    shadowRootY->appendChild(divInY);
    RefPtrWillBeRawPtr<ShadowRoot> shadowRootA = divInY->createShadowRoot(ASSERT_NO_EXCEPTION);

    EXPECT_EQ(document.get(), shadowRootA->commonAncestorTreeScope(*shadowRootB));
    EXPECT_EQ(document.get(), shadowRootB->commonAncestorTreeScope(*shadowRootA));
}

TEST(TreeScopeTest, CommonAncestorOfTreesInDifferentDocuments)
{
    RefPtrWillBeRawPtr<Document> document1 = Document::create();
    RefPtrWillBeRawPtr<Document> document2 = Document::create();
    EXPECT_EQ(0, document1->commonAncestorTreeScope(*document2));
    EXPECT_EQ(0, document2->commonAncestorTreeScope(*document1));
}

} // namespace
