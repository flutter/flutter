// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/dart_vm.h"
#include "gtest/gtest.h"

namespace blink {

TEST(DartVM, SimpleInitialization) {
  Settings settings = {};
  settings.task_observer_add = [](intptr_t, fxl::Closure) {};
  settings.task_observer_remove = [](intptr_t) {};
  auto vm = DartVM::ForProcess(settings);
  ASSERT_TRUE(vm);
  ASSERT_EQ(vm, DartVM::ForProcess(settings));
  ASSERT_FALSE(DartVM::IsRunningPrecompiledCode());
  ASSERT_EQ(vm->GetPlatformKernel(), nullptr);
}

}  // namespace blink
