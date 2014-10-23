// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/tools/tester/test_runner.h"

#include <iostream>
#include "base/bind.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/cpp/application/service_provider_impl.h"
#include "mojo/services/public/cpp/view_manager/view.h"

namespace sky {
namespace tester {

TestRunner::TestRunner(TestRunnerClient* client, mojo::View* container,
    const std::string& url)
    : test_observer_factory_(this),
      client_(client),
      weak_ptr_factory_(this) {
  CHECK(client);

  scoped_ptr<mojo::ServiceProviderImpl> exported_services(
    new mojo::ServiceProviderImpl());
  exported_services->AddService(&test_observer_factory_);

  container->Embed(url, exported_services.Pass());
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

void TestRunner::OnTestComplete(const std::string& test_result) {
  std::cout << "Content-Type: text/plain\n";
  std::cout << test_result << "\n";
  std::cout << "#EOF\n";
  std::cout << "#EOF\n";
  std::cout.flush();
  std::cerr << "#EOF\n";
  std::cerr.flush();

  client_->OnTestComplete();
}

}  // namespace tester
}  // namespace sky
