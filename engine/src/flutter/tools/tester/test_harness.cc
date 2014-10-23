// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/tools/tester/test_harness.h"

#include "base/bind.h"
#include "base/message_loop/message_loop.h"
#include <iostream>

namespace sky {
namespace tester {
namespace {

std::string WaitForURL() {
  std::string url;
  std::cin >> url;
  return url;
}

}  // namespace

TestHarness::TestHarness(mojo::View* container)
    : container_(container),
      weak_ptr_factory_(this) {
  std::cout << "#READY\n";
  std::cout.flush();
}

TestHarness::~TestHarness() {
}

void TestHarness::ScheduleRun() {
  base::MessageLoop::current()->PostTask(FROM_HERE,
      base::Bind(&TestHarness::Run, weak_ptr_factory_.GetWeakPtr()));
}

void TestHarness::Run() {
  DCHECK(!test_runner_);
  test_runner_.reset(new TestRunner(this, container_, WaitForURL()));
}

void TestHarness::OnTestComplete() {
  test_runner_.reset();
  ScheduleRun();
}

}  // namespace tester
}  // namespace sky
