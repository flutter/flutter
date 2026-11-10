// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_socket_accessible.h"

#include "flutter/shell/platform/linux/public/flutter_linux/fl_view.h"
#include "flutter/shell/platform/linux/testing/fl_test_gtk_logs.h"

#include "flutter/shell/platform/linux/testing/linux_test.h"
#include "gtest/gtest.h"

class FlSocketAccessibleTest : public flutter::testing::LinuxTest {};

TEST_F(FlSocketAccessibleTest, SocketParent) {
  flutter::testing::fl_ensure_gtk_init();
  FlView* view = fl_view_new(project);
  g_object_ref_sink(view);

  AtkObject* accessible = gtk_widget_get_accessible(GTK_WIDGET(view));
  ASSERT_TRUE(FL_IS_SOCKET_ACCESSIBLE(accessible));
  ASSERT_EQ(atk_object_get_n_accessible_children(accessible), 1);
  g_autoptr(AtkObject) socket = atk_object_ref_accessible_child(accessible, 0);
  ASSERT_TRUE(ATK_IS_SOCKET(socket));
  EXPECT_EQ(atk_object_get_parent(socket), accessible);

  g_object_unref(view);
}

TEST_F(FlSocketAccessibleTest, SocketState) {
  flutter::testing::fl_ensure_gtk_init();
  FlView* view = fl_view_new(project);
  g_object_ref_sink(view);

  AtkObject* accessible = gtk_widget_get_accessible(GTK_WIDGET(view));
  g_autoptr(AtkObject) socket = atk_object_ref_accessible_child(accessible, 0);
  g_autoptr(AtkStateSet) hidden_states = atk_object_ref_state_set(socket);
  EXPECT_FALSE(atk_state_set_contains_state(hidden_states, ATK_STATE_VISIBLE));

  gtk_widget_set_visible(GTK_WIDGET(view), TRUE);
  g_autoptr(AtkStateSet) visible_states = atk_object_ref_state_set(socket);
  EXPECT_TRUE(atk_state_set_contains_state(visible_states, ATK_STATE_VISIBLE));

  g_object_unref(view);
}

TEST_F(FlSocketAccessibleTest, Embed) {
  flutter::testing::fl_ensure_gtk_init();
  FlView* view = fl_view_new(project);
  g_object_ref_sink(view);

  // Simulate at-spi2-atk embedding.
  AtkSocketClass* atk_socket_class =
      ATK_SOCKET_CLASS(g_type_class_ref(ATK_TYPE_SOCKET));
  auto saved_embed = atk_socket_class->embed;
  atk_socket_class->embed = [](AtkSocket* socket, const gchar* plug_id) {
    ATK_OBJECT_GET_CLASS(socket)->ref_state_set = [](AtkObject* object) {
      return atk_state_set_new();
    };
  };
  AtkPlugClass* atk_plug_class =
      ATK_PLUG_CLASS(g_type_class_ref(ATK_TYPE_PLUG));
  auto saved_get_object_id = atk_plug_class->get_object_id;
  atk_plug_class->get_object_id = [](AtkPlug* plug) {
    return g_strdup(":1.0:/org/a11y/atspi/accessible/1");
  };

  AtkObject* accessible = gtk_widget_get_accessible(GTK_WIDGET(view));
  g_autoptr(AtkObject) socket = atk_object_ref_accessible_child(accessible, 0);
  AtkObjectClass* socket_class = ATK_OBJECT_GET_CLASS(socket);
  auto ref_state_set = socket_class->ref_state_set;
  g_autoptr(AtkObject) plug = atk_plug_new();
  fl_socket_accessible_embed(FL_SOCKET_ACCESSIBLE(accessible), ATK_PLUG(plug));
  EXPECT_EQ(socket_class->ref_state_set, ref_state_set);
  EXPECT_EQ(atk_object_get_parent(plug), socket);

  socket_class->ref_state_set = ref_state_set;
  atk_plug_class->get_object_id = saved_get_object_id;
  g_type_class_unref(atk_plug_class);
  atk_socket_class->embed = saved_embed;
  g_type_class_unref(atk_socket_class);
  g_object_unref(view);
}
