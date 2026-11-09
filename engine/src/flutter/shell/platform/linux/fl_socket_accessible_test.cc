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
  EXPECT_TRUE(ATK_IS_SOCKET(socket));
  EXPECT_EQ(atk_object_get_parent(socket), accessible);

  g_object_unref(view);
}
