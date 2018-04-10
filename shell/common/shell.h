// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_COMMON_SHELL_H_
#define SHELL_COMMON_SHELL_H_

#include <mutex>
#include <unordered_set>

#include "flutter/fml/thread.h"
#include "flutter/shell/common/tracing_controller.h"
#include "lib/fxl/command_line.h"
#include "lib/fxl/functional/closure.h"
#include "lib/fxl/macros.h"
#include "lib/fxl/memory/ref_ptr.h"
#include "lib/fxl/memory/weak_ptr.h"
#include "lib/fxl/synchronization/thread_checker.h"
#include "lib/fxl/synchronization/waitable_event.h"
#include "lib/fxl/tasks/task_runner.h"

namespace shell {

class PlatformView;

class Shell {
 public:
  ~Shell();

  static void InitStandalone(fxl::CommandLine command_line,
                             std::string icu_data_path = "",
                             std::string application_library_path = "",
                             std::string bundle_path = "");

  static Shell& Shared();

  const fxl::CommandLine& GetCommandLine() const;

  void AddPlatformView(PlatformView* platform_view);

  void RemovePlatformView(PlatformView* platform_view);

  void IteratePlatformViews(
      std::function<bool /* continue */ (PlatformView*)> iterator) const;

  // Attempt to run a script inside a flutter view indicated by |view_id|.
  // Will set |view_existed| to true if the view was found and false otherwise.
  void RunInPlatformView(uintptr_t view_id,
                         const char* main_script,
                         const char* packages_file,
                         const char* asset_directory,
                         bool* view_existed,
                         int64_t* dart_isolate_id,
                         std::string* isolate_name);

  void SetAssetBundlePathInPlatformView(uintptr_t view_id,
                                        const char* asset_directory,
                                        bool* view_existed,
                                        int64_t* dart_isolate_id,
                                        std::string* isolate_name);

 private:
  fxl::CommandLine command_line_;
  std::unique_ptr<fml::Thread> gpu_thread_;
  std::unique_ptr<fml::Thread> ui_thread_;
  std::unique_ptr<fml::Thread> io_thread_;
  std::unique_ptr<fxl::ThreadChecker> gpu_thread_checker_;
  std::unique_ptr<fxl::ThreadChecker> ui_thread_checker_;
  TracingController tracing_controller_;
  mutable std::mutex platform_views_mutex_;
  std::unordered_set<PlatformView*> platform_views_;

  static void Init(fxl::CommandLine command_line,
                   const std::string& bundle_path);

  Shell(fxl::CommandLine command_line);

  void InitGpuThread();

  void InitUIThread();

  void RunInPlatformViewUIThread(uintptr_t view_id,
                                 const std::string& main,
                                 const std::string& packages,
                                 const std::string& assets_directory,
                                 bool* view_existed,
                                 int64_t* dart_isolate_id,
                                 std::string* isolate_name,
                                 fxl::AutoResetWaitableEvent* latch);

  void SetAssetBundlePathInPlatformViewUIThread(
      uintptr_t view_id,
      const std::string& main,
      bool* view_existed,
      int64_t* dart_isolate_id,
      std::string* isolate_name,
      fxl::AutoResetWaitableEvent* latch);

  FXL_DISALLOW_COPY_AND_ASSIGN(Shell);
};

}  // namespace shell

#endif  // SHELL_COMMON_SHELL_H_
