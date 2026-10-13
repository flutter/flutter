// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <stdio.h>
#include <string.h>
#include <wayland-client.h>
#include "virtual-pointer.h"
static struct zwlr_virtual_pointer_manager_v1* manager;
static void global(void* data,
                   struct wl_registry* registry,
                   uint32_t name,
                   const char* interface,
                   uint32_t version) {
  if (!strcmp(interface, "zwlr_virtual_pointer_manager_v1"))
    manager = wl_registry_bind(registry, name,
                               &zwlr_virtual_pointer_manager_v1_interface, 1);
}
static void removed(void* data, struct wl_registry* registry, uint32_t name) {}
int main(void) {
  struct wl_display* display = wl_display_connect(NULL);
  if (!display)
    return 1;
  struct wl_registry* registry = wl_display_get_registry(display);
  struct wl_registry_listener listener = {global, removed};
  wl_registry_add_listener(registry, &listener, NULL);
  wl_display_roundtrip(display);
  if (!manager)
    return 2;
  struct zwlr_virtual_pointer_v1* pointer =
      zwlr_virtual_pointer_manager_v1_create_virtual_pointer(manager, NULL);
  wl_display_roundtrip(display);
  puts("READY");
  fflush(stdout);
  unsigned time = 1000;
  char command[32];
  while (scanf("%31s", command) == 1) {
    if (!strcmp(command, "click")) {
      unsigned x, y, w, h;
      if (scanf("%u %u %u %u", &x, &y, &w, &h) != 4)
        return 3;
      zwlr_virtual_pointer_v1_motion_absolute(pointer, time++, x, y, w, h);
      zwlr_virtual_pointer_v1_frame(pointer);
      wl_display_roundtrip(display);
      zwlr_virtual_pointer_v1_button(pointer, time++, 272, 1);
      zwlr_virtual_pointer_v1_frame(pointer);
      zwlr_virtual_pointer_v1_button(pointer, time++, 272, 0);
      zwlr_virtual_pointer_v1_frame(pointer);
    } else if (!strcmp(command, "scroll")) {
      zwlr_virtual_pointer_v1_axis_source(pointer,
                                          WL_POINTER_AXIS_SOURCE_WHEEL);
      zwlr_virtual_pointer_v1_axis_discrete(pointer, time++,
                                            WL_POINTER_AXIS_VERTICAL_SCROLL,
                                            wl_fixed_from_int(15), 1);
      zwlr_virtual_pointer_v1_frame(pointer);
    }
    wl_display_roundtrip(display);
  }
  zwlr_virtual_pointer_v1_destroy(pointer);
  wl_display_flush(display);
  wl_display_disconnect(display);
  return 0;
}
