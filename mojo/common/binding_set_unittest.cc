// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/common/binding_set.h"

#include "base/message_loop/message_loop.h"
#include "mojo/common/message_pump_mojo.h"
#include "mojo/common/test_interfaces.mojom.h"
#include "mojo/public/cpp/bindings/binding.h"
#include "mojo/public/cpp/bindings/interface_request.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace common {
namespace {

class DummyImpl : public tests::Dummy {
 public:
  DummyImpl() {}

  void Foo() override { call_count_++; }

  int call_count() const { return call_count_; }

 private:
  int call_count_ = 0;

  DISALLOW_COPY_AND_ASSIGN(DummyImpl);
};

// Tests all of the functionality of BindingSet.
TEST(BindingSetTest, FullLifeCycle) {
  base::MessageLoop loop(MessagePumpMojo::Create());

  // Create 10 InterfacePtrs and DummyImpls.
  const size_t kNumObjects = 10;
  InterfacePtr<tests::Dummy> intrfc_ptrs[kNumObjects];
  DummyImpl impls[kNumObjects];

  // Create 10 message pipes, bind everything together, and add the
  // bindings to binding_set.
  BindingSet<tests::Dummy> binding_set;
  EXPECT_EQ(0u, binding_set.size());
  for (size_t i = 0; i < kNumObjects; i++) {
    binding_set.AddBinding(&impls[i], GetProxy(&intrfc_ptrs[i]));
  }
  EXPECT_EQ(kNumObjects, binding_set.size());

  // Check that initially all call counts are zero.
  for (const auto& impl : impls) {
    EXPECT_EQ(0, impl.call_count());
  }

  // Invoke method foo() on all 10 InterfacePointers.
  for (InterfacePtr<tests::Dummy>& ptr : intrfc_ptrs) {
    ptr->Foo();
  }

  // Check that now all call counts are one.
  loop.RunUntilIdle();
  for (const auto& impl : impls) {
    EXPECT_EQ(1, impl.call_count());
  }

  // Close the first 5 message pipes and destroy the first five
  // InterfacePtrs.
  for (size_t i = 0; i < kNumObjects / 2; i++) {
    intrfc_ptrs[i].reset();
  }

  // Check that the set contains only five elements now.
  loop.RunUntilIdle();
  EXPECT_EQ(kNumObjects / 2, binding_set.size());

  // Invoke method foo() on the second five InterfacePointers.
  for (size_t i = kNumObjects / 2; i < kNumObjects; i++) {
    intrfc_ptrs[i]->Foo();
  }
  loop.RunUntilIdle();

  // Check that now the first five counts are still 1 but the second five
  // counts are two.
  for (size_t i = 0; i < kNumObjects; i++) {
    int expected = (i < kNumObjects / 2 ? 1 : 2);
    EXPECT_EQ(expected, impls[i].call_count());
  }

  // Invoke CloseAllBindings
  binding_set.CloseAllBindings();
  EXPECT_EQ(0u, binding_set.size());

  // Invoke method foo() on the second five InterfacePointers.
  for (size_t i = kNumObjects / 2; i < kNumObjects; i++) {
    intrfc_ptrs[i]->Foo();
  }
  loop.RunUntilIdle();

  // Check that the call counts are the same as before.
  for (size_t i = 0; i < kNumObjects; i++) {
    int expected = (i < kNumObjects / 2 ? 1 : 2);
    EXPECT_EQ(expected, impls[i].call_count());
  }
}

}  // namespace
}  // namespace common
}  // namespace mojo
