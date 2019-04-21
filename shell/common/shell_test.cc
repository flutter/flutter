// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/common/shell_test.h"

#include "flutter/fml/mapping.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/testing/testing.h"

namespace flutter {
namespace testing {

ShellTest::ShellTest()
    : native_resolver_(std::make_shared<TestDartNativeResolver>()) {}

ShellTest::~ShellTest() = default;

void ShellTest::SetSnapshotsAndAssets(Settings& settings) {
  if (!assets_dir_.is_valid()) {
    return;
  }

  settings.assets_dir = assets_dir_.get();

  // In JIT execution, all snapshots are present within the binary itself and
  // don't need to be explicitly suppiled by the embedder.
  if (DartVM::IsRunningPrecompiledCode()) {
    settings.vm_snapshot_data = [this]() {
      return fml::FileMapping::CreateReadOnly(assets_dir_, "vm_snapshot_data");
    };

    settings.isolate_snapshot_data = [this]() {
      return fml::FileMapping::CreateReadOnly(assets_dir_,
                                              "isolate_snapshot_data");
    };

    if (DartVM::IsRunningPrecompiledCode()) {
      settings.vm_snapshot_instr = [this]() {
        return fml::FileMapping::CreateReadExecute(assets_dir_,
                                                   "vm_snapshot_instr");
      };

      settings.isolate_snapshot_instr = [this]() {
        return fml::FileMapping::CreateReadExecute(assets_dir_,
                                                   "isolate_snapshot_instr");
      };
    }
  } else {
    settings.application_kernels = [this]() {
      std::vector<std::unique_ptr<const fml::Mapping>> kernel_mappings;
      kernel_mappings.emplace_back(
          fml::FileMapping::CreateReadOnly(assets_dir_, "kernel_blob.bin"));
      return kernel_mappings;
    };
  }
}

Settings ShellTest::CreateSettingsForFixture() {
  Settings settings;
  settings.leak_vm = false;
  settings.task_observer_add = [](intptr_t key, fml::closure handler) {
    fml::MessageLoop::GetCurrent().AddTaskObserver(key, handler);
  };
  settings.task_observer_remove = [](intptr_t key) {
    fml::MessageLoop::GetCurrent().RemoveTaskObserver(key);
  };
  settings.isolate_create_callback = [this]() {
    native_resolver_->SetNativeResolverForIsolate();
  };
  SetSnapshotsAndAssets(settings);
  return settings;
}

TaskRunners ShellTest::GetTaskRunnersForFixture() {
  return {
      "test",
      thread_host_->platform_thread->GetTaskRunner(),  // platform
      thread_host_->gpu_thread->GetTaskRunner(),       // gpu
      thread_host_->ui_thread->GetTaskRunner(),        // ui
      thread_host_->io_thread->GetTaskRunner()         // io
  };
}

// |testing::ThreadTest|
void ShellTest::SetUp() {
  ThreadTest::SetUp();
  assets_dir_ =
      fml::OpenDirectory(GetFixturesPath(), false, fml::FilePermission::kRead);
  thread_host_ = std::make_unique<ThreadHost>(
      "io.flutter.test." + GetCurrentTestName() + ".",
      ThreadHost::Type::Platform | ThreadHost::Type::IO | ThreadHost::Type::UI |
          ThreadHost::Type::GPU);
}

// |testing::ThreadTest|
void ShellTest::TearDown() {
  ThreadTest::TearDown();
  assets_dir_.reset();
  thread_host_.reset();
}

void ShellTest::AddNativeCallback(std::string name,
                                  Dart_NativeFunction callback) {
  native_resolver_->AddNativeCallback(std::move(name), callback);
}

ShellTestPlatformView::ShellTestPlatformView(PlatformView::Delegate& delegate,
                                             TaskRunners task_runners)
    : PlatformView(delegate, std::move(task_runners)) {}

ShellTestPlatformView::~ShellTestPlatformView() = default;

// |PlatformView|
std::unique_ptr<Surface> ShellTestPlatformView::CreateRenderingSurface() {
  return std::make_unique<GPUSurfaceSoftware>(this);
}

// |GPUSurfaceSoftwareDelegate|
sk_sp<SkSurface> ShellTestPlatformView::AcquireBackingStore(
    const SkISize& size) {
  SkImageInfo image_info = SkImageInfo::MakeN32Premul(
      size.width(), size.height(), SkColorSpace::MakeSRGB());
  return SkSurface::MakeRaster(image_info);
}

// |GPUSurfaceSoftwareDelegate|
bool ShellTestPlatformView::PresentBackingStore(
    sk_sp<SkSurface> backing_store) {
  return true;
}

}  // namespace testing
}  // namespace flutter
