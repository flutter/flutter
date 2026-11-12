// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include "flutter/shell/platform/linux/fl_opengl_manager.h"
#include "flutter/shell/platform/linux/fl_subsurface_egl.h"
#include "flutter/shell/platform/linux/fl_wayland_display.h"
#include "flutter/shell/platform/linux/testing/mock_epoxy.h"
#include "flutter/shell/platform/linux/testing/wayland_test.h"

#include <epoxy/egl.h>
#include <wayland-client.h>

using flutter::testing::fl_mock_wayland_free_surface;
using flutter::testing::fl_mock_wayland_get_display;
using flutter::testing::fl_mock_wayland_get_surface;

constexpr size_t kWidth = 100;
constexpr size_t kHeight = 200;
constexpr gint kScale = 2;

// The native window, and so the buffer frames are drawn into, is created in
// device pixels.
constexpr size_t kBufferWidth = kWidth * kScale;
constexpr size_t kBufferHeight = kHeight * kScale;

class FlSubsurfaceEGLTest : public flutter::testing::WaylandTest {
 protected:
  void SetUp() override {
    // A driver that supports glBlitFramebuffer, which is the path used when
    // available.
    ON_CALL(epoxy, glGetString(GL_VENDOR))
        .WillByDefault(
            ::testing::Return(reinterpret_cast<const GLubyte*>("Intel")));
    ON_CALL(epoxy, epoxy_is_desktop_gl).WillByDefault(::testing::Return(true));
    ON_CALL(epoxy, epoxy_gl_version).WillByDefault(::testing::Return(30));

    opengl_manager = fl_opengl_manager_new();
    display = fl_wayland_display_open(fl_mock_wayland_get_display());
    ASSERT_NE(display, nullptr);
    parent_surface = fl_mock_wayland_get_surface();
    subsurface = fl_wayland_display_create_subsurface(display, parent_surface);
    ASSERT_NE(subsurface, nullptr);
  }

  void TearDown() override {
    g_clear_object(&subsurface);
    g_clear_object(&display);
    g_clear_object(&opengl_manager);
    fl_mock_wayland_free_surface(parent_surface);
  }

  FlSubsurfaceEGL* CreateEGL() {
    return fl_subsurface_egl_new(opengl_manager, subsurface, kWidth, kHeight,
                                 kScale);
  }

  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
  FlOpenGLManager* opengl_manager = nullptr;
  FlWaylandDisplay* display = nullptr;
  struct wl_surface* parent_surface = nullptr;
  FlSubsurface* subsurface = nullptr;
};

// The native window is created in device pixels, i.e. scaled by the buffer
// scale of the surface.
TEST_F(FlSubsurfaceEGLTest, Create) {
  EXPECT_CALL(wayland, EGLWindowCreate(kWidth * kScale, kHeight * kScale));
  EXPECT_CALL(wayland, Request(::testing::StrEq("wl_surface"),
                               WL_SURFACE_SET_BUFFER_SCALE));

  g_autoptr(FlSubsurfaceEGL) egl = CreateEGL();
  EXPECT_NE(egl, nullptr);
  EXPECT_FALSE(HasReceivedLogLevel(G_LOG_LEVEL_WARNING));
}

// If the EGL setup fails an object is still returned, so the caller doesn't
// have to handle a failed construction.
TEST_F(FlSubsurfaceEGLTest, CreateFailure) {
  wayland.egl_window_create_fails = true;

  g_autoptr(FlSubsurfaceEGL) egl = CreateEGL();
  EXPECT_NE(egl, nullptr);
  EXPECT_TRUE(HasReceivedLogLevel(G_LOG_LEVEL_WARNING));
}

// A subsurface reference is held, so the Wayland surface being drawn to can't
// be destroyed while the EGL surface exists.
TEST_F(FlSubsurfaceEGLTest, HoldsSubsurface) {
  g_autoptr(FlSubsurfaceEGL) egl = CreateEGL();
  ASSERT_NE(egl, nullptr);

  // Drop the reference held by the test; the EGL object keeps it alive.
  FlSubsurface* s = subsurface;
  subsurface = nullptr;
  gpointer weak_subsurface = s;
  g_object_add_weak_pointer(G_OBJECT(s), &weak_subsurface);
  g_object_unref(s);
  EXPECT_NE(weak_subsurface, nullptr);
  g_object_remove_weak_pointer(G_OBJECT(s), &weak_subsurface);
}

TEST_F(FlSubsurfaceEGLTest, Resize) {
  g_autoptr(FlSubsurfaceEGL) egl = CreateEGL();
  ASSERT_NE(egl, nullptr);

  EXPECT_CALL(wayland, EGLWindowResize(300, 400));

  fl_subsurface_egl_resize(egl, 300, 400);
}

// Frames are blitted to the window surface and presented with a buffer swap.
TEST_F(FlSubsurfaceEGLTest, Present) {
  g_autoptr(FlSubsurfaceEGL) egl = CreateEGL();
  ASSERT_NE(egl, nullptr);

  EXPECT_CALL(epoxy, glBlitFramebuffer);

  fl_subsurface_egl_present(egl, 1, kWidth, kHeight, nullptr);
}

// The native window is resized if a frame of a different size arrives, so the
// frame isn't scaled by the compositor.
TEST_F(FlSubsurfaceEGLTest, PresentResizes) {
  g_autoptr(FlSubsurfaceEGL) egl = CreateEGL();
  ASSERT_NE(egl, nullptr);

  EXPECT_CALL(wayland, EGLWindowResize(kBufferWidth + 50, kBufferHeight + 50));

  fl_subsurface_egl_present(egl, 1, kBufferWidth + 50, kBufferHeight + 50,
                            nullptr);
}

// Drivers without glBlitFramebuffer draw the frame with a shader instead.
TEST_F(FlSubsurfaceEGLTest, PresentWithoutBlit) {
  EXPECT_CALL(epoxy, epoxy_gl_version).WillRepeatedly(::testing::Return(20));
  EXPECT_CALL(epoxy, epoxy_has_gl_extension(::testing::_))
      .WillRepeatedly(::testing::Return(false));

  g_autoptr(FlSubsurfaceEGL) egl = CreateEGL();
  ASSERT_NE(egl, nullptr);

  EXPECT_CALL(epoxy, glBlitFramebuffer).Times(0);

  fl_subsurface_egl_present(egl, 1, kWidth, kHeight, nullptr);
}

// A frame the same size as the buffer is written to the whole buffer and
// presented with a single swap.
TEST_F(FlSubsurfaceEGLTest, PresentMatchingBuffer) {
  g_autoptr(FlSubsurfaceEGL) egl = CreateEGL();
  ASSERT_NE(egl, nullptr);

  EXPECT_CALL(epoxy, glBlitFramebuffer(0, 0, kBufferWidth, kBufferHeight, 0, 0,
                                       kBufferWidth, kBufferHeight,
                                       ::testing::_, ::testing::_));
  EXPECT_CALL(epoxy, eglSwapBuffers).Times(1);

  fl_subsurface_egl_present(egl, 1, kBufferWidth, kBufferHeight, nullptr);
}

// The buffer a frame is drawn into is acquired when the previous frame is
// swapped, so a resize doesn't reach it. A frame of a new size swaps the stale
// buffer away unused so the frame is drawn into one of the right size, which
// is the only chance a window that is sized to its content gets.
TEST_F(FlSubsurfaceEGLTest, PresentDifferentSizeSwapsStaleBuffer) {
  g_autoptr(FlSubsurfaceEGL) egl = CreateEGL();
  ASSERT_NE(egl, nullptr);

  EXPECT_CALL(epoxy, eglSwapBuffers).Times(2);

  fl_subsurface_egl_present(egl, 1, kBufferWidth + 50, kBufferHeight + 50,
                            nullptr);
}

// The whole frame is still written, rather than being aligned against the size
// of the buffer that was swapped away.
TEST_F(FlSubsurfaceEGLTest, PresentDifferentSizeWritesWholeFrame) {
  g_autoptr(FlSubsurfaceEGL) egl = CreateEGL();
  ASSERT_NE(egl, nullptr);

  EXPECT_CALL(epoxy,
              glBlitFramebuffer(0, 0, kBufferWidth + 50, kBufferHeight + 50, 0,
                                0, kBufferWidth + 50, kBufferHeight + 50,
                                ::testing::_, ::testing::_));

  fl_subsurface_egl_present(egl, 1, kBufferWidth + 50, kBufferHeight + 50,
                            nullptr);
}

// The shader path writes the whole frame in the same way.
TEST_F(FlSubsurfaceEGLTest, PresentDifferentSizeWithoutBlit) {
  EXPECT_CALL(epoxy, epoxy_gl_version).WillRepeatedly(::testing::Return(20));
  EXPECT_CALL(epoxy, epoxy_has_gl_extension(::testing::_))
      .WillRepeatedly(::testing::Return(false));

  g_autoptr(FlSubsurfaceEGL) egl = CreateEGL();
  ASSERT_NE(egl, nullptr);

  EXPECT_CALL(epoxy, glViewport(0, 0, kBufferWidth + 50, kBufferHeight + 50));

  fl_subsurface_egl_present(egl, 1, kBufferWidth + 50, kBufferHeight + 50,
                            nullptr);
}

// A resize from the window leaves the buffer stale in the same way, so the
// next frame swaps it away before drawing.
TEST_F(FlSubsurfaceEGLTest, PresentAfterResizeSwapsStaleBuffer) {
  g_autoptr(FlSubsurfaceEGL) egl = CreateEGL();
  ASSERT_NE(egl, nullptr);

  fl_subsurface_egl_resize(egl, kBufferWidth + 50, kBufferHeight + 50);

  EXPECT_CALL(wayland, EGLWindowResize).Times(0);
  EXPECT_CALL(epoxy, eglSwapBuffers).Times(2);

  fl_subsurface_egl_present(egl, 1, kBufferWidth + 50, kBufferHeight + 50,
                            nullptr);
}

// Once the buffer has caught up with the frame size, frames are presented with
// a single swap again.
TEST_F(FlSubsurfaceEGLTest, PresentSecondFrameOfNewSize) {
  g_autoptr(FlSubsurfaceEGL) egl = CreateEGL();
  ASSERT_NE(egl, nullptr);

  fl_subsurface_egl_present(egl, 1, kBufferWidth + 50, kBufferHeight + 50,
                            nullptr);

  EXPECT_CALL(epoxy, eglSwapBuffers).Times(1);

  fl_subsurface_egl_present(egl, 1, kBufferWidth + 50, kBufferHeight + 50,
                            nullptr);
}

// Wayland requires buffer sizes to be an integer multiple of the buffer scale,
// so a frame that isn't a whole number of logical pixels, which a view that
// hasn't been allocated yet can produce, is rounded up.
TEST_F(FlSubsurfaceEGLTest, PresentRoundsUpToBufferScale) {
  g_autoptr(FlSubsurfaceEGL) egl = CreateEGL();
  ASSERT_NE(egl, nullptr);

  EXPECT_CALL(wayland, EGLWindowResize(kScale, kScale));

  fl_subsurface_egl_present(egl, 1, 1, 1, nullptr);
}

// A rounded up frame doesn't fill the buffer, and OpenGL puts the origin at the
// bottom left while Wayland puts it at the top left, so the frame is written at
// the top of the buffer rather than at the OpenGL origin.
TEST_F(FlSubsurfaceEGLTest, PresentRoundedFrameWritesAtTopOfBuffer) {
  g_autoptr(FlSubsurfaceEGL) egl = CreateEGL();
  ASSERT_NE(egl, nullptr);

  EXPECT_CALL(epoxy, glBlitFramebuffer(0, 0, 1, 1, 0, kScale - 1, 1, kScale,
                                       ::testing::_, ::testing::_));

  fl_subsurface_egl_present(egl, 1, 1, 1, nullptr);
}

// A resize from the window is rounded up in the same way.
TEST_F(FlSubsurfaceEGLTest, ResizeRoundsUpToBufferScale) {
  g_autoptr(FlSubsurfaceEGL) egl = CreateEGL();
  ASSERT_NE(egl, nullptr);

  EXPECT_CALL(wayland, EGLWindowResize(kScale, kScale));

  fl_subsurface_egl_resize(egl, 1, 1);
}

// The native window is released with the object.
TEST_F(FlSubsurfaceEGLTest, Destroy) {
  FlSubsurfaceEGL* egl = CreateEGL();
  ASSERT_NE(egl, nullptr);

  EXPECT_CALL(wayland, EGLWindowDestroy());

  g_object_unref(egl);
}
