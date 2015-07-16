// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <stdlib.h>

#include <sstream>
#include <string>

#include "mojo/public/cpp/environment/environment.h"
#include "mojo/public/cpp/environment/logging.h"
#include "mojo/public/cpp/system/macros.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace {

// The current logging system strips the path, so we need our filename.
const char kOurFilename[] = "logging_unittest.cc";

class PtrToMemberHelper {
 public:
  int member;
};

bool DcheckTestHelper(bool* was_called) {
  *was_called = true;
  return false;
}

class LoggingTest : public testing::Test {
 public:
  LoggingTest() : environment_(nullptr, &kMockLogger, nullptr) {
    minimum_log_level_ = MOJO_LOG_LEVEL_INFO;
    ResetMockLogger();
  }
  ~LoggingTest() override {}

 protected:
  // Note: Does not reset |minimum_log_level_|.
  static void ResetMockLogger() {
    log_message_was_called_ = false;
    last_log_level_ = MOJO_LOG_LEVEL_INFO;
    last_source_file_.clear();
    last_source_line_ = 0;
    last_message_.clear();
  }

  // A function returning |bool| that shouldn't be called.
  static bool NotCalledCondition() {
    not_called_condition_was_called_ = true;
    return false;
  }

  static bool log_message_was_called() { return log_message_was_called_; }
  static MojoLogLevel last_log_level() { return last_log_level_; }
  static const std::string& last_source_file() { return last_source_file_; }
  static uint32_t last_source_line() { return last_source_line_; }
  static const std::string& last_message() { return last_message_; }
  static bool not_called_condition_was_called() {
    return not_called_condition_was_called_;
  }

 private:
  // Note: We record calls even if |log_level| is below |minimum_log_level_|
  // (since the macros should mostly avoid this, and we want to be able to check
  // that they do).
  static void MockLogMessage(MojoLogLevel log_level,
                             const char* source_file,
                             uint32_t source_line,
                             const char* message) {
    log_message_was_called_ = true;
    last_log_level_ = log_level;
    last_source_file_ = source_file;
    last_source_line_ = source_line;
    last_message_ = message;
  }

  static MojoLogLevel MockGetMinimumLogLevel() { return minimum_log_level_; }

  static void MockSetMinimumLogLevel(MojoLogLevel minimum_log_level) {
    minimum_log_level_ = minimum_log_level;
  }

  Environment environment_;

  static const MojoLogger kMockLogger;
  static MojoLogLevel minimum_log_level_;
  static bool log_message_was_called_;
  static MojoLogLevel last_log_level_;
  static std::string last_source_file_;
  static uint32_t last_source_line_;
  static std::string last_message_;
  static bool not_called_condition_was_called_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(LoggingTest);
};

// static
const MojoLogger LoggingTest::kMockLogger = {
    &LoggingTest::MockLogMessage,
    &LoggingTest::MockGetMinimumLogLevel,
    &LoggingTest::MockSetMinimumLogLevel};

// static
MojoLogLevel LoggingTest::minimum_log_level_ = MOJO_LOG_LEVEL_INFO;

// static
bool LoggingTest::log_message_was_called_ = MOJO_LOG_LEVEL_INFO;

// static
MojoLogLevel LoggingTest::last_log_level_ = MOJO_LOG_LEVEL_INFO;

// static
std::string LoggingTest::last_source_file_;

// static
uint32_t LoggingTest::last_source_line_ = 0;

// static
std::string LoggingTest::last_message_;

// static
bool LoggingTest::not_called_condition_was_called_ = false;

TEST_F(LoggingTest, InternalLogMessage) {
  internal::LogMessage(MOJO_LOG_LEVEL_INFO, "foo.cc", 123).stream() << "hello "
                                                                    << "world";
  EXPECT_TRUE(log_message_was_called());
  EXPECT_EQ(MOJO_LOG_LEVEL_INFO, last_log_level());
  EXPECT_EQ("foo.cc", last_source_file());
  EXPECT_EQ(123u, last_source_line());
  EXPECT_EQ("hello world", last_message());

  ResetMockLogger();

  internal::LogMessage(MOJO_LOG_LEVEL_WARNING, "./path/to/foo.cc", 123).stream()
      << "hello "
      << "world";
  EXPECT_TRUE(log_message_was_called());
  EXPECT_EQ(MOJO_LOG_LEVEL_WARNING, last_log_level());
  EXPECT_EQ("foo.cc", last_source_file());
  EXPECT_EQ(123u, last_source_line());
  EXPECT_EQ("hello world", last_message());

  ResetMockLogger();

  internal::LogMessage(MOJO_LOG_LEVEL_ERROR, "/path/to/foo.cc", 123).stream()
      << "hello "
      << "world";
  EXPECT_TRUE(log_message_was_called());
  EXPECT_EQ(MOJO_LOG_LEVEL_ERROR, last_log_level());
  EXPECT_EQ("foo.cc", last_source_file());
  EXPECT_EQ(123u, last_source_line());
  EXPECT_EQ("hello world", last_message());

  ResetMockLogger();

  internal::LogMessage(MOJO_LOG_LEVEL_FATAL, "path/to/foo.cc", 123).stream()
      << "hello "
      << "world";
  EXPECT_TRUE(log_message_was_called());
  EXPECT_EQ(MOJO_LOG_LEVEL_FATAL, last_log_level());
  EXPECT_EQ("foo.cc", last_source_file());
  EXPECT_EQ(123u, last_source_line());
  EXPECT_EQ("hello world", last_message());

  ResetMockLogger();

  internal::LogMessage(MOJO_LOG_LEVEL_VERBOSE, ".\\xy\\foo.cc", 123).stream()
      << "hello "
      << "world";
  EXPECT_TRUE(log_message_was_called());
  EXPECT_EQ(MOJO_LOG_LEVEL_VERBOSE, last_log_level());
  EXPECT_EQ("foo.cc", last_source_file());
  EXPECT_EQ(123u, last_source_line());
  EXPECT_EQ("hello world", last_message());

  ResetMockLogger();

  internal::LogMessage(MOJO_LOG_LEVEL_VERBOSE - 1, "xy\\foo.cc", 123).stream()
      << "hello "
      << "world";
  EXPECT_TRUE(log_message_was_called());
  EXPECT_EQ(MOJO_LOG_LEVEL_VERBOSE - 1, last_log_level());
  EXPECT_EQ("foo.cc", last_source_file());
  EXPECT_EQ(123u, last_source_line());
  EXPECT_EQ("hello world", last_message());

  ResetMockLogger();

  internal::LogMessage(MOJO_LOG_LEVEL_VERBOSE - 9, "C:\\xy\\foo.cc", 123)
          .stream()
      << "hello "
      << "world";
  EXPECT_TRUE(log_message_was_called());
  EXPECT_EQ(MOJO_LOG_LEVEL_VERBOSE - 9, last_log_level());
  EXPECT_EQ("foo.cc", last_source_file());
  EXPECT_EQ(123u, last_source_line());
  EXPECT_EQ("hello world", last_message());

  ResetMockLogger();

  internal::LogMessage(MOJO_LOG_LEVEL_INFO, __FILE__, 123).stream() << "hello "
                                                                    << "world";
  EXPECT_TRUE(log_message_was_called());
  EXPECT_EQ(MOJO_LOG_LEVEL_INFO, last_log_level());
  EXPECT_EQ(kOurFilename, last_source_file());
  EXPECT_EQ(123u, last_source_line());
  EXPECT_EQ("hello world", last_message());
}

TEST_F(LoggingTest, LogStream) {
  MOJO_LOG_STREAM(INFO) << "hello";
  EXPECT_TRUE(log_message_was_called());
  EXPECT_EQ(MOJO_LOG_LEVEL_INFO, last_log_level());
  EXPECT_EQ(kOurFilename, last_source_file());
  EXPECT_EQ(static_cast<uint32_t>(__LINE__ - 4), last_source_line());
  EXPECT_EQ("hello", last_message());

  ResetMockLogger();

  MOJO_LOG_STREAM(ERROR) << "hi " << 123;
  EXPECT_TRUE(log_message_was_called());
  EXPECT_EQ(MOJO_LOG_LEVEL_ERROR, last_log_level());
  EXPECT_EQ(kOurFilename, last_source_file());
  EXPECT_EQ(static_cast<uint32_t>(__LINE__ - 4), last_source_line());
  EXPECT_EQ("hi 123", last_message());
}

TEST_F(LoggingTest, LazyLogStream) {
  MOJO_LAZY_LOG_STREAM(INFO, true) << "hello";
  EXPECT_TRUE(log_message_was_called());
  EXPECT_EQ(MOJO_LOG_LEVEL_INFO, last_log_level());
  EXPECT_EQ(kOurFilename, last_source_file());
  EXPECT_EQ(static_cast<uint32_t>(__LINE__ - 4), last_source_line());
  EXPECT_EQ("hello", last_message());

  ResetMockLogger();

  MOJO_LAZY_LOG_STREAM(ERROR, true) << "hi " << 123;
  EXPECT_TRUE(log_message_was_called());
  EXPECT_EQ(MOJO_LOG_LEVEL_ERROR, last_log_level());
  EXPECT_EQ(kOurFilename, last_source_file());
  EXPECT_EQ(static_cast<uint32_t>(__LINE__ - 4), last_source_line());
  EXPECT_EQ("hi 123", last_message());

  ResetMockLogger();

  MOJO_LAZY_LOG_STREAM(INFO, false) << "hello";
  EXPECT_FALSE(log_message_was_called());

  ResetMockLogger();

  MOJO_LAZY_LOG_STREAM(FATAL, false) << "hello";
  EXPECT_FALSE(log_message_was_called());

  ResetMockLogger();

  PtrToMemberHelper helper;
  helper.member = 1;
  int PtrToMemberHelper::*member_ptr = &PtrToMemberHelper::member;

  // This probably fails to compile if we forget to parenthesize the condition
  // in the macro (.* has lower precedence than !, which can't apply to
  // |helper|).
  MOJO_LAZY_LOG_STREAM(ERROR, helper.*member_ptr == 1) << "hello";
  EXPECT_TRUE(log_message_was_called());

  ResetMockLogger();

  MOJO_LAZY_LOG_STREAM(WARNING, helper.*member_ptr == 0) << "hello";
  EXPECT_FALSE(log_message_was_called());
}

TEST_F(LoggingTest, ShouldLog) {
  // We start at |MOJO_LOG_LEVEL_INFO|.
  EXPECT_FALSE(MOJO_SHOULD_LOG(VERBOSE));
  EXPECT_TRUE(MOJO_SHOULD_LOG(INFO));
  EXPECT_TRUE(MOJO_SHOULD_LOG(WARNING));
  EXPECT_TRUE(MOJO_SHOULD_LOG(ERROR));
  EXPECT_TRUE(MOJO_SHOULD_LOG(FATAL));

  Environment::GetDefaultLogger()->SetMinimumLogLevel(MOJO_LOG_LEVEL_ERROR);
  EXPECT_FALSE(MOJO_SHOULD_LOG(VERBOSE));
  EXPECT_FALSE(MOJO_SHOULD_LOG(INFO));
  EXPECT_FALSE(MOJO_SHOULD_LOG(WARNING));
  EXPECT_TRUE(MOJO_SHOULD_LOG(ERROR));
  EXPECT_TRUE(MOJO_SHOULD_LOG(FATAL));

  Environment::GetDefaultLogger()->SetMinimumLogLevel(MOJO_LOG_LEVEL_VERBOSE -
                                                      1);
  EXPECT_TRUE(MOJO_SHOULD_LOG(VERBOSE));
  EXPECT_TRUE(MOJO_SHOULD_LOG(INFO));
  EXPECT_TRUE(MOJO_SHOULD_LOG(WARNING));
  EXPECT_TRUE(MOJO_SHOULD_LOG(ERROR));
  EXPECT_TRUE(MOJO_SHOULD_LOG(FATAL));
}

TEST_F(LoggingTest, Log) {
  // We start at |MOJO_LOG_LEVEL_INFO|.
  MOJO_LOG(VERBOSE) << "hello";
  EXPECT_FALSE(log_message_was_called());

  ResetMockLogger();

  MOJO_LOG(INFO) << "hello";
  EXPECT_TRUE(log_message_was_called());
  EXPECT_EQ(MOJO_LOG_LEVEL_INFO, last_log_level());
  EXPECT_EQ(kOurFilename, last_source_file());
  EXPECT_EQ(static_cast<uint32_t>(__LINE__ - 4), last_source_line());
  EXPECT_EQ("hello", last_message());

  ResetMockLogger();

  MOJO_LOG(ERROR) << "hello";
  EXPECT_TRUE(log_message_was_called());
  EXPECT_EQ(MOJO_LOG_LEVEL_ERROR, last_log_level());
  EXPECT_EQ(kOurFilename, last_source_file());
  EXPECT_EQ(static_cast<uint32_t>(__LINE__ - 4), last_source_line());
  EXPECT_EQ("hello", last_message());

  ResetMockLogger();

  Environment::GetDefaultLogger()->SetMinimumLogLevel(MOJO_LOG_LEVEL_ERROR);

  MOJO_LOG(VERBOSE) << "hello";
  EXPECT_FALSE(log_message_was_called());

  ResetMockLogger();

  MOJO_LOG(INFO) << "hello";
  EXPECT_FALSE(log_message_was_called());

  ResetMockLogger();

  MOJO_LOG(ERROR) << "hello";
  EXPECT_TRUE(log_message_was_called());
  EXPECT_EQ(MOJO_LOG_LEVEL_ERROR, last_log_level());
  EXPECT_EQ(kOurFilename, last_source_file());
  EXPECT_EQ(static_cast<uint32_t>(__LINE__ - 4), last_source_line());
  EXPECT_EQ("hello", last_message());
}

TEST_F(LoggingTest, LogIf) {
  // We start at |MOJO_LOG_LEVEL_INFO|.
  MOJO_LOG_IF(VERBOSE, true) << "hello";
  EXPECT_FALSE(log_message_was_called());

  ResetMockLogger();

  MOJO_LOG_IF(VERBOSE, false) << "hello";
  EXPECT_FALSE(log_message_was_called());

  ResetMockLogger();
  Environment::GetDefaultLogger()->SetMinimumLogLevel(MOJO_LOG_LEVEL_ERROR);

  bool x = true;
  // Also try to make sure that we parenthesize the condition properly.
  MOJO_LOG_IF(INFO, false || x) << "hello";
  EXPECT_FALSE(log_message_was_called());

  ResetMockLogger();

  MOJO_LOG_IF(INFO, 0 != 1) << "hello";
  EXPECT_FALSE(log_message_was_called());

  ResetMockLogger();

  MOJO_LOG_IF(WARNING, 1 + 1 == 2) << "hello";
  EXPECT_FALSE(log_message_was_called());

  ResetMockLogger();

  MOJO_LOG_IF(ERROR, 1 * 2 == 2) << "hello";
  EXPECT_TRUE(log_message_was_called());
  EXPECT_EQ(MOJO_LOG_LEVEL_ERROR, last_log_level());
  EXPECT_EQ(kOurFilename, last_source_file());
  EXPECT_EQ(static_cast<uint32_t>(__LINE__ - 4), last_source_line());
  EXPECT_EQ("hello", last_message());

  ResetMockLogger();

  MOJO_LOG_IF(FATAL, 1 * 2 == 3) << "hello";
  EXPECT_FALSE(log_message_was_called());

  ResetMockLogger();

  // |MOJO_LOG_IF()| shouldn't evaluate its condition if the level is below the
  // minimum.
  MOJO_LOG_IF(INFO, NotCalledCondition()) << "hello";
  EXPECT_FALSE(not_called_condition_was_called());
  EXPECT_FALSE(log_message_was_called());
}

TEST_F(LoggingTest, Check) {
  MOJO_CHECK(true) << "hello";
  EXPECT_FALSE(log_message_was_called());

  ResetMockLogger();

  PtrToMemberHelper helper;
  helper.member = 0;
  int PtrToMemberHelper::*member_ptr = &PtrToMemberHelper::member;

  // Also try to make sure that we parenthesize the condition properly.
  MOJO_CHECK(helper.*member_ptr == 1) << "hello";
  EXPECT_TRUE(log_message_was_called());
  EXPECT_EQ(MOJO_LOG_LEVEL_FATAL, last_log_level());
  EXPECT_EQ(kOurFilename, last_source_file());
  EXPECT_EQ(static_cast<uint32_t>(__LINE__ - 4), last_source_line());
  EXPECT_EQ("Check failed: helper.*member_ptr == 1. hello", last_message());

  ResetMockLogger();

  // Also test a "naked" |MOJO_CHECK()|s.
  MOJO_CHECK(1 + 2 == 3);
  EXPECT_FALSE(log_message_was_called());
}

TEST_F(LoggingTest, Dlog) {
  // We start at |MOJO_LOG_LEVEL_INFO|.
  MOJO_DLOG(VERBOSE) << "hello";
  EXPECT_FALSE(log_message_was_called());

  ResetMockLogger();

  MOJO_DLOG(INFO) << "hello";
#ifdef NDEBUG
  EXPECT_FALSE(log_message_was_called());
#else
  EXPECT_TRUE(log_message_was_called());
  EXPECT_EQ(MOJO_LOG_LEVEL_INFO, last_log_level());
  EXPECT_EQ(kOurFilename, last_source_file());
  EXPECT_EQ(static_cast<uint32_t>(__LINE__ - 7), last_source_line());
  EXPECT_EQ("hello", last_message());
#endif
}

TEST_F(LoggingTest, DlogIf) {
  // We start at |MOJO_LOG_LEVEL_INFO|. It shouldn't evaluate the condition in
  // this case.
  MOJO_DLOG_IF(VERBOSE, NotCalledCondition()) << "hello";
  EXPECT_FALSE(not_called_condition_was_called());
  EXPECT_FALSE(log_message_was_called());

  ResetMockLogger();

  MOJO_DLOG_IF(INFO, 1 == 0) << "hello";
  EXPECT_FALSE(log_message_was_called());

  ResetMockLogger();

  MOJO_DLOG_IF(INFO, 1 == 1) << "hello";
#ifdef NDEBUG
  EXPECT_FALSE(log_message_was_called());
#else
  EXPECT_TRUE(log_message_was_called());
  EXPECT_EQ(MOJO_LOG_LEVEL_INFO, last_log_level());
  EXPECT_EQ(kOurFilename, last_source_file());
  EXPECT_EQ(static_cast<uint32_t>(__LINE__ - 7), last_source_line());
  EXPECT_EQ("hello", last_message());
#endif

  ResetMockLogger();

// |MOJO_DLOG_IF()| shouldn't compile its condition for non-debug builds.
#ifndef NDEBUG
  bool debug_only = true;
#endif
  MOJO_DLOG_IF(WARNING, debug_only) << "hello";
#ifdef NDEBUG
  EXPECT_FALSE(log_message_was_called());
#else
  EXPECT_TRUE(log_message_was_called());
  EXPECT_EQ(MOJO_LOG_LEVEL_WARNING, last_log_level());
  EXPECT_EQ(kOurFilename, last_source_file());
  EXPECT_EQ(static_cast<uint32_t>(__LINE__ - 7), last_source_line());
  EXPECT_EQ("hello", last_message());
#endif
}

TEST_F(LoggingTest, Dcheck) {
  MOJO_DCHECK(true);
  EXPECT_FALSE(log_message_was_called());

  ResetMockLogger();

  MOJO_DCHECK(true) << "hello";
  EXPECT_FALSE(log_message_was_called());

  ResetMockLogger();

  // |MOJO_DCHECK()| should compile (but not evaluate) its condition even for
  // non-debug builds. (Hopefully, we'll get an unused variable error if it
  // fails to compile the condition.)
  bool was_called = false;
  MOJO_DCHECK(DcheckTestHelper(&was_called)) << "hello";
#if defined(NDEBUG) && !defined(DCHECK_ALWAYS_ON)
  EXPECT_FALSE(was_called);
  EXPECT_FALSE(log_message_was_called());
#else
  EXPECT_TRUE(was_called);
  EXPECT_TRUE(log_message_was_called());
  EXPECT_EQ(MOJO_LOG_LEVEL_FATAL, last_log_level());
  EXPECT_EQ(kOurFilename, last_source_file());
  EXPECT_EQ(static_cast<uint32_t>(__LINE__ - 9), last_source_line());
  EXPECT_EQ("Check failed: DcheckTestHelper(&was_called). hello",
            last_message());
#endif

  ResetMockLogger();

  // Also try to make sure that we parenthesize the condition properly.
  bool x = true;
  MOJO_DCHECK(false || x) << "hello";
  EXPECT_FALSE(log_message_was_called());
}

}  // namespace
}  // namespace mojo
