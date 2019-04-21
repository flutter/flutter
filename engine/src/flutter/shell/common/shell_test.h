// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_SHELL_TEST_H_
#define FLUTTER_SHELL_COMMON_SHELL_TEST_H_

#include <memory>

#include "flutter/common/settings.h"
#include "flutter/fml/macros.h"
#include "flutter/shell/common/run_configuration.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/shell/gpu/gpu_surface_software.h"
#include "flutter/testing/test_dart_native_resolver.h"
#include "flutter/testing/thread_test.h"

namespace flutter {
namespace testing {

class ShellTest : public ThreadTest {
 public:
  ShellTest();

  ~ShellTest();

  Settings CreateSettingsForFixture();

  TaskRunners GetTaskRunnersForFixture();

  void AddNativeCallback(std::string name, Dart_NativeFunction callback);

 protected:
  // |testing::ThreadTest|
  void SetUp() override;

  // |testing::ThreadTest|
  void TearDown() override;

 private:
  fml::UniqueFD assets_dir_;
  std::shared_ptr<TestDartNativeResolver> native_resolver_;
  std::unique_ptr<ThreadHost> thread_host_;

  void SetSnapshotsAndAssets(Settings& settings);
};

class ShellTestPlatformView : public PlatformView,
                              public GPUSurfaceSoftwareDelegate {
 public:
  ShellTestPlatformView(PlatformView::Delegate& delegate,
                        TaskRunners task_runners);

  ~ShellTestPlatformView() override;

 private:
  // |PlatformView|
  std::unique_ptr<Surface> CreateRenderingSurface() override;

  // |GPUSurfaceSoftwareDelegate|
  virtual sk_sp<SkSurface> AcquireBackingStore(const SkISize& size) override;

  // |GPUSurfaceSoftwareDelegate|
  virtual bool PresentBackingStore(sk_sp<SkSurface> backing_store) override;

  FML_DISALLOW_COPY_AND_ASSIGN(ShellTestPlatformView);
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_COMMON_SHELL_TEST_H_
