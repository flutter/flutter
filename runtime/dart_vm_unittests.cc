// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/dart_vm.h"
#include "gtest/gtest.h"

namespace blink {

TEST(DartVM, SimpleInitialization) {
  Settings settings = {};
  settings.task_observer_add = [](intptr_t, fml::closure) {};
  settings.task_observer_remove = [](intptr_t) {};
  auto vm = DartVM::ForProcess(settings);
  ASSERT_TRUE(vm);
  ASSERT_EQ(vm, DartVM::ForProcess(settings));
  ASSERT_FALSE(DartVM::IsRunningPrecompiledCode());
}

TEST(DartVM, SimpleIsolateNameServer) {
  Settings settings = {};
  settings.task_observer_add = [](intptr_t, fml::closure) {};
  settings.task_observer_remove = [](intptr_t) {};
  auto vm = DartVM::ForProcess(settings);
  auto ns = vm->GetIsolateNameServer();
  ASSERT_EQ(ns->LookupIsolatePortByName("foobar"), ILLEGAL_PORT);
  ASSERT_FALSE(ns->RemoveIsolateNameMapping("foobar"));
  ASSERT_TRUE(ns->RegisterIsolatePortWithName(123, "foobar"));
  ASSERT_FALSE(ns->RegisterIsolatePortWithName(123, "foobar"));
  ASSERT_EQ(ns->LookupIsolatePortByName("foobar"), 123);
  ASSERT_TRUE(ns->RemoveIsolateNameMapping("foobar"));
}

}  // namespace blink
