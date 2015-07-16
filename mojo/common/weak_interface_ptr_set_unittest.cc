// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/common/weak_interface_ptr_set.h"

#include "base/message_loop/message_loop.h"
#include "mojo/common/message_pump_mojo.h"
#include "mojo/common/test_interfaces.mojom.h"
#include "mojo/public/cpp/bindings/binding.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace common {
namespace {

class DummyImpl : public tests::Dummy {
 public:
  explicit DummyImpl(InterfaceRequest<tests::Dummy> request)
      : binding_(this, request.Pass()) {}

  void Foo() override { call_count_++; }

  void CloseMessagePipe() { binding_.Close(); }

  int call_count() { return call_count_; }

 private:
  Binding<tests::Dummy> binding_;
  int call_count_ = 0;

  DISALLOW_COPY_AND_ASSIGN(DummyImpl);
};

// Tests all of the functionality of WeakInterfacePtrSet.
TEST(WeakInterfacePtr, FullLifeCycleTest) {
  base::MessageLoop loop(MessagePumpMojo::Create());

  // Create 10 InterfacePtrs.
  const size_t kNumObjects = 10;
  InterfacePtr<tests::Dummy> intrfc_ptrs[kNumObjects];

  // Create 10 DummyImpls and 10 message pipes and bind them all together.
  std::unique_ptr<DummyImpl> impls[kNumObjects];
  for (size_t i = 0; i < kNumObjects; i++) {
    impls[i].reset(new DummyImpl(GetProxy(&intrfc_ptrs[i])));
  }

  // Move all 10 InterfacePtrs into the set.
  WeakInterfacePtrSet<tests::Dummy> intrfc_ptr_set;
  EXPECT_EQ(0u, intrfc_ptr_set.size());
  for (InterfacePtr<tests::Dummy>& ptr : intrfc_ptrs) {
    intrfc_ptr_set.AddInterfacePtr(ptr.Pass());
  }
  EXPECT_EQ(kNumObjects, intrfc_ptr_set.size());

  // Check that initially all call counts are zero.
  for (const std::unique_ptr<DummyImpl>& impl : impls) {
    EXPECT_EQ(0, impl->call_count());
  }

  // Invoke ForAllPtrs().
  size_t num_invocations = 0;
  intrfc_ptr_set.ForAllPtrs([&num_invocations](tests::Dummy* dummy) {
    dummy->Foo();
    num_invocations++;
  });
  EXPECT_EQ(kNumObjects, num_invocations);

  // Check that now all call counts are one.
  loop.RunUntilIdle();
  for (const std::unique_ptr<DummyImpl>& impl : impls) {
    EXPECT_EQ(1, impl->call_count());
  }

  // Close the first 5 message pipes.
  for (size_t i = 0; i < kNumObjects / 2; i++) {
    impls[i]->CloseMessagePipe();
  }

  // Invoke ForAllPtrs() again. This will cause connection errors on the
  // closed pipes which will cause the first five objects to be removed.
  EXPECT_EQ(kNumObjects, intrfc_ptr_set.size());
  // TODO(rudominer) It should not be necessary to invoke ForAllPtrs in order
  // to see the effect of the error handlers. The error handlers are invoked
  // just after PumpMessages() is invoked. Fix this test after we fix the
  // implementation of WeakInterfacePtrSet.
  intrfc_ptr_set.ForAllPtrs([](tests::Dummy* dummy) { dummy->Foo(); });
  loop.RunUntilIdle();
  EXPECT_EQ(kNumObjects / 2, intrfc_ptr_set.size());

  // Check that now the first five counts are still 1 but the second five
  // counts are two.
  for (size_t i = 0; i < kNumObjects; i++) {
    int expected = (i < kNumObjects / 2 ? 1 : 2);
    EXPECT_EQ(expected, impls[i]->call_count());
  }

  // Close all of the MessagePipes and clear the set.
  intrfc_ptr_set.CloseAll();

  // Invoke ForAllPtrs() again.
  intrfc_ptr_set.ForAllPtrs([](tests::Dummy* dummy) { dummy->Foo(); });
  loop.RunUntilIdle();

  // Check that the counts are the same as last time.
  for (size_t i = 0; i < kNumObjects; i++) {
    int expected = (i < kNumObjects / 2 ? 1 : 2);
    EXPECT_EQ(expected, impls[i]->call_count());
  }
  EXPECT_EQ(0u, intrfc_ptr_set.size());
}

}  // namespace
}  // namespace common
}  // namespace mojo
