// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_TESTING_TEST_RUNNER_H_
#define SKY_SHELL_TESTING_TEST_RUNNER_H_

#include <memory>
#include <string>

#include "base/macros.h"
#include "base/memory/weak_ptr.h"
#include "mojo/common/binding_set.h"
#include "sky/services/engine/sky_engine.mojom.h"

namespace sky {
namespace shell {
class ShellView;

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

  std::unique_ptr<ShellView> shell_view_;
  SkyEnginePtr sky_engine_;

  base::WeakPtrFactory<TestRunner> weak_ptr_factory_;

  DISALLOW_COPY_AND_ASSIGN(TestRunner);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_TESTING_TEST_RUNNER_H_
