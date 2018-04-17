// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define RAPIDJSON_HAS_STDSTRING 1

#include "flutter/shell/common/shell.h"

#include <memory>
#include <sstream>
#include <vector>

#include "flutter/assets/directory_asset_bundle.h"
#include "flutter/fml/file.h"
#include "flutter/fml/icu_util.h"
#include "flutter/fml/message_loop.h"
#include "flutter/glue/trace_event.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/runtime/start_up.h"
#include "flutter/shell/common/engine.h"
#include "flutter/shell/common/skia_event_tracer_impl.h"
#include "flutter/shell/common/switches.h"
#include "flutter/shell/common/vsync_waiter.h"
#include "lib/fxl/files/path.h"
#include "lib/fxl/files/unique_fd.h"
#include "lib/fxl/functional/make_copyable.h"
#include "lib/fxl/log_settings.h"
#include "lib/fxl/logging.h"
#include "third_party/dart/runtime/include/dart_tools_api.h"
#include "third_party/skia/include/core/SkGraphics.h"

#ifdef ERROR
#undef ERROR
#endif

namespace shell {

std::unique_ptr<Shell> Shell::CreateShellOnPlatformThread(
    blink::TaskRunners task_runners,
    blink::Settings settings,
    Shell::CreateCallback<PlatformView> on_create_platform_view,
    Shell::CreateCallback<Rasterizer> on_create_rasterizer) {
  if (!task_runners.IsValid()) {
    return nullptr;
  }

  auto shell = std::unique_ptr<Shell>(new Shell(task_runners, settings));

  // Create the platform view on the platform thread (this thread).
  auto platform_view = on_create_platform_view(*shell.get());
  if (!platform_view || !platform_view->GetWeakPtr()) {
    return nullptr;
  }

  // Ask the platform view for the vsync waiter. This will be used by the engine
  // to create the animator.
  auto vsync_waiter = platform_view->CreateVSyncWaiter();
  if (!vsync_waiter) {
    return nullptr;
  }

  // Create the IO manager on the IO thread. The IO manager must be initialized
  // first because it has state that the other subsystems depend on. It must
  // first be booted and the necessary references obtained to initialize the
  // other subsystems.
  fxl::AutoResetWaitableEvent io_latch;
  std::unique_ptr<IOManager> io_manager;
  fml::WeakPtr<GrContext> resource_context;
  fxl::RefPtr<flow::SkiaUnrefQueue> unref_queue;
  auto io_task_runner = shell->GetTaskRunners().GetIOTaskRunner();
  fml::TaskRunner::RunNowOrPostTask(
      io_task_runner,
      [&io_latch,          //
       &io_manager,        //
       &resource_context,  //
       &unref_queue,       //
       &platform_view,     //
       io_task_runner      //
  ]() {
        io_manager = std::make_unique<IOManager>(
            platform_view->CreateResourceContext(), io_task_runner);
        resource_context = io_manager->GetResourceContext();
        unref_queue = io_manager->GetSkiaUnrefQueue();
        io_latch.Signal();
      });
  io_latch.Wait();

  // Create the rasterizer on the GPU thread.
  fxl::AutoResetWaitableEvent gpu_latch;
  std::unique_ptr<Rasterizer> rasterizer;
  fml::TaskRunner::RunNowOrPostTask(
      task_runners.GetGPUTaskRunner(), [&gpu_latch,            //
                                        &rasterizer,           //
                                        on_create_rasterizer,  //
                                        shell = shell.get()    //
  ]() {
        if (auto new_rasterizer = on_create_rasterizer(*shell)) {
          rasterizer = std::move(new_rasterizer);
        }
        gpu_latch.Signal();
      });

  // Create the engine on the UI thread.
  fxl::AutoResetWaitableEvent ui_latch;
  std::unique_ptr<Engine> engine;
  fml::TaskRunner::RunNowOrPostTask(
      shell->GetTaskRunners().GetUITaskRunner(),
      fxl::MakeCopyable([&ui_latch,                                       //
                         &engine,                                         //
                         shell = shell.get(),                             //
                         vsync_waiter = std::move(vsync_waiter),          //
                         resource_context = std::move(resource_context),  //
                         unref_queue = std::move(unref_queue)             //
  ]() mutable {
        const auto& task_runners = shell->GetTaskRunners();

        // The animator is owned by the UI thread but it gets its vsync pulses
        // from the platform.
        auto animator = std::make_unique<Animator>(*shell, task_runners,
                                                   std::move(vsync_waiter));

        engine = std::make_unique<Engine>(*shell,                       //
                                          shell->GetDartVM(),           //
                                          task_runners,                 //
                                          shell->GetSettings(),         //
                                          std::move(animator),          //
                                          std::move(resource_context),  //
                                          std::move(unref_queue)        //
        );
        ui_latch.Signal();
      }));

  gpu_latch.Wait();
  ui_latch.Wait();
  // We are already on the platform thread. So there is no platform latch to
  // wait on.

  if (!shell->Setup(std::move(platform_view),  //
                    std::move(engine),         //
                    std::move(rasterizer),     //
                    std::move(io_manager))     //
  ) {
    return nullptr;
  }

  return shell;
}

static void RecordStartupTimestamp() {
  if (blink::engine_main_enter_ts == 0) {
    blink::engine_main_enter_ts = Dart_TimelineGetMicros();
  }
}

std::unique_ptr<Shell> Shell::Create(
    blink::TaskRunners task_runners,
    blink::Settings settings,
    Shell::CreateCallback<PlatformView> on_create_platform_view,
    Shell::CreateCallback<Rasterizer> on_create_rasterizer) {
  RecordStartupTimestamp();

  fxl::LogSettings log_settings;
  log_settings.min_log_level =
      settings.verbose_logging ? fxl::LOG_INFO : fxl::LOG_ERROR;
  fxl::SetLogSettings(log_settings);

  if (!task_runners.IsValid() || !on_create_platform_view ||
      !on_create_rasterizer) {
    return nullptr;
  }

  fxl::AutoResetWaitableEvent latch;
  std::unique_ptr<Shell> shell;
  fml::TaskRunner::RunNowOrPostTask(
      task_runners.GetPlatformTaskRunner(),
      [&latch, &shell, task_runners = std::move(task_runners), settings,
       on_create_platform_view, on_create_rasterizer]() {
        shell = CreateShellOnPlatformThread(std::move(task_runners), settings,
                                            on_create_platform_view,
                                            on_create_rasterizer);
        latch.Signal();
      });
  latch.Wait();
  return shell;
}

Shell::Shell(blink::TaskRunners task_runners, blink::Settings settings)
    : task_runners_(std::move(task_runners)),
      settings_(std::move(settings)),
      vm_(blink::DartVM::ForProcess(settings_)) {
  FXL_DCHECK(task_runners_.IsValid());
  FXL_DCHECK(task_runners_.GetPlatformTaskRunner()->RunsTasksOnCurrentThread());

  if (settings_.icu_data_path.size() != 0) {
    fml::icu::InitializeICU(settings_.icu_data_path);
  } else {
    FXL_DLOG(WARNING) << "Skipping ICU initialization in the shell.";
  }

  if (settings_.trace_skia) {
    InitSkiaEventTracer(settings_.trace_skia);
  }

  if (!settings_.skia_deterministic_rendering_on_cpu) {
    SkGraphics::Init();
  } else {
    FXL_DLOG(INFO) << "Skia deterministic rendering is enabled.";
  }

  // Install service protocol handlers.

  service_protocol_handlers_[blink::ServiceProtocol::kScreenshotExtensionName
                                 .ToString()] = {
      task_runners_.GetGPUTaskRunner(),
      std::bind(&Shell::OnServiceProtocolScreenshot, this,
                std::placeholders::_1, std::placeholders::_2)};
  service_protocol_handlers_[blink::ServiceProtocol::kScreenshotSkpExtensionName
                                 .ToString()] = {
      task_runners_.GetGPUTaskRunner(),
      std::bind(&Shell::OnServiceProtocolScreenshotSKP, this,
                std::placeholders::_1, std::placeholders::_2)};
  service_protocol_handlers_[blink::ServiceProtocol::kRunInViewExtensionName
                                 .ToString()] = {
      task_runners_.GetUITaskRunner(),
      std::bind(&Shell::OnServiceProtocolRunInView, this, std::placeholders::_1,
                std::placeholders::_2)};
  service_protocol_handlers_
      [blink::ServiceProtocol::kFlushUIThreadTasksExtensionName.ToString()] = {
          task_runners_.GetUITaskRunner(),
          std::bind(&Shell::OnServiceProtocolFlushUIThreadTasks, this,
                    std::placeholders::_1, std::placeholders::_2)};
  service_protocol_handlers_
      [blink::ServiceProtocol::kSetAssetBundlePathExtensionName.ToString()] = {
          task_runners_.GetUITaskRunner(),
          std::bind(&Shell::OnServiceProtocolSetAssetBundlePath, this,
                    std::placeholders::_1, std::placeholders::_2)};
}

Shell::~Shell() {
  if (auto vm = blink::DartVM::ForProcessIfInitialized()) {
    vm->GetServiceProtocol().RemoveHandler(this);
  }

  fxl::AutoResetWaitableEvent ui_latch, gpu_latch, platform_latch, io_latch;

  fml::TaskRunner::RunNowOrPostTask(
      task_runners_.GetUITaskRunner(),
      fxl::MakeCopyable([engine = std::move(engine_), &ui_latch]() mutable {
        engine.reset();
        ui_latch.Signal();
      }));
  ui_latch.Wait();

  fml::TaskRunner::RunNowOrPostTask(
      task_runners_.GetGPUTaskRunner(),
      fxl::MakeCopyable(
          [rasterizer = std::move(rasterizer_), &gpu_latch]() mutable {
            rasterizer.reset();
            gpu_latch.Signal();
          }));
  gpu_latch.Wait();

  fml::TaskRunner::RunNowOrPostTask(
      task_runners_.GetIOTaskRunner(),
      fxl::MakeCopyable(
          [io_manager = std::move(io_manager_), &io_latch]() mutable {
            io_manager.reset();
            io_latch.Signal();
          }));

  io_latch.Wait();

  // The platform view must go last because it may be holding onto platform side
  // counterparts to resources owned by subsystems running on other threads. For
  // example, the NSOpenGLContext on the Mac.
  fml::TaskRunner::RunNowOrPostTask(
      task_runners_.GetPlatformTaskRunner(),
      fxl::MakeCopyable([platform_view = std::move(platform_view_),
                         &platform_latch]() mutable {
        platform_view.reset();
        platform_latch.Signal();
      }));
  platform_latch.Wait();
}

bool Shell::IsSetup() const {
  return is_setup_;
}

bool Shell::Setup(std::unique_ptr<PlatformView> platform_view,
                  std::unique_ptr<Engine> engine,
                  std::unique_ptr<Rasterizer> rasterizer,
                  std::unique_ptr<IOManager> io_manager) {
  if (is_setup_) {
    return false;
  }

  if (!platform_view || !engine || !rasterizer || !io_manager) {
    return false;
  }

  platform_view_ = std::move(platform_view);
  engine_ = std::move(engine);
  rasterizer_ = std::move(rasterizer);
  io_manager_ = std::move(io_manager);

  is_setup_ = true;

  if (auto vm = blink::DartVM::ForProcessIfInitialized()) {
    vm->GetServiceProtocol().AddHandler(this);
  }

  return true;
}

const blink::Settings& Shell::GetSettings() const {
  return settings_;
}

const blink::TaskRunners& Shell::GetTaskRunners() const {
  return task_runners_;
}

fml::WeakPtr<Rasterizer> Shell::GetRasterizer() {
  FXL_DCHECK(is_setup_);
  return rasterizer_->GetWeakPtr();
}

fml::WeakPtr<Engine> Shell::GetEngine() {
  FXL_DCHECK(is_setup_);
  return engine_->GetWeakPtr();
}

fml::WeakPtr<PlatformView> Shell::GetPlatformView() {
  FXL_DCHECK(is_setup_);
  return platform_view_->GetWeakPtr();
}

const blink::DartVM& Shell::GetDartVM() const {
  return *vm_;
}

// |shell::PlatformView::Delegate|
void Shell::OnPlatformViewCreated(const PlatformView& view,
                                  std::unique_ptr<Surface> surface) {
  FXL_DCHECK(is_setup_);
  FXL_DCHECK(&view == platform_view_.get());
  FXL_DCHECK(task_runners_.GetPlatformTaskRunner()->RunsTasksOnCurrentThread());

  // Note:
  // This is a synchronous operation because certain platforms depend on
  // setup/suspension of all activities that may be interacting with the GPU in
  // a synchronous fashion.

  fxl::AutoResetWaitableEvent latch;
  auto gpu_task = fxl::MakeCopyable([rasterizer = rasterizer_->GetWeakPtr(),  //
                                     surface = std::move(surface),            //
                                     &latch]() mutable {
    if (rasterizer) {
      rasterizer->Setup(std::move(surface));
    }
    // Step 2: All done. Signal the latch that the platform thread is waiting
    // on.
    latch.Signal();
  });

  auto ui_task = [engine = engine_->GetWeakPtr(),                      //
                  gpu_task_runner = task_runners_.GetGPUTaskRunner(),  //
                  gpu_task                                             //
  ] {
    if (engine) {
      engine->OnOutputSurfaceCreated();
    }
    // Step 1: Next, tell the GPU thread that it should create a surface for its
    // rasterizer.
    fml::TaskRunner::RunNowOrPostTask(gpu_task_runner, gpu_task);
  };

  // Step 0: Post a task onto the UI thread to tell the engine that it has an
  // output surface.
  fml::TaskRunner::RunNowOrPostTask(task_runners_.GetUITaskRunner(), ui_task);
  latch.Wait();
}

// |shell::PlatformView::Delegate|
void Shell::OnPlatformViewDestroyed(const PlatformView& view) {
  FXL_DCHECK(is_setup_);
  FXL_DCHECK(&view == platform_view_.get());
  FXL_DCHECK(task_runners_.GetPlatformTaskRunner()->RunsTasksOnCurrentThread());

  // Note:
  // This is a synchronous operation because certain platforms depend on
  // setup/suspension of all activities that may be interacting with the GPU in
  // a synchronous fashion.

  fxl::AutoResetWaitableEvent latch;

  auto gpu_task = [rasterizer = rasterizer_->GetWeakPtr(), &latch]() {
    if (rasterizer) {
      rasterizer->Teardown();
    }
    // Step 2: All done. Signal the latch that the platform thread is waiting
    // on.
    latch.Signal();
  };

  auto ui_task = [engine = engine_->GetWeakPtr(),
                  gpu_task_runner = task_runners_.GetGPUTaskRunner(),
                  gpu_task]() {
    if (engine) {
      engine->OnOutputSurfaceDestroyed();
    }
    // Step 1: Next, tell the GPU thread that its rasterizer should suspend
    // access to the underlying surface.
    fml::TaskRunner::RunNowOrPostTask(gpu_task_runner, gpu_task);
  };

  // Step 0: Post a task onto the UI thread to tell the engine that its output
  // surface is about to go away.
  fml::TaskRunner::RunNowOrPostTask(task_runners_.GetUITaskRunner(), ui_task);
  latch.Wait();
}

// |shell::PlatformView::Delegate|
void Shell::OnPlatformViewSetViewportMetrics(
    const PlatformView& view,
    const blink::ViewportMetrics& metrics) {
  FXL_DCHECK(is_setup_);
  FXL_DCHECK(&view == platform_view_.get());
  FXL_DCHECK(task_runners_.GetPlatformTaskRunner()->RunsTasksOnCurrentThread());

  task_runners_.GetUITaskRunner()->PostTask(
      [engine = engine_->GetWeakPtr(), metrics]() {
        if (engine) {
          engine->SetViewportMetrics(metrics);
        }
      });
}

// |shell::PlatformView::Delegate|
void Shell::OnPlatformViewDispatchPlatformMessage(
    const PlatformView& view,
    fxl::RefPtr<blink::PlatformMessage> message) {
  FXL_DCHECK(is_setup_);
  FXL_DCHECK(&view == platform_view_.get());
  FXL_DCHECK(task_runners_.GetPlatformTaskRunner()->RunsTasksOnCurrentThread());

  task_runners_.GetUITaskRunner()->PostTask(
      [engine = engine_->GetWeakPtr(), message = std::move(message)] {
        if (engine) {
          engine->DispatchPlatformMessage(std::move(message));
        }
      });
}

// |shell::PlatformView::Delegate|
void Shell::OnPlatformViewDispatchPointerDataPacket(
    const PlatformView& view,
    std::unique_ptr<blink::PointerDataPacket> packet) {
  FXL_DCHECK(is_setup_);
  FXL_DCHECK(&view == platform_view_.get());
  FXL_DCHECK(task_runners_.GetPlatformTaskRunner()->RunsTasksOnCurrentThread());
  task_runners_.GetUITaskRunner()->PostTask(fxl::MakeCopyable(
      [engine = engine_->GetWeakPtr(), packet = std::move(packet)] {
        if (engine) {
          engine->DispatchPointerDataPacket(*packet);
        }
      }));
}

// |shell::PlatformView::Delegate|
void Shell::OnPlatformViewDispatchSemanticsAction(const PlatformView& view,
                                                  int32_t id,
                                                  blink::SemanticsAction action,
                                                  std::vector<uint8_t> args) {
  FXL_DCHECK(is_setup_);
  FXL_DCHECK(&view == platform_view_.get());
  FXL_DCHECK(task_runners_.GetPlatformTaskRunner()->RunsTasksOnCurrentThread());

  task_runners_.GetUITaskRunner()->PostTask(
      [engine = engine_->GetWeakPtr(), id, action, args = std::move(args)] {
        if (engine) {
          engine->DispatchSemanticsAction(id, action, std::move(args));
        }
      });
}

// |shell::PlatformView::Delegate|
void Shell::OnPlatformViewSetSemanticsEnabled(const PlatformView& view,
                                              bool enabled) {
  FXL_DCHECK(is_setup_);
  FXL_DCHECK(&view == platform_view_.get());
  FXL_DCHECK(task_runners_.GetPlatformTaskRunner()->RunsTasksOnCurrentThread());

  task_runners_.GetUITaskRunner()->PostTask(
      [engine = engine_->GetWeakPtr(), enabled] {
        if (engine) {
          engine->SetSemanticsEnabled(enabled);
        }
      });
}

// |shell::PlatformView::Delegate|
void Shell::OnPlatformViewRegisterTexture(
    const PlatformView& view,
    std::shared_ptr<flow::Texture> texture) {
  FXL_DCHECK(is_setup_);
  FXL_DCHECK(&view == platform_view_.get());
  FXL_DCHECK(task_runners_.GetPlatformTaskRunner()->RunsTasksOnCurrentThread());

  task_runners_.GetGPUTaskRunner()->PostTask(
      [rasterizer = rasterizer_->GetWeakPtr(), texture] {
        if (rasterizer) {
          if (auto registry = rasterizer->GetTextureRegistry()) {
            registry->RegisterTexture(texture);
          }
        }
      });
}

// |shell::PlatformView::Delegate|
void Shell::OnPlatformViewUnregisterTexture(const PlatformView& view,
                                            int64_t texture_id) {
  FXL_DCHECK(is_setup_);
  FXL_DCHECK(&view == platform_view_.get());
  FXL_DCHECK(task_runners_.GetPlatformTaskRunner()->RunsTasksOnCurrentThread());

  task_runners_.GetGPUTaskRunner()->PostTask(
      [rasterizer = rasterizer_->GetWeakPtr(), texture_id]() {
        if (rasterizer) {
          if (auto registry = rasterizer->GetTextureRegistry()) {
            registry->UnregisterTexture(texture_id);
          }
        }
      });
}

// |shell::PlatformView::Delegate|
void Shell::OnPlatformViewMarkTextureFrameAvailable(const PlatformView& view,
                                                    int64_t texture_id) {
  FXL_DCHECK(is_setup_);
  FXL_DCHECK(&view == platform_view_.get());
  FXL_DCHECK(task_runners_.GetPlatformTaskRunner()->RunsTasksOnCurrentThread());

  // Tell the rasterizer that one of its textures has a new frame available.
  task_runners_.GetGPUTaskRunner()->PostTask(
      [rasterizer = rasterizer_->GetWeakPtr(), texture_id]() {
        auto registry = rasterizer->GetTextureRegistry();

        if (!registry) {
          return;
        }

        auto texture = registry->GetTexture(texture_id);

        if (!texture) {
          return;
        }

        texture->MarkNewFrameAvailable();
      });

  // Schedule a new frame without having to rebuild the layer tree.
  task_runners_.GetUITaskRunner()->PostTask([engine = engine_->GetWeakPtr()]() {
    if (engine) {
      engine->ScheduleFrame(false);
    }
  });
}

// |shell::PlatformView::Delegate|
void Shell::OnPlatformViewSetNextFrameCallback(const PlatformView& view,
                                               fxl::Closure closure) {
  FXL_DCHECK(is_setup_);
  FXL_DCHECK(&view == platform_view_.get());
  FXL_DCHECK(task_runners_.GetPlatformTaskRunner()->RunsTasksOnCurrentThread());

  task_runners_.GetGPUTaskRunner()->PostTask(
      [rasterizer = rasterizer_->GetWeakPtr(), closure = std::move(closure)]() {
        if (rasterizer) {
          rasterizer->SetNextFrameCallback(std::move(closure));
        }
      });
}

// |shell::Animator::Delegate|
void Shell::OnAnimatorBeginFrame(const Animator& animator,
                                 fxl::TimePoint frame_time) {
  FXL_DCHECK(is_setup_);
  FXL_DCHECK(task_runners_.GetUITaskRunner()->RunsTasksOnCurrentThread());

  if (engine_) {
    engine_->BeginFrame(frame_time);
  }
}

// |shell::Animator::Delegate|
void Shell::OnAnimatorNotifyIdle(const Animator& animator, int64_t deadline) {
  FXL_DCHECK(is_setup_);
  FXL_DCHECK(task_runners_.GetUITaskRunner()->RunsTasksOnCurrentThread());

  if (engine_) {
    engine_->NotifyIdle(deadline);
  }
}

// |shell::Animator::Delegate|
void Shell::OnAnimatorDraw(
    const Animator& animator,
    fxl::RefPtr<flutter::Pipeline<flow::LayerTree>> pipeline) {
  FXL_DCHECK(is_setup_);

  task_runners_.GetGPUTaskRunner()->PostTask(
      [rasterizer = rasterizer_->GetWeakPtr(),
       pipeline = std::move(pipeline)]() {
        if (rasterizer) {
          rasterizer->Draw(pipeline);
        }
      });
}

// |shell::Animator::Delegate|
void Shell::OnAnimatorDrawLastLayerTree(const Animator& animator) {
  FXL_DCHECK(is_setup_);

  task_runners_.GetGPUTaskRunner()->PostTask(
      [rasterizer = rasterizer_->GetWeakPtr()]() {
        if (rasterizer) {
          rasterizer->DrawLastLayerTree();
        }
      });
}

// |shell::Engine::Delegate|
void Shell::OnEngineUpdateSemantics(const Engine& engine,
                                    blink::SemanticsNodeUpdates update) {
  FXL_DCHECK(is_setup_);
  FXL_DCHECK(task_runners_.GetUITaskRunner()->RunsTasksOnCurrentThread());

  task_runners_.GetPlatformTaskRunner()->PostTask(
      [view = platform_view_->GetWeakPtr(), update = std::move(update)] {
        if (view) {
          view->UpdateSemantics(std::move(update));
        }
      });
}

// |shell::Engine::Delegate|
void Shell::OnEngineHandlePlatformMessage(
    const Engine& engine,
    fxl::RefPtr<blink::PlatformMessage> message) {
  FXL_DCHECK(is_setup_);
  FXL_DCHECK(task_runners_.GetUITaskRunner()->RunsTasksOnCurrentThread());

  task_runners_.GetPlatformTaskRunner()->PostTask(
      [view = platform_view_->GetWeakPtr(), message = std::move(message)]() {
        if (view) {
          view->HandlePlatformMessage(std::move(message));
        }
      });
}

// |blink::ServiceProtocol::Handler|
fxl::RefPtr<fxl::TaskRunner> Shell::GetServiceProtocolHandlerTaskRunner(
    fxl::StringView method) const {
  FXL_DCHECK(is_setup_);
  auto found = service_protocol_handlers_.find(method.ToString());
  if (found != service_protocol_handlers_.end()) {
    return found->second.first;
  }
  return task_runners_.GetUITaskRunner();
}

// |blink::ServiceProtocol::Handler|
bool Shell::HandleServiceProtocolMessage(
    fxl::StringView method,  // one if the extension names specified above.
    const ServiceProtocolMap& params,
    rapidjson::Document& response) {
  auto found = service_protocol_handlers_.find(method.ToString());
  if (found != service_protocol_handlers_.end()) {
    return found->second.second(params, response);
  }
  return false;
}

// |blink::ServiceProtocol::Handler|
blink::ServiceProtocol::Handler::Description
Shell::GetServiceProtocolDescription() const {
  return {
      engine_->GetUIIsolateMainPort(),
      engine_->GetUIIsolateName(),
  };
}

static void ServiceProtocolParameterError(rapidjson::Document& response,
                                          std::string parameter_name) {
  auto& allocator = response.GetAllocator();
  response.SetObject();
  const int64_t kInvalidParams = -32602;
  response.AddMember("code", kInvalidParams, allocator);
  response.AddMember("message", "Invalid params", allocator);
  {
    rapidjson::Value details(rapidjson::kObjectType);
    details.AddMember("details", parameter_name, allocator);
    response.AddMember("data", details, allocator);
  }
}

// Service protocol handler
bool Shell::OnServiceProtocolScreenshot(
    const blink::ServiceProtocol::Handler::ServiceProtocolMap& params,
    rapidjson::Document& response) {
  FXL_DCHECK(task_runners_.GetGPUTaskRunner()->RunsTasksOnCurrentThread());
  auto screenshot = rasterizer_->ScreenshotLastLayerTree(
      Rasterizer::ScreenshotType::CompressedImage, true);
  if (screenshot.data) {
    response.SetObject();
    auto& allocator = response.GetAllocator();
    response.AddMember("type", "Screenshot", allocator);
    rapidjson::Value image;
    image.SetString(static_cast<const char*>(screenshot.data->data()),
                    screenshot.data->size(), allocator);
    response.AddMember("screenshot", image, allocator);
    return true;
  }
  ServiceProtocolParameterError(response,
                                "Could not capture image screenshot.");
  return false;
}

// Service protocol handler
bool Shell::OnServiceProtocolScreenshotSKP(
    const blink::ServiceProtocol::Handler::ServiceProtocolMap& params,
    rapidjson::Document& response) {
  FXL_DCHECK(task_runners_.GetGPUTaskRunner()->RunsTasksOnCurrentThread());
  auto screenshot = rasterizer_->ScreenshotLastLayerTree(
      Rasterizer::ScreenshotType::SkiaPicture, true);
  if (screenshot.data) {
    response.SetObject();
    auto& allocator = response.GetAllocator();
    response.AddMember("type", "ScreenshotSkp", allocator);
    rapidjson::Value skp;
    skp.SetString(static_cast<const char*>(screenshot.data->data()),
                  screenshot.data->size(), allocator);
    response.AddMember("skp", skp, allocator);
    return true;
  }
  ServiceProtocolParameterError(response, "Could not capture SKP screenshot.");
  return false;
}

static bool FileNameIsDill(const std::string& name) {
  const std::string suffix = ".dill";

  if (name.size() < suffix.size()) {
    return false;
  }

  if (name.rfind(suffix, name.size()) == name.size() - suffix.size()) {
    return true;
  }
  return false;
}

// Service protocol handler
bool Shell::OnServiceProtocolRunInView(
    const blink::ServiceProtocol::Handler::ServiceProtocolMap& params,
    rapidjson::Document& response) {
  FXL_DCHECK(task_runners_.GetUITaskRunner()->RunsTasksOnCurrentThread());

  if (params.count("mainScript") == 0) {
    ServiceProtocolParameterError(response,
                                  "'mainScript' parameter is missing.");
    return false;
  }

  // TODO(chinmaygarde): In case of hot-reload from .dill files, the packages
  // file is ignored. Currently, the tool is passing a junk packages file to
  // pass this check. Update the service protocol interface and remove this
  // workaround.
  if (params.count("packagesFile") == 0) {
    ServiceProtocolParameterError(response,
                                  "'packagesFile' parameter is missing.");
    return false;
  }

  if (params.count("assetDirectory") == 0) {
    ServiceProtocolParameterError(response,
                                  "'assetDirectory' parameter is missing.");
    return false;
  }

  auto main_script_file =
      files::AbsolutePath(params.at("mainScript").ToString());

  auto isolate_configuration =
      FileNameIsDill(main_script_file)
          ? IsolateConfiguration::CreateForSnapshot(
                std::make_unique<fml::FileMapping>(main_script_file, false))
          : IsolateConfiguration::CreateForSource(
                main_script_file, params.at("packagesFile").ToString());

  RunConfiguration configuration(std::move(isolate_configuration));

  configuration.AddAssetResolver(std::make_unique<blink::DirectoryAssetBundle>(
      fml::OpenFile(params.at("assetDirectory").ToString().c_str(),
                    fml::OpenPermission::kRead, true)));

  auto& allocator = response.GetAllocator();
  response.SetObject();
  if (engine_->Restart(std::move(configuration))) {
    response.AddMember("type", "Success", allocator);
    auto new_description = GetServiceProtocolDescription();
    rapidjson::Value view(rapidjson::kObjectType);
    new_description.Write(this, view, allocator);
    response.AddMember("view", view, allocator);
    return true;
  } else {
    FXL_DLOG(ERROR) << "Could not run configuration in engine.";
    response.AddMember("type", "Failure", allocator);
    return false;
  }

  FXL_DCHECK(false);
  return false;
}

// Service protocol handler
bool Shell::OnServiceProtocolFlushUIThreadTasks(
    const blink::ServiceProtocol::Handler::ServiceProtocolMap& params,
    rapidjson::Document& response) {
  FXL_DCHECK(task_runners_.GetUITaskRunner()->RunsTasksOnCurrentThread());
  // This API should not be invoked by production code.
  // It can potentially starve the service isolate if the main isolate pauses
  // at a breakpoint or is in an infinite loop.
  //
  // It should be invoked from the VM Service and and blocks it until UI thread
  // tasks are processed.
  response.SetObject();
  response.AddMember("type", "Success", response.GetAllocator());
  return true;
}

// Service protocol handler
bool Shell::OnServiceProtocolSetAssetBundlePath(
    const blink::ServiceProtocol::Handler::ServiceProtocolMap& params,
    rapidjson::Document& response) {
  FXL_DCHECK(task_runners_.GetUITaskRunner()->RunsTasksOnCurrentThread());

  if (params.count("assetDirectory") == 0) {
    ServiceProtocolParameterError(response,
                                  "'assetDirectory' parameter is missing.");
    return false;
  }

  auto& allocator = response.GetAllocator();
  response.SetObject();

  auto asset_manager = fxl::MakeRefCounted<blink::AssetManager>();

  asset_manager->PushFront(std::make_unique<blink::DirectoryAssetBundle>(
      fml::OpenFile(params.at("assetDirectory").ToString().c_str(),
                    fml::OpenPermission::kRead, true)));

  if (engine_->UpdateAssetManager(std::move(asset_manager))) {
    response.AddMember("type", "Success", allocator);
    auto new_description = GetServiceProtocolDescription();
    rapidjson::Value view(rapidjson::kObjectType);
    new_description.Write(this, view, allocator);
    response.AddMember("view", view, allocator);
    return true;
  } else {
    FXL_DLOG(ERROR) << "Could not update asset directory.";
    response.AddMember("type", "Failure", allocator);
    return false;
  }

  FXL_DCHECK(false);
  return false;
}

Rasterizer::Screenshot Shell::Screenshot(
    Rasterizer::ScreenshotType screenshot_type,
    bool base64_encode) {
  TRACE_EVENT0("flutter", "Shell::Screenshot");
  fxl::AutoResetWaitableEvent latch;
  Rasterizer::Screenshot screenshot;
  fml::TaskRunner::RunNowOrPostTask(
      task_runners_.GetGPUTaskRunner(), [&latch,                        //
                                         rasterizer = GetRasterizer(),  //
                                         &screenshot,                   //
                                         screenshot_type,               //
                                         base64_encode                  //
  ]() {
        if (rasterizer) {
          screenshot = rasterizer->ScreenshotLastLayerTree(screenshot_type,
                                                           base64_encode);
        }
        latch.Signal();
      });
  latch.Wait();
  return screenshot;
}

}  // namespace shell
