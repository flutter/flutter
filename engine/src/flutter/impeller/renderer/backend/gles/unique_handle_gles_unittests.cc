// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "gtest/gtest.h"
#include "impeller/renderer/backend/gles/reactor_gles.h"
#include "impeller/renderer/backend/gles/test/mock_gles.h"
#include "impeller/renderer/backend/gles/unique_handle_gles.h"

namespace impeller {
namespace testing {

namespace {
class TestWorker : public ReactorGLES::Worker {
 public:
  bool CanReactorReactOnCurrentThreadNow(
      const ReactorGLES& reactor) const override {
    return true;
  }
};
}  // namespace

TEST(UniqueHandleGLES, MakeUntracked) {
  auto mock_gles = MockGLES::Init();
  ProcTableGLES::Resolver resolver = kMockResolverGLES;
  auto proc_table = std::make_unique<ProcTableGLES>(resolver);
  auto worker = std::make_shared<TestWorker>();
  auto reactor = std::make_shared<ReactorGLES>(std::move(proc_table));
  reactor->AddWorker(worker);

  mock_gles->GetCapturedCalls();
  UniqueHandleGLES handle =
      UniqueHandleGLES::MakeUntracked(reactor, HandleType::kTexture);
  EXPECT_FALSE(handle.Get().IsDead());
  std::vector<std::string> calls = mock_gles->GetCapturedCalls();
  EXPECT_TRUE(std::find(calls.begin(), calls.end(), "glGenTextures") !=
              calls.end());
}

}  // namespace testing
}  // namespace impeller
