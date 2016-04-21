// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/handle.h"

#include <utility>

#include "mojo/edk/system/mock_simple_dispatcher.h"
#include "testing/gtest/include/gtest/gtest.h"

using mojo::util::MakeRefCounted;

namespace mojo {
namespace system {
namespace {

TEST(HandleTest, Basic) {
  // Not much to do, except to test constructors/assignment. Half of the point
  // of the testing is to verify that things compile and there are no errant
  // assertions and such.

  // "Null" |Handle|.
  {
    Handle h1;
    EXPECT_FALSE(h1);
    EXPECT_FALSE(h1.dispatcher);

    // Copy construction.
    Handle h2(h1);
    EXPECT_FALSE(h1);
    EXPECT_FALSE(h1.dispatcher);
    EXPECT_FALSE(h2);
    EXPECT_FALSE(h2.dispatcher);

    // Move construction.
    Handle h3(std::move(h2));
    EXPECT_FALSE(h2);
    EXPECT_FALSE(h2.dispatcher);
    EXPECT_FALSE(h3);
    EXPECT_FALSE(h3.dispatcher);

    // Copy assignment.
    h1 = h3;
    EXPECT_FALSE(h1);
    EXPECT_FALSE(h1.dispatcher);
    EXPECT_FALSE(h3);
    EXPECT_FALSE(h3.dispatcher);

    // Move assignment.
    h2 = std::move(h1);
    EXPECT_FALSE(h1);
    EXPECT_FALSE(h1.dispatcher);
    EXPECT_FALSE(h2);
    EXPECT_FALSE(h2.dispatcher);
  }

  // "Non-null" |Handle|.
  {
    auto d = MakeRefCounted<test::MockSimpleDispatcher>();

    Handle h1(d.Clone(), MOJO_HANDLE_RIGHT_READ);
    EXPECT_TRUE(h1);
    EXPECT_EQ(d, h1.dispatcher);
    EXPECT_EQ(MOJO_HANDLE_RIGHT_READ, h1.rights);

    // Copy construction.
    Handle h2(h1);
    EXPECT_TRUE(h1);
    EXPECT_EQ(d, h1.dispatcher);
    EXPECT_EQ(MOJO_HANDLE_RIGHT_READ, h1.rights);
    EXPECT_TRUE(h2);
    EXPECT_EQ(d, h2.dispatcher);
    EXPECT_EQ(MOJO_HANDLE_RIGHT_READ, h2.rights);

    // Move construction.
    Handle h3(std::move(h2));
    EXPECT_FALSE(h2);
    EXPECT_FALSE(h2.dispatcher);
    EXPECT_TRUE(h3);
    EXPECT_EQ(d, h3.dispatcher);
    EXPECT_EQ(MOJO_HANDLE_RIGHT_READ, h3.rights);

    // Copy assignment.
    h1 = h3;
    EXPECT_TRUE(h1);
    EXPECT_EQ(d, h1.dispatcher);
    EXPECT_EQ(MOJO_HANDLE_RIGHT_READ, h1.rights);
    EXPECT_TRUE(h3);
    EXPECT_EQ(d, h3.dispatcher);
    EXPECT_EQ(MOJO_HANDLE_RIGHT_READ, h3.rights);

    // Move assignment.
    h2 = std::move(h1);
    EXPECT_FALSE(h1);
    EXPECT_FALSE(h1.dispatcher);
    EXPECT_TRUE(h2);
    EXPECT_EQ(d, h2.dispatcher);
    EXPECT_EQ(MOJO_HANDLE_RIGHT_READ, h2.rights);

    // Copy assignment from "null".
    Handle h4;
    h3 = h4;
    EXPECT_FALSE(h3);
    EXPECT_FALSE(h3.dispatcher);

    // Move assignment from "null".
    Handle h5;
    h2 = std::move(h5);
    EXPECT_FALSE(h2);
    EXPECT_FALSE(h2.dispatcher);

    EXPECT_EQ(MOJO_RESULT_OK, d->Close());
  }
}

}  // namespace
}  // namespace system
}  // namespace mojo
