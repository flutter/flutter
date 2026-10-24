// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/public/flutter_linux/fl_view.h"

#include <gdk/gdkwayland.h>

#include <cstring>
#include <memory>
#include <vector>

#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_renderable.h"
#include "flutter/shell/platform/linux/fl_text_input_handler.h"
#include "flutter/shell/platform/linux/fl_view_private.h"
#include "flutter/shell/platform/linux/testing/fl_test.h"
#include "flutter/shell/platform/linux/testing/fl_test_gtk_logs.h"
#include "flutter/shell/platform/linux/testing/mock_gtk.h"

#include "flutter/shell/platform/linux/testing/linux_test.h"
#include "gtest/gtest.h"

// FIXME(robert-ancell): Disabled, see below.
#if 0
static void first_frame_cb(FlView* view, gboolean* first_frame_emitted) {
  *first_frame_emitted = TRUE;
}
#endif

class FlViewTest : public flutter::testing::LinuxTest {};

TEST_F(FlViewTest, GetEngine) {
  FlView* view = fl_view_new(project);

  // Check the engine is immediately available (i.e. before the widget is
  // realized).
  FlEngine* engine = fl_view_get_engine(view);
  EXPECT_NE(engine, nullptr);
}

TEST_F(FlViewTest, StateUpdateDoesNotHappenInInit) {
  FlView* view = fl_view_new(project);
  // Check that creating a view doesn't try to query the window state in
  // initialization, causing a critical log to be issued.
  EXPECT_FALSE(
      flutter::testing::fl_has_received_gtk_log_level(G_LOG_LEVEL_CRITICAL));

  (void)view;
}

// Disposing a view that holds the text input focus clears the handler's
// widget pointer so it does not dangle.
// https://github.com/flutter/flutter/issues/188657
TEST_F(FlViewTest, DisposeClearsTextInputWidget) {
  FlView* view = fl_view_new(project);
  g_object_ref_sink(view);
  g_autoptr(FlEngine) engine =
      FL_ENGINE(g_object_ref(fl_view_get_engine(view)));
  StartEngine(engine);
  FlTextInputHandler* handler = fl_engine_get_text_input_handler(engine);

  // Give the view text input focus.
  fl_text_input_handler_set_widget(handler, GTK_WIDGET(view));
  EXPECT_EQ(fl_text_input_handler_get_widget(handler), GTK_WIDGET(view));

  // Destroy the view while the engine and handler persist.
  g_object_unref(view);

  EXPECT_EQ(fl_text_input_handler_get_widget(handler), nullptr);
}

TEST_F(FlViewTest, PresentLayersAfterDestroy) {
  // Create a view and destroy it.
  FlView* view = fl_view_new(project);
  g_object_ref_sink(view);
  fl_gtk_widget_destroy(GTK_WIDGET(view));

  // Present a frame on a destroyed widget.
  fl_renderable_present_layers(FL_RENDERABLE(view), nullptr, 0);

  g_object_unref(view);
}

// FIXME(robert-ancell): Disabling this test as it requires the FlView
// to be realized to work after some refactoring. This is proving to be
// very difficult to mock. Following PRs will change this code so enable the
// test again after that.
#if 0
TEST_F(FlViewTest, FirstFrameSignal) {
  FlView* view = fl_view_new(project);
  gboolean first_frame_emitted = FALSE;
  g_signal_connect(view, "first-frame", G_CALLBACK(first_frame_cb),
                   &first_frame_emitted);

  EXPECT_FALSE(first_frame_emitted);

  fl_renderable_present_layers(FL_RENDERABLE(view), nullptr, 0);

  // Signal is emitted in idle, clear the main loop.
  while (g_main_context_iteration(g_main_context_default(), FALSE)) {
    // Repeat until nothing to iterate on.
  }

  // Check view has detected frame.
  EXPECT_TRUE(first_frame_emitted);
}
#endif

// Check semantics update applied
TEST_F(FlViewTest, SemanticsUpdate) {
  FlView* view = fl_view_new(project);

  FlEngine* engine = fl_view_get_engine(view);
  StartEngine(engine);

  FlutterSemanticsFlags flags = {};
  FlutterSemanticsNode2 root_node = {
      .id = 0, .label = "root", .flags2 = &flags};
  FlutterSemanticsNode2* nodes[1] = {&root_node};
  FlutterSemanticsUpdate2 update = {
      .node_count = 1, .nodes = nodes, .view_id = 0};
  g_signal_emit_by_name(engine, "update-semantics", &update);

  FlViewAccessible* accessible = fl_view_get_accessible(view);
  EXPECT_EQ(atk_object_get_n_accessible_children(ATK_OBJECT(accessible)), 1);
  AtkObject* root_object =
      atk_object_ref_accessible_child(ATK_OBJECT(accessible), 0);
  EXPECT_STREQ(atk_object_get_name(root_object), "root");
}

// Check semantics update ignored for other view
TEST_F(FlViewTest, SemanticsUpdateOtherView) {
  FlView* view = fl_view_new(project);

  FlEngine* engine = fl_view_get_engine(view);
  StartEngine(engine);

  FlutterSemanticsFlags flags = {};
  FlutterSemanticsNode2 root_node = {
      .id = 0, .label = "root", .flags2 = &flags};
  FlutterSemanticsNode2* nodes[1] = {&root_node};
  FlutterSemanticsUpdate2 update = {
      .node_count = 1, .nodes = nodes, .view_id = 99};
  g_signal_emit_by_name(engine, "update-semantics", &update);

  FlViewAccessible* accessible = fl_view_get_accessible(view);
  EXPECT_EQ(atk_object_get_n_accessible_children(ATK_OBJECT(accessible)), 0);
}

// Check secondary view is registered with engine.
TEST_F(FlViewTest, SecondaryView) {
  FlView* implicit_view = fl_view_new(project);

  FlEngine* engine = fl_view_get_engine(implicit_view);

  auto view_id = std::make_shared<FlutterViewId>(-1);
  fl_engine_get_embedder_api(engine)->AddView = MOCK_ENGINE_PROC(
      AddView, ([view_id](auto engine, const FlutterAddViewInfo* info) {
        *view_id = info->view_id;
        FlutterAddViewResult result = {
            .struct_size = sizeof(FlutterAddViewResult),
            .added = true,
            .user_data = info->user_data};
        info->add_view_callback(&result);
        return kSuccess;
      }));

  StartEngine(engine);

  FlView* secondary_view = fl_view_new_for_engine(engine);
  EXPECT_EQ(*view_id, fl_view_get_id(secondary_view));
}

// Check secondary view that fails registration.
TEST_F(FlViewTest, SecondaryViewError) {
  FlView* implicit_view = fl_view_new(project);

  FlEngine* engine = fl_view_get_engine(implicit_view);

  auto view_id = std::make_shared<FlutterViewId>(-1);
  fl_engine_get_embedder_api(engine)->AddView = MOCK_ENGINE_PROC(
      AddView, ([view_id](auto engine, const FlutterAddViewInfo* info) {
        *view_id = info->view_id;
        return kInvalidArguments;
      }));

  StartEngine(engine);

  FlView* secondary_view = fl_view_new_for_engine(engine);
  EXPECT_EQ(*view_id, fl_view_get_id(secondary_view));
}

// Check views are deregistered on destruction.
TEST_F(FlViewTest, ViewDestroy) {
  FlView* implicit_view = fl_view_new(project);

  FlEngine* engine = fl_view_get_engine(implicit_view);

  g_autoptr(GPtrArray) removed_views = g_ptr_array_new();
  fl_engine_get_embedder_api(engine)->RemoveView = MOCK_ENGINE_PROC(
      RemoveView,
      ([removed_views](auto engine, const FlutterRemoveViewInfo* info) {
        g_ptr_array_add(removed_views, GINT_TO_POINTER(info->view_id));
        return kSuccess;
      }));

  StartEngine(engine);

  FlView* secondary_view = fl_view_new_for_engine(engine);

  int64_t implicit_view_id = fl_view_get_id(implicit_view);
  int64_t secondary_view_id = fl_view_get_id(secondary_view);

  fl_gtk_widget_destroy(GTK_WIDGET(secondary_view));
  fl_gtk_widget_destroy(GTK_WIDGET(implicit_view));

  EXPECT_EQ(removed_views->len, 2u);
  EXPECT_EQ(GPOINTER_TO_INT(g_ptr_array_index(removed_views, 0)),
            secondary_view_id);
  EXPECT_EQ(GPOINTER_TO_INT(g_ptr_array_index(removed_views, 1)),
            implicit_view_id);
}

// Check views deregistered with errors works.
TEST_F(FlViewTest, ViewDestroyError) {
  FlView* implicit_view = fl_view_new(project);

  FlEngine* engine = fl_view_get_engine(implicit_view);

  fl_engine_get_embedder_api(engine)->RemoveView = MOCK_ENGINE_PROC(
      RemoveView, ([](auto engine, const FlutterRemoveViewInfo* info) {
        return kInvalidArguments;
      }));

  StartEngine(engine);

  FlView* secondary_view = fl_view_new_for_engine(engine);

  fl_gtk_widget_destroy(GTK_WIDGET(secondary_view));
  fl_gtk_widget_destroy(GTK_WIDGET(implicit_view));
}

// Check can create a view that is sized to the content.
TEST_F(FlViewTest, SizedToContent) {
  FlView* implicit_view = fl_view_new(project);

  FlEngine* engine = fl_view_get_engine(implicit_view);

  fl_engine_get_embedder_api(engine)->RemoveView = MOCK_ENGINE_PROC(
      RemoveView, ([](auto engine, const FlutterRemoveViewInfo* info) {
        return kInvalidArguments;
      }));

  StartEngine(engine);

  FlView* secondary_view = fl_view_new_sized_to_content(engine);

  fl_gtk_widget_destroy(GTK_WIDGET(secondary_view));
  fl_gtk_widget_destroy(GTK_WIDGET(implicit_view));
}

// Exercise the event-box and gesture signals installed during FlView
// construction, observing dispatch at the embedder boundary.
class FlViewInputTest : public flutter::testing::LinuxTest {
 protected:
  void SetUp() override {
    pointer_device =
        GDK_DEVICE(g_object_new(gdk_wayland_device_get_type(), "input-source",
                                GDK_SOURCE_MOUSE, nullptr));
    view = fl_view_new(project);
    g_object_ref_sink(view);
    FlEngine* view_engine = fl_view_get_engine(view);
    StartEngine(view_engine);
    // The harness mocks realization, so no native window exists to hide.
    gtk_widget_set_has_window(view->event_box, FALSE);
    fl_engine_get_embedder_api(view_engine)->SendPointerEvent =
        MOCK_ENGINE_PROC(SendPointerEvent,
                         ([this](auto engine, const FlutterPointerEvent* events,
                                 size_t count) {
                           pointer_events.insert(pointer_events.end(), events,
                                                 events + count);
                           return kSuccess;
                         }));
  }

  void TearDown() override {
    g_clear_object(&view);
    g_clear_object(&pointer_device);
    flutter::testing::LinuxTest::TearDown();
  }

  gboolean EmitButton(GdkEventType type, guint32 time) {
    g_autoptr(GdkEvent) event = gdk_event_new(type);
    gdk_event_set_device(event, pointer_device);
    gdk_event_set_source_device(event, pointer_device);
    event->button.time = time;
    event->button.x = 10;
    event->button.y = 20;
    event->button.button = GDK_BUTTON_PRIMARY;
    gboolean handled = FALSE;
    g_signal_emit_by_name(view->event_box,
                          type == GDK_BUTTON_RELEASE ? "button-release-event"
                                                     : "button-press-event",
                          event, &handled);
    return handled;
  }

  void EmitTouch(GdkEventType type) {
    g_autoptr(GdkEvent) event = gdk_event_new(type);
    event->touch.time = 1234;
    event->touch.x = 30;
    event->touch.y = 40;
    gboolean handled = FALSE;
    g_signal_emit_by_name(view->event_box, "touch-event", event, &handled);
    EXPECT_TRUE(handled);
  }

  FlView* view = nullptr;
  GdkDevice* pointer_device = nullptr;
  std::vector<FlutterPointerEvent> pointer_events;
};

TEST_F(FlViewInputTest, ButtonMotionAndReleaseDispatch) {
  EXPECT_TRUE(EmitButton(GDK_BUTTON_PRESS, 1234));

  g_autoptr(GdkEvent) motion = gdk_event_new(GDK_MOTION_NOTIFY);
  gdk_event_set_device(motion, pointer_device);
  gdk_event_set_source_device(motion, pointer_device);
  motion->motion.time = 1235;
  motion->motion.x = 15;
  motion->motion.y = 25;
  gboolean handled = FALSE;
  g_signal_emit_by_name(view->event_box, "motion-notify-event", motion,
                        &handled);
  EXPECT_TRUE(handled);
  EXPECT_TRUE(EmitButton(GDK_BUTTON_RELEASE, 1236));

  ASSERT_EQ(pointer_events.size(), 4u);
  EXPECT_EQ(pointer_events[0].phase, kAdd);
  EXPECT_EQ(pointer_events[1].phase, kDown);
  EXPECT_EQ(pointer_events[1].timestamp, 1234000u);
  EXPECT_EQ(pointer_events[1].x, 10);
  EXPECT_EQ(pointer_events[1].y, 20);
  EXPECT_EQ(pointer_events[1].buttons, kFlutterPointerButtonMousePrimary);
  EXPECT_EQ(pointer_events[2].phase, kMove);
  EXPECT_EQ(pointer_events[2].timestamp, 1235000u);
  EXPECT_EQ(pointer_events[2].x, 15);
  EXPECT_EQ(pointer_events[2].y, 25);
  EXPECT_EQ(pointer_events[3].phase, kUp);
  EXPECT_EQ(pointer_events[3].timestamp, 1236000u);
  EXPECT_EQ(pointer_events[3].buttons, 0);
  for (const auto& event : pointer_events) {
    EXPECT_EQ(event.view_id, fl_view_get_id(view));
    EXPECT_EQ(event.device_kind, kFlutterPointerDeviceKindMouse);
  }
}

TEST_F(FlViewInputTest, MultipleClickNotificationsAreIgnored) {
  EXPECT_FALSE(EmitButton(GDK_DOUBLE_BUTTON_PRESS, 1234));
  EXPECT_FALSE(EmitButton(GDK_TRIPLE_BUTTON_PRESS, 1235));
  EXPECT_TRUE(pointer_events.empty());
}

TEST_F(FlViewInputTest, ScrollDispatch) {
  g_autoptr(GdkEvent) event = gdk_event_new(GDK_SCROLL);
  event->scroll.time = 1234;
  event->scroll.x = 10;
  event->scroll.y = 20;
  event->scroll.direction = GDK_SCROLL_DOWN;
  gboolean handled = FALSE;
  g_signal_emit_by_name(view->event_box, "scroll-event", event, &handled);

  EXPECT_TRUE(handled);
  ASSERT_EQ(pointer_events.size(), 1u);
  EXPECT_EQ(pointer_events[0].signal_kind, kFlutterPointerSignalKindScroll);
  EXPECT_EQ(pointer_events[0].timestamp, 1234000u);
  EXPECT_EQ(pointer_events[0].x, 10);
  EXPECT_EQ(pointer_events[0].y, 20);
  EXPECT_EQ(pointer_events[0].scroll_delta_x, 0);
  EXPECT_EQ(pointer_events[0].scroll_delta_y, 53);
  EXPECT_EQ(pointer_events[0].view_id, fl_view_get_id(view));
}

TEST_F(FlViewInputTest, TouchDispatch) {
  EmitTouch(GDK_TOUCH_BEGIN);
  EmitTouch(GDK_TOUCH_UPDATE);
  EmitTouch(GDK_TOUCH_END);

  ASSERT_EQ(pointer_events.size(), 5u);
  EXPECT_EQ(pointer_events[0].phase, kAdd);
  EXPECT_EQ(pointer_events[1].phase, kDown);
  EXPECT_EQ(pointer_events[2].phase, kMove);
  EXPECT_EQ(pointer_events[3].phase, kUp);
  EXPECT_EQ(pointer_events[4].phase, kRemove);
  for (const auto& event : pointer_events) {
    EXPECT_EQ(event.device_kind, kFlutterPointerDeviceKindTouch);
    EXPECT_EQ(event.timestamp, 1234000u);
    EXPECT_EQ(event.x, 30);
    EXPECT_EQ(event.y, 40);
    EXPECT_EQ(event.view_id, fl_view_get_id(view));
  }
}

TEST_F(FlViewInputTest, ZoomAndRotationShareOnePanZoomSequence) {
  g_signal_emit_by_name(view->zoom_gesture, "begin", nullptr);
  g_signal_emit_by_name(view->rotate_gesture, "begin", nullptr);
  g_signal_emit_by_name(view->zoom_gesture, "scale-changed", 1.5);
  g_signal_emit_by_name(view->rotate_gesture, "angle-changed", 0.25, 0.25);
  g_signal_emit_by_name(view->zoom_gesture, "end", nullptr);
  g_signal_emit_by_name(view->rotate_gesture, "end", nullptr);

  ASSERT_EQ(pointer_events.size(), 4u);
  EXPECT_EQ(pointer_events[0].phase, kPanZoomStart);
  EXPECT_EQ(pointer_events[1].phase, kPanZoomUpdate);
  EXPECT_EQ(pointer_events[1].scale, 1.5);
  EXPECT_EQ(pointer_events[2].phase, kPanZoomUpdate);
  EXPECT_EQ(pointer_events[2].scale, 1.5);
  EXPECT_EQ(pointer_events[2].rotation, 0.25);
  EXPECT_EQ(pointer_events[3].phase, kPanZoomEnd);
  for (const auto& event : pointer_events) {
    EXPECT_EQ(event.view_id, fl_view_get_id(view));
    EXPECT_EQ(event.device_kind, kFlutterPointerDeviceKindTrackpad);
  }
}

class FlViewInputCancellationTest
    : public FlViewInputTest,
      public ::testing::WithParamInterface<const char*> {};

TEST_P(FlViewInputCancellationTest, CancelsMouseAndTouchOnce) {
  EXPECT_TRUE(EmitButton(GDK_BUTTON_PRESS, 1234));
  EmitTouch(GDK_TOUCH_BEGIN);
  pointer_events.clear();

  if (strcmp(GetParam(), "grab-broken-event") == 0) {
    g_autoptr(GdkEvent) event = gdk_event_new(GDK_GRAB_BROKEN);
    gboolean handled = FALSE;
    g_signal_emit_by_name(view->event_box, GetParam(), event, &handled);
    EXPECT_TRUE(handled);
  } else if (strcmp(GetParam(), "grab-notify") == 0) {
    // Restoring a grab must not cancel input; losing it must.
    g_signal_emit_by_name(view->event_box, GetParam(), TRUE);
    EXPECT_TRUE(pointer_events.empty());
    g_signal_emit_by_name(view->event_box, GetParam(), FALSE);
  } else {
    g_signal_emit_by_name(view->event_box, GetParam());
  }

  ASSERT_EQ(pointer_events.size(), 3u);
  EXPECT_EQ(pointer_events[0].phase, kCancel);
  EXPECT_EQ(pointer_events[0].device_kind, kFlutterPointerDeviceKindTouch);
  EXPECT_EQ(pointer_events[1].phase, kRemove);
  EXPECT_EQ(pointer_events[1].device_kind, kFlutterPointerDeviceKindTouch);
  EXPECT_EQ(pointer_events[2].phase, kCancel);
  EXPECT_EQ(pointer_events[2].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(pointer_events[2].buttons, 0);
  for (const auto& event : pointer_events) {
    EXPECT_EQ(event.view_id, fl_view_get_id(view));
  }

  pointer_events.clear();
  g_signal_emit_by_name(view->event_box, "unmap");
  EXPECT_TRUE(pointer_events.empty());
}

INSTANTIATE_TEST_SUITE_P(InputSignals,
                         FlViewInputCancellationTest,
                         ::testing::Values("grab-broken-event",
                                           "grab-notify",
                                           "unmap"));
