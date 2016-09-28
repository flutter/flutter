// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file has perf tests for async waits using |base::MessageLoop| (i.e., the
// "Chromium" |Environment|).

#include <stdint.h>

#include <functional>
#include <memory>

#include "base/bind.h"
#include "base/location.h"
#include "base/memory/scoped_ptr.h"
#include "base/message_loop/message_loop.h"
#include "base/strings/stringprintf.h"
#include "base/test/perf_log.h"
#include "base/time/time.h"
#include "mojo/message_pump/message_pump_mojo.h"
#include "mojo/public/c/environment/tests/async_waiter_perftest_helpers.h"
#include "mojo/public/cpp/environment/environment.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace {

constexpr int64_t kPerftestTimeMicroseconds = 3 * 1000000;

void QuitMessageLoopNow() {
  base::MessageLoop::current()->QuitNow();
}

void SingleThreadedTestHelper(
    const char* name,
    std::function<std::unique_ptr<base::MessageLoop>()> make_message_loop) {
  for (uint32_t num_handles = 1u; num_handles <= 10000u; num_handles *= 10u) {
    auto message_loop = make_message_loop();

    base::TimeTicks start_time;
    base::TimeTicks end_time;
    uint64_t raw_result = test::DoAsyncWaiterPerfTest(
        Environment::GetDefaultAsyncWaiter(), num_handles,
        [&start_time, &end_time]() {
          base::MessageLoop::current()->PostDelayedTask(
              FROM_HERE, base::Bind(&QuitMessageLoopNow),
              base::TimeDelta::FromMicroseconds(kPerftestTimeMicroseconds));
          start_time = base::TimeTicks::Now();
          base::MessageLoop::current()->Run();
          end_time = base::TimeTicks::Now();
        });

    double result =
        static_cast<double>(raw_result) / (end_time - start_time).InSecondsF();
    base::LogPerfResult(
        base::StringPrintf("%s/%u", name, static_cast<unsigned>(num_handles))
            .c_str(),
        result, "callbacks/second");
  }
}

TEST(AsyncWaitPerfTest, SingleThreaded_DefaultMessagePump) {
  SingleThreadedTestHelper(
      "AsyncWaitPerfTest.SingleThreaded_DefaultMessagePump", []() {
        return std::unique_ptr<base::MessageLoop>(new base::MessageLoop());
      });
}

TEST(AsyncWaitPerfTest, SingleThreaded_MessagePumpMojo) {
  SingleThreadedTestHelper(
      "AsyncWaitPerfTest.SingleThreaded_MessagePumpMojo", []() {
        return std::unique_ptr<base::MessageLoop>(new base::MessageLoop(
            make_scoped_ptr(new common::MessagePumpMojo())));
      });
}

}  // namespace
}  // namespace mojo
