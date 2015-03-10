// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_TOOLS_TESTER_TEST_RUNNER_H_
#define SKY_TOOLS_TESTER_TEST_RUNNER_H_

#include "base/memory/weak_ptr.h"
#include "mojo/public/cpp/application/service_provider_impl.h"
#include "sky/tools/tester/test_harness_impl.h"

namespace mojo{
class View;
}

namespace sky {
namespace tester {

class TestRunnerClient {
 public:
  virtual void OnTestComplete() = 0;
  virtual void DispatchInputEvent(mojo::EventPtr event) = 0;

 protected:
  virtual ~TestRunnerClient();
};

class TestRunner : public mojo::InterfaceFactory<TestHarness> {
 public:
  TestRunner(TestRunnerClient* client, mojo::View* container,
      const std::string& url, bool enable_pixel_dumping);
  ~TestRunner() override;

  TestRunnerClient* client() const { return client_; }

  base::WeakPtr<TestRunner> GetWeakPtr();
  void OnTestStart();
  void OnTestComplete(const std::string& test_result,
    const mojo::Array<uint8_t>& pixels);

 private:
  // mojo::InterfaceFactory<TestHarness> implementation:
  void Create(mojo::ApplicationConnection* app,
              mojo::InterfaceRequest<TestHarness> request) override;

  mojo::ServiceProviderImpl test_harness_provider_impl_;
  TestRunnerClient* client_;
  bool enable_pixel_dumping_;
  base::WeakPtrFactory<TestRunner> weak_ptr_factory_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(TestRunner);
};

}  // namespace tester
}  // namespace sky

#endif  // SKY_TOOLS_TESTER_TEST_RUNNER_H_
