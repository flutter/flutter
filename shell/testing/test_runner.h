// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_TESTING_TEST_RUNNER_H_
#define SHELL_TESTING_TEST_RUNNER_H_

#include <memory>
#include <string>

#include "flutter/services/engine/sky_engine.mojom.h"
#include "lib/ftl/macros.h"
#include "lib/ftl/memory/weak_ptr.h"

namespace shell {

class PlatformView;

class TestRunner {
 public:
  static TestRunner& Shared();

  struct TestDescriptor {
    std::string path;
    std::string packages;
  };

  void Run(const TestDescriptor& test);

 private:
  TestRunner();
  ~TestRunner();

  std::unique_ptr<PlatformView> platform_view_;
  sky::SkyEnginePtr sky_engine_;

  ftl::WeakPtrFactory<TestRunner> weak_ptr_factory_;

  FTL_DISALLOW_COPY_AND_ASSIGN(TestRunner);
};

}  // namespace shell

#endif  // SHELL_TESTING_TEST_RUNNER_H_
