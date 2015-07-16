// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TEST_MOCK_LOG_H_
#define BASE_TEST_MOCK_LOG_H_

#include <string>

#include "base/logging.h"
#include "base/macros.h"
#include "base/synchronization/lock.h"
#include "testing/gmock/include/gmock/gmock.h"

namespace base {
namespace test {

// A MockLog object intercepts LOG() messages issued during its lifespan.  Using
// this together with gMock, it's very easy to test how a piece of code calls
// LOG().  The typical usage:
//
//   TEST(FooTest, LogsCorrectly) {
//     MockLog log;
//
//     // We expect the WARNING "Something bad!" exactly twice.
//     EXPECT_CALL(log, Log(WARNING, _, "Something bad!"))
//         .Times(2);
//
//     // We allow foo.cc to call LOG(INFO) any number of times.
//     EXPECT_CALL(log, Log(INFO, HasSubstr("/foo.cc"), _))
//         .Times(AnyNumber());
//
//     log.StartCapturingLogs();  // Call this after done setting expectations.
//     Foo();  // Exercises the code under test.
//   }
//
// CAVEAT: base/logging does not allow a thread to call LOG() again when it's
// already inside a LOG() call.  Doing so will cause a deadlock.  Therefore,
// it's the user's responsibility to not call LOG() in an action triggered by
// MockLog::Log().  You may call RAW_LOG() instead.
class MockLog {
 public:
  // Creates a MockLog object that is not capturing logs.  If it were to start
  // to capture logs, it could be a problem if some other threads already exist
  // and are logging, as the user hasn't had a chance to set up expectation on
  // this object yet (calling a mock method before setting the expectation is
  // UNDEFINED behavior).
  MockLog();

  // When the object is destructed, it stops intercepting logs.
  ~MockLog();

  // Starts log capturing if the object isn't already doing so.
  // Otherwise crashes.
  void StartCapturingLogs();

  // Stops log capturing if the object is capturing logs.  Otherwise crashes.
  void StopCapturingLogs();

  // Log method is invoked for every log message before it's sent to other log
  // destinations (if any).  The method should return true to signal that it
  // handled the message and the message should not be sent to other log
  // destinations.
  MOCK_METHOD5(Log,
               bool(int severity,
                    const char* file,
                    int line,
                    size_t message_start,
                    const std::string& str));

 private:
  // The currently active mock log.
  static MockLog* g_instance_;

  // Lock protecting access to g_instance_.
  static Lock g_lock;

  // Static function which is set as the logging message handler.
  // Called once for each message.
  static bool LogMessageHandler(int severity,
                                const char* file,
                                int line,
                                size_t message_start,
                                const std::string& str);

  // True if this object is currently capturing logs.
  bool is_capturing_logs_;

  // The previous handler to restore when the MockLog is destroyed.
  logging::LogMessageHandlerFunction previous_handler_;

  DISALLOW_COPY_AND_ASSIGN(MockLog);
};

}  // namespace test
}  // namespace base

#endif  // BASE_TEST_MOCK_LOG_H_
