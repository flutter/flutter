// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Reproduces https://github.com/flutter/flutter/issues/192365 end to end:
// `Scene.toImage` from Dart while the view has no window surface, rendered by
// Impeller's OpenGL ES backend.
//
// The OpenGL ES driver is |MockGLES|, so this runs on any host. EGL is faked
// just enough to model what matters on Android:
//  - Which thread, if any, has the context current. That is what decides
//    whether |ReactorGLES| may react.
//  - A |SnapshotSurfaceProducer| that "makes a pbuffer current" and then builds
//    a |GPUSurfaceGLImpeller|, like
//    `AndroidSurfaceGLImpeller::CreateSnapshotSurface`.

#include <atomic>
#include <memory>
#include <optional>
#include <string>
#include <thread>
#include <vector>

#include "flutter/fml/mapping.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/common/shell_test.h"
#include "flutter/shell/common/snapshot_surface_producer.h"
#include "flutter/shell/gpu/gpu_surface_gl_delegate.h"
#include "flutter/shell/gpu/gpu_surface_gl_impeller.h"
#include "flutter/testing/testing.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "impeller/entity/gles/entity_shaders_gles.h"
#include "impeller/entity/gles/framebuffer_blend_shaders_gles.h"
#include "impeller/entity/gles/modern_shaders_gles.h"
#include "impeller/renderer/backend/gles/context_gles.h"
#include "impeller/renderer/backend/gles/proc_table_gles.h"
#include "impeller/renderer/backend/gles/reactor_gles.h"
#include "impeller/renderer/backend/gles/test/mock_gles.h"
#include "third_party/tonic/converter/dart_converter.h"

// CREATE_NATIVE_ENTRY is leaky by design
// NOLINTBEGIN(clang-analyzer-core.StackAddressEscape)

namespace flutter {
namespace testing {

namespace {

using ::testing::_;
using ::testing::NiceMock;
using ::testing::Return;

/// Models the one piece of EGL state that matters here: which thread, if any,
/// has the (single) GL context current.
class FakeEGL {
 public:
  void MakeCurrent() { current_thread_.store(std::this_thread::get_id()); }

  void ClearCurrent() { current_thread_.store(std::thread::id()); }

  bool IsCurrentOnThisThread() const {
    return current_thread_.load() == std::this_thread::get_id();
  }

 private:
  std::atomic<std::thread::id> current_thread_;
};

/// Lets the reactor react only on the thread that has the context current,
/// like the Android embedder's worker in `android_context_gl_impeller.cc`.
class FakeEGLReactorWorker final : public impeller::ReactorGLES::Worker {
 public:
  explicit FakeEGLReactorWorker(std::shared_ptr<FakeEGL> egl)
      : egl_(std::move(egl)) {}

  // |ReactorGLES::Worker|
  bool CanReactorReactOnCurrentThreadNow(
      const impeller::ReactorGLES& reactor) const override {
    return egl_->IsCurrentOnThisThread();
  }

 private:
  std::shared_ptr<FakeEGL> egl_;
};

/// Builds a |GPUSurfaceGLImpeller| after making an offscreen ("pbuffer")
/// context current, like `AndroidSurfaceGLImpeller::CreateSnapshotSurface`.
class FakePbufferSnapshotSurfaceProducer final
    : public SnapshotSurfaceProducer {
 public:
  FakePbufferSnapshotSurfaceProducer(GPUSurfaceGLDelegate* delegate,
                                     std::shared_ptr<impeller::Context> context,
                                     std::shared_ptr<FakeEGL> egl)
      : delegate_(delegate),
        context_(std::move(context)),
        egl_(std::move(egl)) {}

  // |SnapshotSurfaceProducer|
  std::unique_ptr<Surface> CreateSnapshotSurface() override {
    // Make the snapshot surface current because constructing a
    // GPUSurfaceGLImpeller and its AiksContext may invoke graphics APIs.
    egl_->MakeCurrent();
    return std::make_unique<GPUSurfaceGLImpeller>(delegate_, context_,
                                                  /*render_to_surface=*/true);
  }

 private:
  GPUSurfaceGLDelegate* delegate_;
  std::shared_ptr<impeller::Context> context_;
  std::shared_ptr<FakeEGL> egl_;
};

/// A platform view with an Impeller OpenGL ES context that never gets a window
/// surface: the test never calls |PlatformViewNotifyCreated|, like an Android
/// app before `SurfaceView.surfaceCreated` (or after `surfaceDestroyed`).
class NoSurfaceGLESPlatformView final : public PlatformView,
                                        public GPUSurfaceGLDelegate {
 public:
  NoSurfaceGLESPlatformView(PlatformView::Delegate& delegate,
                            const TaskRunners& task_runners,
                            std::shared_ptr<impeller::ContextGLES> context,
                            std::shared_ptr<FakeEGL> egl)
      : PlatformView(delegate, task_runners),
        context_(std::move(context)),
        egl_(std::move(egl)) {}

  // |PlatformView|
  std::shared_ptr<impeller::Context> GetImpellerContext() const override {
    return context_;
  }

  // |PlatformView|
  std::unique_ptr<SnapshotSurfaceProducer> CreateSnapshotSurfaceProducer()
      override {
    return std::make_unique<FakePbufferSnapshotSurfaceProducer>(this, context_,
                                                                egl_);
  }

  // |GPUSurfaceGLDelegate|
  std::unique_ptr<GLContextResult> GLContextMakeCurrent() override {
    egl_->MakeCurrent();
    return std::make_unique<GLContextDefaultResult>(true);
  }

  // |GPUSurfaceGLDelegate|
  bool GLContextClearCurrent() override {
    egl_->ClearCurrent();
    return true;
  }

  // |GPUSurfaceGLDelegate|
  bool GLContextPresent(const GLPresentInfo& present_info) override {
    return true;
  }

  // |GPUSurfaceGLDelegate|
  GLFBOInfo GLContextFBO(GLFrameInfo frame_info) const override {
    return GLFBOInfo{0, std::nullopt};
  }

 private:
  std::shared_ptr<impeller::ContextGLES> context_;
  std::shared_ptr<FakeEGL> egl_;
};

std::vector<std::shared_ptr<fml::Mapping>> ShaderLibraryMappings() {
  return {
      std::make_shared<fml::NonOwnedMapping>(
          impeller_entity_shaders_gles_data,
          impeller_entity_shaders_gles_length),
      std::make_shared<fml::NonOwnedMapping>(
          impeller_modern_shaders_gles_data,
          impeller_modern_shaders_gles_length),
      std::make_shared<fml::NonOwnedMapping>(
          impeller_framebuffer_blend_shaders_gles_data,
          impeller_framebuffer_blend_shaders_gles_length),
  };
}

/// Gives the mock driver just enough behavior for pipelines to compile and
/// offscreen render targets to be complete.
void ConfigureMockDriver(NiceMock<impeller::testing::MockGLESImpl>& gl) {
  ON_CALL(gl, CreateShader(_)).WillByDefault(Return(1));
  ON_CALL(gl, CreateProgram()).WillByDefault(Return(1));
  ON_CALL(gl, IsProgram(_)).WillByDefault(Return(GL_TRUE));
  ON_CALL(gl, GetShaderiv(_, _, _))
      .WillByDefault([](GLuint shader, GLenum pname, GLint* params) {
        *params = pname == GL_COMPILE_STATUS ? GL_TRUE : 0;
      });
  ON_CALL(gl, GetProgramiv(_, _, _))
      .WillByDefault([](GLuint program, GLenum pname, GLint* params) {
        *params = pname == GL_LINK_STATUS ? GL_TRUE : 0;
      });
  ON_CALL(gl, GetIntegerv(_, _)).WillByDefault([](GLenum name, GLint* value) {
    if (name == GL_MAX_TEXTURE_IMAGE_UNITS ||
        name == GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS) {
      *value = 8;
    }
  });
  ON_CALL(gl, GenTextures(_, _)).WillByDefault([](GLsizei n, GLuint* names) {
    static std::atomic<GLuint> next_name = 1;
    for (GLsizei i = 0; i < n; i++) {
      names[i] = next_name++;
    }
  });
  ON_CALL(gl, GenFramebuffers(_, _))
      .WillByDefault([](GLsizei n, GLuint* names) {
        static std::atomic<GLuint> next_name = 1;
        for (GLsizei i = 0; i < n; i++) {
          names[i] = next_name++;
        }
      });
  ON_CALL(gl, IsTexture(_)).WillByDefault(Return(GL_TRUE));
  ON_CALL(gl, CheckFramebufferStatus(_))
      .WillByDefault(Return(GL_FRAMEBUFFER_COMPLETE));
}

}  // namespace

// In unoptimized builds this stops first at the FML_DCHECK in
// ReactorGLES::CreateUntrackedHandle, when the throwaway AiksContext is built
// with no context current. In optimized builds it crashes with the
// use-after-free in DeviceBufferGLES::OnGetContents from the issue.
TEST_F(ShellTest, SceneToImageWithoutSurfaceOnImpellerGLES) {
  auto mock_gles_impl =
      std::make_unique<NiceMock<impeller::testing::MockGLESImpl>>();
  ConfigureMockDriver(*mock_gles_impl);
  std::shared_ptr<impeller::testing::MockGLES> mock_gles =
      impeller::testing::MockGLES::Init(std::move(mock_gles_impl));

  auto egl = std::make_shared<FakeEGL>();
  std::shared_ptr<impeller::ContextGLES> context =
      impeller::ContextGLES::Create(impeller::Flags{},
                                    std::make_unique<impeller::ProcTableGLES>(
                                        impeller::testing::kMockResolverGLES),
                                    ShaderLibraryMappings(),
                                    /*enable_gpu_tracing=*/false);
  ASSERT_TRUE(context);
  ASSERT_TRUE(std::static_pointer_cast<impeller::Context>(context)->IsValid());
  auto worker = std::make_shared<FakeEGLReactorWorker>(egl);
  context->AddReactorWorker(worker);

  Settings settings = CreateSettingsForFixture();
  settings.enable_impeller = true;
  TaskRunners task_runners("test",                  // label
                           GetCurrentTaskRunner(),  // platform
                           CreateNewThread(),       // raster
                           CreateNewThread(),       // ui
                           CreateNewThread()        // io
  );

  std::unique_ptr<Shell> shell = CreateShell({
      .settings = settings,
      .task_runners = task_runners,
      .platform_view_create_callback =
          [&context, &egl](Shell& shell) -> std::unique_ptr<PlatformView> {
        return std::make_unique<NoSurfaceGLESPlatformView>(
            shell, shell.GetTaskRunners(), context, egl);
      },
  });
  ASSERT_TRUE(shell->IsSetup());
  // Deliberately no PlatformViewNotifyCreated(): the rasterizer has no
  // surface, so no context is current on the raster thread.

  fml::AutoResetWaitableEvent latch;
  int64_t width = 0;
  int64_t height = 0;
  std::optional<std::string> error;
  AddNativeCallback(
      "SceneToImageResult", CREATE_NATIVE_ENTRY([&](Dart_NativeArguments args) {
        width = tonic::DartConverter<int64_t>::FromDart(
            Dart_GetNativeArgument(args, 0));
        height = tonic::DartConverter<int64_t>::FromDart(
            Dart_GetNativeArgument(args, 1));
        Dart_Handle error_handle = Dart_GetNativeArgument(args, 2);
        if (!Dart_IsNull(error_handle)) {
          error = tonic::DartConverter<std::string>::FromDart(error_handle);
        }
        latch.Signal();
      }));

  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("sceneToImageWithoutSurface");
  shell->RunEngine(std::move(configuration), [](auto result) {
    ASSERT_EQ(result, Engine::RunStatus::Success);
  });

  latch.Wait();
  EXPECT_EQ(error, std::nullopt);
  EXPECT_EQ(width, 8);
  EXPECT_EQ(height, 8);

  DestroyShell(std::move(shell), task_runners);
}

}  // namespace testing
}  // namespace flutter

// NOLINTEND(clang-analyzer-core.StackAddressEscape)
