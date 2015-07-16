// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/basictypes.h"
#include "base/containers/linked_list.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace {

class Node : public LinkNode<Node> {
 public:
  explicit Node(int id) : id_(id) {}

  int id() const { return id_; }

 private:
  int id_;
};

class MultipleInheritanceNodeBase {
 public:
  MultipleInheritanceNodeBase() : field_taking_up_space_(0) {}
  int field_taking_up_space_;
};

class MultipleInheritanceNode : public MultipleInheritanceNodeBase,
                                public LinkNode<MultipleInheritanceNode> {
 public:
  MultipleInheritanceNode() {}
};

// Checks that when iterating |list| (either from head to tail, or from
// tail to head, as determined by |forward|), we get back |node_ids|,
// which is an array of size |num_nodes|.
void ExpectListContentsForDirection(const LinkedList<Node>& list,
  int num_nodes, const int* node_ids, bool forward) {
  int i = 0;
  for (const LinkNode<Node>* node = (forward ? list.head() : list.tail());
       node != list.end();
       node = (forward ? node->next() : node->previous())) {
    ASSERT_LT(i, num_nodes);
    int index_of_id = forward ? i : num_nodes - i - 1;
    EXPECT_EQ(node_ids[index_of_id], node->value()->id());
    ++i;
  }
  EXPECT_EQ(num_nodes, i);
}

void ExpectListContents(const LinkedList<Node>& list,
                        int num_nodes,
                        const int* node_ids) {
  {
    SCOPED_TRACE("Iterating forward (from head to tail)");
    ExpectListContentsForDirection(list, num_nodes, node_ids, true);
  }
  {
    SCOPED_TRACE("Iterating backward (from tail to head)");
    ExpectListContentsForDirection(list, num_nodes, node_ids, false);
  }
}

TEST(LinkedList, Empty) {
  LinkedList<Node> list;
  EXPECT_EQ(list.end(), list.head());
  EXPECT_EQ(list.end(), list.tail());
  ExpectListContents(list, 0, NULL);
}

TEST(LinkedList, Append) {
  LinkedList<Node> list;
  ExpectListContents(list, 0, NULL);

  Node n1(1);
  list.Append(&n1);

  EXPECT_EQ(&n1, list.head());
  EXPECT_EQ(&n1, list.tail());
  {
    const int expected[] = {1};
    ExpectListContents(list, arraysize(expected), expected);
  }

  Node n2(2);
  list.Append(&n2);

  EXPECT_EQ(&n1, list.head());
  EXPECT_EQ(&n2, list.tail());
  {
    const int expected[] = {1, 2};
    ExpectListContents(list, arraysize(expected), expected);
  }

  Node n3(3);
  list.Append(&n3);

  EXPECT_EQ(&n1, list.head());
  EXPECT_EQ(&n3, list.tail());
  {
    const int expected[] = {1, 2, 3};
    ExpectListContents(list, arraysize(expected), expected);
  }
}

TEST(LinkedList, RemoveFromList) {
  LinkedList<Node> list;

  Node n1(1);
  Node n2(2);
  Node n3(3);
  Node n4(4);
  Node n5(5);

  list.Append(&n1);
  list.Append(&n2);
  list.Append(&n3);
  list.Append(&n4);
  list.Append(&n5);

  EXPECT_EQ(&n1, list.head());
  EXPECT_EQ(&n5, list.tail());
  {
    const int expected[] = {1, 2, 3, 4, 5};
    ExpectListContents(list, arraysize(expected), expected);
  }

  // Remove from the middle.
  n3.RemoveFromList();

  EXPECT_EQ(&n1, list.head());
  EXPECT_EQ(&n5, list.tail());
  {
    const int expected[] = {1, 2, 4, 5};
    ExpectListContents(list, arraysize(expected), expected);
  }

  // Remove from the tail.
  n5.RemoveFromList();

  EXPECT_EQ(&n1, list.head());
  EXPECT_EQ(&n4, list.tail());
  {
    const int expected[] = {1, 2, 4};
    ExpectListContents(list, arraysize(expected), expected);
  }

  // Remove from the head.
  n1.RemoveFromList();

  EXPECT_EQ(&n2, list.head());
  EXPECT_EQ(&n4, list.tail());
  {
    const int expected[] = {2, 4};
    ExpectListContents(list, arraysize(expected), expected);
  }

  // Empty the list.
  n2.RemoveFromList();
  n4.RemoveFromList();

  ExpectListContents(list, 0, NULL);
  EXPECT_EQ(list.end(), list.head());
  EXPECT_EQ(list.end(), list.tail());

  // Fill the list once again.
  list.Append(&n1);
  list.Append(&n2);
  list.Append(&n3);
  list.Append(&n4);
  list.Append(&n5);

  EXPECT_EQ(&n1, list.head());
  EXPECT_EQ(&n5, list.tail());
  {
    const int expected[] = {1, 2, 3, 4, 5};
    ExpectListContents(list, arraysize(expected), expected);
  }
}

TEST(LinkedList, InsertBefore) {
  LinkedList<Node> list;

  Node n1(1);
  Node n2(2);
  Node n3(3);
  Node n4(4);

  list.Append(&n1);
  list.Append(&n2);

  EXPECT_EQ(&n1, list.head());
  EXPECT_EQ(&n2, list.tail());
  {
    const int expected[] = {1, 2};
    ExpectListContents(list, arraysize(expected), expected);
  }

  n3.InsertBefore(&n2);

  EXPECT_EQ(&n1, list.head());
  EXPECT_EQ(&n2, list.tail());
  {
    const int expected[] = {1, 3, 2};
    ExpectListContents(list, arraysize(expected), expected);
  }

  n4.InsertBefore(&n1);

  EXPECT_EQ(&n4, list.head());
  EXPECT_EQ(&n2, list.tail());
  {
    const int expected[] = {4, 1, 3, 2};
    ExpectListContents(list, arraysize(expected), expected);
  }
}

TEST(LinkedList, InsertAfter) {
  LinkedList<Node> list;

  Node n1(1);
  Node n2(2);
  Node n3(3);
  Node n4(4);

  list.Append(&n1);
  list.Append(&n2);

  EXPECT_EQ(&n1, list.head());
  EXPECT_EQ(&n2, list.tail());
  {
    const int expected[] = {1, 2};
    ExpectListContents(list, arraysize(expected), expected);
  }

  n3.InsertAfter(&n2);

  EXPECT_EQ(&n1, list.head());
  EXPECT_EQ(&n3, list.tail());
  {
    const int expected[] = {1, 2, 3};
    ExpectListContents(list, arraysize(expected), expected);
  }

  n4.InsertAfter(&n1);

  EXPECT_EQ(&n1, list.head());
  EXPECT_EQ(&n3, list.tail());
  {
    const int expected[] = {1, 4, 2, 3};
    ExpectListContents(list, arraysize(expected), expected);
  }
}

TEST(LinkedList, MultipleInheritanceNode) {
  MultipleInheritanceNode node;
  EXPECT_EQ(&node, node.value());
}

TEST(LinkedList, EmptyListIsEmpty) {
  LinkedList<Node> list;
  EXPECT_TRUE(list.empty());
}

TEST(LinkedList, NonEmptyListIsNotEmpty) {
  LinkedList<Node> list;

  Node n(1);
  list.Append(&n);

  EXPECT_FALSE(list.empty());
}

TEST(LinkedList, EmptiedListIsEmptyAgain) {
  LinkedList<Node> list;

  Node n(1);
  list.Append(&n);
  n.RemoveFromList();

  EXPECT_TRUE(list.empty());
}

TEST(LinkedList, NodesCanBeReused) {
  LinkedList<Node> list1;
  LinkedList<Node> list2;

  Node n(1);
  list1.Append(&n);
  n.RemoveFromList();
  list2.Append(&n);

  EXPECT_EQ(list2.head()->value(), &n);
}

TEST(LinkedList, RemovedNodeHasNullNextPrevious) {
  LinkedList<Node> list;

  Node n(1);
  list.Append(&n);
  n.RemoveFromList();

  EXPECT_EQ(NULL, n.next());
  EXPECT_EQ(NULL, n.previous());
}

}  // namespace
}  // namespace base
