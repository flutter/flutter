// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gl_context_switch_test.h"

#include "flutter/fml/thread_local.h"

namespace flutter {
namespace testing {

FML_THREAD_LOCAL fml::ThreadLocalUniquePtr<int> current_context;

TestSwitchableGLContext::TestSwitchableGLContext(int context)
    : context_(context){};

TestSwitchableGLContext::~TestSwitchableGLContext() = default;

bool TestSwitchableGLContext::SetCurrent() {
  SetCurrentContext(context_);
  return true;
};

bool TestSwitchableGLContext::RemoveCurrent() {
  SetCurrentContext(-1);
  return true;
};

int TestSwitchableGLContext::GetContext() {
  return context_;
};

int TestSwitchableGLContext::GetCurrentContext() {
  return *(current_context.get());
};

void TestSwitchableGLContext::SetCurrentContext(int context) {
  current_context.reset(new int(context));
};
}  // namespace testing
}  // namespace flutter
