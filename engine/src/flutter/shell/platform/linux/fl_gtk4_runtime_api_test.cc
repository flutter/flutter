// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_gtk4_runtime_api.h"

#include <sys/mman.h>
#include <unistd.h>

#include <cstring>

#include "flutter/testing/testing.h"

namespace {

bool GtkRuntimeAtLeast(int major, int minor, int micro) {
  return gtk_check_version(major, minor, micro) == nullptr;
}

gboolean SetCaret(GtkAccessible*, unsigned int) {
  return TRUE;
}

gboolean SetSelection(GtkAccessible*, gsize, FlGtkAccessibleTextRange4_14*) {
  return TRUE;
}

TEST(FlGtk4RuntimeApiTest, EditingCallbacksOnlyWriteTheSupportedTail) {
  struct GuardedInterface {
    guint64 before = 0x11223344;
    FlGtkAccessibleTextInterface4_22 iface = {};
    guint64 after = 0x55667788;
  } guarded;
  guarded.iface.base.g_iface.g_type = 123;
  unsigned char original[sizeof(guarded)];
  memcpy(original, &guarded, sizeof(guarded));
  const bool supported = GtkRuntimeAtLeast(4, 22, 0);
  EXPECT_EQ(fl_gtk_runtime_accessible_text_install_editing_callbacks(
                &guarded.iface.base, SetCaret, SetSelection),
            supported);
  if (supported) {
    EXPECT_EQ(guarded.iface.set_caret_position, SetCaret);
    EXPECT_EQ(guarded.iface.set_selection, SetSelection);
    EXPECT_EQ(guarded.before, 0x11223344u);
    EXPECT_EQ(guarded.after, 0x55667788u);
    EXPECT_EQ(memcmp(&guarded.iface.base,
                     original + offsetof(GuardedInterface, iface),
                     sizeof(guarded.iface.base)),
              0);
  } else {
    EXPECT_EQ(memcmp(&guarded, original, sizeof(guarded)), 0);
  }
}

TEST(FlGtk4RuntimeApiTest,
     EditingCallbacksRejectIncompleteArgumentsWithoutWrites) {
  FlGtkAccessibleTextInterface4_22 iface = {};
  iface.set_caret_position = SetCaret;
  iface.set_selection = SetSelection;
  unsigned char original[sizeof(iface)];
  memcpy(original, &iface, sizeof(iface));
  EXPECT_FALSE(fl_gtk_runtime_accessible_text_install_editing_callbacks(
      nullptr, SetCaret, SetSelection));
  EXPECT_FALSE(fl_gtk_runtime_accessible_text_install_editing_callbacks(
      &iface.base, nullptr, SetSelection));
  EXPECT_FALSE(fl_gtk_runtime_accessible_text_install_editing_callbacks(
      &iface.base, SetCaret, nullptr));
  EXPECT_EQ(memcmp(&iface, original, sizeof(iface)), 0);
}

TEST(FlGtk4RuntimeApiTest, OlderRuntimeDoesNotAccessBeyondTextInterface) {
  if (GtkRuntimeAtLeast(4, 22, 0)) {
    GTEST_SKIP() << "Run with an older GTK runtime to exercise tail protection";
  }
  const long page_size = sysconf(_SC_PAGESIZE);
  ASSERT_GT(page_size, 0);
  void* memory = mmap(nullptr, page_size * 2, PROT_READ | PROT_WRITE,
                      MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
  ASSERT_NE(memory, MAP_FAILED);
  auto* boundary = static_cast<unsigned char*>(memory) + page_size;
  ASSERT_EQ(mprotect(boundary, page_size, PROT_NONE), 0);
  // A real old-size interface ends exactly where the inaccessible page begins.
  const size_t old_size =
      GtkRuntimeAtLeast(4, 16, 0)
          ? sizeof(FlGtkAccessibleTextInterface4_14)
          : offsetof(FlGtkAccessibleTextInterface4_14, get_extents);
  auto* iface =
      reinterpret_cast<FlGtkAccessibleTextInterface4_14*>(boundary - old_size);
  EXPECT_FALSE(fl_gtk_runtime_accessible_text_install_editing_callbacks(
      iface, SetCaret, SetSelection));
  EXPECT_EQ(munmap(memory, page_size * 2), 0);
}

TEST(FlGtk4RuntimeApiTest, CapabilitiesMatchLoadedGtk) {
  const FlGtkRuntimeApi* api = fl_gtk_runtime_api_get();

  EXPECT_EQ(api->gtk_at_least_4_10, GtkRuntimeAtLeast(4, 10, 0));
  EXPECT_EQ(api->gtk_at_least_4_14, GtkRuntimeAtLeast(4, 14, 0));
  EXPECT_EQ(api->gtk_at_least_4_18, GtkRuntimeAtLeast(4, 18, 0));
  EXPECT_EQ(api->gtk_accessible_update_platform_state != nullptr,
            GtkRuntimeAtLeast(4, 18, 0));
  EXPECT_EQ(api->gtk_accessible_set_accessible_parent != nullptr,
            GtkRuntimeAtLeast(4, 10, 0));
  EXPECT_EQ(api->gtk_accessible_get_first_accessible_child != nullptr,
            GtkRuntimeAtLeast(4, 10, 0));
  EXPECT_EQ(api->gtk_accessible_announce != nullptr,
            GtkRuntimeAtLeast(4, 14, 0));
  EXPECT_EQ(api->gtk_accessible_text_get_type != nullptr,
            GtkRuntimeAtLeast(4, 14, 0));
  EXPECT_EQ(api->gtk_accessible_text_update_caret_position != nullptr,
            GtkRuntimeAtLeast(4, 14, 0));
  EXPECT_EQ(api->gtk_accessible_text_update_selection_bound != nullptr,
            GtkRuntimeAtLeast(4, 14, 0));
  EXPECT_EQ(api->gtk_accessible_text_update_contents != nullptr,
            GtkRuntimeAtLeast(4, 14, 0));
  EXPECT_EQ(fl_gtk_runtime_supports_native_accessibility_tree(),
            GtkRuntimeAtLeast(4, 10, 0));
  EXPECT_EQ(fl_gtk_runtime_supports_native_accessibility_text(),
            GtkRuntimeAtLeast(4, 14, 0));
  EXPECT_EQ(fl_gtk_runtime_supports_dmabuf_textures(),
            GtkRuntimeAtLeast(4, 14, 0));

  const bool supports_dmabuf = GtkRuntimeAtLeast(4, 14, 0);
  EXPECT_EQ(api->gdk_display_get_dmabuf_formats != nullptr, supports_dmabuf);
  EXPECT_EQ(api->gdk_dmabuf_formats_contains != nullptr, supports_dmabuf);
  EXPECT_EQ(api->gdk_dmabuf_texture_builder_new != nullptr, supports_dmabuf);
  EXPECT_EQ(api->gdk_dmabuf_texture_builder_build != nullptr, supports_dmabuf);
}

TEST(FlGtk4RuntimeApiTest, MissingOptionalFunctionsUseNoOpFallback) {
  const FlGtkRuntimeApi* api = fl_gtk_runtime_api_get();

  if (api->gtk_accessible_update_platform_state == nullptr) {
    fl_gtk_runtime_accessible_update_platform_state(
        nullptr, FL_GTK_ACCESSIBLE_PLATFORM_STATE_FOCUSED);
  }

  if (api->gtk_accessible_set_accessible_parent == nullptr) {
    fl_gtk_runtime_accessible_set_accessible_parent(nullptr, nullptr, nullptr);
  }
  if (api->gtk_accessible_get_first_accessible_child == nullptr) {
    EXPECT_EQ(fl_gtk_runtime_accessible_get_first_accessible_child(nullptr),
              nullptr);
  }
  if (api->gtk_accessible_announce == nullptr) {
    fl_gtk_runtime_accessible_announce(nullptr, "test announcement", 0);
  }
  if (!fl_gtk_runtime_supports_native_accessibility_text()) {
    EXPECT_EQ(fl_gtk_runtime_accessible_text_get_type(), G_TYPE_INVALID);
    fl_gtk_runtime_accessible_text_update_caret_position(nullptr);
    fl_gtk_runtime_accessible_text_update_selection_bound(nullptr);
    fl_gtk_runtime_accessible_text_update_contents(nullptr, 0, 0, 0);
  }
}

}  // namespace
