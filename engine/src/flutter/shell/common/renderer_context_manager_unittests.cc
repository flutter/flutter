// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#define FML_USED_ON_EMBEDDER

#include <functional>
#include <future>
#include <memory>

#include "flutter/shell/common/renderer_context_manager.h"
#include "gtest/gtest.h"
#include "renderer_context_test.h"

namespace flutter {
namespace testing {

TEST_F(RendererContextTest, StartWithNoContextFlutterMakeCurrent) {
  auto flutter_context = std::make_unique<TestRendererContext>(0);
  auto flutter_resource_context = std::make_unique<TestRendererContext>(1);

  RendererContextManager manager(std::move(flutter_context),
                                 std::move(flutter_resource_context));
  // started with current_context as -1
  TestRendererContext::SetCurrentContext(-1);
  ASSERT_EQ(TestRendererContext::GetCurrentContext(), -1);
  {
    // made flutter context to be the current
    auto context_switch = manager.FlutterMakeCurrent();
    ASSERT_EQ(TestRendererContext::GetCurrentContext(), 0);
  }
  // flutter context is popped
  ASSERT_EQ(TestRendererContext::GetCurrentContext(), -1);
}

TEST_F(RendererContextTest, StartWithNoContextFlutterResourceMakeCurrent) {
  auto flutter_context = std::make_unique<TestRendererContext>(0);
  auto flutter_resource_context = std::make_unique<TestRendererContext>(1);

  RendererContextManager manager(std::move(flutter_context),
                                 std::move(flutter_resource_context));
  // started with current_context as -1
  TestRendererContext::SetCurrentContext(-1);
  ASSERT_EQ(TestRendererContext::GetCurrentContext(), -1);
  {
    // made resource context to be the current
    auto context_switch = manager.FlutterResourceMakeCurrent();
    ASSERT_EQ(TestRendererContext::GetCurrentContext(), 1);
  }
  // flutter context is popped
  ASSERT_EQ(TestRendererContext::GetCurrentContext(), -1);
}

TEST_F(RendererContextTest, StartWithSomeContextFlutterMakeCurrent) {
  auto flutter_context = std::make_unique<TestRendererContext>(0);
  auto flutter_resource_context = std::make_unique<TestRendererContext>(1);
  auto some_context = std::make_unique<TestRendererContext>(2);

  RendererContextManager manager(std::move(flutter_context),
                                 std::move(flutter_resource_context));
  // started with some_context
  auto context_switch = manager.MakeCurrent(std::move(some_context));
  ASSERT_EQ(TestRendererContext::GetCurrentContext(), 2);
  {
    // made flutter context to be the current
    auto context_switch2 = manager.FlutterMakeCurrent();
    ASSERT_EQ(TestRendererContext::GetCurrentContext(), 0);
  }
  // flutter context is popped
  ASSERT_EQ(TestRendererContext::GetCurrentContext(), 2);
}

TEST_F(RendererContextTest, StartWithSomeContextFlutterResourceMakeCurrent) {
  auto flutter_context = std::make_unique<TestRendererContext>(0);
  auto flutter_resource_context = std::make_unique<TestRendererContext>(1);
  auto some_context = std::make_unique<TestRendererContext>(2);

  RendererContextManager manager(std::move(flutter_context),
                                 std::move(flutter_resource_context));
  // started with some_context
  auto context_switch = manager.MakeCurrent(std::move(some_context));
  ASSERT_EQ(TestRendererContext::GetCurrentContext(), 2);
  {
    // made resource context to be the current
    auto context_switch2 = manager.FlutterResourceMakeCurrent();
    ASSERT_EQ(TestRendererContext::GetCurrentContext(), 1);
  }
  // flutter context is popped
  ASSERT_EQ(TestRendererContext::GetCurrentContext(), 2);
}

TEST_F(RendererContextTest, Nested) {
  auto flutter_context = std::make_unique<TestRendererContext>(0);
  auto flutter_resource_context = std::make_unique<TestRendererContext>(1);
  auto some_context = std::make_unique<TestRendererContext>(2);

  RendererContextManager manager(std::move(flutter_context),
                                 std::move(flutter_resource_context));

  // started with some_context
  auto context_switch = manager.MakeCurrent(std::move(some_context));
  ASSERT_EQ(TestRendererContext::GetCurrentContext(), 2);
  {
    // made flutter context to be the current
    auto context_switch2 = manager.FlutterMakeCurrent();
    ASSERT_EQ(TestRendererContext::GetCurrentContext(), 0);
    {
      // made resource context to be the current
      auto context_switch2 = manager.FlutterResourceMakeCurrent();
      ASSERT_EQ(TestRendererContext::GetCurrentContext(), 1);
    }
    // resource context is popped
    ASSERT_EQ(TestRendererContext::GetCurrentContext(), 0);
  }
  // flutter context is popped
  ASSERT_EQ(TestRendererContext::GetCurrentContext(), 2);
}

}  // namespace testing
}  // namespace flutter
