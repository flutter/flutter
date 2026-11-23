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

Settings CreateVmServiceSettings(const Settings& base_settings,
                                 bool start_paused,
                                 bool pause_on_exit) {
  Settings settings = base_settings;
  settings.start_paused = start_paused;
  settings.enable_vm_service = true;
  if (pause_on_exit) {
    settings.root_isolate_create_callback = [](const auto&) {
      Dart_SetShouldPauseOnExit(true);
    };
  }
  return settings;
}

template <typename Predicate>
void WaitUntilIsolateCondition(AutoIsolateShutdown* isolate,
                               const fml::RefPtr<fml::TaskRunner>& ui_runner,
                               Predicate predicate) {
  for (int attempt = 0; attempt < 6000; ++attempt) {
    bool satisfied = false;
    ASSERT_TRUE(isolate->RunInIsolateScope([&]() {
      satisfied = predicate();
      return true;
    }));
    if (satisfied) {
      return;
    }
    fml::AutoResetWaitableEvent turn;
    ui_runner->PostDelayedTask([&]() { turn.Signal(); },
                               fml::TimeDelta::FromMilliseconds(5));
    turn.Wait();
  }
  FAIL() << "Timed out waiting for isolate condition.";
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

// Invokes a VM Service JSON-RPC method directly on the in-process VM service
// isolate via `Dart_InvokeVMServiceMethod` (avoiding TCP sockets so the test
// works in sandboxed environments such as Fuchsia).
bool InvokeVmServiceMethod(std::string request) {
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
    // Retry only while the service isolate has not yet finished initializing or
    // registered the target isolate as runnable.
    constexpr const char* kIsolateMustBeRunnableCode = R"("code":105)";
    constexpr const char* kServiceDisappearedCode = R"("code":112)";
    const bool transient_not_registered =
        !ok || response.find(kIsolateMustBeRunnableCode) != std::string::npos ||
        response.find(kServiceDisappearedCode) != std::string::npos;
    if (!transient_not_registered) {
      return false;
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(10));
  }
  return false;
}

bool InvokeVmServiceResume(const std::string& isolate_id) {
  return InvokeVmServiceMethod(
      R"({"jsonrpc":"2.0","id":"1","method":"resume","params":{"isolateId":")" +
      isolate_id + R"("}})");
}

bool InvokeVmServiceSetFlag(const std::string& name, const std::string& value) {
  return InvokeVmServiceMethod(
      R"({"jsonrpc":"2.0","id":"1","method":"setFlag","params":{"name":")" +
      name + R"(","value":")" + value + R"("}})");
}

void ClearPausedStateForShutdown(AutoIsolateShutdown* isolate) {
  (void)isolate->RunInIsolateScope([&]() {
    if (Dart_IsPausedOnStart()) {
      Dart_SetPausedOnStart(false);
    }
    if (Dart_IsPausedOnExit()) {
      Dart_SetPausedOnExit(false);
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
        ClearPausedStateForShutdown(paused_isolate.get());
        paused_isolate->Shutdown();
      }
      // `Dart_SetVMFlags` mutates process-global Dart VM flags that persist
      // across `DartVM` instances in the same test binary. Reset
      // `pause_isolates_on_start` before shutting down the VM so subsequent
      // tests (or `--gtest_shuffle` / `--gtest_repeat`) are unaffected.
      if (vm_ref && settings.start_paused) {
        EXPECT_TRUE(InvokeVmServiceSetFlag("pause_isolates_on_start", "false"));
      }
    }

    Settings settings;
    DartVMRef vm_ref;
    fml::RefPtr<fml::TaskRunner> ui_thread;
    std::string target_isolate_id;
    fml::AutoResetWaitableEvent main_ran;
    std::unique_ptr<AutoIsolateShutdown> paused_isolate;
  };

  std::unique_ptr<PausedIsolateSession> StartIsolateSession(
      const std::string& entrypoint,
      bool start_paused,
      bool pause_on_exit) {
    auto session = std::make_unique<PausedIsolateSession>(
        CreateVmServiceSettings(CreateSettingsForFixture(), start_paused,
                                pause_on_exit),
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

    if (start_paused) {
      WaitUntilIsolateCondition(session->paused_isolate.get(),
                                session->ui_thread, Dart_IsPausedOnStart);
    } else if (pause_on_exit) {
      WaitUntilIsolateCondition(session->paused_isolate.get(),
                                session->ui_thread, Dart_IsPausedOnExit);
    }
    session->target_isolate_id =
        GetIsolateServiceId(session->paused_isolate.get());
    return session;
  }

  void RunResumeConsumedByInterruptTest(bool pause_on_start) {
    ASSERT_FALSE(DartVMRef::IsInstanceRunning());
    auto session = StartIsolateSession("pauseOnStartMain",
                                       /*start_paused=*/pause_on_start,
                                       /*pause_on_exit=*/!pause_on_start);
    ASSERT_TRUE(session);
    if (pause_on_start) {
      EXPECT_TRUE(session->main_ran.WaitWithTimeout(
          fml::TimeDelta::FromMilliseconds(20)));
    } else {
      EXPECT_FALSE(
          session->main_ran.WaitWithTimeout(fml::TimeDelta::FromSeconds(30)));
    }

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
    WaitUntilIsolateCondition(session->paused_isolate.get(), session->ui_thread,
                              Dart_HasServiceMessages);

    // Invoke a Dart callback directly on the primary UI queue before
    // `DartMessageHandler::OnHandleMessage` can run. Its prologue hits
    // `Thread::HandleInterrupts()`, draining the OOB `resume` message.
    bool still_should_pause = true;
    ASSERT_TRUE(session->paused_isolate->RunInIsolateScope([&]() {
      Dart_Handle result =
          tonic::DartInvokeField(Dart_RootLibrary(), "embedderCallback", {});
      EXPECT_FALSE(Dart_IsError(result));
      still_should_pause =
          pause_on_start ? Dart_ShouldPauseOnStart() : Dart_ShouldPauseOnExit();
      EXPECT_TRUE(pause_on_start ? Dart_IsPausedOnStart()
                                 : Dart_IsPausedOnExit());
      return true;
    }));
    // Abort early on failure so `cleanup` resumes `kDartEventLoop` before
    // waiting on `resume_completed`, avoiding a deadlock if the interrupt did
    // not drain the OOB `resume` message.
    ASSERT_FALSE(still_should_pause);

    resume_completed.Wait();
    EXPECT_TRUE(resume_succeeded);

    // Now unpause `kDartEventLoop` tasks (mirroring
    // `VsyncWaiter::ResumeDartEventLoopTasks()`) so the scheduled
    // `DartMessageHandler::OnHandleMessage` task runs.
    resume_secondary_source();

    if (pause_on_start) {
      EXPECT_FALSE(
          session->main_ran.WaitWithTimeout(fml::TimeDelta::FromSeconds(30)));
    } else {
      WaitUntilIsolateCondition(session->paused_isolate.get(),
                                session->ui_thread,
                                []() { return !Dart_IsPausedOnExit(); });
    }
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
  RunResumeConsumedByInterruptTest(/*pause_on_start=*/true);
}

// Symmetric regression test for `PauseExit`: if an embedder `Dart_Invoke`
// drains the OOB `resume` service message via `Thread::HandleInterrupts()`
// before `DartMessageHandler::OnHandleMessage` runs, `DartMessageHandler` must
// still clear `Dart_IsPausedOnExit()`.
TEST_F(DartMessageHandlerTest,
       PauseOnExitResumesWhenServiceResumeConsumedByInterrupt) {
#if (FLUTTER_RUNTIME_MODE != FLUTTER_RUNTIME_MODE_DEBUG) && \
    (FLUTTER_RUNTIME_MODE != FLUTTER_RUNTIME_MODE_PROFILE)
  GTEST_SKIP();
#endif
  RunResumeConsumedByInterruptTest(/*pause_on_start=*/false);
}

}  // namespace testing
}  // namespace flutter
