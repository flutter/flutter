// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_TESTING_MOCK_WAYLAND_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_TESTING_MOCK_WAYLAND_H_

#include <cstdint>

#include "gmock/gmock.h"

struct wl_display;
struct wl_surface;

namespace flutter {
namespace testing {

// Replaces libwayland-client and libwayland-egl with an in-process
// implementation, so Wayland objects can be created without a compositor.
//
// The Wayland protocol requests used by Flutter are all inline functions
// calling wl_proxy_marshal_flags(), so intercepting the small number of
// libwayland entry points below is enough to fake the whole protocol.
class MockWayland {
 public:
  MockWayland();
  ~MockWayland();

  // Called when a proxy is created, i.e. a request that creates a new object
  // is made. [interface] is the name of the interface being created.
  MOCK_METHOD(void, CreateObject, (const char* interface));

  // Called when a proxy is destroyed.
  MOCK_METHOD(void, DestroyObject, (const char* interface));

  // Called when a request is made. [interface] is the interface the request is
  // made on and [opcode] the request being made.
  MOCK_METHOD(void, Request, (const char* interface, uint32_t opcode));

  // Called when a wl_egl_window is created, resized or destroyed.
  MOCK_METHOD(void, EGLWindowCreate, (int width, int height));
  MOCK_METHOD(void, EGLWindowResize, (int width, int height));
  MOCK_METHOD(void, EGLWindowDestroy, ());

  // Set to FALSE to make the compositor not advertise wl_compositor or
  // wl_subcompositor in the registry.
  bool has_compositor = true;
  bool has_subcompositor = true;

  // Set to true to make wl_egl_window_create() fail.
  bool egl_window_create_fails = false;
};

// Gets a fake Wayland display that can be passed to code being tested.
struct wl_display* fl_mock_wayland_get_display();

// Gets a fake Wayland surface that can be used as a parent surface.
struct wl_surface* fl_mock_wayland_get_surface();

// Releases a surface returned by fl_mock_wayland_get_surface().
void fl_mock_wayland_free_surface(struct wl_surface* surface);

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_TESTING_MOCK_WAYLAND_H_
