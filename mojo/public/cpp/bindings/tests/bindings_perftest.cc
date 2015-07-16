// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/bindings/binding.h"
#include "mojo/public/cpp/test_support/test_support.h"
#include "mojo/public/cpp/test_support/test_utils.h"
#include "mojo/public/cpp/utility/run_loop.h"
#include "mojo/public/interfaces/bindings/tests/ping_service.mojom.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace {

const double kMojoTicksPerSecond = 1000000.0;

double MojoTicksToSeconds(MojoTimeTicks ticks) {
  return ticks / kMojoTicksPerSecond;
}

class PingServiceImpl : public test::PingService {
 public:
  explicit PingServiceImpl() {}
  ~PingServiceImpl() override {}

  // |PingService| methods:
  void Ping(const Callback<void()>& callback) override;

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(PingServiceImpl);
};

void PingServiceImpl::Ping(const Callback<void()>& callback) {
  callback.Run();
}

class PingPongTest {
 public:
  explicit PingPongTest(test::PingServicePtr service);

  void Run(unsigned int iterations);

 private:
  void OnPingDone();

  test::PingServicePtr service_;
  unsigned int iterations_to_run_;
  unsigned int current_iterations_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(PingPongTest);
};

PingPongTest::PingPongTest(test::PingServicePtr service)
    : service_(service.Pass()) {
}

void PingPongTest::Run(unsigned int iterations) {
  iterations_to_run_ = iterations;
  current_iterations_ = 0;

  service_->Ping([this]() { OnPingDone(); });
  RunLoop::current()->Run();
}

void PingPongTest::OnPingDone() {
  current_iterations_++;
  if (current_iterations_ >= iterations_to_run_) {
    RunLoop::current()->Quit();
    return;
  }

  service_->Ping([this]() { OnPingDone(); });
}

struct BoundPingService {
  BoundPingService() : binding(&impl) {
    binding.Bind(GetProxy(&service));
  }

  PingServiceImpl impl;
  test::PingServicePtr service;
  Binding<test::PingService> binding;
};

class MojoBindingsPerftest : public testing::Test {
 protected:
  Environment env_;
  RunLoop run_loop_;
};

TEST_F(MojoBindingsPerftest, InProcessPingPong) {
  test::PingServicePtr service;
  PingServiceImpl impl;
  Binding<test::PingService> binding(&impl, GetProxy(&service));
  PingPongTest test(service.Pass());

  {
    const unsigned int kIterations = 100000;
    const MojoTimeTicks start_time = MojoGetTimeTicksNow();
    test.Run(kIterations);
    const MojoTimeTicks end_time = MojoGetTimeTicksNow();
    test::LogPerfResult(
        "InProcessPingPong", "0_Inactive",
        kIterations / MojoTicksToSeconds(end_time - start_time),
        "pings/second");
  }

  {
    const size_t kNumInactiveServices = 1000;
    BoundPingService* inactive_services =
        new BoundPingService[kNumInactiveServices];

    const unsigned int kIterations = 10000;
    const MojoTimeTicks start_time = MojoGetTimeTicksNow();
    test.Run(kIterations);
    const MojoTimeTicks end_time = MojoGetTimeTicksNow();
    test::LogPerfResult(
        "InProcessPingPong", "1000_Inactive",
        kIterations / MojoTicksToSeconds(end_time - start_time),
        "pings/second");

    delete[] inactive_services;
  }
}

}  // namespace
}  // namespace mojo
