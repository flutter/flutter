/*
 * Copyright (C) 2012 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"

#include "wtf/TreeNode.h"

#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"
#include "wtf/RefPtr.h"
#include <gtest/gtest.h>

namespace {

class TestTree : public RefCounted<TestTree>, public TreeNode<TestTree> {
public:
    static PassRefPtr<TestTree> create() { return adoptRef(new TestTree()); }
};

TEST(TreeNodeTest, AppendChild)
{
    RefPtr<TestTree> root = TestTree::create();
    RefPtr<TestTree> firstChild = TestTree::create();
    RefPtr<TestTree> lastChild = TestTree::create();

    root->appendChild(firstChild.get());
    EXPECT_EQ(root->firstChild(), firstChild.get());
    EXPECT_EQ(root->lastChild(), firstChild.get());
    EXPECT_EQ(firstChild->parent(), root.get());

    root->appendChild(lastChild.get());
    EXPECT_EQ(root->firstChild(), firstChild.get());
    EXPECT_EQ(root->lastChild(), lastChild.get());
    EXPECT_EQ(lastChild->previous(), firstChild.get());
    EXPECT_EQ(firstChild->next(), lastChild.get());
    EXPECT_EQ(lastChild->parent(), root.get());
}

TEST(TreeNodeTest, InsertBefore)
{
    RefPtr<TestTree> root = TestTree::create();
    RefPtr<TestTree> firstChild = TestTree::create();
    RefPtr<TestTree> middleChild = TestTree::create();
    RefPtr<TestTree> lastChild = TestTree::create();

    // Inserting single node
    root->insertBefore(lastChild.get(), 0);
    EXPECT_EQ(lastChild->parent(), root.get());
    EXPECT_EQ(root->firstChild(), lastChild.get());
    EXPECT_EQ(root->lastChild(), lastChild.get());

    // Then prepend
    root->insertBefore(firstChild.get(), lastChild.get());
    EXPECT_EQ(firstChild->parent(), root.get());
    EXPECT_EQ(root->firstChild(), firstChild.get());
    EXPECT_EQ(root->lastChild(), lastChild.get());
    EXPECT_EQ(firstChild->next(), lastChild.get());
    EXPECT_EQ(firstChild.get(), lastChild->previous());

    // Inserting in the middle
    root->insertBefore(middleChild.get(), lastChild.get());
    EXPECT_EQ(middleChild->parent(), root.get());
    EXPECT_EQ(root->firstChild(), firstChild.get());
    EXPECT_EQ(root->lastChild(), lastChild.get());
    EXPECT_EQ(middleChild->previous(), firstChild.get());
    EXPECT_EQ(middleChild->next(), lastChild.get());
    EXPECT_EQ(firstChild->next(), middleChild.get());
    EXPECT_EQ(lastChild->previous(), middleChild.get());

}

TEST(TreeNodeTest, RemoveSingle)
{
    RefPtr<TestTree> root = TestTree::create();
    RefPtr<TestTree> child = TestTree::create();
    RefPtr<TestTree> nullNode;

    root->appendChild(child.get());
    root->removeChild(child.get());
    EXPECT_EQ(child->next(), nullNode.get());
    EXPECT_EQ(child->previous(), nullNode.get());
    EXPECT_EQ(child->parent(), nullNode.get());
    EXPECT_EQ(root->firstChild(), nullNode.get());
    EXPECT_EQ(root->lastChild(), nullNode.get());
}

class Trio {
public:
    Trio()
        : root(TestTree::create())
        , firstChild(TestTree::create())
        , middleChild(TestTree::create())
        , lastChild(TestTree::create())
    {
    }

    void appendChildren()
    {
        root->appendChild(firstChild.get());
        root->appendChild(middleChild.get());
        root->appendChild(lastChild.get());
    }

    RefPtr<TestTree> root;
    RefPtr<TestTree> firstChild;
    RefPtr<TestTree> middleChild;
    RefPtr<TestTree> lastChild;
};

TEST(TreeNodeTest, RemoveMiddle)
{
    Trio trio;
    trio.appendChildren();

    trio.root->removeChild(trio.middleChild.get());
    EXPECT_TRUE(trio.middleChild->orphan());
    EXPECT_EQ(trio.firstChild->next(), trio.lastChild.get());
    EXPECT_EQ(trio.lastChild->previous(), trio.firstChild.get());
    EXPECT_EQ(trio.root->firstChild(), trio.firstChild.get());
    EXPECT_EQ(trio.root->lastChild(), trio.lastChild.get());
}

TEST(TreeNodeTest, RemoveLast)
{
    RefPtr<TestTree> nullNode;
    Trio trio;
    trio.appendChildren();

    trio.root->removeChild(trio.lastChild.get());
    EXPECT_TRUE(trio.lastChild->orphan());
    EXPECT_EQ(trio.middleChild->next(), nullNode.get());
    EXPECT_EQ(trio.root->firstChild(), trio.firstChild.get());
    EXPECT_EQ(trio.root->lastChild(), trio.middleChild.get());
}

TEST(TreeNodeTest, RemoveFirst)
{
    RefPtr<TestTree> nullNode;
    Trio trio;
    trio.appendChildren();

    trio.root->removeChild(trio.firstChild.get());
    EXPECT_TRUE(trio.firstChild->orphan());
    EXPECT_EQ(trio.middleChild->previous(), nullNode.get());
    EXPECT_EQ(trio.root->firstChild(), trio.middleChild.get());
    EXPECT_EQ(trio.root->lastChild(), trio.lastChild.get());
}

TEST(TreeNodeTest, TakeChildrenFrom)
{
    RefPtr<TestTree> newParent = TestTree::create();
    Trio trio;
    trio.appendChildren();

    newParent->takeChildrenFrom(trio.root.get());

    EXPECT_FALSE(trio.root->hasChildren());
    EXPECT_TRUE(newParent->hasChildren());
    EXPECT_EQ(trio.firstChild.get(), newParent->firstChild());
    EXPECT_EQ(trio.middleChild.get(), newParent->firstChild()->next());
    EXPECT_EQ(trio.lastChild.get(), newParent->lastChild());
}

class TrioWithGrandChild : public Trio {
public:
    TrioWithGrandChild()
        : grandChild(TestTree::create())
    {
    }

    void appendChildren()
    {
        Trio::appendChildren();
        middleChild->appendChild(grandChild.get());
    }

    RefPtr<TestTree> grandChild;
};

TEST(TreeNodeTest, TraverseNext)
{
    TrioWithGrandChild trio;
    trio.appendChildren();

    TestTree* order[] = {
        trio.root.get(), trio.firstChild.get(), trio.middleChild.get(),
        trio.grandChild.get(), trio.lastChild.get()
    };

    unsigned orderIndex = 0;
    for (TestTree* node = trio.root.get(); node; node = traverseNext(node), orderIndex++)
        EXPECT_EQ(node, order[orderIndex]);
    EXPECT_EQ(orderIndex, sizeof(order) / sizeof(TestTree*));
}

TEST(TreeNodeTest, TraverseNextPostORder)
{
    TrioWithGrandChild trio;
    trio.appendChildren();


    TestTree* order[] = {
        trio.firstChild.get(),
        trio.grandChild.get(), trio.middleChild.get(), trio.lastChild.get(), trio.root.get()
    };

    unsigned orderIndex = 0;
    for (TestTree* node = traverseFirstPostOrder(trio.root.get()); node; node = traverseNextPostOrder(node), orderIndex++)
        EXPECT_EQ(node, order[orderIndex]);
    EXPECT_EQ(orderIndex, sizeof(order) / sizeof(TestTree*));

}


} // namespace
