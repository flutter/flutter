// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_RENDERER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_RENDERER_H_

#include <memory>

#include "flutter/common/settings.h"
#include "flutter/common/task_runners.h"
#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/context/android_context.h"
#include "flutter/shell/platform/android/surface/android_native_window.h"
#include "flutter/shell/platform/android/surface/android_surface.h"
#include "flutter/shell/platform/android/surface/snapshot_surface_producer.h"

namespace flutter {

class AndroidSurfaceFactoryImpl : public AndroidSurfaceFactory {
 public:
  //----------------------------------------------------------------------------
  /// @param[in]  create_transaction  Passed to the Vulkan surfaces it creates.
  ///
  AndroidSurfaceFactoryImpl(const std::shared_ptr<AndroidContext>& context,
                            bool enable_impeller,
                            bool lazy_shader_mode,
                            CreateSurfaceTransaction create_transaction);

  ~AndroidSurfaceFactoryImpl() override;

  std::unique_ptr<AndroidSurface> CreateSurface() override;

 private:
  const std::shared_ptr<AndroidContext>& android_context_;
  const bool enable_impeller_;
  const bool lazy_shader_mode_;
  const CreateSurfaceTransaction create_transaction_;
};

//------------------------------------------------------------------------------
/// @brief      Renders an engine into the ANativeWindow it is given: owns the
///             Android graphics context (OpenGL ES, Vulkan or software), the
///             onscreen surface for the window, and the factory for overlay
///             surfaces, and answers the engine's rendering callbacks.
///
///             The window calls block the calling thread until the raster
///             thread has applied them.
///
class AndroidRenderer {
 public:
  //----------------------------------------------------------------------------
  /// @brief      Creates a renderer with a new context for `rendering_api`.
  ///
  /// @param[in]  io_task_runner      Where the OpenGL ES contexts upload
  ///                                 resources.
  /// @param[in]  create_transaction  Gives the Vulkan swapchain an
  ///                                 embedder-owned transaction for each frame.
  ///                                 May be null.
  ///
  AndroidRenderer(const TaskRunners& task_runners,
                  const Settings& settings,
                  AndroidRenderingAPI rendering_api,
                  std::shared_ptr<fml::BasicTaskRunner> io_task_runner,
                  CreateSurfaceTransaction create_transaction);

  //----------------------------------------------------------------------------
  /// @brief      Creates a renderer that shares `android_context`, so that a
  ///             spawned engine shares GPU resources with its parent.
  ///
  AndroidRenderer(const TaskRunners& task_runners,
                  const Settings& settings,
                  std::shared_ptr<AndroidContext> android_context,
                  CreateSurfaceTransaction create_transaction);

  ~AndroidRenderer();

  bool SetNativeWindow(fml::RefPtr<AndroidNativeWindow> native_window);

  void SwapNativeWindow(fml::RefPtr<AndroidNativeWindow> native_window);

  void ResizeSurface(const DlISize& size);

  void TeardownSurface();

  //----------------------------------------------------------------------------
  /// @brief      The engine's rendering callbacks. Called on the raster thread,
  ///             except where the shell documents otherwise.
  ///
  std::unique_ptr<Surface> CreateRenderingSurface();

  std::unique_ptr<SnapshotSurfaceProducer> CreateSnapshotSurfaceProducer();

  bool MakeResourceContextCurrent() const;

  void ReleaseResourceContext() const;

  std::shared_ptr<impeller::Context> GetImpellerContext() const;

  void SetupImpellerContext();

  const std::shared_ptr<AndroidContext>& GetAndroidContext() const {
    return android_context_;
  }

  //----------------------------------------------------------------------------
  /// @brief      Creates the overlay surfaces of hybrid composition.
  ///
  const std::shared_ptr<AndroidSurfaceFactoryImpl>& GetSurfaceFactory() const {
    return surface_factory_;
  }

  //----------------------------------------------------------------------------
  /// @brief      Whether the settings and the device allow HCPP: surface
  ///             control enabled, Impeller, and a new enough API level.
  ///
  bool MeetsHCPPCriteria() const { return android_meets_hcpp_criteria_; }

  /// @brief Whether the SurfaceControl based swapchain is enabled and active.
  bool IsSurfaceControlEnabled() const;

 private:
  const TaskRunners task_runners_;
  std::shared_ptr<AndroidContext> android_context_;
  std::shared_ptr<AndroidSurfaceFactoryImpl> surface_factory_;
  std::unique_ptr<AndroidSurface> android_surface_;
  bool android_meets_hcpp_criteria_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidRenderer);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_RENDERER_H_
