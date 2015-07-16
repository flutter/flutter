// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/environment/environment.h"
#include "mojo/public/interfaces/bindings/tests/test_structs.mojom.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace test {

namespace {

RectPtr CreateRect() {
  RectPtr r = Rect::New();
  r->x = 1;
  r->y = 2;
  r->width = 3;
  r->height = 4;
  return r.Pass();
}

class EqualsTest : public testing::Test {
 public:
  ~EqualsTest() override {}

 private:
  Environment env_;
};
}

TEST_F(EqualsTest, Null) {
  RectPtr r1;
  RectPtr r2;
  EXPECT_TRUE(r1.Equals(r2));
  EXPECT_TRUE(r2.Equals(r1));

  r1 = CreateRect();
  EXPECT_FALSE(r1.Equals(r2));
  EXPECT_FALSE(r2.Equals(r1));
}

TEST_F(EqualsTest, EqualsStruct) {
  RectPtr r1(CreateRect());
  RectPtr r2(r1.Clone());
  EXPECT_TRUE(r1.Equals(r2));
  r2->y = 1;
  EXPECT_FALSE(r1.Equals(r2));
  r2.reset();
  EXPECT_FALSE(r1.Equals(r2));
}

TEST_F(EqualsTest, EqualsStructNested) {
  RectPairPtr p1(RectPair::New());
  p1->first = CreateRect();
  p1->second = CreateRect();
  RectPairPtr p2(p1.Clone());
  EXPECT_TRUE(p1.Equals(p2));
  p2->second->width = 0;
  EXPECT_FALSE(p1.Equals(p2));
  p2->second.reset();
  EXPECT_FALSE(p1.Equals(p2));
}

TEST_F(EqualsTest, EqualsArray) {
  NamedRegionPtr n1(NamedRegion::New());
  n1->name = "n1";
  n1->rects.push_back(CreateRect());
  NamedRegionPtr n2(n1.Clone());
  EXPECT_TRUE(n1.Equals(n2));

  n2->rects.reset();
  EXPECT_FALSE(n1.Equals(n2));
  n2->rects.resize(0);
  EXPECT_FALSE(n1.Equals(n2));

  n2->rects.push_back(CreateRect());
  n2->rects.push_back(CreateRect());
  EXPECT_FALSE(n1.Equals(n2));

  n2->rects.resize(1);
  n2->rects[0]->width = 0;
  EXPECT_FALSE(n1.Equals(n2));

  n2->rects[0] = CreateRect();
  EXPECT_TRUE(n1.Equals(n2));
}

TEST_F(EqualsTest, EqualsMap) {
  auto n1(NamedRegion::New());
  n1->name = "foo";
  n1->rects.push_back(CreateRect());

  Map<std::string, NamedRegionPtr> m1;
  m1.insert("foo", n1.Pass());

  decltype(m1) m2;
  EXPECT_FALSE(m1.Equals(m2));

  m2.insert("bar", m1.at("foo").Clone());
  EXPECT_FALSE(m1.Equals(m2));

  m2 = m1.Clone();
  m2.at("foo")->name = "monkey";
  EXPECT_FALSE(m1.Equals(m2));

  m2 = m1.Clone();
  m2.at("foo")->rects.push_back(Rect::New());
  EXPECT_FALSE(m1.Equals(m2));

  m2.at("foo")->rects.resize(1);
  m2.at("foo")->rects[0]->width = 1;
  EXPECT_FALSE(m1.Equals(m2));

  m2 = m1.Clone();
  EXPECT_TRUE(m1.Equals(m2));
}

}  // test
}  // mojo
