// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <chrono>
#include <cstdlib>
#include <thread>

#include "flutter/fml/closure.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/message_loop_task_queues.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/runtime/dart_vm_lifecycle.h"
#include "flutter/testing/dart_isolate_runner.h"
#include "flutter/testing/fixture_test.h"
#include "third_party/dart/runtime/include/dart_api.h"
#include "third_party/dart/runtime/include/dart_native_api.h"
#include "third_party/dart/runtime/include/dart_tools_api.h"
#include "tonic/logging/dart_invoke.h"

namespace flutter {
namespace testing {

namespace {

Settings CreateStartPausedVmServiceSettings(const Settings& base_settings) {
  Settings settings = base_settings;
  settings.start_paused = true;
  settings.enable_vm_service = true;
  settings.vm_service_host = "127.0.0.1";
  return settings;
}

void WaitUntilPausedOnStart(AutoIsolateShutdown* isolate,
                            const fml::RefPtr<fml::TaskRunner>& ui_runner) {
  while (true) {
    bool is_paused = false;
    ASSERT_TRUE(isolate->RunInIsolateScope([&]() {
      is_paused = Dart_IsPausedOnStart();
      return true;
    }));
    if (is_paused) {
      return;
    }
    fml::AutoResetWaitableEvent turn;
    ui_runner->PostDelayedTask([&]() { turn.Signal(); },
                               fml::TimeDelta::FromMilliseconds(2));
    turn.Wait();
  }
}

std::string GetIsolateServiceId(AutoIsolateShutdown* isolate) {
  Dart_Port main_port = ILLEGAL_PORT;
  bool ok = isolate->RunInIsolateScope([&]() {
    main_port = Dart_GetMainPortId();
    return main_port != ILLEGAL_PORT;
  });
  FML_CHECK(ok);
  return "isolates/" + std::to_string(main_port);
}

// Sends a VM Service `resume` RPC directly to the in-process VM service
// isolate via `Dart_InvokeVMServiceMethod` (avoiding TCP sockets so the test
// works in sandboxed environments such as Fuchsia).
bool InvokeVmServiceResume(const std::string& isolate_id) {
  std::string request =
      R"({"jsonrpc":"2.0","id":"1","method":"resume","params":{"isolateId":")" +
      isolate_id + R"("}})";
  for (int attempt = 0; attempt < 500; ++attempt) {
    uint8_t* response_json = nullptr;
    intptr_t response_json_length = 0;
    char* error = nullptr;
    const bool ok = Dart_InvokeVMServiceMethod(
        reinterpret_cast<uint8_t*>(request.data()), request.size(),
        &response_json, &response_json_length, &error);
    std::string response;
    if (response_json != nullptr) {
      response.assign(reinterpret_cast<char*>(response_json),
                      response_json_length);
      std::free(response_json);
    }
    if (error != nullptr) {
      std::free(error);
    }
    if (ok && response.find(R"("type":"Success")") != std::string::npos) {
      return true;
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(10));
  }
  return false;
}

void ClearPausedOnStartForShutdown(AutoIsolateShutdown* isolate) {
  (void)isolate->RunInIsolateScope([&]() {
    if (Dart_IsPausedOnStart()) {
      Dart_SetPausedOnStart(false);
    }
    return true;
  });
}

}  // namespace

class DartMessageHandlerTest : public FixtureTest {
 protected:
  struct PausedIsolateSession {
    PausedIsolateSession(Settings s, fml::RefPtr<fml::TaskRunner> thread)
        : settings(std::move(s)),
          vm_ref(DartVMRef::Create(settings)),
          ui_thread(std::move(thread)) {}

    ~PausedIsolateSession() {
      if (paused_isolate) {
        ClearPausedOnStartForShutdown(paused_isolate.get());
        paused_isolate->Shutdown();
      }
    }

    Settings settings;
    DartVMRef vm_ref;
    fml::RefPtr<fml::TaskRunner> ui_thread;
    std::string target_isolate_id;
    fml::AutoResetWaitableEvent main_ran;
    std::unique_ptr<AutoIsolateShutdown> paused_isolate;
  };

  std::unique_ptr<PausedIsolateSession> StartPausedIsolateSession(
      const std::string& entrypoint) {
    auto session = std::make_unique<PausedIsolateSession>(
        CreateStartPausedVmServiceSettings(CreateSettingsForFixture()),
        CreateNewThread());
    if (!session->vm_ref) {
      return nullptr;
    }

    AddNativeCallback(
        "SignalDone",
        CREATE_NATIVE_ENTRY([raw = session.get()](Dart_NativeArguments args) {
          raw->main_ran.Signal();
        }));

    TaskRunners paused_runners(GetCurrentTestName(), session->ui_thread,
                               session->ui_thread, session->ui_thread,
                               session->ui_thread);
    session->paused_isolate =
        RunDartCodeInIsolate(session->vm_ref, session->settings, paused_runners,
                             entrypoint, {}, GetDefaultKernelFilePath());
    if (!session->paused_isolate) {
      return nullptr;
    }

    WaitUntilPausedOnStart(session->paused_isolate.get(), session->ui_thread);
    session->target_isolate_id =
        GetIsolateServiceId(session->paused_isolate.get());
    return session;
  }
};

// Regression test for https://github.com/Dart-Code/Dart-Code/issues/6156:
// When an isolate is paused at `PauseStart` and an embedder `Dart_Invoke` on
// the primary UI queue (while `kDartEventLoop` secondary tasks are paused, such
// as during `VsyncWaiter::FireCallback`) hits `Thread::HandleInterrupts()` and
// drains the OOB `resume` service message before `DartMessageHandler` runs its
// scheduled `OnHandleMessage` task, `DartMessageHandler` must still observe
// that pause-on-start has been cleared and resume `main()`.
TEST_F(DartMessageHandlerTest,
       PauseOnStartResumesWhenServiceResumeConsumedByInterrupt) {
#if (FLUTTER_RUNTIME_MODE != FLUTTER_RUNTIME_MODE_DEBUG) && \
    (FLUTTER_RUNTIME_MODE != FLUTTER_RUNTIME_MODE_PROFILE)
  GTEST_SKIP();
#endif
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
  auto session = StartPausedIsolateSession("pauseOnStartMain");
  ASSERT_TRUE(session);
  EXPECT_TRUE(
      session->main_ran.WaitWithTimeout(fml::TimeDelta::FromMilliseconds(20)));

  // Pause `kDartEventLoop` tasks on the UI queue, mirroring
  // `VsyncWaiter::PauseDartEventLoopTasks()`.
  const fml::TaskQueueId ui_queue_id = session->ui_thread->GetTaskQueueId();
  fml::AutoResetWaitableEvent paused_event_loop;
  session->ui_thread->PostTask([&]() {
    fml::MessageLoopTaskQueues::GetInstance()->PauseSecondarySource(
        ui_queue_id);
    paused_event_loop.Signal();
  });
  paused_event_loop.Wait();

  bool secondary_source_resumed = false;
  auto resume_secondary_source = [&]() {
    if (secondary_source_resumed) {
      return;
    }
    secondary_source_resumed = true;
    fml::AutoResetWaitableEvent resumed;
    session->ui_thread->PostTask([&]() {
      fml::MessageLoopTaskQueues::GetInstance()->ResumeSecondarySource(
          ui_queue_id);
      resumed.Signal();
    });
    resumed.Wait();
  };

  bool resume_succeeded = false;
  fml::ManualResetWaitableEvent resume_completed;
  auto rpc_thread = CreateNewThread();
  rpc_thread->PostTask([&]() {
    resume_succeeded = InvokeVmServiceResume(session->target_isolate_id);
    resume_completed.Signal();
  });

  fml::ScopedCleanupClosure cleanup([&]() {
    resume_secondary_source();
    resume_completed.Wait();
  });

  // Wait until the OOB `resume` message is queued on `paused_isolate` while
  // `kDartEventLoop` tasks are still held back.
  bool has_service_messages = false;
  for (int attempt = 0; attempt < 6000 && !has_service_messages; ++attempt) {
    ASSERT_TRUE(session->paused_isolate->RunInIsolateScope([&]() {
      has_service_messages = Dart_HasServiceMessages();
      return true;
    }));
    if (!has_service_messages) {
      fml::AutoResetWaitableEvent poll;
      session->ui_thread->PostDelayedTask([&]() { poll.Signal(); },
                                          fml::TimeDelta::FromMilliseconds(5));
      poll.Wait();
    }
  }
  ASSERT_TRUE(has_service_messages);

  // Invoke a Dart callback directly on the primary UI queue before
  // `DartMessageHandler::OnHandleMessage` can run. Its prologue hits
  // `Thread::HandleInterrupts()`, draining the OOB `resume` message.
  bool should_pause_on_start = true;
  ASSERT_TRUE(session->paused_isolate->RunInIsolateScope([&]() {
    Dart_Handle result =
        tonic::DartInvokeField(Dart_RootLibrary(), "embedderCallback", {});
    EXPECT_FALSE(Dart_IsError(result));
    should_pause_on_start = Dart_ShouldPauseOnStart();
    EXPECT_TRUE(Dart_IsPausedOnStart());
    return true;
  }));
  // Abort early on failure so `cleanup` resumes `kDartEventLoop` before
  // waiting on `resume_completed`, avoiding a deadlock if the interrupt did
  // not drain the OOB `resume` message.
  ASSERT_FALSE(should_pause_on_start);

  resume_completed.Wait();
  EXPECT_TRUE(resume_succeeded);

  // Now unpause `kDartEventLoop` tasks (mirroring
  // `VsyncWaiter::ResumeDartEventLoopTasks()`) so the scheduled
  // `DartMessageHandler::OnHandleMessage` task runs.
  resume_secondary_source();

  EXPECT_FALSE(
      session->main_ran.WaitWithTimeout(fml::TimeDelta::FromSeconds(30)));
}

// Verifies that if multiple normal `SendPort` messages arrive while an isolate
// is paused at `PauseStart` (consuming their per-message `OnHandleMessage`
// tasks while paused), resuming from `PauseStart` delivers all queued messages
// rather than stranding all but the first, even if `main()` throws a non-fatal
// uncaught exception.
TEST_F(DartMessageHandlerTest,
       PauseOnStartDeliversAllQueuedNormalMessagesUponResume) {
#if (FLUTTER_RUNTIME_MODE != FLUTTER_RUNTIME_MODE_DEBUG) && \
    (FLUTTER_RUNTIME_MODE != FLUTTER_RUNTIME_MODE_PROFILE)
  GTEST_SKIP();
#endif
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());

  fml::AutoResetWaitableEvent all_messages_received;
  int64_t received_sum = 0;
  AddNativeCallback("SignalAllMessagesReceived",
                    CREATE_NATIVE_ENTRY([&](Dart_NativeArguments args) {
                      EXPECT_FALSE(Dart_IsError(Dart_GetNativeIntegerArgument(
                          args, 0, &received_sum)));
                      all_messages_received.Signal();
                    }));

  auto session = StartPausedIsolateSession("pauseOnStartThrowMain");
  ASSERT_TRUE(session);

  // Open a ReceivePort inside `paused_isolate` and post 3 normal messages to it
  // while `Dart_IsPausedOnStart()` is true.
  Dart_Port test_port_id = ILLEGAL_PORT;
  ASSERT_TRUE(session->paused_isolate->RunInIsolateScope([&]() {
    Dart_Handle send_port =
        tonic::DartInvokeField(Dart_RootLibrary(), "openPausedTestPort", {});
    EXPECT_FALSE(Dart_IsError(send_port));
    EXPECT_FALSE(Dart_IsError(Dart_SendPortGetId(send_port, &test_port_id)));
    EXPECT_NE(test_port_id, ILLEGAL_PORT);
    return true;
  }));

  EXPECT_TRUE(Dart_PostInteger(test_port_id, 10));
  EXPECT_TRUE(Dart_PostInteger(test_port_id, 20));
  EXPECT_TRUE(Dart_PostInteger(test_port_id, 30));

  // Flush the `OnHandleMessage` tasks scheduled for those 3 messages while the
  // isolate is still paused on start.
  fml::AutoResetWaitableEvent flushed_while_paused;
  fml::MessageLoopTaskQueues::GetInstance()->RegisterTask(
      session->ui_thread->GetTaskQueueId(),
      [&]() { flushed_while_paused.Signal(); }, fml::TimePoint::Now(),
      fml::TaskSourceGrade::kDartEventLoop);
  flushed_while_paused.Wait();

  ASSERT_TRUE(session->paused_isolate->RunInIsolateScope([&]() {
    EXPECT_TRUE(Dart_IsPausedOnStart());
    return true;
  }));

  EXPECT_TRUE(InvokeVmServiceResume(session->target_isolate_id));

  EXPECT_FALSE(
      session->main_ran.WaitWithTimeout(fml::TimeDelta::FromSeconds(30)));
  EXPECT_FALSE(
      all_messages_received.WaitWithTimeout(fml::TimeDelta::FromSeconds(30)));
  EXPECT_EQ(received_sum, 60);
}

}  // namespace testing
}  // namespace flutter
