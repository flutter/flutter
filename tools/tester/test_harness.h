// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_TOOLS_TESTER_TEST_HARNESS_H_
#define SKY_TOOLS_TESTER_TEST_HARNESS_H_

#include "base/memory/weak_ptr.h"
#include "sky/tools/tester/test_runner.h"

namespace mojo{
class View;
}

namespace sky {
namespace tester {

class TestHarness : public TestRunnerClient {
 public:
  explicit TestHarness(mojo::View* container);
  virtual ~TestHarness();

  void ScheduleRun();

 private:
  void Run();
  void OnTestComplete() override;

  mojo::View* container_;
  scoped_ptr<TestRunner> test_runner_;
  base::WeakPtrFactory<TestHarness> weak_ptr_factory_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(TestHarness);
};

}  // namespace tester
}  // namespace sky

#endif  // SKY_TOOLS_TESTER_TEST_HARNESS_H_
