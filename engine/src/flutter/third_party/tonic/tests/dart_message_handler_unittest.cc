// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/message_loop.h"
#include "flutter/fml/message_loop_task_queues.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/runtime/dart_vm_lifecycle.h"
#include "flutter/testing/dart_isolate_runner.h"
#include "flutter/testing/fixture_test.h"
#include "third_party/dart/runtime/include/dart_api.h"
#include "third_party/dart/runtime/include/dart_native_api.h"
#include "tonic/logging/dart_invoke.h"

namespace flutter {
namespace testing {

namespace {

Settings CreateStartPausedVmServiceSettings(const Settings& base_settings) {
  Settings settings = base_settings;
  settings.start_paused = true;
  settings.enable_vm_service = true;
  settings.vm_service_host = "127.0.0.1";
  settings.vm_service_port = 0;
  settings.enable_service_port_fallback = true;
  settings.disable_service_auth_codes = true;
  settings.task_observer_add = [](intptr_t key, const fml::closure& callback) {
    fml::TaskQueueId queue_id = fml::MessageLoop::GetCurrentTaskQueueId();
    fml::MessageLoopTaskQueues::GetInstance()->AddTaskObserver(queue_id, key,
                                                               callback);
    return queue_id;
  };
  settings.task_observer_remove = [](fml::TaskQueueId queue_id, intptr_t key) {
    fml::MessageLoopTaskQueues::GetInstance()->RemoveTaskObserver(queue_id,
                                                                  key);
  };
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

    Settings settings;
    DartVMRef vm_ref;
    fml::RefPtr<fml::TaskRunner> ui_thread;
    std::string target_isolate_id;
    fml::AutoResetWaitableEvent main_ran;
    fml::AutoResetWaitableEvent resume_completed;
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
    AddNativeCallback(
        "SignalResumeCompleted",
        CREATE_NATIVE_ENTRY([raw = session.get()](Dart_NativeArguments args) {
          raw->resume_completed.Signal();
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

  std::unique_ptr<AutoIsolateShutdown> StartVmServiceResumerIsolate(
      PausedIsolateSession* session) {
    auto helper_thread = CreateNewThread();
    TaskRunners helper_runners(std::string(GetCurrentTestName()) + "_helper",
                               helper_thread, helper_thread, helper_thread,
                               helper_thread);
    auto helper_isolate = RunDartCodeInIsolate(
        session->vm_ref, session->settings, helper_runners,
        "resumePausedIsolateViaVmService", {session->target_isolate_id},
        GetDefaultKernelFilePath());
    if (!helper_isolate) {
      return nullptr;
    }
    WaitUntilPausedOnStart(helper_isolate.get(),
                           helper_runners.GetUITaskRunner());
    bool started = helper_isolate->RunInIsolateScope([&]() {
      Dart_SetShouldPauseOnExit(false);
      Dart_SetPausedOnStart(false);
      Dart_Handle main_msg = Dart_HandleMessage();
      if (Dart_IsError(main_msg)) {
        return false;
      }
      tonic::DartState::Current()->MessageEpilogue(main_msg);
      return true;
    });
    return started ? std::move(helper_isolate) : nullptr;
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

  auto helper_isolate = StartVmServiceResumerIsolate(session.get());
  ASSERT_TRUE(helper_isolate);

  // Wait until the OOB `resume` message is queued on `paused_isolate` while
  // `kDartEventLoop` tasks are still held back.
  while (true) {
    bool has_service_messages = false;
    ASSERT_TRUE(session->paused_isolate->RunInIsolateScope([&]() {
      has_service_messages = Dart_HasServiceMessages();
      return true;
    }));
    if (has_service_messages) {
      break;
    }
    fml::AutoResetWaitableEvent poll;
    session->ui_thread->PostDelayedTask([&]() { poll.Signal(); },
                                        fml::TimeDelta::FromMilliseconds(2));
    poll.Wait();
  }

  // Invoke a Dart callback directly on the primary UI queue before
  // `DartMessageHandler::OnHandleMessage` can run. Its prologue hits
  // `Thread::HandleInterrupts()`, draining the OOB `resume` message.
  ASSERT_TRUE(session->paused_isolate->RunInIsolateScope([&]() {
    Dart_Handle result =
        tonic::DartInvokeField(Dart_RootLibrary(), "embedderCallback", {});
    EXPECT_FALSE(Dart_IsError(result));
    EXPECT_FALSE(Dart_ShouldPauseOnStart());
    EXPECT_TRUE(Dart_IsPausedOnStart());
    return true;
  }));

  session->resume_completed.Wait();

  // Now unpause `kDartEventLoop` tasks (mirroring
  // `VsyncWaiter::ResumeDartEventLoopTasks()`) so the scheduled
  // `DartMessageHandler::OnHandleMessage` task runs.
  session->ui_thread->PostTask([&]() {
    fml::MessageLoopTaskQueues::GetInstance()->ResumeSecondarySource(
        ui_queue_id);
  });

  session->main_ran.Wait();

  ClearPausedOnStartForShutdown(session->paused_isolate.get());
  helper_isolate->Shutdown();
  session->paused_isolate->Shutdown();
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

  auto helper_isolate = StartVmServiceResumerIsolate(session.get());
  ASSERT_TRUE(helper_isolate);

  session->resume_completed.Wait();
  session->main_ran.Wait();
  all_messages_received.Wait();
  EXPECT_EQ(received_sum, 60);

  ClearPausedOnStartForShutdown(session->paused_isolate.get());
  helper_isolate->Shutdown();
  session->paused_isolate->Shutdown();
}

}  // namespace testing
}  // namespace flutter
