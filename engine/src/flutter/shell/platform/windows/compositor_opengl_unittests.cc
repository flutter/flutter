// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include <vector>

#include "flutter/impeller/renderer/backend/gles/gles.h"
#include "flutter/shell/platform/windows/compositor_opengl.h"
#include "flutter/shell/platform/windows/flutter_windows_view.h"
#include "flutter/shell/platform/windows/testing/egl/mock_context.h"
#include "flutter/shell/platform/windows/testing/egl/mock_manager.h"
#include "flutter/shell/platform/windows/testing/engine_modifier.h"
#include "flutter/shell/platform/windows/testing/flutter_windows_engine_builder.h"
#include "flutter/shell/platform/windows/testing/mock_window_binding_handler.h"
#include "flutter/shell/platform/windows/testing/test_presentation_surface.h"
#include "flutter/shell/platform/windows/testing/windows_test.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {
namespace {

using ::testing::AnyNumber;
using ::testing::Return;

class CountingPresentationSurface : public TestPresentationSurface {
 public:
  CountingPresentationSurface(size_t width, size_t height)
      : TestPresentationSurface(width, height) {}

  bool MakeCurrent() override {
    make_current_count++;
    return make_current_result;
  }

  bool Present() override {
    present_count++;
    return present_result && TestPresentationSurface::Present();
  }

  int make_current_count = 0;
  int present_count = 0;
  bool make_current_result = true;
  bool present_result = true;
};

void MockGetIntegerv(GLenum name, int* value) {
  if (name == GL_NUM_EXTENSIONS) {
    *value = 1;
  } else {
    *value = 0;
  }
}

const unsigned char* MockGetString(GLenum name) {
  switch (name) {
    case GL_VERSION:
    case GL_SHADING_LANGUAGE_VERSION:
      return reinterpret_cast<const unsigned char*>("3.0");
    default:
      return reinterpret_cast<const unsigned char*>("");
  }
}

const unsigned char* MockGetStringi(GLenum name, int index) {
  if (name == GL_EXTENSIONS) {
    return reinterpret_cast<const unsigned char*>("GL_ANGLE_framebuffer_blit");
  }
  return reinterpret_cast<const unsigned char*>("");
}

GLenum MockGetError() {
  return GL_NO_ERROR;
}

void DoNothing() {}

const impeller::ProcTableGLES::Resolver kMockResolver = [](const char* name) {
  std::string function_name{name};

  if (function_name == "glGetString") {
    return reinterpret_cast<void*>(&MockGetString);
  }
  if (function_name == "glGetStringi") {
    return reinterpret_cast<void*>(&MockGetStringi);
  }
  if (function_name == "glGetIntegerv") {
    return reinterpret_cast<void*>(&MockGetIntegerv);
  }
  if (function_name == "glGetError") {
    return reinterpret_cast<void*>(&MockGetError);
  }
  return reinterpret_cast<void*>(&DoNothing);
};

class CompositorOpenGLTest : public WindowsTest {
 public:
  CompositorOpenGLTest() = default;
  ~CompositorOpenGLTest() override = default;

 protected:
  FlutterWindowsEngine* engine() { return engine_.get(); }
  FlutterWindowsView* view() { return view_.get(); }
  egl::MockContext* render_context() { return render_context_.get(); }
  CountingPresentationSurface* presentation_surface() {
    return presentation_surface_;
  }

  void UseHeadlessEngine() {
    auto egl_manager = std::make_unique<egl::MockManager>();
    render_context_ = std::make_unique<egl::MockContext>();
    egl_manager_ = egl_manager.get();

    EXPECT_CALL(*egl_manager_, render_context)
        .Times(AnyNumber())
        .WillRepeatedly(Return(render_context_.get()));

    FlutterWindowsEngineBuilder builder{GetContext()};
    engine_ = builder.Build();

    EngineModifier modifier{engine_.get()};
    modifier.SetEGLManager(std::move(egl_manager));
  }

  void UseEngineWithView() {
    UseHeadlessEngine();

    engine_->SetPresentationSurfaceFactoryForTesting(
        [this](HWND hwnd, size_t width, size_t height,
               flutter::egl::Manager* egl_manager) {
          auto surface =
              std::make_unique<CountingPresentationSurface>(width, height);
          presentation_surface_ = surface.get();
          return surface;
        });

    auto window = std::make_unique<MockWindowBindingHandler>();
    EXPECT_CALL(*window, SetView).Times(1);
    EXPECT_CALL(*window, GetWindowHandle).WillRepeatedly(Return(nullptr));
    EXPECT_CALL(*window, GetPhysicalWindowBounds)
        .WillRepeatedly(Return(PhysicalWindowBounds{100, 100}));

    view_ =
        engine_->CreateView(std::move(window),
                            /*is_sized_to_content=*/false, BoxConstraints());
    ASSERT_NE(view_, nullptr);
    ASSERT_NE(presentation_surface_, nullptr);
  }

 private:
  std::unique_ptr<FlutterWindowsEngine> engine_;
  std::unique_ptr<FlutterWindowsView> view_;
  std::unique_ptr<egl::MockContext> render_context_;
  egl::MockManager* egl_manager_ = nullptr;
  CountingPresentationSurface* presentation_surface_ = nullptr;

  FML_DISALLOW_COPY_AND_ASSIGN(CompositorOpenGLTest);
};

}  // namespace

TEST_F(CompositorOpenGLTest, CreateBackingStore) {
  UseHeadlessEngine();

  auto compositor =
      CompositorOpenGL{engine(), kMockResolver, /*enable_impeller=*/false};

  FlutterBackingStoreConfig config = {};
  FlutterBackingStore backing_store = {};

  EXPECT_CALL(*render_context(), MakeCurrent).WillOnce(Return(true));
  ASSERT_TRUE(compositor.CreateBackingStore(config, &backing_store));
  ASSERT_TRUE(compositor.CollectBackingStore(&backing_store));
}

TEST_F(CompositorOpenGLTest, CreateBackingStoreImpeller) {
  UseHeadlessEngine();

  auto compositor =
      CompositorOpenGL{engine(), kMockResolver, /*enable_impeller=*/true};

  FlutterBackingStoreConfig config = {};
  FlutterBackingStore backing_store = {};

  EXPECT_CALL(*render_context(), MakeCurrent).WillOnce(Return(true));
  ASSERT_TRUE(compositor.CreateBackingStore(config, &backing_store));
  ASSERT_TRUE(compositor.CollectBackingStore(&backing_store));
}

TEST_F(CompositorOpenGLTest, InitializationFailure) {
  UseHeadlessEngine();

  auto compositor =
      CompositorOpenGL{engine(), kMockResolver, /*enable_impeller=*/false};

  FlutterBackingStoreConfig config = {};
  FlutterBackingStore backing_store = {};

  EXPECT_CALL(*render_context(), MakeCurrent).WillOnce(Return(false));
  EXPECT_FALSE(compositor.CreateBackingStore(config, &backing_store));
}

TEST_F(CompositorOpenGLTest, PresentUsesPresentationSurface) {
  UseEngineWithView();

  auto compositor =
      CompositorOpenGL{engine(), kMockResolver, /*enable_impeller=*/false};

  FlutterBackingStoreConfig config = {};
  FlutterBackingStore backing_store = {};

  EXPECT_CALL(*render_context(), MakeCurrent).WillOnce(Return(true));
  ASSERT_TRUE(compositor.CreateBackingStore(config, &backing_store));

  FlutterLayer layer = {};
  layer.type = kFlutterLayerContentTypeBackingStore;
  layer.backing_store = &backing_store;
  const FlutterLayer* layer_ptr = &layer;

  EXPECT_TRUE(compositor.Present(view(), &layer_ptr, 1));
  EXPECT_EQ(presentation_surface()->make_current_count, 1);
  EXPECT_EQ(presentation_surface()->present_count, 1);

  ASSERT_TRUE(compositor.CollectBackingStore(&backing_store));
}

TEST_F(CompositorOpenGLTest, PresentEmptyClearsPresentationSurface) {
  UseEngineWithView();

  auto compositor =
      CompositorOpenGL{engine(), kMockResolver, /*enable_impeller=*/false};

  EXPECT_CALL(*render_context(), MakeCurrent).WillOnce(Return(true));
  EXPECT_TRUE(compositor.Present(view(), nullptr, 0));
  EXPECT_EQ(presentation_surface()->make_current_count, 1);
  EXPECT_EQ(presentation_surface()->present_count, 1);
}

TEST_F(CompositorOpenGLTest,
       PresentFailsIfPresentationSurfaceCannotBecomeCurrent) {
  UseEngineWithView();
  presentation_surface()->make_current_result = false;

  auto compositor =
      CompositorOpenGL{engine(), kMockResolver, /*enable_impeller=*/false};

  FlutterBackingStoreConfig config = {};
  FlutterBackingStore backing_store = {};

  EXPECT_CALL(*render_context(), MakeCurrent).WillOnce(Return(true));
  ASSERT_TRUE(compositor.CreateBackingStore(config, &backing_store));

  FlutterLayer layer = {};
  layer.type = kFlutterLayerContentTypeBackingStore;
  layer.backing_store = &backing_store;
  const FlutterLayer* layer_ptr = &layer;

  EXPECT_FALSE(compositor.Present(view(), &layer_ptr, 1));
  EXPECT_EQ(presentation_surface()->present_count, 0);

  ASSERT_TRUE(compositor.CollectBackingStore(&backing_store));
}

}  // namespace testing
}  // namespace flutter
