// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_CONTAINERS_LINKED_LIST_H_
#define BASE_CONTAINERS_LINKED_LIST_H_

#include "base/macros.h"

// Simple LinkedList type. (See the Q&A section to understand how this
// differs from std::list).
//
// To use, start by declaring the class which will be contained in the linked
// list, as extending LinkNode (this gives it next/previous pointers).
//
//   class MyNodeType : public LinkNode<MyNodeType> {
//     ...
//   };
//
// Next, to keep track of the list's head/tail, use a LinkedList instance:
//
//   LinkedList<MyNodeType> list;
//
// To add elements to the list, use any of LinkedList::Append,
// LinkNode::InsertBefore, or LinkNode::InsertAfter:
//
//   LinkNode<MyNodeType>* n1 = ...;
//   LinkNode<MyNodeType>* n2 = ...;
//   LinkNode<MyNodeType>* n3 = ...;
//
//   list.Append(n1);
//   list.Append(n3);
//   n3->InsertBefore(n3);
//
// Lastly, to iterate through the linked list forwards:
//
//   for (LinkNode<MyNodeType>* node = list.head();
//        node != list.end();
//        node = node->next()) {
//     MyNodeType* value = node->value();
//     ...
//   }
//
// Or to iterate the linked list backwards:
//
//   for (LinkNode<MyNodeType>* node = list.tail();
//        node != list.end();
//        node = node->previous()) {
//     MyNodeType* value = node->value();
//     ...
//   }
//
// Questions and Answers:
//
// Q. Should I use std::list or base::LinkedList?
//
// A. The main reason to use base::LinkedList over std::list is
//    performance. If you don't care about the performance differences
//    then use an STL container, as it makes for better code readability.
//
//    Comparing the performance of base::LinkedList<T> to std::list<T*>:
//
//    * Erasing an element of type T* from base::LinkedList<T> is
//      an O(1) operation. Whereas for std::list<T*> it is O(n).
//      That is because with std::list<T*> you must obtain an
//      iterator to the T* element before you can call erase(iterator).
//
//    * Insertion operations with base::LinkedList<T> never require
//      heap allocations.
//
// Q. How does base::LinkedList implementation differ from std::list?
//
// A. Doubly-linked lists are made up of nodes that contain "next" and
//    "previous" pointers that reference other nodes in the list.
//
//    With base::LinkedList<T>, the type being inserted already reserves
//    space for the "next" and "previous" pointers (base::LinkNode<T>*).
//    Whereas with std::list<T> the type can be anything, so the implementation
//    needs to glue on the "next" and "previous" pointers using
//    some internal node type.

namespace base {

template <typename T>
class LinkNode {
 public:
  LinkNode() : previous_(NULL), next_(NULL) {}
  LinkNode(LinkNode<T>* previous, LinkNode<T>* next)
      : previous_(previous), next_(next) {}

  // Insert |this| into the linked list, before |e|.
  void InsertBefore(LinkNode<T>* e) {
    this->next_ = e;
    this->previous_ = e->previous_;
    e->previous_->next_ = this;
    e->previous_ = this;
  }

  // Insert |this| into the linked list, after |e|.
  void InsertAfter(LinkNode<T>* e) {
    this->next_ = e->next_;
    this->previous_ = e;
    e->next_->previous_ = this;
    e->next_ = this;
  }

  // Remove |this| from the linked list.
  void RemoveFromList() {
    this->previous_->next_ = this->next_;
    this->next_->previous_ = this->previous_;
    // next() and previous() return non-NULL if and only this node is not in any
    // list.
    this->next_ = NULL;
    this->previous_ = NULL;
  }

  LinkNode<T>* previous() const {
    return previous_;
  }

  LinkNode<T>* next() const {
    return next_;
  }

  // Cast from the node-type to the value type.
  const T* value() const {
    return static_cast<const T*>(this);
  }

  T* value() {
    return static_cast<T*>(this);
  }

 private:
  LinkNode<T>* previous_;
  LinkNode<T>* next_;

  DISALLOW_COPY_AND_ASSIGN(LinkNode);
};

template <typename T>
class LinkedList {
 public:
  // The "root" node is self-referential, and forms the basis of a circular
  // list (root_.next() will point back to the start of the list,
  // and root_->previous() wraps around to the end of the list).
  LinkedList() : root_(&root_, &root_) {}

  // Appends |e| to the end of the linked list.
  void Append(LinkNode<T>* e) {
    e->InsertBefore(&root_);
  }

  LinkNode<T>* head() const {
    return root_.next();
  }

  LinkNode<T>* tail() const {
    return root_.previous();
  }

  const LinkNode<T>* end() const {
    return &root_;
  }

  bool empty() const { return head() == end(); }

 private:
  LinkNode<T> root_;

  DISALLOW_COPY_AND_ASSIGN(LinkedList);
};

}  // namespace base

#endif  // BASE_CONTAINERS_LINKED_LIST_H_
