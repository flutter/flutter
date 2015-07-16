// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <numeric>

#include "base/logging.h"
#include "base/message_loop/message_loop.h"
#include "base/timer/elapsed_timer.h"
#include "base/tracked_objects.h"
#include "mojo/common/message_pump_mojo.h"
#include "mojo/public/cpp/bindings/binding.h"
#include "mojo/public/cpp/environment/environment.h"
#include "mojo/public/cpp/environment/task_tracker.h"
#include "mojo/public/cpp/test_support/test_support.h"
#include "mojo/public/cpp/test_support/test_utils.h"
#include "mojo/public/interfaces/bindings/tests/sample_interfaces.mojom.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace test {
namespace {

class ProviderImpl : public sample::Provider {
 public:
  explicit ProviderImpl(InterfaceRequest<sample::Provider> request)
      : binding_(this, request.Pass()) {}

  void EchoString(const String& a,
                  const Callback<void(String)>& callback) override {
    callback.Run(a);
  }

  void EchoStrings(const String& a,
                   const String& b,
                   const Callback<void(String, String)>& callback) override {
    CHECK(false);
  }

  void EchoMessagePipeHandle(
      ScopedMessagePipeHandle a,
      const Callback<void(ScopedMessagePipeHandle)>& callback) override {
    CHECK(false);
  }

  void EchoEnum(sample::Enum a,
                const Callback<void(sample::Enum)>& callback) override {
    CHECK(false);
  }

  void EchoInt(int32_t a, const EchoIntCallback& callback) override {
    CHECK(false);
  }

  Binding<sample::Provider> binding_;
};

class RequestResponsePerfTest : public testing::Test {
 public:
  RequestResponsePerfTest()
      : loop_(make_scoped_ptr(new common::MessagePumpMojo())) {}

  ~RequestResponsePerfTest() override { loop_.RunUntilIdle(); }

  void Iterate(size_t count);
  void Measure(const char* case_nam);

  void SetUp() override {
    tracked_objects::ThreadData::InitializeAndSetTrackingStatus(
        tracked_objects::ThreadData::PROFILING_ACTIVE);
  }

  void TearDown() override {
    tracked_objects::ThreadData::InitializeAndSetTrackingStatus(
        tracked_objects::ThreadData::DEACTIVATED);
  }

  void PumpMessages() { loop_.RunUntilIdle(); }

 private:
  base::MessageLoop loop_;
};

const size_t kCallsPerIteration = 1000;
const size_t kIterations = 1000;

void RequestResponsePerfTest::Iterate(size_t count) {
  sample::ProviderPtr provider;
  ProviderImpl provider_impl(GetProxy(&provider));

  size_t remaining = count;
  Callback<void(const String&)> reply =
      [&provider, &reply, &remaining](const String& a) {
        if (!remaining)
          return;
        remaining--;
        provider->EchoString(a, reply);
      };

  provider->EchoString(String::From("hello"), reply);
  PumpMessages();
}

void RequestResponsePerfTest::Measure(const char* case_name) {
  std::vector<double> laps;
  for (size_t i = 0; i < kIterations; ++i) {
    base::ElapsedTimer timer;
    Iterate(kCallsPerIteration);
    laps.push_back(timer.Elapsed().InMillisecondsF());
  }

  double avg = std::accumulate(laps.begin(), laps.end(), 0.0) / laps.size();
  double var = std::accumulate(laps.begin(), laps.end(), 0.0, [avg](double acc,
                                                                    double x) {
    return acc + (x - avg) * (x - avg);
  }) / laps.size();

  double sd = sqrt(var);
  mojo::test::LogPerfResult(case_name, "Avg", avg, "ms/1000call");
  mojo::test::LogPerfResult(case_name, "SD", sd, "ms/1000call");
}

TEST_F(RequestResponsePerfTest, TrackingEnabled) {
  Environment::GetDefaultTaskTracker()->SetEnabled(true);
  Measure(__FUNCTION__);
  Environment::GetDefaultTaskTracker()->SetEnabled(false);
}

TEST_F(RequestResponsePerfTest, TrackingDisabled) {
  Measure(__FUNCTION__);
}

}  // namespace
}  // namespace test
}  // namespace mojo
