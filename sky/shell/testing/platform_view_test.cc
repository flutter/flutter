// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/shell/testing/platform_view_test.h"

#include "flutter/sky/shell/shell.h"

namespace sky {
namespace shell {

PlatformViewTest::PlatformViewTest() : weak_factory_(this) {}

PlatformViewTest::~PlatformViewTest() = default;

ftl::WeakPtr<PlatformView> PlatformViewTest::GetWeakViewPtr() {
  return weak_factory_.GetWeakPtr();
}

uint64_t PlatformViewTest::DefaultFramebuffer() const {
  return 0;
}

bool PlatformViewTest::ContextMakeCurrent() {
  return false;
}

bool PlatformViewTest::ResourceContextMakeCurrent() {
  return false;
}

bool PlatformViewTest::SwapBuffers() {
  return false;
}

}  // namespace shell
}  // namespace sky
