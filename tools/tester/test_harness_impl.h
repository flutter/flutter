// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_TOOLS_TESTER_TEST_HARNESS_IMPL_H_
#define SKY_TOOLS_TESTER_TEST_HARNESS_IMPL_H_

#include "base/memory/weak_ptr.h"
#include "mojo/public/cpp/application/interface_factory_impl.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/public/cpp/system/core.h"
#include "sky/services/testing/test_harness.mojom.h"

namespace sky {
namespace tester {
class TestRunner;

class TestHarnessImpl : public TestHarness {
 public:
  TestHarnessImpl(TestRunner* runner,
                  mojo::InterfaceRequest<TestHarness> request);
  virtual ~TestHarnessImpl();

 private:
  // TestHarness implementation.
  void OnTestComplete(const mojo::String& test_result,
    const mojo::Array<uint8_t> pixels) override;
  void DispatchInputEvent(mojo::EventPtr event) override;

  mojo::StrongBinding<TestHarness> binding_;
  base::WeakPtr<TestRunner> test_runner_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(TestHarnessImpl);
};

}  // namespace tester
}  // namespace sky

#endif  // SKY_TOOLS_TESTER_TEST_HARNESS_IMPL_H_
