// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/move.h"

#include "testing/gtest/include/gtest/gtest.h"

namespace {

class MoveOnly {
  MOVE_ONLY_TYPE_WITH_MOVE_CONSTRUCTOR_FOR_CPP_03(MoveOnly)

 public:
  MoveOnly() {}

  MoveOnly(MoveOnly&& other) {}
  MoveOnly& operator=(MoveOnly&& other) { return *this; }
};

class Container {
 public:
  Container() = default;
  Container(const Container& other) = default;
  Container& operator=(const Container& other) = default;

  Container(Container&& other) { value_ = other.value_.Pass(); }

  Container& operator=(Container&& other) {
    value_ = other.value_.Pass();
    return *this;
  }

 private:
  MoveOnly value_;
};

Container GetContainerRvalue() {
  Container x;
  return x;
}

TEST(MoveTest, CopyableContainerCanBeMoved) {
  // Container should be move-constructible and move-assignable.
  Container y = GetContainerRvalue();
  y = GetContainerRvalue();
}

}  // namespace
