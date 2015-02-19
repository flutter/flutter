// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/tools/tester/test_runner.h"

#include <iostream>
#include "base/bind.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/services/view_manager/public/cpp/view.h"

namespace sky {
namespace tester {

TestRunnerClient::~TestRunnerClient() {
}

TestRunner::TestRunner(TestRunnerClient* client,
                       mojo::View* container,
                       const std::string& url,
                       bool enable_pixel_dumping)
    : client_(client),
      weak_ptr_factory_(this),
      enable_pixel_dumping_(enable_pixel_dumping) {
  CHECK(client);

  mojo::ServiceProviderPtr test_harness_provider;
  test_harness_provider_impl_.AddService(this);
  test_harness_provider_impl_.Bind(GetProxy(&test_harness_provider));

  container->Embed(url, nullptr, test_harness_provider.Pass());
}

TestRunner::~TestRunner() {
}

base::WeakPtr<TestRunner> TestRunner::GetWeakPtr() {
  return weak_ptr_factory_.GetWeakPtr();
}

void TestRunner::OnTestStart() {
  std::cout << "#BEGIN\n";
  std::cout.flush();
}

void TestRunner::OnTestComplete(const std::string& test_result,
    const mojo::Array<uint8_t>& pixels) {
  std::cout << "Content-Type: text/plain\n";
  std::cout << test_result << "\n";
  std::cout << "#EOF\n";

  // TODO(ojan): Don't generate the pixels if enable_pixel_dumping_ is false.
  if (enable_pixel_dumping_) {
    // TODO(ojan): Add real hashes here once we want to do pixel tests.
    std::cout << "\nActualHash: FAKEHASHSTUB\n";
    std::cout << "Content-Type: image/png\n";
    std::cout << "Content-Length: " << pixels.size() << "\n";
    CHECK(pixels.size()) << "Could not dump pixels. Did you call notifyTestComplete before the first paint?";
    std::cout.write(
        reinterpret_cast<const char*>(&pixels[0]), pixels.size());
  }

  std::cout << "#EOF\n";
  std::cout.flush();
  std::cerr << "#EOF\n";
  std::cerr.flush();

  client_->OnTestComplete();
}

void TestRunner::Create(mojo::ApplicationConnection* app,
                        mojo::InterfaceRequest<TestHarness> request) {
  new TestHarnessImpl(this, request.Pass());
}

}  // namespace tester
}  // namespace sky
