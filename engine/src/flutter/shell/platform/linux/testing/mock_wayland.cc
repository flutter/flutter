// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/testing/mock_wayland.h"

#include <wayland-client.h>
#include <wayland-egl.h>

#include <vector>

using namespace flutter::testing;

// The fake object all Wayland proxies are made of. libwayland's struct wl_proxy
// is opaque and every entry point that could look inside it is replaced here,
// so proxies can be represented with whatever is convenient.
struct MockProxy {
  const struct wl_interface* interface;
  uint32_t version;
  void (**listener)(void);
  void* listener_data;
};

// The fake wl_egl_window; libwayland-egl is replaced in the same way as
// libwayland-client.
struct wl_egl_window {
  int width;
  int height;
};

static MockWayland* mock = nullptr;

// Registries that have been created and are waiting to be sent the globals.
static std::vector<MockProxy*>* pending_registries = nullptr;

MockWayland::MockWayland() {
  mock = this;
  pending_registries = new std::vector<MockProxy*>();
}

MockWayland::~MockWayland() {
  if (mock == this) {
    mock = nullptr;
  }
  delete pending_registries;
  pending_registries = nullptr;
}

static MockProxy* proxy_new(const struct wl_interface* interface,
                            uint32_t version) {
  MockProxy* proxy = new MockProxy();
  proxy->interface = interface;
  proxy->version = version;
  return proxy;
}

static const char* proxy_interface_name(MockProxy* proxy) {
  if (proxy == nullptr || proxy->interface == nullptr) {
    return "";
  }
  return proxy->interface->name;
}

static void proxy_free(MockProxy* proxy) {
  if (mock != nullptr) {
    mock->DestroyObject(proxy_interface_name(proxy));
  }
  delete proxy;
}

struct wl_display* flutter::testing::fl_mock_wayland_get_display() {
  static MockProxy display = {
      .interface = &wl_display_interface,
      .version = 1,
      .listener = nullptr,
      .listener_data = nullptr,
  };
  return reinterpret_cast<struct wl_display*>(&display);
}

struct wl_surface* flutter::testing::fl_mock_wayland_get_surface() {
  return reinterpret_cast<struct wl_surface*>(
      proxy_new(&wl_surface_interface, 4));
}

void flutter::testing::fl_mock_wayland_free_surface(
    struct wl_surface* surface) {
  delete reinterpret_cast<MockProxy*>(surface);
}

extern "C" {

// Creates the object a request that has a "new_id" argument returns.
static struct wl_proxy* marshal_constructor(
    struct wl_proxy* proxy,
    uint32_t opcode,
    const struct wl_interface* interface,
    uint32_t version) {
  MockProxy* mock_proxy = reinterpret_cast<MockProxy*>(proxy);

  if (mock != nullptr) {
    mock->Request(proxy_interface_name(mock_proxy), opcode);
  }

  MockProxy* new_proxy = proxy_new(interface, version);
  if (mock != nullptr) {
    mock->CreateObject(interface->name);
  }
  if (interface == &wl_registry_interface && pending_registries != nullptr) {
    pending_registries->push_back(new_proxy);
  }

  return reinterpret_cast<struct wl_proxy*>(new_proxy);
}

void wl_proxy_marshal(struct wl_proxy* proxy, uint32_t opcode, ...) {
  MockProxy* mock_proxy = reinterpret_cast<MockProxy*>(proxy);
  if (mock != nullptr) {
    mock->Request(proxy_interface_name(mock_proxy), opcode);
  }
}

struct wl_proxy* wl_proxy_marshal_constructor(
    struct wl_proxy* proxy,
    uint32_t opcode,
    const struct wl_interface* interface,
    ...) {
  return marshal_constructor(proxy, opcode, interface,
                             wl_proxy_get_version(proxy));
}

struct wl_proxy* wl_proxy_marshal_constructor_versioned(
    struct wl_proxy* proxy,
    uint32_t opcode,
    const struct wl_interface* interface,
    uint32_t version,
    ...) {
  return marshal_constructor(proxy, opcode, interface, version);
}

#ifdef WL_MARSHAL_FLAG_DESTROY
// Used by libwayland 1.19.91 and later, which route every request through this
// function instead of the ones above.
struct wl_proxy* wl_proxy_marshal_flags(struct wl_proxy* proxy,
                                        uint32_t opcode,
                                        const struct wl_interface* interface,
                                        uint32_t version,
                                        uint32_t flags,
                                        ...) {
  MockProxy* mock_proxy = reinterpret_cast<MockProxy*>(proxy);

  // Requests that create a new object have the interface of that object set.
  struct wl_proxy* new_proxy = nullptr;
  if (interface != nullptr) {
    new_proxy = marshal_constructor(proxy, opcode, interface, version);
  } else if (mock != nullptr) {
    mock->Request(proxy_interface_name(mock_proxy), opcode);
  }

  if ((flags & WL_MARSHAL_FLAG_DESTROY) != 0) {
    proxy_free(mock_proxy);
  }

  return new_proxy;
}
#endif

void wl_proxy_destroy(struct wl_proxy* proxy) {
  MockProxy* mock_proxy = reinterpret_cast<MockProxy*>(proxy);
  if (pending_registries != nullptr) {
    for (auto it = pending_registries->begin(); it != pending_registries->end();
         it++) {
      if (*it == mock_proxy) {
        pending_registries->erase(it);
        break;
      }
    }
  }
  proxy_free(mock_proxy);
}

int wl_proxy_add_listener(struct wl_proxy* proxy,
                          void (**implementation)(void),
                          void* data) {
  MockProxy* mock_proxy = reinterpret_cast<MockProxy*>(proxy);
  mock_proxy->listener = implementation;
  mock_proxy->listener_data = data;
  return 0;
}

uint32_t wl_proxy_get_version(struct wl_proxy* proxy) {
  return reinterpret_cast<MockProxy*>(proxy)->version;
}

int wl_display_roundtrip(struct wl_display* display) {
  if (pending_registries == nullptr) {
    return 0;
  }

  // Send the globals to any registry that has been created since the last
  // roundtrip, as a real compositor does when a registry is bound.
  std::vector<MockProxy*> registries;
  registries.swap(*pending_registries);
  for (MockProxy* registry : registries) {
    if (registry->listener == nullptr) {
      continue;
    }
    const struct wl_registry_listener* listener =
        reinterpret_cast<const struct wl_registry_listener*>(
            registry->listener);
    struct wl_registry* registry_proxy =
        reinterpret_cast<struct wl_registry*>(registry);
    uint32_t name = 1;
    if (mock == nullptr || mock->has_compositor) {
      listener->global(registry->listener_data, registry_proxy, name++,
                       wl_compositor_interface.name, 4);
    }
    if (mock == nullptr || mock->has_subcompositor) {
      listener->global(registry->listener_data, registry_proxy, name++,
                       wl_subcompositor_interface.name, 1);
    }
  }

  return 0;
}

struct wl_egl_window* wl_egl_window_create(struct wl_surface* surface,
                                           int width,
                                           int height) {
  if (mock != nullptr) {
    mock->EGLWindowCreate(width, height);
    if (mock->egl_window_create_fails) {
      return nullptr;
    }
  }

  struct wl_egl_window* window = new wl_egl_window();
  window->width = width;
  window->height = height;
  return window;
}

void wl_egl_window_destroy(struct wl_egl_window* window) {
  if (mock != nullptr) {
    mock->EGLWindowDestroy();
  }
  delete window;
}

void wl_egl_window_resize(struct wl_egl_window* window,
                          int width,
                          int height,
                          int dx,
                          int dy) {
  if (mock != nullptr) {
    mock->EGLWindowResize(width, height);
  }
  window->width = width;
  window->height = height;
}

void wl_egl_window_get_attached_size(struct wl_egl_window* window,
                                     int* width,
                                     int* height) {
  if (width != nullptr) {
    *width = window->width;
  }
  if (height != nullptr) {
    *height = window->height;
  }
}
}
