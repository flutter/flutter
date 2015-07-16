// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Unit tests for event trace consumer base class.
#include "base/win/event_trace_consumer.h"

#include <list>

#include <objbase.h>

#include "base/basictypes.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/files/scoped_temp_dir.h"
#include "base/logging.h"
#include "base/process/process_handle.h"
#include "base/strings/stringprintf.h"
#include "base/win/event_trace_controller.h"
#include "base/win/event_trace_provider.h"
#include "base/win/scoped_handle.h"
#include "testing/gtest/include/gtest/gtest.h"

#include <initguid.h>  // NOLINT - has to be last

namespace base {
namespace win {

namespace {

typedef std::list<EVENT_TRACE> EventQueue;

class TestConsumer: public EtwTraceConsumerBase<TestConsumer> {
 public:
  TestConsumer() {
    sank_event_.Set(::CreateEvent(NULL, TRUE, FALSE, NULL));
    ClearQueue();
  }

  ~TestConsumer() {
    ClearQueue();
    sank_event_.Close();
  }

  void ClearQueue() {
    for (EventQueue::const_iterator it(events_.begin()), end(events_.end());
         it != end; ++it) {
      delete[] reinterpret_cast<char*>(it->MofData);
    }

    events_.clear();
  }

  static void EnqueueEvent(EVENT_TRACE* event) {
    events_.push_back(*event);
    EVENT_TRACE& back = events_.back();

    if (event->MofData != NULL && event->MofLength != 0) {
      back.MofData = new char[event->MofLength];
      memcpy(back.MofData, event->MofData, event->MofLength);
    }
  }

  static void ProcessEvent(EVENT_TRACE* event) {
    EnqueueEvent(event);
    ::SetEvent(sank_event_.Get());
  }

  static ScopedHandle sank_event_;
  static EventQueue events_;

 private:
  DISALLOW_COPY_AND_ASSIGN(TestConsumer);
};

ScopedHandle TestConsumer::sank_event_;
EventQueue TestConsumer::events_;

class EtwTraceConsumerBaseTest: public testing::Test {
 public:
  EtwTraceConsumerBaseTest()
      : session_name_(StringPrintf(L"TestSession-%d", GetCurrentProcId())) {
  }

  void SetUp() override {
    // Cleanup any potentially dangling sessions.
    EtwTraceProperties ignore;
    EtwTraceController::Stop(session_name_.c_str(), &ignore);

    // Allocate a new GUID for each provider test.
    ASSERT_HRESULT_SUCCEEDED(::CoCreateGuid(&test_provider_));
  }

  void TearDown() override {
    // Cleanup any potentially dangling sessions.
    EtwTraceProperties ignore;
    EtwTraceController::Stop(session_name_.c_str(), &ignore);
  }

 protected:
  GUID test_provider_;
  std::wstring session_name_;
};

}  // namespace

TEST_F(EtwTraceConsumerBaseTest, Initialize) {
  TestConsumer consumer_;
}

TEST_F(EtwTraceConsumerBaseTest, OpenRealtimeSucceedsWhenNoSession) {
  TestConsumer consumer_;
  ASSERT_HRESULT_SUCCEEDED(
      consumer_.OpenRealtimeSession(session_name_.c_str()));
}

TEST_F(EtwTraceConsumerBaseTest, ConsumerImmediateFailureWhenNoSession) {
  TestConsumer consumer_;
  ASSERT_HRESULT_SUCCEEDED(
      consumer_.OpenRealtimeSession(session_name_.c_str()));
  ASSERT_HRESULT_FAILED(consumer_.Consume());
}

namespace {

class EtwTraceConsumerRealtimeTest: public EtwTraceConsumerBaseTest {
 public:
  void SetUp() override {
    EtwTraceConsumerBaseTest::SetUp();
    ASSERT_HRESULT_SUCCEEDED(
        consumer_.OpenRealtimeSession(session_name_.c_str()));
  }

  void TearDown() override {
    consumer_.Close();
    EtwTraceConsumerBaseTest::TearDown();
  }

  DWORD ConsumerThread() {
    ::SetEvent(consumer_ready_.Get());
    return consumer_.Consume();
  }

  static DWORD WINAPI ConsumerThreadMainProc(void* arg) {
    return reinterpret_cast<EtwTraceConsumerRealtimeTest*>(arg)->
        ConsumerThread();
  }

  HRESULT StartConsumerThread() {
    consumer_ready_.Set(::CreateEvent(NULL, TRUE, FALSE, NULL));
    EXPECT_TRUE(consumer_ready_.IsValid());
    consumer_thread_.Set(::CreateThread(NULL, 0, ConsumerThreadMainProc, this,
                                        0, NULL));
    if (consumer_thread_.Get() == NULL)
      return HRESULT_FROM_WIN32(::GetLastError());

    HANDLE events[] = { consumer_ready_.Get(), consumer_thread_.Get() };
    DWORD result = ::WaitForMultipleObjects(arraysize(events), events,
                                            FALSE, INFINITE);
    switch (result) {
      case WAIT_OBJECT_0:
        // The event was set, the consumer_ is ready.
        return S_OK;
      case WAIT_OBJECT_0 + 1: {
          // The thread finished. This may race with the event, so check
          // explicitly for the event here, before concluding there's trouble.
          if (::WaitForSingleObject(consumer_ready_.Get(), 0) == WAIT_OBJECT_0)
            return S_OK;
          DWORD exit_code = 0;
          if (::GetExitCodeThread(consumer_thread_.Get(), &exit_code))
            return exit_code;
          return HRESULT_FROM_WIN32(::GetLastError());
        }
      default:
        return E_UNEXPECTED;
    }
  }

  // Waits for consumer_ thread to exit, and returns its exit code.
  HRESULT JoinConsumerThread() {
    if (::WaitForSingleObject(consumer_thread_.Get(), INFINITE) !=
        WAIT_OBJECT_0) {
      return HRESULT_FROM_WIN32(::GetLastError());
    }

    DWORD exit_code = 0;
    if (::GetExitCodeThread(consumer_thread_.Get(), &exit_code))
      return exit_code;

    return HRESULT_FROM_WIN32(::GetLastError());
  }

  TestConsumer consumer_;
  ScopedHandle consumer_ready_;
  ScopedHandle consumer_thread_;
};

}  // namespace

TEST_F(EtwTraceConsumerRealtimeTest, ConsumerReturnsWhenSessionClosed) {
  EtwTraceController controller;
  if (controller.StartRealtimeSession(session_name_.c_str(), 100 * 1024) ==
      E_ACCESSDENIED) {
    VLOG(1) << "You must be an administrator to run this test on Vista";
    return;
  }

  // Start the consumer_.
  ASSERT_HRESULT_SUCCEEDED(StartConsumerThread());

  // Wait around for the consumer_ thread a bit.
  ASSERT_EQ(WAIT_TIMEOUT, ::WaitForSingleObject(consumer_thread_.Get(), 50));
  ASSERT_HRESULT_SUCCEEDED(controller.Stop(NULL));

  // The consumer_ returns success on session stop.
  ASSERT_HRESULT_SUCCEEDED(JoinConsumerThread());
}

namespace {

// {57E47923-A549-476f-86CA-503D57F59E62}
DEFINE_GUID(
    kTestEventType,
    0x57e47923, 0xa549, 0x476f, 0x86, 0xca, 0x50, 0x3d, 0x57, 0xf5, 0x9e, 0x62);

}  // namespace

TEST_F(EtwTraceConsumerRealtimeTest, ConsumeEvent) {
  EtwTraceController controller;
  if (controller.StartRealtimeSession(session_name_.c_str(), 100 * 1024) ==
      E_ACCESSDENIED) {
    VLOG(1) << "You must be an administrator to run this test on Vista";
    return;
  }

  ASSERT_HRESULT_SUCCEEDED(controller.EnableProvider(
      test_provider_, TRACE_LEVEL_VERBOSE, 0xFFFFFFFF));

  EtwTraceProvider provider(test_provider_);
  ASSERT_EQ(ERROR_SUCCESS, provider.Register());

  // Start the consumer_.
  ASSERT_HRESULT_SUCCEEDED(StartConsumerThread());
  ASSERT_EQ(0, TestConsumer::events_.size());

  EtwMofEvent<1> event(kTestEventType, 1, TRACE_LEVEL_ERROR);
  EXPECT_EQ(ERROR_SUCCESS, provider.Log(&event.header));
  EXPECT_EQ(WAIT_OBJECT_0,
            ::WaitForSingleObject(TestConsumer::sank_event_.Get(), INFINITE));
  ASSERT_HRESULT_SUCCEEDED(controller.Stop(NULL));
  ASSERT_HRESULT_SUCCEEDED(JoinConsumerThread());
  ASSERT_NE(0u, TestConsumer::events_.size());
}

namespace {

// We run events through a file session to assert that
// the content comes through.
class EtwTraceConsumerDataTest: public EtwTraceConsumerBaseTest {
 public:
  EtwTraceConsumerDataTest() {
  }

  void SetUp() override {
    EtwTraceConsumerBaseTest::SetUp();

    EtwTraceProperties prop;
    EtwTraceController::Stop(session_name_.c_str(), &prop);

    // Create a temp dir for this test.
    ASSERT_TRUE(temp_dir_.CreateUniqueTempDir());
    // Construct a temp file name in our dir.
    temp_file_ = temp_dir_.path().Append(L"test.etl");
  }

  void TearDown() override {
    EXPECT_TRUE(base::DeleteFile(temp_file_, false));

    EtwTraceConsumerBaseTest::TearDown();
  }

  HRESULT LogEventToTempSession(PEVENT_TRACE_HEADER header) {
    EtwTraceController controller;

    // Set up a file session.
    HRESULT hr = controller.StartFileSession(session_name_.c_str(),
                                             temp_file_.value().c_str());
    if (FAILED(hr))
      return hr;

    // Enable our provider.
    EXPECT_HRESULT_SUCCEEDED(controller.EnableProvider(
        test_provider_, TRACE_LEVEL_VERBOSE, 0xFFFFFFFF));

    EtwTraceProvider provider(test_provider_);
    // Then register our provider, means we get a session handle immediately.
    EXPECT_EQ(ERROR_SUCCESS, provider.Register());
    // Trace the event, it goes to the temp file.
    EXPECT_EQ(ERROR_SUCCESS, provider.Log(header));
    EXPECT_HRESULT_SUCCEEDED(controller.DisableProvider(test_provider_));
    EXPECT_HRESULT_SUCCEEDED(provider.Unregister());
    EXPECT_HRESULT_SUCCEEDED(controller.Flush(NULL));
    EXPECT_HRESULT_SUCCEEDED(controller.Stop(NULL));

    return S_OK;
  }

  HRESULT ConsumeEventFromTempSession() {
    // Now consume the event(s).
    TestConsumer consumer_;
    HRESULT hr = consumer_.OpenFileSession(temp_file_.value().c_str());
    if (SUCCEEDED(hr))
      hr = consumer_.Consume();
    consumer_.Close();
    // And nab the result.
    events_.swap(TestConsumer::events_);
    return hr;
  }

  HRESULT RoundTripEvent(PEVENT_TRACE_HEADER header, PEVENT_TRACE* trace) {
    base::DeleteFile(temp_file_, false);

    HRESULT hr = LogEventToTempSession(header);
    if (SUCCEEDED(hr))
      hr = ConsumeEventFromTempSession();

    if (FAILED(hr))
      return hr;

    // We should now have the event in the queue.
    if (events_.empty())
      return E_FAIL;

    *trace = &events_.back();
    return S_OK;
  }

  EventQueue events_;
  ScopedTempDir temp_dir_;
  FilePath temp_file_;
};

}  // namespace


TEST_F(EtwTraceConsumerDataTest, RoundTrip) {
  EtwMofEvent<1> event(kTestEventType, 1, TRACE_LEVEL_ERROR);

  static const char kData[] = "This is but test data";
  event.fields[0].DataPtr = reinterpret_cast<ULONG64>(kData);
  event.fields[0].Length = sizeof(kData);

  PEVENT_TRACE trace = NULL;
  HRESULT hr = RoundTripEvent(&event.header, &trace);
  if (hr == E_ACCESSDENIED) {
    VLOG(1) << "You must be an administrator to run this test on Vista";
    return;
  }
  ASSERT_HRESULT_SUCCEEDED(hr) << "RoundTripEvent failed";
  ASSERT_TRUE(trace != NULL);
  ASSERT_EQ(sizeof(kData), trace->MofLength);
  ASSERT_STREQ(kData, reinterpret_cast<const char*>(trace->MofData));
}

}  // namespace win
}  // namespace base
