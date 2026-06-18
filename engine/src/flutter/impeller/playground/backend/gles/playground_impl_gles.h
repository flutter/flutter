// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_PLAYGROUND_BACKEND_GLES_PLAYGROUND_IMPL_GLES_H_
#define FLUTTER_IMPELLER_PLAYGROUND_BACKEND_GLES_PLAYGROUND_IMPL_GLES_H_

#include "impeller/playground/playground_impl.h"

#include "impeller/renderer/backend/gles/context_gles.h"

struct GLFWwindow;

namespace impeller {

class PlaygroundImplGLES final : public PlaygroundImpl {
 public:
  struct ShareableContext;

  explicit PlaygroundImplGLES(
      PlaygroundSwitches switches,
      std::shared_ptr<ShareableContext>& shared_context);

  ~PlaygroundImplGLES();

  fml::Status SetCapabilities(
      const std::shared_ptr<Capabilities>& capabilities) override;

 private:
  class ReactorWorker;

  static void DestroyWindowHandle(WindowHandle handle);
  using UniqueHandle =
      std::unique_ptr<GLFWwindow, decltype(&DestroyWindowHandle)>;
  UniqueHandle handle_;
  const bool use_angle_;
  void* angle_glesv2_;
  std::shared_ptr<Context> context_;

  // |PlaygroundImpl|
  std::shared_ptr<Context> GetContext() const override;

  // |PlaygroundImpl|
  WindowHandle GetWindowHandle() const override;

  // |PlaygroundImpl|
  std::unique_ptr<Surface> AcquireSurfaceFrame(
      std::shared_ptr<Context> context) override;

  // |PlaygroundImpl|
  Playground::GLProcAddressResolver CreateGLProcAddressResolver()
      const override;

  static Playground::GLProcAddressResolver CreateGLProcAddressResolver(
      const PlaygroundSwitches& switches);

  static GLFWwindow* CreateGLWindow(const PlaygroundSwitches& switches,
                                    GLFWwindow* share_window);

  static std::shared_ptr<ShareableContext> MakeShareableContext(
      const PlaygroundSwitches& switches);

  RuntimeStageBackend GetRuntimeStageBackend() const override;

  PlaygroundImplGLES(const PlaygroundImplGLES&) = delete;

  PlaygroundImplGLES& operator=(const PlaygroundImplGLES&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_PLAYGROUND_BACKEND_GLES_PLAYGROUND_IMPL_GLES_H_
