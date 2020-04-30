// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "renderer_context_test.h"

namespace flutter {
namespace testing {

FML_THREAD_LOCAL fml::ThreadLocalUniquePtr<int> current_context;

RendererContextTest::RendererContextTest() = default;

TestRendererContext::TestRendererContext(int context) : context_(context){};

TestRendererContext::~TestRendererContext() = default;

bool TestRendererContext::SetCurrent() {
  SetCurrentContext(context_);
  return true;
};

void TestRendererContext::RemoveCurrent() {
  SetCurrentContext(-1);
};

int TestRendererContext::GetContext() {
  return context_;
};

int TestRendererContext::GetCurrentContext() {
  return *(current_context.get());
};

void TestRendererContext::SetCurrentContext(int context) {
  current_context.reset(new int(context));
};
}  // namespace testing
}  // namespace flutter
