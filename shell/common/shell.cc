// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/shell.h"

#include <fcntl.h>
#include <memory>
#include <sstream>
#include <vector>

#include "flutter/common/settings.h"
#include "flutter/common/threads.h"
#include "flutter/fml/icu_util.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/trace_event.h"
#include "flutter/runtime/dart_init.h"
#include "flutter/shell/common/engine.h"
#include "flutter/shell/common/platform_view_service_protocol.h"
#include "flutter/shell/common/skia_event_tracer_impl.h"
#include "flutter/shell/common/switches.h"
#include "lib/fxl/files/unique_fd.h"
#include "third_party/dart/runtime/include/dart_tools_api.h"
#include "third_party/skia/include/core/SkGraphics.h"

namespace shell {
namespace {

static Shell* g_shell = nullptr;

template <typename T>
bool GetSwitchValue(const fxl::CommandLine& command_line,
                    Switch sw,
                    T* result) {
  std::string switch_string;

  if (!command_line.GetOptionValue(FlagForSwitch(sw), &switch_string)) {
    return false;
  }

  std::stringstream stream(switch_string);
  T value = 0;
  if (stream >> value) {
    *result = value;
    return true;
  }

  return false;
}

}  // namespace

Shell::Shell(fxl::CommandLine command_line)
    : command_line_(std::move(command_line)) {
  FXL_DCHECK(!g_shell);

  gpu_thread_.reset(new fml::Thread("gpu_thread"));
  ui_thread_.reset(new fml::Thread("ui_thread"));
  io_thread_.reset(new fml::Thread("io_thread"));

  // Since we are not using fml::Thread, we need to initialize the message loop
  // manually.
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  blink::Threads threads(fml::MessageLoop::GetCurrent().GetTaskRunner(),
                         gpu_thread_->GetTaskRunner(),
                         ui_thread_->GetTaskRunner(),
                         io_thread_->GetTaskRunner());
  blink::Threads::Set(threads);

  blink::Threads::Gpu()->PostTask([this]() { InitGpuThread(); });
  blink::Threads::UI()->PostTask([this]() { InitUIThread(); });

  blink::SetRegisterNativeServiceProtocolExtensionHook(
      PlatformViewServiceProtocol::RegisterHook);
}

Shell::~Shell() {}

void Shell::InitStandalone(fxl::CommandLine command_line,
                           std::string icu_data_path,
                           std::string application_library_path,
                           std::string bundle_path) {
  TRACE_EVENT0("flutter", "Shell::InitStandalone");

  fml::icu::InitializeICU(icu_data_path);

  SkGraphics::Init();

  blink::Settings settings;
  settings.application_library_path = application_library_path;

  // Enable Observatory
  settings.enable_observatory =
      !command_line.HasOption(FlagForSwitch(Switch::DisableObservatory));

  // Set Observatory Port
  if (command_line.HasOption(FlagForSwitch(Switch::DeviceObservatoryPort))) {
    if (!GetSwitchValue(command_line, Switch::DeviceObservatoryPort,
                        &settings.observatory_port)) {
      FXL_LOG(INFO)
          << "Observatory port specified was malformed. Will default to "
          << settings.observatory_port;
    }
  }

  // Checked mode overrides.
  settings.dart_non_checked_mode =
      command_line.HasOption(FlagForSwitch(Switch::DartNonCheckedMode));

  settings.ipv6 = command_line.HasOption(FlagForSwitch(Switch::IPv6));

  settings.start_paused =
      command_line.HasOption(FlagForSwitch(Switch::StartPaused));

  settings.enable_dart_profiling =
      command_line.HasOption(FlagForSwitch(Switch::EnableDartProfiling));

  settings.enable_software_rendering =
      command_line.HasOption(FlagForSwitch(Switch::EnableSoftwareRendering));

  settings.using_blink =
      !command_line.HasOption(FlagForSwitch(Switch::EnableTxt));

  settings.endless_trace_buffer =
      command_line.HasOption(FlagForSwitch(Switch::EndlessTraceBuffer));

  settings.trace_startup =
      command_line.HasOption(FlagForSwitch(Switch::TraceStartup));

  command_line.GetOptionValue(FlagForSwitch(Switch::AotSnapshotPath),
                              &settings.aot_snapshot_path);

  command_line.GetOptionValue(FlagForSwitch(Switch::AotVmSnapshotData),
                              &settings.aot_vm_snapshot_data_filename);

  command_line.GetOptionValue(FlagForSwitch(Switch::AotVmSnapshotInstructions),
                              &settings.aot_vm_snapshot_instr_filename);

  command_line.GetOptionValue(FlagForSwitch(Switch::AotIsolateSnapshotData),
                              &settings.aot_isolate_snapshot_data_filename);

  command_line.GetOptionValue(FlagForSwitch(Switch::AotSharedLibraryPath),
                              &settings.aot_shared_library_path);

  command_line.GetOptionValue(
      FlagForSwitch(Switch::AotIsolateSnapshotInstructions),
      &settings.aot_isolate_snapshot_instr_filename);

  command_line.GetOptionValue(FlagForSwitch(Switch::CacheDirPath),
                              &settings.temp_directory_path);

  settings.use_test_fonts =
      command_line.HasOption(FlagForSwitch(Switch::UseTestFonts));

  std::string all_dart_flags;
  if (command_line.GetOptionValue(FlagForSwitch(Switch::DartFlags),
                                  &all_dart_flags)) {
    std::stringstream stream(all_dart_flags);
    std::istream_iterator<std::string> end;
    for (std::istream_iterator<std::string> it(stream); it != end; ++it)
      settings.dart_flags.push_back(*it);
  }

  command_line.GetOptionValue(FlagForSwitch(Switch::LogTag), &settings.log_tag);

  blink::Settings::Set(settings);

  Init(std::move(command_line), bundle_path);
}

void Shell::Init(fxl::CommandLine command_line,
                 const std::string& bundle_path) {
#if FLUTTER_RUNTIME_MODE != FLUTTER_RUNTIME_MODE_RELEASE
  bool trace_skia = command_line.HasOption(FlagForSwitch(Switch::TraceSkia));
  InitSkiaEventTracer(trace_skia);
#endif

  FXL_DCHECK(!g_shell);
  g_shell = new Shell(std::move(command_line));
  blink::Threads::UI()->PostTask(
      [bundle_path]() { Engine::Init(bundle_path); });
}

Shell& Shell::Shared() {
  FXL_DCHECK(g_shell);
  return *g_shell;
}

const fxl::CommandLine& Shell::GetCommandLine() const {
  return command_line_;
}

void Shell::InitGpuThread() {
  gpu_thread_checker_.reset(new fxl::ThreadChecker());
}

void Shell::InitUIThread() {
  ui_thread_checker_.reset(new fxl::ThreadChecker());
}

void Shell::AddPlatformView(PlatformView* platform_view) {
  if (platform_view == nullptr) {
    return;
  }
  fxl::MutexLocker lock(&platform_views_mutex_);
  platform_views_.insert(platform_view);
}

void Shell::RemovePlatformView(PlatformView* platform_view) {
  if (platform_view == nullptr) {
    return;
  }
  fxl::MutexLocker lock(&platform_views_mutex_);
  platform_views_.erase(platform_view);
}

void Shell::IteratePlatformViews(
    std::function<bool(PlatformView*)> iterator) const {
  if (iterator == nullptr) {
    return;
  }
  fxl::MutexLocker lock(&platform_views_mutex_);
  for (PlatformView* view : platform_views_) {
    if (!iterator(view)) {
      return;
    }
  }
}

void Shell::RunInPlatformView(uintptr_t view_id,
                              const char* main_script,
                              const char* packages_file,
                              const char* asset_directory,
                              bool* view_existed,
                              int64_t* dart_isolate_id,
                              std::string* isolate_name) {
  fxl::AutoResetWaitableEvent latch;
  FXL_DCHECK(view_id != 0);
  FXL_DCHECK(main_script);
  FXL_DCHECK(packages_file);
  FXL_DCHECK(asset_directory);
  FXL_DCHECK(view_existed);

  blink::Threads::UI()->PostTask([this, view_id, main_script, packages_file,
                                  asset_directory, view_existed,
                                  dart_isolate_id, isolate_name, &latch]() {
    RunInPlatformViewUIThread(view_id, main_script, packages_file,
                              asset_directory, view_existed, dart_isolate_id,
                              isolate_name, &latch);
  });
  latch.Wait();
}

void Shell::RunInPlatformViewUIThread(uintptr_t view_id,
                                      const std::string& main,
                                      const std::string& packages,
                                      const std::string& assets_directory,
                                      bool* view_existed,
                                      int64_t* dart_isolate_id,
                                      std::string* isolate_name,
                                      fxl::AutoResetWaitableEvent* latch) {
  FXL_DCHECK(ui_thread_checker_ &&
             ui_thread_checker_->IsCreationThreadCurrent());

  *view_existed = false;

  IteratePlatformViews(
      [view_id,  // argument
#if !defined(OS_WIN)
                 // Using std::move on const references inside lambda capture is
                 // not supported on Windows for some reason.
       assets_directory = std::move(assets_directory),  // argument
       main = std::move(main),                          // argument
       packages = std::move(packages),                  // argument
#else
       assets_directory,  // argument
       main,              // argument
       packages,          // argument
#endif
       &view_existed,     // out
       &dart_isolate_id,  // out
       &isolate_name      // out
  ](PlatformView* view) -> bool {
        if (reinterpret_cast<uintptr_t>(view) != view_id) {
          // Keep looking.
          return true;
        }
        *view_existed = true;
        view->RunFromSource(assets_directory, main, packages);
        *dart_isolate_id = view->engine().GetUIIsolateMainPort();
        *isolate_name = view->engine().GetUIIsolateName();
        // We found the requested view. Stop iterating over platform views.
        return false;
      });

  latch->Signal();
}

void Shell::SetAssetBundlePathInPlatformView(uintptr_t view_id,
                                             const char* asset_directory,
                                             bool* view_existed,
                                             int64_t* dart_isolate_id,
                                             std::string* isolate_name) {
  fxl::AutoResetWaitableEvent latch;
  FXL_DCHECK(view_id != 0);
  FXL_DCHECK(asset_directory);
  FXL_DCHECK(view_existed);

  blink::Threads::UI()->PostTask([this, view_id, asset_directory, view_existed,
                                  dart_isolate_id, isolate_name, &latch]() {
    SetAssetBundlePathInPlatformViewUIThread(view_id, asset_directory,
                                             view_existed, dart_isolate_id,
                                             isolate_name, &latch);
  });
  latch.Wait();
}

void Shell::SetAssetBundlePathInPlatformViewUIThread(
    uintptr_t view_id,
    const std::string& assets_directory,
    bool* view_existed,
    int64_t* dart_isolate_id,
    std::string* isolate_name,
    fxl::AutoResetWaitableEvent* latch) {
  FXL_DCHECK(ui_thread_checker_ &&
             ui_thread_checker_->IsCreationThreadCurrent());

  *view_existed = false;

  IteratePlatformViews(
      [view_id,  // argument
#if !defined(OS_WIN)
                 // Using std::move on const references inside lambda capture is
                 // not supported on Windows for some reason.
                 // TODO(https://github.com/flutter/flutter/issues/13908):
                 // Investigate the root cause of the difference.
       assets_directory = std::move(assets_directory),  // argument
#else
       assets_directory,  // argument
#endif
       &view_existed,     // out
       &dart_isolate_id,  // out
       &isolate_name      // out
  ](PlatformView* view) -> bool {
        if (reinterpret_cast<uintptr_t>(view) != view_id) {
          // Keep looking.
          return true;
        }
        *view_existed = true;
        view->SetAssetBundlePath(assets_directory);
        *dart_isolate_id = view->engine().GetUIIsolateMainPort();
        *isolate_name = view->engine().GetUIIsolateName();
        // We found the requested view. Stop iterating over
        // platform views.
        return false;
      });

  latch->Signal();
}

}  // namespace shell
