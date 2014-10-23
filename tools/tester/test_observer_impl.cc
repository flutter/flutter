// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/tools/tester/test_observer_impl.h"

#include "sky/tools/tester/test_runner.h"

namespace sky {
namespace tester {

TestObserverImpl::TestObserverImpl(TestRunner* test_runner)
    : test_runner_(test_runner->GetWeakPtr()) {
  // FIXME: This is technically when the V8 context gets created and
  // not when the test is started. An error before we instantiated
  // the V8 context would show up before the #BEGIN line for this test.
  test_runner->OnTestStart();
}

TestObserverImpl::~TestObserverImpl() {
}

void TestObserverImpl::OnTestComplete(const mojo::String& test_result) {
  if (test_runner_)
    test_runner_->OnTestComplete(test_result);
}

}  // namespace tester
}  // namespace sky
