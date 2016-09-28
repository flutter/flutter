// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/handle_table.h"

#include <vector>

#include "mojo/edk/system/dispatcher.h"
#include "mojo/edk/system/handle.h"
#include "mojo/edk/system/mock_simple_dispatcher.h"
#include "testing/gtest/include/gtest/gtest.h"

using mojo::util::MakeRefCounted;
using mojo::util::RefPtr;

namespace mojo {
namespace system {
namespace {

TEST(HandleTableTest, Basic) {
  HandleTable ht(1000u);

  Handle h(MakeRefCounted<test::MockSimpleDispatcher>(),
           MOJO_HANDLE_RIGHT_TRANSFER | MOJO_HANDLE_RIGHT_READ);

  MojoHandle hv = ht.AddHandle(h.Clone());
  ASSERT_NE(hv, MOJO_HANDLE_INVALID);

  // Save the pointer value (without taking a ref), so we can check that we get
  // the same object back.
  Dispatcher* dv = h.dispatcher.get();
  // Reset this, to make sure that the handle table takes a ref.
  h.reset();

  EXPECT_EQ(MOJO_RESULT_OK, ht.GetHandle(hv, &h));
  EXPECT_EQ(dv, h.dispatcher.get());
  EXPECT_EQ(MOJO_HANDLE_RIGHT_TRANSFER | MOJO_HANDLE_RIGHT_READ, h.rights);

  h.reset();
  ASSERT_EQ(MOJO_RESULT_OK, ht.GetAndRemoveHandle(hv, &h));
  ASSERT_EQ(dv, h.dispatcher.get());
  EXPECT_EQ(MOJO_HANDLE_RIGHT_TRANSFER | MOJO_HANDLE_RIGHT_READ, h.rights);

  EXPECT_EQ(MOJO_RESULT_OK, h.dispatcher->Close());

  // We removed |hv|, so it should no longer be valid.
  h.reset();
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT, ht.GetHandle(hv, &h));
}

TEST(HandleTableTest, AddHandlePair) {
  HandleTable ht(1000u);

  Handle h1(MakeRefCounted<test::MockSimpleDispatcher>(),
            MOJO_HANDLE_RIGHT_NONE);
  Handle h2(MakeRefCounted<test::MockSimpleDispatcher>(),
            MOJO_HANDLE_RIGHT_DUPLICATE);

  auto hp = ht.AddHandlePair(h1.Clone(), h2.Clone());
  ASSERT_NE(hp.first, MOJO_HANDLE_INVALID);
  ASSERT_NE(hp.second, MOJO_HANDLE_INVALID);
  ASSERT_NE(hp.first, hp.second);

  Handle h;
  ASSERT_EQ(MOJO_RESULT_OK, ht.GetAndRemoveHandle(hp.first, &h));
  ASSERT_EQ(h1, h);

  h.reset();
  ASSERT_EQ(MOJO_RESULT_OK, ht.GetAndRemoveHandle(hp.second, &h));
  ASSERT_EQ(h2, h);

  EXPECT_EQ(MOJO_RESULT_OK, h1.dispatcher->Close());
  EXPECT_EQ(MOJO_RESULT_OK, h2.dispatcher->Close());
}

TEST(HandleTableTest, AddHandleTooMany) {
  HandleTable ht(2u);

  Handle h1(MakeRefCounted<test::MockSimpleDispatcher>(),
            MOJO_HANDLE_RIGHT_NONE);
  Handle h2(MakeRefCounted<test::MockSimpleDispatcher>(),
            MOJO_HANDLE_RIGHT_DUPLICATE);
  Handle h3(MakeRefCounted<test::MockSimpleDispatcher>(),
            MOJO_HANDLE_RIGHT_TRANSFER);

  MojoHandle hv1 = ht.AddHandle(h1.Clone());
  ASSERT_NE(hv1, MOJO_HANDLE_INVALID);

  MojoHandle hv2 = ht.AddHandle(h2.Clone());
  ASSERT_NE(hv2, MOJO_HANDLE_INVALID);
  EXPECT_NE(hv2, hv1);

  // Table should be full; adding |h3| should fail.
  EXPECT_EQ(MOJO_HANDLE_INVALID, ht.AddHandle(h3.Clone()));

  // Remove |hv2|/|h2|.
  Handle h;
  ASSERT_EQ(MOJO_RESULT_OK, ht.GetAndRemoveHandle(hv2, &h));
  ASSERT_EQ(h2, h);

  // Now adding |h3| should succeed.
  MojoHandle hv3 = ht.AddHandle(h3.Clone());
  ASSERT_NE(hv3, MOJO_HANDLE_INVALID);
  EXPECT_NE(hv3, hv1);
  // Note: |hv3| may be equal to |hv2| (handle values may be reused).

  h.reset();
  ASSERT_EQ(MOJO_RESULT_OK, ht.GetAndRemoveHandle(hv1, &h));
  ASSERT_EQ(h1, h);

  h.reset();
  ASSERT_EQ(MOJO_RESULT_OK, ht.GetAndRemoveHandle(hv3, &h));
  ASSERT_EQ(h3, h);

  EXPECT_EQ(MOJO_RESULT_OK, h1.dispatcher->Close());
  EXPECT_EQ(MOJO_RESULT_OK, h2.dispatcher->Close());
  EXPECT_EQ(MOJO_RESULT_OK, h3.dispatcher->Close());
}

TEST(HandleTableTest, AddHandlePairTooMany) {
  HandleTable ht(2u);

  Handle h1(MakeRefCounted<test::MockSimpleDispatcher>(),
            MOJO_HANDLE_RIGHT_NONE);
  Handle h2(MakeRefCounted<test::MockSimpleDispatcher>(),
            MOJO_HANDLE_RIGHT_TRANSFER);
  Handle h3(MakeRefCounted<test::MockSimpleDispatcher>(),
            MOJO_HANDLE_RIGHT_READ);
  Handle h4(MakeRefCounted<test::MockSimpleDispatcher>(),
            MOJO_HANDLE_RIGHT_WRITE);

  auto hp = ht.AddHandlePair(h1.Clone(), h2.Clone());
  auto hv1 = hp.first;
  auto hv2 = hp.second;
  ASSERT_NE(hv1, MOJO_HANDLE_INVALID);
  ASSERT_NE(hv2, MOJO_HANDLE_INVALID);
  ASSERT_NE(hv1, hv2);

  // Table should be full; adding |h3| should fail.
  EXPECT_EQ(MOJO_HANDLE_INVALID, ht.AddHandle(h3.Clone()));

  // Adding |h3| and |h4| as a pair should also fail.
  auto hp2 = ht.AddHandlePair(h3.Clone(), h4.Clone());
  EXPECT_EQ(MOJO_HANDLE_INVALID, hp2.first);
  EXPECT_EQ(MOJO_HANDLE_INVALID, hp2.second);

  // Remove |hv2|/|h2|.
  Handle h;
  ASSERT_EQ(MOJO_RESULT_OK, ht.GetAndRemoveHandle(hv2, &h));
  ASSERT_EQ(h2, h);

  // Trying to add |h3| and |h4| as a pair should still fail.
  hp2 = ht.AddHandlePair(h3.Clone(), h4.Clone());
  EXPECT_EQ(MOJO_HANDLE_INVALID, hp2.first);
  EXPECT_EQ(MOJO_HANDLE_INVALID, hp2.second);

  // Remove |hv1|/|h1|.
  h.reset();
  ASSERT_EQ(MOJO_RESULT_OK, ht.GetAndRemoveHandle(hv1, &h));
  ASSERT_EQ(h1, h);

  // Add |h3| and |h4| as a pair should now succeed fail.
  hp2 = ht.AddHandlePair(h3.Clone(), h4.Clone());
  auto hv3 = hp2.first;
  auto hv4 = hp2.second;
  ASSERT_NE(hv3, MOJO_HANDLE_INVALID);
  ASSERT_NE(hv4, MOJO_HANDLE_INVALID);
  ASSERT_NE(hv3, hv4);

  h.reset();
  ASSERT_EQ(MOJO_RESULT_OK, ht.GetAndRemoveHandle(hv3, &h));
  ASSERT_EQ(h3, h);

  h.reset();
  ASSERT_EQ(MOJO_RESULT_OK, ht.GetAndRemoveHandle(hv4, &h));
  ASSERT_EQ(h4, h);

  EXPECT_EQ(MOJO_RESULT_OK, h1.dispatcher->Close());
  EXPECT_EQ(MOJO_RESULT_OK, h2.dispatcher->Close());
  EXPECT_EQ(MOJO_RESULT_OK, h3.dispatcher->Close());
  EXPECT_EQ(MOJO_RESULT_OK, h4.dispatcher->Close());
}

TEST(HandleTableTest, AddHandleVector) {
  static constexpr size_t kNumHandles = 10u;

  HandleTable ht(1000u);

  HandleVector handles;
  for (size_t i = 0u; i < kNumHandles; i++) {
    handles.push_back(Handle(MakeRefCounted<test::MockSimpleDispatcher>(),
                             static_cast<MojoHandleRights>(i)));
    ASSERT_TRUE(handles[i]) << i;
  }

  std::vector<MojoHandle> handle_values(kNumHandles, MOJO_HANDLE_INVALID);

  HandleVector handles_copy = handles;
  ASSERT_TRUE(ht.AddHandleVector(&handles_copy, handle_values.data()));

  for (size_t i = 0u; i < kNumHandles; i++) {
    ASSERT_NE(handle_values[i], MOJO_HANDLE_INVALID) << i;
    EXPECT_FALSE(handles_copy[i]) << i;

    Handle h;
    ASSERT_EQ(MOJO_RESULT_OK, ht.GetAndRemoveHandle(handle_values[i], &h)) << i;
    ASSERT_EQ(handles[i], h) << i;

    EXPECT_EQ(MOJO_RESULT_OK, handles[i].dispatcher->Close()) << i;
  }
}

TEST(HandleTableTest, AddHandleVectorTooMany) {
  static constexpr size_t kHandleTableSize = 10u;
  static constexpr size_t kNumHandles = kHandleTableSize + 1u;

  HandleTable ht(kHandleTableSize);

  HandleVector handles;
  for (size_t i = 0u; i < kNumHandles; i++) {
    handles.push_back(Handle(MakeRefCounted<test::MockSimpleDispatcher>(),
                             static_cast<MojoHandleRights>(i)));
    ASSERT_TRUE(handles[i]) << i;
  }

  std::vector<MojoHandle> handle_values(kNumHandles, MOJO_HANDLE_INVALID);

  HandleVector handles_copy = handles;
  EXPECT_FALSE(ht.AddHandleVector(&handles_copy, handle_values.data()));

  handles_copy.pop_back();
  handle_values.pop_back();

  ASSERT_TRUE(ht.AddHandleVector(&handles_copy, handle_values.data()));

  for (size_t i = 0u; i < kNumHandles - 1u; i++) {
    ASSERT_NE(handle_values[i], MOJO_HANDLE_INVALID) << i;
    EXPECT_FALSE(handles_copy[i]) << i;

    Handle h;
    ASSERT_EQ(MOJO_RESULT_OK, ht.GetAndRemoveHandle(handle_values[i], &h)) << i;
    ASSERT_EQ(handles[i], h) << i;
  }

  for (size_t i = 0u; i < kNumHandles; i++)
    EXPECT_EQ(MOJO_RESULT_OK, handles[i].dispatcher->Close()) << i;
}

// TODO(vtl): Figure out how to test |MarkBusyAndStartTransport()|.

}  // namespace
}  // namespace system
}  // namespace mojo
