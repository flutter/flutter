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

  EXPECT_CALL(wayland, EGLWindowResize(kWidth, kHeight));

  fl_subsurface_egl_present(egl, 1, kWidth, kHeight, nullptr);
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

// A frame that fills the surface is written to the whole surface.
TEST_F(FlSubsurfaceEGLTest, PresentMatchingSurface) {
  epoxy.egl_surface_width = kWidth;
  epoxy.egl_surface_height = kHeight;

  g_autoptr(FlSubsurfaceEGL) egl = CreateEGL();
  ASSERT_NE(egl, nullptr);

  EXPECT_CALL(epoxy, glBlitFramebuffer(0, 0, kWidth, kHeight, 0, 0, kWidth,
                                       kHeight, ::testing::_, ::testing::_));

  fl_subsurface_egl_present(egl, 1, kWidth, kHeight, nullptr);
}

// OpenGL puts the origin at the bottom left of the surface but Wayland puts it
// at the top left, so a frame that doesn't fill a taller surface has to be
// moved up to stay where the window expects it. Writing it at the OpenGL
// origin would leave it below where it belongs.
TEST_F(FlSubsurfaceEGLTest, PresentTallerSurface) {
  epoxy.egl_surface_width = kWidth;
  epoxy.egl_surface_height = kHeight + 50;

  g_autoptr(FlSubsurfaceEGL) egl = CreateEGL();
  ASSERT_NE(egl, nullptr);

  EXPECT_CALL(epoxy,
              glBlitFramebuffer(0, 0, kWidth, kHeight, 0, 50, kWidth,
                                kHeight + 50, ::testing::_, ::testing::_));

  fl_subsurface_egl_present(egl, 1, kWidth, kHeight, nullptr);
}

// The origins only differ vertically, so a frame that doesn't fill a wider
// surface is left where it is.
TEST_F(FlSubsurfaceEGLTest, PresentWiderSurface) {
  epoxy.egl_surface_width = kWidth + 50;
  epoxy.egl_surface_height = kHeight;

  g_autoptr(FlSubsurfaceEGL) egl = CreateEGL();
  ASSERT_NE(egl, nullptr);

  EXPECT_CALL(epoxy, glBlitFramebuffer(0, 0, kWidth, kHeight, 0, 0, kWidth,
                                       kHeight, ::testing::_, ::testing::_));

  fl_subsurface_egl_present(egl, 1, kWidth, kHeight, nullptr);
}

// A frame bigger than the surface has its bottom rows dropped, as that's the
// end the window is being clipped at in Wayland's coordinates. Writing it from
// the OpenGL origin would drop the top rows instead and shift the contents up.
TEST_F(FlSubsurfaceEGLTest, PresentShorterSurface) {
  epoxy.egl_surface_width = kWidth;
  epoxy.egl_surface_height = kHeight - 50;

  g_autoptr(FlSubsurfaceEGL) egl = CreateEGL();
  ASSERT_NE(egl, nullptr);

  EXPECT_CALL(epoxy,
              glBlitFramebuffer(0, 50, kWidth, kHeight, 0, 0, kWidth,
                                kHeight - 50, ::testing::_, ::testing::_));

  fl_subsurface_egl_present(egl, 1, kWidth, kHeight, nullptr);
}

// The shader path clips the same way, using a viewport that starts off the
// bottom of the surface.
TEST_F(FlSubsurfaceEGLTest, PresentShorterSurfaceWithoutBlit) {
  EXPECT_CALL(epoxy, epoxy_gl_version).WillRepeatedly(::testing::Return(20));
  EXPECT_CALL(epoxy, epoxy_has_gl_extension(::testing::_))
      .WillRepeatedly(::testing::Return(false));
  epoxy.egl_surface_width = kWidth;
  epoxy.egl_surface_height = kHeight - 50;

  g_autoptr(FlSubsurfaceEGL) egl = CreateEGL();
  ASSERT_NE(egl, nullptr);

  EXPECT_CALL(epoxy, glViewport(0, -50, kWidth, kHeight));

  fl_subsurface_egl_present(egl, 1, kWidth, kHeight, nullptr);
}

// The frame is moved up the same way when it's drawn with the shader.
TEST_F(FlSubsurfaceEGLTest, PresentTallerSurfaceWithoutBlit) {
  EXPECT_CALL(epoxy, epoxy_gl_version).WillRepeatedly(::testing::Return(20));
  EXPECT_CALL(epoxy, epoxy_has_gl_extension(::testing::_))
      .WillRepeatedly(::testing::Return(false));
  epoxy.egl_surface_width = kWidth;
  epoxy.egl_surface_height = kHeight + 50;

  g_autoptr(FlSubsurfaceEGL) egl = CreateEGL();
  ASSERT_NE(egl, nullptr);

  EXPECT_CALL(epoxy, glViewport(0, 50, kWidth, kHeight));

  fl_subsurface_egl_present(egl, 1, kWidth, kHeight, nullptr);
}

// If the surface size isn't known, e.g. because it couldn't be queried, the
// frame is written from the origin rather than being aligned against a size
// that would drop all of it.
TEST_F(FlSubsurfaceEGLTest, PresentUnknownSurfaceSize) {
  epoxy.egl_surface_width = 0;
  epoxy.egl_surface_height = 0;

  g_autoptr(FlSubsurfaceEGL) egl = CreateEGL();
  ASSERT_NE(egl, nullptr);

  EXPECT_CALL(epoxy, glBlitFramebuffer(0, 0, kWidth, kHeight, 0, 0, kWidth,
                                       kHeight, ::testing::_, ::testing::_));

  fl_subsurface_egl_present(egl, 1, kWidth, kHeight, nullptr);
}

// The native window is released with the object.
TEST_F(FlSubsurfaceEGLTest, Destroy) {
  FlSubsurfaceEGL* egl = CreateEGL();
  ASSERT_NE(egl, nullptr);

  EXPECT_CALL(wayland, EGLWindowDestroy());

  g_object_unref(egl);
}
