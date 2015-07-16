// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/trace_event.h"

#include <strstream>

#include "base/at_exit.h"
#include "base/basictypes.h"
#include "base/files/file_util.h"
#include "base/trace_event/trace_event.h"
#include "base/trace_event/trace_event_win.h"
#include "base/win/event_trace_consumer.h"
#include "base/win/event_trace_controller.h"
#include "base/win/event_trace_provider.h"
#include "base/win/windows_version.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"
#include <initguid.h>  // NOLINT - must be last include.

namespace base {
namespace trace_event {

namespace {

using testing::_;
using testing::AnyNumber;
using testing::InSequence;
using testing::Ge;
using testing::Le;
using testing::NotNull;

using base::win::EtwEventType;
using base::win::EtwTraceConsumerBase;
using base::win::EtwTraceController;
using base::win::EtwTraceProperties;

// Data for unittests traces.
const char kEmpty[] = "";
const char kName[] = "unittest.trace_name";
const char kExtra[] = "UnittestDummyExtraString";
const void* kId = kName;

const wchar_t kTestSessionName[] = L"TraceEvent unittest session";

MATCHER_P(BufferStartsWith, str, "Buffer starts with") {
  return memcmp(arg, str.c_str(), str.length()) == 0;
}

// Duplicated from <evntrace.h> to fix link problems.
DEFINE_GUID( /* 68fdd900-4a3e-11d1-84f4-0000f80464e3 */
    kEventTraceGuid,
    0x68fdd900,
    0x4a3e,
    0x11d1,
    0x84, 0xf4, 0x00, 0x00, 0xf8, 0x04, 0x64, 0xe3);

class TestEventConsumer: public EtwTraceConsumerBase<TestEventConsumer> {
 public:
  TestEventConsumer() {
    EXPECT_TRUE(current_ == NULL);
    current_ = this;
  }

  ~TestEventConsumer() {
    EXPECT_TRUE(current_ == this);
    current_ = NULL;
  }

  MOCK_METHOD4(Event, void(REFGUID event_class,
                      EtwEventType event_type,
                      size_t buf_len,
                      const void* buf));

  static void ProcessEvent(EVENT_TRACE* event) {
    ASSERT_TRUE(current_ != NULL);
    current_->Event(event->Header.Guid,
                    event->Header.Class.Type,
                    event->MofLength,
                    event->MofData);
  }

 private:
  static TestEventConsumer* current_;
};

TestEventConsumer* TestEventConsumer::current_ = NULL;

class TraceEventWinTest: public testing::Test {
 public:
  TraceEventWinTest() {
  }

  void SetUp() override {
    bool is_xp = win::GetVersion() < base::win::VERSION_VISTA;

    if (is_xp) {
      // Tear down any dangling session from an earlier failing test.
      EtwTraceProperties ignore;
      EtwTraceController::Stop(kTestSessionName, &ignore);
    }

    // Resurrect and initialize the TraceLog singleton instance.
    // On Vista and better, we need the provider registered before we
    // start the private, in-proc session, but on XP we need the global
    // session created and the provider enabled before we register our
    // provider.
    TraceEventETWProvider* tracelog = NULL;
    if (!is_xp) {
      TraceEventETWProvider::Resurrect();
      tracelog = TraceEventETWProvider::GetInstance();
      ASSERT_TRUE(tracelog != NULL);
      ASSERT_FALSE(tracelog->IsTracing());
    }

    // Create the log file.
    ASSERT_TRUE(base::CreateTemporaryFile(&log_file_));

    // Create a private log session on the file.
    EtwTraceProperties prop;
    ASSERT_HRESULT_SUCCEEDED(prop.SetLoggerFileName(log_file_.value().c_str()));
    EVENT_TRACE_PROPERTIES& p = *prop.get();
    p.Wnode.ClientContext = 1;  // QPC timer accuracy.
    p.LogFileMode = EVENT_TRACE_FILE_MODE_SEQUENTIAL;   // Sequential log.

    // On Vista and later, we create a private in-process log session, because
    // otherwise we'd need administrator privileges. Unfortunately we can't
    // do the same on XP and better, because the semantics of a private
    // logger session are different, and the IN_PROC flag is not supported.
    if (!is_xp) {
      p.LogFileMode |= EVENT_TRACE_PRIVATE_IN_PROC |  // In-proc for non-admin.
          EVENT_TRACE_PRIVATE_LOGGER_MODE;  // Process-private log.
    }

    p.MaximumFileSize = 100;  // 100M file size.
    p.FlushTimer = 1;  // 1 second flush lag.
    ASSERT_HRESULT_SUCCEEDED(controller_.Start(kTestSessionName, &prop));

    // Enable the TraceLog provider GUID.
    ASSERT_HRESULT_SUCCEEDED(
        controller_.EnableProvider(kChromeTraceProviderName,
                                   TRACE_LEVEL_INFORMATION,
                                   0));

    if (is_xp) {
      TraceEventETWProvider::Resurrect();
      tracelog = TraceEventETWProvider::GetInstance();
    }
    ASSERT_TRUE(tracelog != NULL);
    EXPECT_TRUE(tracelog->IsTracing());
  }

  void TearDown() override {
    EtwTraceProperties prop;
    if (controller_.session() != 0)
      EXPECT_HRESULT_SUCCEEDED(controller_.Stop(&prop));

    if (!log_file_.value().empty())
      base::DeleteFile(log_file_, false);

    // We want our singleton torn down after each test.
    TraceLog::DeleteForTesting();
  }

  void ExpectEvent(REFGUID guid,
                   EtwEventType type,
                   const char* name,
                   size_t name_len,
                   const void* id,
                   const char* extra,
                   size_t extra_len) {
    // Build the trace event buffer we expect will result from this.
    std::stringbuf str;
    str.sputn(name, name_len + 1);
    str.sputn(reinterpret_cast<const char*>(&id), sizeof(id));
    str.sputn(extra, extra_len + 1);

    // And set up the expectation for the event callback.
    EXPECT_CALL(consumer_, Event(guid,
                                 type,
                                 testing::Ge(str.str().length()),
                                 BufferStartsWith(str.str())));
  }

  void ExpectPlayLog() {
    // Ignore EventTraceGuid events.
    EXPECT_CALL(consumer_, Event(kEventTraceGuid, _, _, _))
        .Times(AnyNumber());
  }

  void PlayLog() {
    EtwTraceProperties prop;
    EXPECT_HRESULT_SUCCEEDED(controller_.Flush(&prop));
    EXPECT_HRESULT_SUCCEEDED(controller_.Stop(&prop));
    ASSERT_HRESULT_SUCCEEDED(
        consumer_.OpenFileSession(log_file_.value().c_str()));

    ASSERT_HRESULT_SUCCEEDED(consumer_.Consume());
  }

 private:
  // We want our singleton torn down after each test.
  ShadowingAtExitManager at_exit_manager_;
  EtwTraceController controller_;
  FilePath log_file_;
  TestEventConsumer consumer_;
};

}  // namespace


TEST_F(TraceEventWinTest, TraceLog) {
  ExpectPlayLog();

  // The events should arrive in the same sequence as the expects.
  InSequence in_sequence;

  // Full argument version, passing lengths explicitly.
  TraceEventETWProvider::Trace(kName,
                        strlen(kName),
                        TRACE_EVENT_PHASE_BEGIN,
                        kId,
                        kExtra,
                        strlen(kExtra));

  ExpectEvent(kTraceEventClass32,
              kTraceEventTypeBegin,
              kName, strlen(kName),
              kId,
              kExtra, strlen(kExtra));

  // Const char* version.
  TraceEventETWProvider::Trace(static_cast<const char*>(kName),
                        TRACE_EVENT_PHASE_END,
                        kId,
                        static_cast<const char*>(kExtra));

  ExpectEvent(kTraceEventClass32,
              kTraceEventTypeEnd,
              kName, strlen(kName),
              kId,
              kExtra, strlen(kExtra));

  // std::string extra version.
  TraceEventETWProvider::Trace(static_cast<const char*>(kName),
                        TRACE_EVENT_PHASE_INSTANT,
                        kId,
                        std::string(kExtra));

  ExpectEvent(kTraceEventClass32,
              kTraceEventTypeInstant,
              kName, strlen(kName),
              kId,
              kExtra, strlen(kExtra));


  // Test for sanity on NULL inputs.
  TraceEventETWProvider::Trace(NULL,
                        0,
                        TRACE_EVENT_PHASE_BEGIN,
                        kId,
                        NULL,
                        0);

  ExpectEvent(kTraceEventClass32,
              kTraceEventTypeBegin,
              kEmpty, 0,
              kId,
              kEmpty, 0);

  TraceEventETWProvider::Trace(NULL,
                        TraceEventETWProvider::kUseStrlen,
                        TRACE_EVENT_PHASE_END,
                        kId,
                        NULL,
                        TraceEventETWProvider::kUseStrlen);

  ExpectEvent(kTraceEventClass32,
              kTraceEventTypeEnd,
              kEmpty, 0,
              kId,
              kEmpty, 0);

  PlayLog();
}

TEST_F(TraceEventWinTest, Macros) {
  ExpectPlayLog();

  // The events should arrive in the same sequence as the expects.
  InSequence in_sequence;

  TRACE_EVENT_BEGIN_ETW(kName, kId, kExtra);
  ExpectEvent(kTraceEventClass32,
              kTraceEventTypeBegin,
              kName, strlen(kName),
              kId,
              kExtra, strlen(kExtra));

  TRACE_EVENT_END_ETW(kName, kId, kExtra);
  ExpectEvent(kTraceEventClass32,
              kTraceEventTypeEnd,
              kName, strlen(kName),
              kId,
              kExtra, strlen(kExtra));

  TRACE_EVENT_INSTANT_ETW(kName, kId, kExtra);
  ExpectEvent(kTraceEventClass32,
              kTraceEventTypeInstant,
              kName, strlen(kName),
              kId,
              kExtra, strlen(kExtra));

  PlayLog();
}

}  // namespace trace_event
}  // namespace base
