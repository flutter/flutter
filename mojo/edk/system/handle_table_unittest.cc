// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/handle_table.h"

#include "mojo/edk/system/dispatcher.h"
#include "mojo/edk/system/mock_simple_dispatcher.h"
#include "testing/gtest/include/gtest/gtest.h"

using mojo::util::MakeRefCounted;
using mojo::util::RefPtr;

namespace mojo {
namespace system {
namespace {

TEST(HandleTableTest, Basic) {
  HandleTable ht;

  RefPtr<Dispatcher> d = MakeRefCounted<test::MockSimpleDispatcher>();

  MojoHandle h = ht.AddDispatcher(d.get());
  EXPECT_NE(h, MOJO_HANDLE_INVALID);

  // Save the pointer value (without taking a ref), so we can check that we get
  // the same object back.
  Dispatcher* dv = d.get();
  // Reset this, to make sure that the handle table takes a ref.
  d = nullptr;

  EXPECT_EQ(MOJO_RESULT_OK, ht.GetDispatcher(h, &d));
  EXPECT_EQ(d.get(), dv);

  d = nullptr;
  ASSERT_EQ(MOJO_RESULT_OK, ht.GetAndRemoveDispatcher(h, &d));
  ASSERT_EQ(d.get(), dv);

  EXPECT_EQ(MOJO_RESULT_OK, d->Close());

  // We removed |h|, so it should no longer be valid.
  d = nullptr;
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT, ht.GetDispatcher(h, &d));
}

}  // namespace
}  // namespace system
}  // namespace mojo
