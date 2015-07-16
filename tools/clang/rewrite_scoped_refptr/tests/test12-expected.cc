// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <iterator>
#include <map>
#include <string>

#include "scoped_refptr.h"

struct Foo {
  int dummy;
};

typedef std::map<std::string, scoped_refptr<const Foo> > MyMap;

class MyIter
    : public std::iterator<std::input_iterator_tag, scoped_refptr<const Foo> > {
 public:
  MyIter() {}
  MyIter(const MyIter& other) : it_(other.it_) {}
  explicit MyIter(MyMap::const_iterator it) : it_(it) {}
  MyIter& operator++() {
    ++it_;
    return *this;
  }
  const scoped_refptr<const Foo> operator*() { return it_->second; }
  bool operator!=(const MyIter& other) { return it_ != other.it_; }
  bool operator==(const MyIter& other) { return it_ == other.it_; }

 private:
  MyMap::const_iterator it_;
};

void TestsAScopedRefptr() {
  MyMap map;
  map["foo"] = new Foo;
  map["bar"] = new Foo;
  MyIter my_begin(map.begin());
  MyIter my_end(map.end());
  for (MyIter it = my_begin; it != my_end; ++it) {
    const Foo* item = NULL;
    if (it->get())
      item = it->get();
  }
}
