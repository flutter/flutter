// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_SHELL_H_
#define SKY_SHELL_SHELL_H_

#include "base/threading/thread.h"
#include "lib/ftl/macros.h"
#include "lib/ftl/memory/ref_ptr.h"
#include "lib/ftl/memory/weak_ptr.h"
#include "lib/ftl/synchronization/waitable_event.h"
#include "lib/ftl/tasks/task_runner.h"
#include "flutter/sky/shell/tracing_controller.h"

namespace sky {
namespace shell {

class PlatformView;
class Rasterizer;

class Shell {
 public:
  ~Shell();

  // Init the shell to stand alone from MojoShell.
  static void InitStandalone(std::string icu_data_path = "");

  // Init the shell to run inside MojoShell.
  static void Init();

  static Shell& Shared();

  ftl::TaskRunner* gpu_ftl_task_runner() const {
    return gpu_ftl_task_runner_.get();
  }

  ftl::TaskRunner* ui_ftl_task_runner() const {
    return ui_ftl_task_runner_.get();
  }

  ftl::TaskRunner* io_ftl_task_runner() const {
    return io_ftl_task_runner_.get();
  }

  TracingController& tracing_controller();

  // Maintain a list of rasterizers.
  // These APIs must only be accessed on the GPU thread.
  void AddRasterizer(const ftl::WeakPtr<Rasterizer>& rasterizer);
  void PurgeRasterizers();
  void GetRasterizers(std::vector<ftl::WeakPtr<Rasterizer>>* rasterizer);

  // List of PlatformViews.

  // These APIs must only be accessed on UI thread.
  void AddPlatformView(const ftl::WeakPtr<PlatformView>& platform_view);
  void PurgePlatformViews();
  void GetPlatformViews(
      std::vector<ftl::WeakPtr<PlatformView>>* platform_views);

  struct PlatformViewInfo {
    uintptr_t view_id;
    int64_t isolate_id;
  };

  // These APIs can be called from any thread.
  // Return the list of platform view ids at the time of this call.
  void WaitForPlatformViewIds(std::vector<PlatformViewInfo>* platform_view_ids);

  // Attempt to run a script inside a flutter view indicated by |view_id|.
  // Will set |view_existed| to true if the view was found and false otherwise.
  void RunInPlatformView(uintptr_t view_id,
                         const char* main_script,
                         const char* packages_file,
                         const char* asset_directory,
                         bool* view_existed,
                         int64_t* dart_isolate_id);

 private:
  Shell();

  void InitGpuThread();
  void InitUIThread();

  void WaitForPlatformViewsIdsUIThread(
      std::vector<PlatformViewInfo>* platform_views,
      ftl::AutoResetWaitableEvent* latch);

  void RunInPlatformViewUIThread(uintptr_t view_id,
                                 const std::string& main,
                                 const std::string& packages,
                                 const std::string& assets_directory,
                                 bool* view_existed,
                                 int64_t* dart_isolate_id,
                                 ftl::AutoResetWaitableEvent* latch);

  std::unique_ptr<base::Thread> gpu_thread_;
  std::unique_ptr<base::Thread> ui_thread_;
  std::unique_ptr<base::Thread> io_thread_;

  ftl::RefPtr<ftl::TaskRunner> gpu_ftl_task_runner_;
  ftl::RefPtr<ftl::TaskRunner> ui_ftl_task_runner_;
  ftl::RefPtr<ftl::TaskRunner> io_ftl_task_runner_;

  std::unique_ptr<base::ThreadChecker> gpu_thread_checker_;
  std::unique_ptr<base::ThreadChecker> ui_thread_checker_;

  TracingController tracing_controller_;

  std::vector<ftl::WeakPtr<Rasterizer>> rasterizers_;
  std::vector<ftl::WeakPtr<PlatformView>> platform_views_;

  FTL_DISALLOW_COPY_AND_ASSIGN(Shell);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_SHELL_H_
