// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/shell.h"

#include <fcntl.h>
#include <memory>
#include <sstream>

#include "base/bind.h"
#include "base/command_line.h"
#include "base/i18n/icu_util.h"
#include "base/lazy_instance.h"
#include "base/memory/discardable_memory.h"
#include "base/memory/discardable_memory_allocator.h"
#include "base/posix/eintr_wrapper.h"
#include "base/single_thread_task_runner.h"
#include "base/trace_event/trace_event.h"
#include "dart/runtime/include/dart_tools_api.h"
#include "mojo/message_pump/message_pump_mojo.h"
#include "skia/ext/event_tracer_impl.h"
#include "sky/engine/core/script/dart_init.h"
#include "sky/engine/public/platform/sky_settings.h"
#include "sky/shell/diagnostic/diagnostic_server.h"
#include "sky/shell/platform_view_service_protocol.h"
#include "sky/shell/switches.h"
#include "sky/shell/ui/engine.h"

namespace sky {
namespace shell {
namespace {

static Shell* g_shell = nullptr;

scoped_ptr<base::MessagePump> CreateMessagePumpMojo() {
  return make_scoped_ptr(new mojo::common::MessagePumpMojo);
}

bool IsInvalid(const base::WeakPtr<Rasterizer>& rasterizer) {
  return !rasterizer;
}

bool IsViewInvalid(const base::WeakPtr<PlatformView>& platform_view) {
  return !platform_view;
}

class NonDiscardableMemory : public base::DiscardableMemory {
 public:
  explicit NonDiscardableMemory(size_t size) : data_(new uint8_t[size]) {}
  bool Lock() override { return false; }
  void Unlock() override {}
  void* data() const override { return data_.get(); }

 private:
  std::unique_ptr<uint8_t[]> data_;
};

class NonDiscardableMemoryAllocator : public base::DiscardableMemoryAllocator {
 public:
  scoped_ptr<base::DiscardableMemory> AllocateLockedDiscardableMemory(
      size_t size) override {
    return make_scoped_ptr(new NonDiscardableMemory(size));
  }
};

base::LazyInstance<NonDiscardableMemoryAllocator> g_discardable;

void ServiceIsolateHook(bool running_precompiled) {
  if (!running_precompiled) {
    const blink::SkySettings& settings = blink::SkySettings::Get();
    if (settings.enable_observatory)
      DiagnosticServer::Start();
  }
}

}  // namespace

Shell::Shell() {
  DCHECK(!g_shell);

  base::Thread::Options options;
  options.message_pump_factory = base::Bind(&CreateMessagePumpMojo);

  gpu_thread_.reset(new base::Thread("gpu_thread"));
  gpu_thread_->StartWithOptions(options);
  gpu_task_runner_ = gpu_thread_->message_loop()->task_runner();
  gpu_task_runner_->PostTask(
      FROM_HERE, base::Bind(&Shell::InitGpuThread, base::Unretained(this)));

  ui_thread_.reset(new base::Thread("ui_thread"));
  ui_thread_->StartWithOptions(options);
  ui_task_runner_ = ui_thread_->message_loop()->task_runner();
  ui_task_runner_->PostTask(
      FROM_HERE, base::Bind(&Shell::InitUIThread, base::Unretained(this)));

  io_thread_.reset(new base::Thread("io_thread"));
  io_thread_->StartWithOptions(options);
  io_task_runner_ = io_thread_->message_loop()->task_runner();

  blink::SetServiceIsolateHook(ServiceIsolateHook);
  blink::SetRegisterNativeServiceProtocolExtensionHook(
      PlatformViewServiceProtocol::RegisterHook);
}

Shell::~Shell() {}

void Shell::InitStandalone(std::string icu_data_path) {
  TRACE_EVENT0("flutter", "Shell::InitStandalone");

  int file_descriptor =
      icu_data_path.size() != 0
          ? HANDLE_EINTR(::open(icu_data_path.data(), O_RDONLY))
          : -1;

  if (file_descriptor == -1) {
    // If the embedder did not specify a valid file, fallback to looking through
    // internal search paths.
    CHECK(base::i18n::InitializeICU());
  } else {
    auto region = base::MemoryMappedFile::Region::kWholeFile;
    CHECK(base::i18n::InitializeICUWithFileDescriptor(file_descriptor, region));
    IGNORE_EINTR(::close(file_descriptor));
  }

  base::CommandLine& command_line = *base::CommandLine::ForCurrentProcess();

  blink::SkySettings settings;
  // Enable Observatory
  settings.enable_observatory =
      !command_line.HasSwitch(switches::kNonInteractive);
  // Set Observatory Port
  if (command_line.HasSwitch(switches::kDeviceObservatoryPort)) {
    auto port_string =
        command_line.GetSwitchValueASCII(switches::kDeviceObservatoryPort);
    std::stringstream stream(port_string);
    uint32_t port = 0;
    if (stream >> port) {
      settings.observatory_port = port;
    } else {
      LOG(INFO) << "Observatory port specified was malformed. Will default to "
                << settings.observatory_port;
    }
  }
  settings.start_paused = command_line.HasSwitch(switches::kStartPaused);
  settings.enable_dart_checked_mode =
      command_line.HasSwitch(switches::kEnableCheckedMode);
  settings.trace_startup = command_line.HasSwitch(switches::kTraceStartup);
  settings.aot_snapshot_path =
      command_line.GetSwitchValueASCII(switches::kAotSnapshotPath);
  if (command_line.HasSwitch(switches::kCacheDirPath)) {
    settings.temp_directory_path =
        command_line.GetSwitchValueASCII(switches::kCacheDirPath);
  }
  blink::SkySettings::Set(settings);

  Init();
}

void Shell::Init() {
  base::DiscardableMemoryAllocator::SetInstance(&g_discardable.Get());

#ifndef FLUTTER_PRODUCT_MODE
  InitSkiaEventTracer();
#endif

  DCHECK(!g_shell);
  g_shell = new Shell();
  g_shell->ui_task_runner()->PostTask(FROM_HERE, base::Bind(&Engine::Init));
}

Shell& Shell::Shared() {
  DCHECK(g_shell);
  return *g_shell;
}

TracingController& Shell::tracing_controller() {
  return tracing_controller_;
}

void Shell::InitGpuThread() {
  gpu_thread_checker_.reset(new base::ThreadChecker());
}


void Shell::InitUIThread() {
  ui_thread_checker_.reset(new base::ThreadChecker());
}


void Shell::AddRasterizer(const base::WeakPtr<Rasterizer>& rasterizer) {
  DCHECK(gpu_thread_checker_ && gpu_thread_checker_->CalledOnValidThread());
  rasterizers_.push_back(rasterizer);
}

void Shell::PurgeRasterizers() {
  DCHECK(gpu_thread_checker_ && gpu_thread_checker_->CalledOnValidThread());
  rasterizers_.erase(
      std::remove_if(rasterizers_.begin(), rasterizers_.end(), IsInvalid),
      rasterizers_.end());
}

void Shell::GetRasterizers(
    std::vector<base::WeakPtr<Rasterizer>>* rasterizers) {
  DCHECK(gpu_thread_checker_ && gpu_thread_checker_->CalledOnValidThread());
  *rasterizers = rasterizers_;
}

void Shell::AddPlatformView(const base::WeakPtr<PlatformView>& platform_view) {
  DCHECK(ui_thread_checker_ && ui_thread_checker_->CalledOnValidThread());
  if (platform_view) {
    platform_views_.push_back(platform_view);
  }
}

void Shell::PurgePlatformViews() {
  DCHECK(ui_thread_checker_ && ui_thread_checker_->CalledOnValidThread());
  platform_views_.erase(std::remove_if(platform_views_.begin(),
                                       platform_views_.end(),
                                       IsViewInvalid),
                        platform_views_.end());
}

void Shell::GetPlatformViews(
    std::vector<base::WeakPtr<PlatformView>>* platform_views) {
  DCHECK(ui_thread_checker_ && ui_thread_checker_->CalledOnValidThread());
  *platform_views = platform_views_;
}

void Shell::WaitForPlatformViews(
    std::vector<base::WeakPtr<PlatformView>>* platform_views) {

  base::WaitableEvent latch(false, false);

  ui_task_runner()->PostTask(
      FROM_HERE,
      base::Bind(&Shell::WaitForPlatformViewsUIThread,
                 base::Unretained(this),
                 base::Unretained(platform_views),
                 base::Unretained(&latch)));

  latch.Wait();
}

void Shell::WaitForPlatformViewsUIThread(
    std::vector<base::WeakPtr<PlatformView>>* platform_views,
    base::WaitableEvent* latch) {
  GetPlatformViews(platform_views);
  latch->Signal();
}

}  // namespace shell
}  // namespace sky
