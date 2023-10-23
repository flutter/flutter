// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/engine.h"

#include <cstring>

#include "flutter/runtime/dart_vm_lifecycle.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/shell_test.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/testing/fixture_test.h"
#include "flutter/testing/testing.h"
#include "gmock/gmock.h"
#include "rapidjson/document.h"
#include "rapidjson/stringbuffer.h"
#include "rapidjson/writer.h"

namespace flutter {

namespace {

using ::testing::Invoke;
using ::testing::ReturnRef;

static void PostSync(const fml::RefPtr<fml::TaskRunner>& task_runner,
                     const fml::closure& task) {
  fml::AutoResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(task_runner, [&latch, &task] {
    task();
    latch.Signal();
  });
  latch.Wait();
}

class MockDelegate : public Engine::Delegate {
 public:
  MOCK_METHOD(void,
              OnEngineUpdateSemantics,
              (SemanticsNodeUpdates, CustomAccessibilityActionUpdates),
              (override));
  MOCK_METHOD(void,
              OnEngineHandlePlatformMessage,
              (std::unique_ptr<PlatformMessage>),
              (override));
  MOCK_METHOD(void, OnPreEngineRestart, (), (override));
  MOCK_METHOD(void, OnRootIsolateCreated, (), (override));
  MOCK_METHOD(void,
              UpdateIsolateDescription,
              (const std::string, int64_t),
              (override));
  MOCK_METHOD(void, SetNeedsReportTimings, (bool), (override));
  MOCK_METHOD(std::unique_ptr<std::vector<std::string>>,
              ComputePlatformResolvedLocale,
              (const std::vector<std::string>&),
              (override));
  MOCK_METHOD(void, RequestDartDeferredLibrary, (intptr_t), (override));
  MOCK_METHOD(fml::TimePoint, GetCurrentTimePoint, (), (override));
  MOCK_METHOD(const std::shared_ptr<PlatformMessageHandler>&,
              GetPlatformMessageHandler,
              (),
              (const, override));
  MOCK_METHOD(void, OnEngineChannelUpdate, (std::string, bool), (override));
  MOCK_METHOD(double,
              GetScaledFontSize,
              (double font_size, int configuration_id),
              (const, override));
};

class MockResponse : public PlatformMessageResponse {
 public:
  MOCK_METHOD(void, Complete, (std::unique_ptr<fml::Mapping> data), (override));
  MOCK_METHOD(void, CompleteEmpty, (), (override));
};

class MockRuntimeDelegate : public RuntimeDelegate {
 public:
  MOCK_METHOD(std::string, DefaultRouteName, (), (override));
  MOCK_METHOD(void, ScheduleFrame, (bool), (override));
  MOCK_METHOD(void,
              Render,
              (int64_t, std::unique_ptr<flutter::LayerTree>, float),
              (override));
  MOCK_METHOD(void,
              UpdateSemantics,
              (SemanticsNodeUpdates, CustomAccessibilityActionUpdates),
              (override));
  MOCK_METHOD(void,
              HandlePlatformMessage,
              (std::unique_ptr<PlatformMessage>),
              (override));
  MOCK_METHOD(FontCollection&, GetFontCollection, (), (override));
  MOCK_METHOD(std::shared_ptr<AssetManager>, GetAssetManager, (), (override));
  MOCK_METHOD(void, OnRootIsolateCreated, (), (override));
  MOCK_METHOD(void,
              UpdateIsolateDescription,
              (const std::string, int64_t),
              (override));
  MOCK_METHOD(void, SetNeedsReportTimings, (bool), (override));
  MOCK_METHOD(std::unique_ptr<std::vector<std::string>>,
              ComputePlatformResolvedLocale,
              (const std::vector<std::string>&),
              (override));
  MOCK_METHOD(void, RequestDartDeferredLibrary, (intptr_t), (override));
  MOCK_METHOD(std::weak_ptr<PlatformMessageHandler>,
              GetPlatformMessageHandler,
              (),
              (const, override));
  MOCK_METHOD(void, SendChannelUpdate, (std::string, bool), (override));
  MOCK_METHOD(double,
              GetScaledFontSize,
              (double font_size, int configuration_id),
              (const, override));
};

class MockRuntimeController : public RuntimeController {
 public:
  MockRuntimeController(RuntimeDelegate& client,
                        const TaskRunners& p_task_runners)
      : RuntimeController(client, p_task_runners) {}
  MOCK_METHOD(bool, IsRootIsolateRunning, (), (override));
  MOCK_METHOD(bool,
              DispatchPlatformMessage,
              (std::unique_ptr<PlatformMessage>),
              (override));
  MOCK_METHOD(void,
              LoadDartDeferredLibraryError,
              (intptr_t, const std::string, bool),
              (override));
  MOCK_METHOD(DartVM*, GetDartVM, (), (const, override));
  MOCK_METHOD(bool, NotifyIdle, (fml::TimeDelta), (override));
};

class MockAnimatorDelegate : public Animator::Delegate {
 public:
  /* Animator::Delegate */
  MOCK_METHOD(void,
              OnAnimatorBeginFrame,
              (fml::TimePoint frame_target_time, uint64_t frame_number),
              (override));
  MOCK_METHOD(void,
              OnAnimatorNotifyIdle,
              (fml::TimeDelta deadline),
              (override));
  MOCK_METHOD(void,
              OnAnimatorUpdateLatestFrameTargetTime,
              (fml::TimePoint frame_target_time),
              (override));
  MOCK_METHOD(void,
              OnAnimatorDraw,
              (std::shared_ptr<FramePipeline> pipeline),
              (override));
  MOCK_METHOD(void,
              OnAnimatorDrawLastLayerTrees,
              (std::unique_ptr<FrameTimingsRecorder> frame_timings_recorder),
              (override));
};

class MockPlatformMessageHandler : public PlatformMessageHandler {
 public:
  MOCK_METHOD(void,
              HandlePlatformMessage,
              (std::unique_ptr<PlatformMessage> message),
              (override));
  MOCK_METHOD(bool,
              DoesHandlePlatformMessageOnPlatformThread,
              (),
              (const, override));
  MOCK_METHOD(void,
              InvokePlatformMessageResponseCallback,
              (int response_id, std::unique_ptr<fml::Mapping> mapping),
              (override));
  MOCK_METHOD(void,
              InvokePlatformMessageEmptyResponseCallback,
              (int response_id),
              (override));
};

std::unique_ptr<PlatformMessage> MakePlatformMessage(
    const std::string& channel,
    const std::map<std::string, std::string>& values,
    const fml::RefPtr<PlatformMessageResponse>& response) {
  rapidjson::Document document;
  auto& allocator = document.GetAllocator();
  document.SetObject();

  for (const auto& pair : values) {
    rapidjson::Value key(pair.first.c_str(), strlen(pair.first.c_str()),
                         allocator);
    rapidjson::Value value(pair.second.c_str(), strlen(pair.second.c_str()),
                           allocator);
    document.AddMember(key, value, allocator);
  }

  rapidjson::StringBuffer buffer;
  rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
  document.Accept(writer);
  const uint8_t* data = reinterpret_cast<const uint8_t*>(buffer.GetString());

  std::unique_ptr<PlatformMessage> message = std::make_unique<PlatformMessage>(
      channel, fml::MallocMapping::Copy(data, buffer.GetSize()), response);
  return message;
}

class EngineTest : public testing::FixtureTest {
 public:
  EngineTest()
      : thread_host_("EngineTest",
                     ThreadHost::Type::Platform | ThreadHost::Type::IO |
                         ThreadHost::Type::UI | ThreadHost::Type::RASTER),
        task_runners_({
            "EngineTest",
            thread_host_.platform_thread->GetTaskRunner(),  // platform
            thread_host_.raster_thread->GetTaskRunner(),    // raster
            thread_host_.ui_thread->GetTaskRunner(),        // ui
            thread_host_.io_thread->GetTaskRunner()         // io
        }) {}

  void PostUITaskSync(const std::function<void()>& function) {
    fml::AutoResetWaitableEvent latch;
    task_runners_.GetUITaskRunner()->PostTask([&] {
      function();
      latch.Signal();
    });
    latch.Wait();
  }

 protected:
  void SetUp() override {
    settings_ = CreateSettingsForFixture();
    dispatcher_maker_ = [](PointerDataDispatcher::Delegate&) {
      return nullptr;
    };
  }

  MockDelegate delegate_;
  PointerDataDispatcherMaker dispatcher_maker_;
  ThreadHost thread_host_;
  TaskRunners task_runners_;
  Settings settings_;
  std::unique_ptr<Animator> animator_;
  fml::WeakPtr<IOManager> io_manager_;
  std::unique_ptr<RuntimeController> runtime_controller_;
  std::shared_ptr<fml::ConcurrentTaskRunner> image_decoder_task_runner_;
  fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate_;
};

// A class that can launch an Engine with the specified Engine::Delegate.
//
// To use this class, contruct this class with Create, call Run, and use the
// engine with EngineTaskSync().
class EngineContext {
 public:
  using EngineCallback = std::function<void(Engine&)>;

  [[nodiscard]] static std::unique_ptr<EngineContext> Create(
      Engine::Delegate& delegate,       //
      Settings settings,                //
      const TaskRunners& task_runners,  //
      std::unique_ptr<Animator> animator) {
    auto [vm, isolate_snapshot] = Shell::InferVmInitDataFromSettings(settings);
    FML_CHECK(vm) << "Must be able to initialize the VM.";
    // Construct the class with `new` because `make_unique` has no access to the
    // private constructor.
    EngineContext* raw_pointer =
        new EngineContext(delegate, settings, task_runners, std::move(animator),
                          std::move(vm), isolate_snapshot);
    return std::unique_ptr<EngineContext>(raw_pointer);
  }

  void Run(RunConfiguration configuration) {
    PostSync(task_runners_.GetUITaskRunner(), [this, &configuration] {
      Engine::RunStatus run_status = engine_->Run(std::move(configuration));
      FML_CHECK(run_status == Engine::RunStatus::Success)
          << "Engine failed to run.";
      (void)run_status;  // Suppress unused-variable warning
    });
  }

  // Run a task that operates the Engine on the UI thread, and wait for the
  // task to end.
  //
  // If called on the UI thread, the task is executed synchronously.
  void EngineTaskSync(EngineCallback task) {
    ASSERT_TRUE(engine_);
    ASSERT_TRUE(task);
    auto runner = task_runners_.GetUITaskRunner();
    if (runner->RunsTasksOnCurrentThread()) {
      task(*engine_);
    } else {
      PostSync(task_runners_.GetUITaskRunner(), [&]() { task(*engine_); });
    }
  }

  ~EngineContext() {
    PostSync(task_runners_.GetUITaskRunner(), [this] { engine_.reset(); });
  }

 private:
  EngineContext(Engine::Delegate& delegate,          //
                Settings settings,                   //
                const TaskRunners& task_runners,     //
                std::unique_ptr<Animator> animator,  //
                DartVMRef vm,                        //
                fml::RefPtr<const DartSnapshot> isolate_snapshot)
      : task_runners_(task_runners), vm_(std::move(vm)) {
    PostSync(task_runners.GetUITaskRunner(), [this, &settings, &animator,
                                              &delegate, &isolate_snapshot] {
      auto dispatcher_maker =
          [](DefaultPointerDataDispatcher::Delegate& delegate) {
            return std::make_unique<DefaultPointerDataDispatcher>(delegate);
          };
      engine_ = std::make_unique<Engine>(
          /*delegate=*/delegate,
          /*dispatcher_maker=*/dispatcher_maker,
          /*vm=*/*&vm_,
          /*isolate_snapshot=*/std::move(isolate_snapshot),
          /*task_runners=*/task_runners_,
          /*platform_data=*/PlatformData(),
          /*settings=*/settings,
          /*animator=*/std::move(animator),
          /*io_manager=*/io_manager_,
          /*unref_queue=*/nullptr,
          /*snapshot_delegate=*/snapshot_delegate_,
          /*volatile_path_tracker=*/nullptr,
          /*gpu_disabled_switch=*/std::make_shared<fml::SyncSwitch>());
    });
  }

  TaskRunners task_runners_;
  DartVMRef vm_;
  std::unique_ptr<Engine> engine_;

  fml::WeakPtr<IOManager> io_manager_;
  fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate_;
};

}  // namespace

TEST_F(EngineTest, Create) {
  PostUITaskSync([this] {
    auto engine = std::make_unique<Engine>(
        /*delegate=*/delegate_,
        /*dispatcher_maker=*/dispatcher_maker_,
        /*image_decoder_task_runner=*/image_decoder_task_runner_,
        /*task_runners=*/task_runners_,
        /*settings=*/settings_,
        /*animator=*/std::move(animator_),
        /*io_manager=*/io_manager_,
        /*font_collection=*/std::make_shared<FontCollection>(),
        /*runtime_controller=*/std::move(runtime_controller_),
        /*gpu_disabled_switch=*/std::make_shared<fml::SyncSwitch>());
    EXPECT_TRUE(engine);
  });
}

TEST_F(EngineTest, DispatchPlatformMessageUnknown) {
  PostUITaskSync([this] {
    MockRuntimeDelegate client;
    auto mock_runtime_controller =
        std::make_unique<MockRuntimeController>(client, task_runners_);
    EXPECT_CALL(*mock_runtime_controller, IsRootIsolateRunning())
        .WillRepeatedly(::testing::Return(false));
    auto engine = std::make_unique<Engine>(
        /*delegate=*/delegate_,
        /*dispatcher_maker=*/dispatcher_maker_,
        /*image_decoder_task_runner=*/image_decoder_task_runner_,
        /*task_runners=*/task_runners_,
        /*settings=*/settings_,
        /*animator=*/std::move(animator_),
        /*io_manager=*/io_manager_,
        /*font_collection=*/std::make_shared<FontCollection>(),
        /*runtime_controller=*/std::move(mock_runtime_controller),
        /*gpu_disabled_switch=*/std::make_shared<fml::SyncSwitch>());

    fml::RefPtr<PlatformMessageResponse> response =
        fml::MakeRefCounted<MockResponse>();
    std::unique_ptr<PlatformMessage> message =
        std::make_unique<PlatformMessage>("foo", response);
    engine->DispatchPlatformMessage(std::move(message));
  });
}

TEST_F(EngineTest, DispatchPlatformMessageInitialRoute) {
  PostUITaskSync([this] {
    MockRuntimeDelegate client;
    auto mock_runtime_controller =
        std::make_unique<MockRuntimeController>(client, task_runners_);
    EXPECT_CALL(*mock_runtime_controller, IsRootIsolateRunning())
        .WillRepeatedly(::testing::Return(false));
    auto engine = std::make_unique<Engine>(
        /*delegate=*/delegate_,
        /*dispatcher_maker=*/dispatcher_maker_,
        /*image_decoder_task_runner=*/image_decoder_task_runner_,
        /*task_runners=*/task_runners_,
        /*settings=*/settings_,
        /*animator=*/std::move(animator_),
        /*io_manager=*/io_manager_,
        /*font_collection=*/std::make_shared<FontCollection>(),
        /*runtime_controller=*/std::move(mock_runtime_controller),
        /*gpu_disabled_switch=*/std::make_shared<fml::SyncSwitch>());

    fml::RefPtr<PlatformMessageResponse> response =
        fml::MakeRefCounted<MockResponse>();
    std::map<std::string, std::string> values{
        {"method", "setInitialRoute"},
        {"args", "test_initial_route"},
    };
    std::unique_ptr<PlatformMessage> message =
        MakePlatformMessage("flutter/navigation", values, response);
    engine->DispatchPlatformMessage(std::move(message));
    EXPECT_EQ(engine->InitialRoute(), "test_initial_route");
  });
}

TEST_F(EngineTest, DispatchPlatformMessageInitialRouteIgnored) {
  PostUITaskSync([this] {
    MockRuntimeDelegate client;
    auto mock_runtime_controller =
        std::make_unique<MockRuntimeController>(client, task_runners_);
    EXPECT_CALL(*mock_runtime_controller, IsRootIsolateRunning())
        .WillRepeatedly(::testing::Return(true));
    EXPECT_CALL(*mock_runtime_controller, DispatchPlatformMessage(::testing::_))
        .WillRepeatedly(::testing::Return(true));
    auto engine = std::make_unique<Engine>(
        /*delegate=*/delegate_,
        /*dispatcher_maker=*/dispatcher_maker_,
        /*image_decoder_task_runner=*/image_decoder_task_runner_,
        /*task_runners=*/task_runners_,
        /*settings=*/settings_,
        /*animator=*/std::move(animator_),
        /*io_manager=*/io_manager_,
        /*font_collection=*/std::make_shared<FontCollection>(),
        /*runtime_controller=*/std::move(mock_runtime_controller),
        /*gpu_disabled_switch=*/std::make_shared<fml::SyncSwitch>());

    fml::RefPtr<PlatformMessageResponse> response =
        fml::MakeRefCounted<MockResponse>();
    std::map<std::string, std::string> values{
        {"method", "setInitialRoute"},
        {"args", "test_initial_route"},
    };
    std::unique_ptr<PlatformMessage> message =
        MakePlatformMessage("flutter/navigation", values, response);
    engine->DispatchPlatformMessage(std::move(message));
    EXPECT_EQ(engine->InitialRoute(), "");
  });
}

TEST_F(EngineTest, SpawnSharesFontLibrary) {
  PostUITaskSync([this] {
    MockRuntimeDelegate client;
    auto mock_runtime_controller =
        std::make_unique<MockRuntimeController>(client, task_runners_);
    auto vm_ref = DartVMRef::Create(settings_);
    EXPECT_CALL(*mock_runtime_controller, GetDartVM())
        .WillRepeatedly(::testing::Return(vm_ref.get()));
    auto engine = std::make_unique<Engine>(
        /*delegate=*/delegate_,
        /*dispatcher_maker=*/dispatcher_maker_,
        /*image_decoder_task_runner=*/image_decoder_task_runner_,
        /*task_runners=*/task_runners_,
        /*settings=*/settings_,
        /*animator=*/std::move(animator_),
        /*io_manager=*/io_manager_,
        /*font_collection=*/std::make_shared<FontCollection>(),
        /*runtime_controller=*/std::move(mock_runtime_controller),
        /*gpu_disabled_switch=*/std::make_shared<fml::SyncSwitch>());

    auto spawn =
        engine->Spawn(delegate_, dispatcher_maker_, settings_, nullptr,
                      std::string(), io_manager_, snapshot_delegate_, nullptr);
    EXPECT_TRUE(spawn != nullptr);
    EXPECT_EQ(&engine->GetFontCollection(), &spawn->GetFontCollection());
  });
}

TEST_F(EngineTest, SpawnWithCustomInitialRoute) {
  PostUITaskSync([this] {
    MockRuntimeDelegate client;
    auto mock_runtime_controller =
        std::make_unique<MockRuntimeController>(client, task_runners_);
    auto vm_ref = DartVMRef::Create(settings_);
    EXPECT_CALL(*mock_runtime_controller, GetDartVM())
        .WillRepeatedly(::testing::Return(vm_ref.get()));
    auto engine = std::make_unique<Engine>(
        /*delegate=*/delegate_,
        /*dispatcher_maker=*/dispatcher_maker_,
        /*image_decoder_task_runner=*/image_decoder_task_runner_,
        /*task_runners=*/task_runners_,
        /*settings=*/settings_,
        /*animator=*/std::move(animator_),
        /*io_manager=*/io_manager_,
        /*font_collection=*/std::make_shared<FontCollection>(),
        /*runtime_controller=*/std::move(mock_runtime_controller),
        /*gpu_disabled_switch=*/std::make_shared<fml::SyncSwitch>());

    auto spawn =
        engine->Spawn(delegate_, dispatcher_maker_, settings_, nullptr, "/foo",
                      io_manager_, snapshot_delegate_, nullptr);
    EXPECT_TRUE(spawn != nullptr);
    ASSERT_EQ("/foo", spawn->InitialRoute());
  });
}

TEST_F(EngineTest, SpawnWithCustomSettings) {
  PostUITaskSync([this] {
    MockRuntimeDelegate client;
    auto mock_runtime_controller =
        std::make_unique<MockRuntimeController>(client, task_runners_);
    auto vm_ref = DartVMRef::Create(settings_);
    EXPECT_CALL(*mock_runtime_controller, GetDartVM())
        .WillRepeatedly(::testing::Return(vm_ref.get()));
    auto engine = std::make_unique<Engine>(
        /*delegate=*/delegate_,
        /*dispatcher_maker=*/dispatcher_maker_,
        /*image_decoder_task_runner=*/image_decoder_task_runner_,
        /*task_runners=*/task_runners_,
        /*settings=*/settings_,
        /*animator=*/std::move(animator_),
        /*io_manager=*/io_manager_,
        /*font_collection=*/std::make_shared<FontCollection>(),
        /*runtime_controller=*/std::move(mock_runtime_controller),
        /*gpu_disabled_switch=*/std::make_shared<fml::SyncSwitch>());

    Settings custom_settings = settings_;
    custom_settings.persistent_isolate_data =
        std::make_shared<fml::DataMapping>("foo");
    auto spawn =
        engine->Spawn(delegate_, dispatcher_maker_, custom_settings, nullptr,
                      std::string(), io_manager_, snapshot_delegate_, nullptr);
    EXPECT_TRUE(spawn != nullptr);
    auto new_persistent_isolate_data =
        const_cast<RuntimeController*>(spawn->GetRuntimeController())
            ->GetPersistentIsolateData();
    EXPECT_EQ(custom_settings.persistent_isolate_data->GetMapping(),
              new_persistent_isolate_data->GetMapping());
    EXPECT_EQ(custom_settings.persistent_isolate_data->GetSize(),
              new_persistent_isolate_data->GetSize());
  });
}

TEST_F(EngineTest, PassesLoadDartDeferredLibraryErrorToRuntime) {
  PostUITaskSync([this] {
    intptr_t error_id = 123;
    const std::string error_message = "error message";
    MockRuntimeDelegate client;
    auto mock_runtime_controller =
        std::make_unique<MockRuntimeController>(client, task_runners_);
    EXPECT_CALL(*mock_runtime_controller, IsRootIsolateRunning())
        .WillRepeatedly(::testing::Return(true));
    EXPECT_CALL(*mock_runtime_controller,
                LoadDartDeferredLibraryError(error_id, error_message, true))
        .Times(1);
    auto engine = std::make_unique<Engine>(
        /*delegate=*/delegate_,
        /*dispatcher_maker=*/dispatcher_maker_,
        /*image_decoder_task_runner=*/image_decoder_task_runner_,
        /*task_runners=*/task_runners_,
        /*settings=*/settings_,
        /*animator=*/std::move(animator_),
        /*io_manager=*/io_manager_,
        /*font_collection=*/std::make_shared<FontCollection>(),
        /*runtime_controller=*/std::move(mock_runtime_controller),
        /*gpu_disabled_switch=*/std::make_shared<fml::SyncSwitch>());

    engine->LoadDartDeferredLibraryError(error_id, error_message, true);
  });
}

TEST_F(EngineTest, AnimatorAcceptsMultipleRenders) {
  MockAnimatorDelegate animator_delegate;
  std::unique_ptr<EngineContext> engine_context;

  std::shared_ptr<PlatformMessageHandler> platform_message_handler =
      std::make_shared<MockPlatformMessageHandler>();
  EXPECT_CALL(delegate_, GetPlatformMessageHandler)
      .WillOnce(ReturnRef(platform_message_handler));

  fml::AutoResetWaitableEvent draw_latch;
  EXPECT_CALL(animator_delegate, OnAnimatorDraw)
      .WillOnce(
          Invoke([&draw_latch](const std::shared_ptr<FramePipeline>& pipeline) {
            auto status =
                pipeline->Consume([&](std::unique_ptr<FrameItem> item) {
                  EXPECT_EQ(item->layer_tree_tasks.size(), 2u);
                  EXPECT_EQ(item->layer_tree_tasks[0]->view_id, 1);
                  EXPECT_EQ(item->layer_tree_tasks[1]->view_id, 2);
                });
            EXPECT_EQ(status, PipelineConsumeResult::Done);
            draw_latch.Signal();
          }));
  EXPECT_CALL(animator_delegate, OnAnimatorBeginFrame)
      .WillOnce(Invoke([&engine_context](fml::TimePoint frame_target_time,
                                         uint64_t frame_number) {
        engine_context->EngineTaskSync([&](Engine& engine) {
          engine.BeginFrame(frame_target_time, frame_number);
        });
      }));

  static fml::AutoResetWaitableEvent callback_ready_latch;
  callback_ready_latch.Reset();
  AddNativeCallback("NotifyNative",
                    [](auto args) { callback_ready_latch.Signal(); });

  std::unique_ptr<Animator> animator;
  PostSync(task_runners_.GetUITaskRunner(),
           [&animator, &animator_delegate, &task_runners = task_runners_] {
             animator = std::make_unique<Animator>(
                 animator_delegate, task_runners,
                 static_cast<std::unique_ptr<VsyncWaiter>>(
                     std::make_unique<testing::ConstantFiringVsyncWaiter>(
                         task_runners)));
           });

  engine_context = EngineContext::Create(delegate_, settings_, task_runners_,
                                         std::move(animator));

  auto configuration = RunConfiguration::InferFromSettings(settings_);
  configuration.SetEntrypoint("onBeginFrameRendersMultipleViews");
  engine_context->Run(std::move(configuration));

  engine_context->EngineTaskSync([](Engine& engine) {
    engine.AddView(1, {1, 10, 10, 22, 0});
    engine.AddView(2, {1, 10, 10, 22, 0});
  });

  callback_ready_latch.Wait();

  engine_context->EngineTaskSync(
      [](Engine& engine) { engine.ScheduleFrame(); });
  draw_latch.Wait();
}

}  // namespace flutter
