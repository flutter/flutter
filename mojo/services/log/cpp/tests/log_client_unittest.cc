// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <set>
#include <thread>
#include <vector>

#include "mojo/public/cpp/application/application_test_base.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/public/cpp/system/macros.h"
#include "mojo/public/cpp/utility/run_loop.h"
#include "mojo/services/log/cpp/log_client.h"
#include "mojo/services/log/interfaces/entry.mojom.h"
#include "mojo/services/log/interfaces/log.mojom.h"
#include "testing/gtest/include/gtest/gtest.h"

using LogClientTest = mojo::test::ApplicationTestBase;
using mojo::Environment;

namespace mojo {
namespace {

// A Log implementation that remembers the set of all incoming messages.
class TestLogServiceImpl : public log::Log {
 public:
  explicit TestLogServiceImpl(InterfaceRequest<log::Log> log_req)
      : binding_(this, std::move(log_req)) {
    EXPECT_TRUE(binding_.is_bound());
    binding_.set_connection_error_handler([this]() {
      FAIL() << "Log service lost connection to the log client.";
    });
  }
  void AddEntry(mojo::log::EntryPtr entry) override {
    entry_msgs_.insert(entry->message.To<std::string>());
  }
  const std::set<std::string>& entries() { return entry_msgs_; }

 private:
  mojo::StrongBinding<log::Log> binding_;
  std::set<std::string> entry_msgs_;
};

MojoLogLevel g_fallback_logger_level;
bool g_fallback_logger_invoked;

// This tests that multiple threads can use the MojoLogger that
// mojo::log::LogClient produces, by spawning off |kNumLogEntries| threads, each
// issuing one unique log message.
TEST_F(LogClientTest, ConcurrentAddEntry) {
  g_fallback_logger_level = MOJO_LOG_LEVEL_INFO;
  g_fallback_logger_invoked = false;

  log::LogPtr log_ptr;
  std::unique_ptr<mojo::TestLogServiceImpl> log_impl(
      new mojo::TestLogServiceImpl(mojo::GetProxy(&log_ptr)));

  // This is our test fallback logger + state.  We simply records whether it's
  // been called.
  MojoLogger fallback_logger = {
      // LogMessage
      [](MojoLogLevel log_level, const char* source_file, uint32_t source_line,
         const char* message) { g_fallback_logger_invoked = true; },
      // SetMinimumLogLevel
      []() -> MojoLogLevel { return g_fallback_logger_level; },
      // GetMinimumLogLevel
      [](MojoLogLevel lvl) { g_fallback_logger_level = lvl; }};
  log::InitializeLogger(std::move(log_ptr), &fallback_logger);
  Environment::SetDefaultLogger(log::GetLogger());

  // Spawn off numerous threads, each of them issuing a unique log message.
  std::vector<std::thread> threads;
  std::set<std::string> expected_entries;

  // The number of log entries to issue.
  const int kNumLogEntries = 1000;
  for (int i = 0; i < kNumLogEntries; i++) {
    std::stringstream msg;
    msg << "Test message: " << i;
    EXPECT_TRUE(expected_entries.insert(msg.str()).second);

    std::thread t([](std::string msg) { MOJO_LOG(INFO) << msg; }, msg.str());

    threads.push_back(std::move(t));
  }
  for (auto& t : threads) {
    t.join();
  }

  // The log message calls should now be processed by TestLogServiceImpl.
  mojo::RunLoop::current()->RunUntilIdle();

  EXPECT_EQ(expected_entries, log_impl->entries());

  // We kill our binding, closing the connection to the log client and
  // causing the log client to revert to using its fallback logger.
  log_impl.reset();

  EXPECT_FALSE(mojo::g_fallback_logger_invoked);
  MOJO_LOG(INFO) << "Ignore this log message.";
  EXPECT_TRUE(mojo::g_fallback_logger_invoked);

  // Check that this logger propogates get/set min level calls to the fallback
  // logger.
  auto* logger = log::GetLogger();
  EXPECT_EQ(MOJO_LOG_LEVEL_INFO, logger->GetMinimumLogLevel());
  logger->SetMinimumLogLevel(MOJO_LOG_LEVEL_FATAL);
  EXPECT_EQ(MOJO_LOG_LEVEL_FATAL, logger->GetMinimumLogLevel());
  EXPECT_EQ(MOJO_LOG_LEVEL_FATAL, fallback_logger.GetMinimumLogLevel());

  log::DestroyLogger();
}

}  // namespace
}  // namespace mojo
