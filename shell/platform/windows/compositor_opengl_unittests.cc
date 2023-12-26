// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include <vector>

#include "flutter/impeller/renderer/backend/gles/gles.h"
#include "flutter/shell/platform/windows/angle_surface_manager.h"
#include "flutter/shell/platform/windows/compositor_opengl.h"
#include "flutter/shell/platform/windows/flutter_windows_view.h"
#include "flutter/shell/platform/windows/testing/engine_modifier.h"
#include "flutter/shell/platform/windows/testing/flutter_windows_engine_builder.h"
#include "flutter/shell/platform/windows/testing/mock_window_binding_handler.h"
#include "flutter/shell/platform/windows/testing/windows_test.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {
using ::testing::Return;

const unsigned char* MockGetString(GLenum name) {
  switch (name) {
    case GL_VERSION:
    case GL_SHADING_LANGUAGE_VERSION:
      return reinterpret_cast<const unsigned char*>("3.0");
    default:
      return reinterpret_cast<const unsigned char*>("");
  }
}

void MockGetIntegerv(GLenum name, int* value) {
  *value = 0;
}

GLenum MockGetError() {
  return GL_NO_ERROR;
}

void DoNothing() {}

const impeller::ProcTableGLES::Resolver kMockResolver = [](const char* name) {
  std::string function_name{name};

  if (function_name == "glGetString") {
    return reinterpret_cast<void*>(&MockGetString);
  } else if (function_name == "glGetIntegerv") {
    return reinterpret_cast<void*>(&MockGetIntegerv);
  } else if (function_name == "glGetError") {
    return reinterpret_cast<void*>(&MockGetError);
  } else {
    return reinterpret_cast<void*>(&DoNothing);
  }
};

class MockAngleSurfaceManager : public AngleSurfaceManager {
 public:
  MockAngleSurfaceManager() : AngleSurfaceManager(false) {}

  MOCK_METHOD(bool, MakeCurrent, (), (override));

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(MockAngleSurfaceManager);
};

class MockFlutterWindowsView : public FlutterWindowsView {
 public:
  MockFlutterWindowsView(std::unique_ptr<WindowBindingHandler> window)
      : FlutterWindowsView(std::move(window)) {}
  virtual ~MockFlutterWindowsView() = default;

  MOCK_METHOD(bool, SwapBuffers, (), (override));

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(MockFlutterWindowsView);
};

class CompositorOpenGLTest : public WindowsTest {
 public:
  CompositorOpenGLTest() = default;
  virtual ~CompositorOpenGLTest() = default;

 protected:
  FlutterWindowsEngine* engine() { return engine_.get(); }
  MockFlutterWindowsView* view() { return view_.get(); }
  MockAngleSurfaceManager* surface_manager() { return surface_manager_; }

  void UseHeadlessEngine() {
    auto surface_manager = std::make_unique<MockAngleSurfaceManager>();
    surface_manager_ = surface_manager.get();

    FlutterWindowsEngineBuilder builder{GetContext()};

    engine_ = builder.Build();
    EngineModifier modifier(engine_.get());
    modifier.SetSurfaceManager(std::move(surface_manager));
  }

  void UseEngineWithView() {
    UseHeadlessEngine();

    auto window = std::make_unique<MockWindowBindingHandler>();
    EXPECT_CALL(*window.get(), SetView).Times(1);
    EXPECT_CALL(*window.get(), GetWindowHandle).WillRepeatedly(Return(nullptr));

    view_ = std::make_unique<MockFlutterWindowsView>(std::move(window));

    engine_->SetView(view_.get());
  }

 private:
  std::unique_ptr<FlutterWindowsEngine> engine_;
  std::unique_ptr<MockFlutterWindowsView> view_;
  MockAngleSurfaceManager* surface_manager_;

  FML_DISALLOW_COPY_AND_ASSIGN(CompositorOpenGLTest);
};

}  // namespace

TEST_F(CompositorOpenGLTest, CreateBackingStore) {
  UseHeadlessEngine();

  auto compositor = CompositorOpenGL{engine(), kMockResolver};

  FlutterBackingStoreConfig config = {};
  FlutterBackingStore backing_store = {};

  EXPECT_CALL(*surface_manager(), MakeCurrent).WillOnce(Return(true));
  ASSERT_TRUE(compositor.CreateBackingStore(config, &backing_store));
  ASSERT_TRUE(compositor.CollectBackingStore(&backing_store));
}

TEST_F(CompositorOpenGLTest, InitializationFailure) {
  UseHeadlessEngine();

  auto compositor = CompositorOpenGL{engine(), kMockResolver};

  FlutterBackingStoreConfig config = {};
  FlutterBackingStore backing_store = {};

  EXPECT_CALL(*surface_manager(), MakeCurrent).WillOnce(Return(false));
  EXPECT_FALSE(compositor.CreateBackingStore(config, &backing_store));
}

TEST_F(CompositorOpenGLTest, Present) {
  UseEngineWithView();

  auto compositor = CompositorOpenGL{engine(), kMockResolver};

  FlutterBackingStoreConfig config = {};
  FlutterBackingStore backing_store = {};

  EXPECT_CALL(*surface_manager(), MakeCurrent).WillOnce(Return(true));
  ASSERT_TRUE(compositor.CreateBackingStore(config, &backing_store));

  FlutterLayer layer = {};
  layer.type = kFlutterLayerContentTypeBackingStore;
  layer.backing_store = &backing_store;
  const FlutterLayer* layer_ptr = &layer;

  EXPECT_CALL(*surface_manager(), MakeCurrent).WillOnce(Return(true));
  EXPECT_CALL(*view(), SwapBuffers).WillOnce(Return(true));
  EXPECT_TRUE(compositor.Present(&layer_ptr, 1));

  ASSERT_TRUE(compositor.CollectBackingStore(&backing_store));
}

TEST_F(CompositorOpenGLTest, PresentEmpty) {
  UseEngineWithView();

  auto compositor = CompositorOpenGL{engine(), kMockResolver};

  // The context will be bound twice: first to initialize the compositor, second
  // to clear the surface.
  EXPECT_CALL(*surface_manager(), MakeCurrent)
      .Times(2)
      .WillRepeatedly(Return(true));
  EXPECT_CALL(*view(), SwapBuffers).WillOnce(Return(true));
  EXPECT_TRUE(compositor.Present(nullptr, 0));
}

TEST_F(CompositorOpenGLTest, HeadlessPresentIgnored) {
  UseHeadlessEngine();

  auto compositor = CompositorOpenGL{engine(), kMockResolver};

  FlutterBackingStoreConfig config = {};
  FlutterBackingStore backing_store = {};

  EXPECT_CALL(*surface_manager(), MakeCurrent).WillOnce(Return(true));
  ASSERT_TRUE(compositor.CreateBackingStore(config, &backing_store));

  FlutterLayer layer = {};
  layer.type = kFlutterLayerContentTypeBackingStore;
  layer.backing_store = &backing_store;
  const FlutterLayer* layer_ptr = &layer;

  EXPECT_FALSE(compositor.Present(&layer_ptr, 1));

  ASSERT_TRUE(compositor.CollectBackingStore(&backing_store));
}

}  // namespace testing
}  // namespace flutter
