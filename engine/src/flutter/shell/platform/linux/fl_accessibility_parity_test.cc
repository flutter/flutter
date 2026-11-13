// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Included first as it collides with the X11 headers.
#include "flutter/shell/platform/linux/testing/linux_test.h"

#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_view_private.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_standard_message_codec.h"
#include "gtest/gtest.h"

#if FLUTTER_LINUX_GTK4
#include "flutter/shell/platform/linux/fl_gtk4_runtime_api.h"  // nogncheck
#else
#include "flutter/shell/platform/linux/fl_socket_accessible.h"  // nogncheck

// Host the production ATK plug/socket tree without starting a GL renderer.
struct ParitySurface {
  GtkBox parent_instance;
};
struct ParitySurfaceClass {
  GtkBoxClass parent_class;
};
G_DEFINE_TYPE(ParitySurface, parity_surface, GTK_TYPE_BOX)

static void parity_surface_class_init(ParitySurfaceClass* klass) {
  gtk_widget_class_set_accessible_type(GTK_WIDGET_CLASS(klass),
                                       fl_socket_accessible_get_type());
}
static void parity_surface_init(ParitySurface*) {}
#endif

namespace {

class FlAccessibilityParityTest : public flutter::testing::LinuxTest {};

TEST_F(FlAccessibilityParityTest, ExternalAtspiParity) {
  if (g_strcmp0(g_getenv("FLUTTER_TEST_ATSPI_PARITY"), "1") != 0) {
    GTEST_SKIP() << "Requires the external AT-SPI parity client";
  }
#if FLUTTER_LINUX_GTK4
  ASSERT_TRUE(fl_view_gtk4_accessibility_native_tree_is_enabled_for_testing());
#endif
  g_autoptr(FlView) view = fl_view_new(project);
  g_object_ref_sink(view);
  FlEngine* view_engine = fl_view_get_engine(view);
  StartEngine(view_engine);
  g_print("PARITY_RUNTIME {\"gtk\":\"%u.%u.%u\",\"glib\":\"%u.%u.%u\"}\n",
          gtk_get_major_version(), gtk_get_minor_version(),
          gtk_get_micro_version(), glib_major_version, glib_minor_version,
          glib_micro_version);
  FlutterSemanticsFlags flags[11] = {};
  FlutterSemanticsNode2 semantics[11] = {};
  FlutterSemanticsNode2* nodes[11] = {};
  const char* names[] = {"Parity root",   "Activate",     "Checked",
                         "Editor",        "Password",     "Slider",
                         "Scroll region", "Nested group", "Finish comparison",
                         "Unicode",       "Toggle"};
  for (size_t i = 0; i < G_N_ELEMENTS(semantics); i++) {
    flags[i].is_enabled = kFlutterTristateTrue;
    semantics[i].id = i;
    semantics[i].label = names[i];
    semantics[i].flags2 = &flags[i];
    semantics[i].rect = {10, static_cast<double>(i * 20), 110,
                         static_cast<double>(i * 20 + 20)};
    nodes[i] = &semantics[i];
  }
  int32_t children[] = {1, 2, 3, 4, 5, 6, 7, 10};
  int32_t nested_children[] = {8, 9};
  semantics[0].child_count = G_N_ELEMENTS(children);
  semantics[0].children_in_traversal_order = children;
  semantics[7].child_count = G_N_ELEMENTS(nested_children);
  semantics[7].children_in_traversal_order = nested_children;
  flags[1].is_button = flags[8].is_button = true;
  semantics[1].actions = semantics[2].actions = semantics[8].actions =
      kFlutterSemanticsActionTap;
  flags[2].is_checked = kFlutterCheckStateTrue;
  flags[10].is_toggled = kFlutterTristateTrue;
  semantics[10].actions = kFlutterSemanticsActionTap;
  flags[3].is_text_field = flags[4].is_text_field = flags[9].is_text_field =
      true;
  flags[4].is_obscured = true;
  semantics[3].value = "Hello world";
  semantics[3].actions = static_cast<FlutterSemanticsAction>(
      kFlutterSemanticsActionCopy | kFlutterSemanticsActionCut |
      kFlutterSemanticsActionPaste);
  semantics[3].text_selection_base = 2;
  semantics[3].text_selection_extent = 5;
  semantics[4].value = "fixture-private-value";
  // Deliberately inconsistent embedder input exercises adapter-side defense.
  semantics[4].actions = semantics[3].actions;
  semantics[4].hint = "Enter your password";
  semantics[4].tooltip = "Protected input";
  semantics[9].value = "A\xF0\x9F\x98\x80 caf\xC3\xA9";
  semantics[9].text_selection_base = 1;
  semantics[9].text_selection_extent = 3;
  semantics[9].actions = static_cast<FlutterSemanticsAction>(
      semantics[3].actions | kFlutterSemanticsActionSetSelection);
  flags[5].is_slider = true;
  semantics[5].value = "50%";
  semantics[5].actions = static_cast<FlutterSemanticsAction>(
      kFlutterSemanticsActionIncrease | kFlutterSemanticsActionDecrease);
  semantics[6].actions = kFlutterSemanticsActionScrollDown;
  FlutterSemanticsUpdate2 update = {};
  update.view_id = fl_view_get_id(view);
  update.node_count = G_N_ELEMENTS(nodes);
  update.nodes = nodes;

#if FLUTTER_LINUX_GTK4
  const auto apply_update = [&](const FlutterSemanticsUpdate2* batch) {
    fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                             batch);
  };
  g_autoptr(GtkWidget) surface = GTK_WIDGET(g_object_ref(view->render_area));
  g_signal_handlers_disconnect_by_data(surface, view);
  gtk_box_remove(GTK_BOX(view), surface);
  g_autoptr(GtkWindow) window = GTK_WINDOW(gtk_window_new());
  g_object_ref_sink(window);
  gtk_window_set_child(window, surface);
#else
  g_autoptr(FlViewAccessible) accessible =
      fl_view_accessible_new(view_engine, update.view_id);
  const auto apply_update = [&](const FlutterSemanticsUpdate2* batch) {
    fl_view_accessible_handle_update_semantics(accessible, batch);
  };
  g_autoptr(GtkWidget) surface =
      GTK_WIDGET(g_object_new(parity_surface_get_type(), nullptr));
  g_object_ref_sink(surface);
  g_autofree gchar* plug_id = atk_plug_get_id(ATK_PLUG(accessible));
  ASSERT_NE(plug_id, nullptr);
  fl_socket_accessible_embed(
      FL_SOCKET_ACCESSIBLE(gtk_widget_get_accessible(surface)), plug_id);
  g_autoptr(GtkWidget) window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  g_object_ref_sink(window);
  gtk_container_add(GTK_CONTAINER(window), surface);
#endif
  size_t button_calls = 0;
  size_t slider_calls = 0;
  size_t scroll_calls = 0;
  size_t finish_calls = 0;
  size_t protected_selection_calls = 0;
  fl_engine_get_embedder_api(view_engine)->SendSemanticsAction =
      MOCK_ENGINE_PROC(
          SendSemanticsAction,
          ([&](auto, const FlutterSendSemanticsActionInfo* info) {
            EXPECT_EQ(info->view_id, update.view_id);
            EXPECT_EQ(info->data_length == 0u, info->node_id != 9);
            FlutterSemanticsNode2* changed = nullptr;
            switch (info->node_id) {
              case 1:
                EXPECT_EQ(info->action, kFlutterSemanticsActionTap);
                button_calls++;
                flags[2].is_checked = kFlutterCheckStateFalse;
                changed = &semantics[2];
                break;
              case 5:
                EXPECT_EQ(info->action, kFlutterSemanticsActionIncrease);
                slider_calls++;
                semantics[5].value = "51%";
                changed = &semantics[5];
                // Protect an existing Text object without changing its role.
                flags[3].is_obscured = true;
                flags[9].is_obscured = true;
                {
                  FlutterSemanticsNode2* protected_nodes[] = {&semantics[3],
                                                              &semantics[9]};
                  FlutterSemanticsUpdate2 partial = {};
                  partial.view_id = update.view_id;
                  partial.node_count = G_N_ELEMENTS(protected_nodes);
                  partial.nodes = protected_nodes;
                  apply_update(&partial);
                }
                break;
              case 6:
                EXPECT_EQ(info->action, kFlutterSemanticsActionScrollDown);
                scroll_calls++;
                flags[3].is_obscured = false;
                flags[9].is_obscured = false;
                {
                  FlutterSemanticsNode2* unicode = &semantics[9];
                  FlutterSemanticsUpdate2 partial = {};
                  partial.view_id = update.view_id;
                  partial.node_count = 1;
                  partial.nodes = &unicode;
                  apply_update(&partial);
                }
                changed = &semantics[3];
                break;
              case 9: {
                EXPECT_TRUE(flags[9].is_obscured);
                EXPECT_EQ(info->action, kFlutterSemanticsActionSetSelection);
                g_autoptr(GBytes) bytes =
                    g_bytes_new(info->data, info->data_length);
                g_autoptr(FlStandardMessageCodec) codec =
                    fl_standard_message_codec_new();
                g_autoptr(FlValue) selection = fl_message_codec_decode_message(
                    FL_MESSAGE_CODEC(codec), bytes, nullptr);
                EXPECT_NE(selection, nullptr);
                if (selection != nullptr) {
                  EXPECT_EQ(fl_value_get_int(
                                fl_value_lookup_string(selection, "base")),
                            1);
                  EXPECT_EQ(fl_value_get_int(
                                fl_value_lookup_string(selection, "extent")),
                            3);
                }
                protected_selection_calls++;
                break;
              }
              case 8:
                EXPECT_EQ(info->action, kFlutterSemanticsActionTap);
                finish_calls++;
                g_main_loop_quit(loop);
                break;
              default:
                ADD_FAILURE()
                    << "Unexpected parity action node " << info->node_id;
            }
            if (changed != nullptr) {
              FlutterSemanticsUpdate2 partial = {};
              partial.view_id = update.view_id;
              partial.node_count = 1;
              partial.nodes = &changed;
              apply_update(&partial);
            }
            return kSuccess;
          }));
  apply_update(&update);
  gtk_window_set_default_size(GTK_WINDOW(window), 400, 300);
#if !FLUTTER_LINUX_GTK4
  gtk_widget_show_all(window);
#endif
  gtk_window_present(GTK_WINDOW(window));
  const guint timeout = g_timeout_add_seconds(
      15,
      [](gpointer data) -> gboolean {
        g_main_loop_quit(static_cast<GMainLoop*>(data));
        return G_SOURCE_CONTINUE;
      },
      loop);
  g_main_loop_run(loop);
  g_source_remove(timeout);
  EXPECT_EQ(button_calls, 1u);
  EXPECT_EQ(slider_calls, 1u);
  EXPECT_EQ(scroll_calls, 1u);
  EXPECT_EQ(finish_calls, 1u);
#if FLUTTER_LINUX_GTK4
  EXPECT_EQ(protected_selection_calls,
            gtk_check_version(4, 22, 0) == nullptr ? 1u : 0u);
#else
  EXPECT_EQ(protected_selection_calls, 0u);
#endif
#if FLUTTER_LINUX_GTK4
  gtk_window_set_child(window, nullptr);
  gtk_box_append(GTK_BOX(view), surface);
  gtk_window_destroy(window);
#else
  gtk_widget_destroy(window);
#endif
}

}  // namespace
