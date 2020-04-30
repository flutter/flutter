// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_RENDERER_CONTEXT_TEST_H_
#define FLUTTER_SHELL_RENDERER_CONTEXT_TEST_H_

#include "flutter/fml/thread_local.h"
#include "gtest/gtest.h"
#include "renderer_context_manager.h"

namespace flutter {
namespace testing {

class RendererContextTest : public ::testing::Test {
 public:
  RendererContextTest();
};

//------------------------------------------------------------------------------
/// The renderer context used for testing
class TestRendererContext : public RendererContext {
 public:
  TestRendererContext(int context);

  ~TestRendererContext() override;

  bool SetCurrent() override;

  void RemoveCurrent() override;

  int GetContext();

  static int GetCurrentContext();

  //------------------------------------------------------------------------------
  /// Set the current context without going through the
  /// |RendererContextManager|.
  ///
  /// This is to mimic how other programs outside flutter sets the context.
  static void SetCurrentContext(int context);

 private:
  int context_;

  FML_DISALLOW_COPY_AND_ASSIGN(TestRendererContext);
};
}  // namespace testing
}  // namespace flutter
#endif  // FLUTTER_SHELL_RENDERER_CONTEXT_TEST_H_
