// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_gtk_frame_pacer.h"

#include <thread>
#include <vector>

#include "gtest/gtest.h"

namespace {

// Deliberately has no FlEngine or renderer: this is a GTK lifecycle contract.
class FlGtkFramePacerTest : public ::testing::Test {
 protected:
  void SetUp() override {
#if FLUTTER_LINUX_GTK4
    gtk_init();
    window = gtk_window_new();
    widget = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    gtk_window_set_child(GTK_WINDOW(window), widget);
    gtk_window_present(GTK_WINDOW(window));
#else
    gtk_init(nullptr, nullptr);
    window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    widget = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    gtk_container_add(GTK_CONTAINER(window), widget);
    gtk_widget_show_all(window);
#endif
    ASSERT_TRUE(gtk_widget_get_mapped(widget));
    clock = gtk_widget_get_frame_clock(widget);
    ASSERT_NE(clock, nullptr);
    pacer = fl_gtk_frame_pacer_new();
  }

  void TearDown() override {
    fl_gtk_frame_pacer_stop(pacer);
    g_clear_object(&pacer);
#if FLUTTER_LINUX_GTK4
    gtk_window_destroy(GTK_WINDOW(window));
#else
    gtk_widget_destroy(window);
#endif
  }

  void Request(intptr_t baton, GtkWidget* target) {
    fl_gtk_frame_pacer_request(
        pacer, target, baton,
        [](intptr_t baton, uint64_t start, uint64_t target, gpointer data) {
          auto* self = static_cast<FlGtkFramePacerTest*>(data);
          EXPECT_EQ(g_thread_self(), self->thread);
          EXPECT_GT(start, 0u);
          EXPECT_GT(target, start);
          self->batons.push_back(baton);
          if (self->stop_on_delivery) {
            fl_gtk_frame_pacer_stop(self->pacer);
          }
        },
        this,
        [](gpointer data) {
          auto* self = static_cast<FlGtkFramePacerTest*>(data);
          self->releases++;
          if (self->stop_on_release) {
            fl_gtk_frame_pacer_stop(self->pacer);
          }
        });
  }

  void Arm(intptr_t baton = 1, bool mapped = true) {
    auto* context = g_main_context_default();
    ASSERT_TRUE(g_main_context_acquire(context));
    Request(baton, mapped ? widget : nullptr);
    g_main_context_release(context);
  }

  gulong TickHandler() {
    return g_signal_handler_find(clock, G_SIGNAL_MATCH_DATA, 0, 0, nullptr,
                                 nullptr, widget);
  }

  void Tick() { g_signal_emit_by_name(clock, "update"); }

  void WaitForDelivery() {
    const gint64 deadline = g_get_monotonic_time() + G_USEC_PER_SEC;
    while (batons.empty() && g_get_monotonic_time() < deadline) {
      g_main_context_iteration(nullptr, FALSE);
      g_usleep(1000);
    }
    ASSERT_FALSE(batons.empty());
  }

  FlGtkFramePacer* pacer = nullptr;
  GtkWidget* window = nullptr;
  GtkWidget* widget = nullptr;
  GdkFrameClock* clock = nullptr;
  GThread* thread = g_thread_self();
  std::vector<intptr_t> batons;
  int releases = 0;
  bool stop_on_delivery = false;
  bool stop_on_release = false;
};

TEST_F(FlGtkFramePacerTest, DeliveryReleasesRecipientBeforeNextTick) {
  Arm();
  const gulong handler = TickHandler();
  ASSERT_NE(handler, 0u);
  Tick();
  EXPECT_EQ(batons, std::vector<intptr_t>({1}));
  EXPECT_EQ(releases, 1);
  EXPECT_EQ(TickHandler(), handler);
  Tick();
  EXPECT_EQ(releases, 1);
  EXPECT_EQ(TickHandler(), 0u);
}

TEST_F(FlGtkFramePacerTest, StopReleasesCompletedButStalledSubscription) {
  Arm();
  Tick();
  g_signal_handler_block(clock, TickHandler());
  fl_gtk_frame_pacer_stop(pacer);
  EXPECT_EQ(TickHandler(), 0u);
  EXPECT_EQ(batons, std::vector<intptr_t>({1}));
  EXPECT_EQ(releases, 1);
}

TEST_F(FlGtkFramePacerTest, StopDrainsWorkerRequestsBeforeDispatch) {
  std::thread worker([&] {
    Request(1, widget);
    Request(2, nullptr);
  });
  worker.join();
  EXPECT_TRUE(batons.empty());
  fl_gtk_frame_pacer_stop(pacer);
  EXPECT_EQ(batons, std::vector<intptr_t>({1, 2}));
  EXPECT_EQ(releases, 2);
  EXPECT_EQ(TickHandler(), 0u);
  while (g_main_context_iteration(nullptr, FALSE)) {
  }
  EXPECT_EQ(releases, 2);
}

TEST_F(FlGtkFramePacerTest, StopDrainsMappedRequestExactlyOnce) {
  Arm();
  fl_gtk_frame_pacer_stop(pacer);
  fl_gtk_frame_pacer_stop(pacer);
  Tick();
  EXPECT_EQ(batons, std::vector<intptr_t>({1}));
  EXPECT_EQ(releases, 1);
  EXPECT_EQ(TickHandler(), 0u);
}

TEST_F(FlGtkFramePacerTest, StopDrainsFallbackTimer) {
  Arm(1, false);
  EXPECT_TRUE(batons.empty());
  fl_gtk_frame_pacer_stop(pacer);
  EXPECT_EQ(batons, std::vector<intptr_t>({1}));
  EXPECT_EQ(releases, 1);
}

TEST_F(FlGtkFramePacerTest, DeliveryCanStopPacerReentrantly) {
  stop_on_delivery = true;
  Arm();
  Tick();
  EXPECT_EQ(batons, std::vector<intptr_t>({1}));
  EXPECT_EQ(releases, 1);
  EXPECT_EQ(TickHandler(), 0u);
}

TEST_F(FlGtkFramePacerTest, RecipientReleaseCanStopPacerReentrantly) {
  stop_on_release = true;
  Arm();
  Tick();
  EXPECT_EQ(batons, std::vector<intptr_t>({1}));
  EXPECT_EQ(releases, 1);
  EXPECT_EQ(TickHandler(), 0u);
}

TEST_F(FlGtkFramePacerTest, UnmapDrainsBatonWithoutRedelivery) {
  Arm();
  gtk_widget_set_visible(window, FALSE);
  EXPECT_EQ(batons, std::vector<intptr_t>({1}));
  EXPECT_EQ(releases, 1);
  fl_gtk_frame_pacer_stop(pacer);
  EXPECT_EQ(releases, 1);
}

TEST_F(FlGtkFramePacerTest, WorkerOwningMainContextStillMarshals) {
  std::thread worker([&] {
    auto* context = g_main_context_default();
    ASSERT_TRUE(g_main_context_acquire(context));
    Request(1, nullptr);
    g_main_context_release(context);
  });
  worker.join();
  EXPECT_TRUE(batons.empty());
  WaitForDelivery();
  EXPECT_EQ(releases, 1);
}

TEST_F(FlGtkFramePacerTest, StalledClockReturnsPendingBaton) {
  Arm();
  g_signal_handler_block(clock, TickHandler());
  WaitForDelivery();
  EXPECT_EQ(releases, 1);
  EXPECT_EQ(TickHandler(), 0u);
}

TEST_F(FlGtkFramePacerTest, DeliveredRequestDoesNotRetainUnparentedWidget) {
  Arm();
  Tick();
  bool finalized = false;
  g_object_weak_ref(
      G_OBJECT(widget),
      [](gpointer data, GObject*) { *static_cast<bool*>(data) = true; },
      &finalized);
#if FLUTTER_LINUX_GTK4
  gtk_window_set_child(GTK_WINDOW(window), nullptr);
#else
  gtk_container_remove(GTK_CONTAINER(window), widget);
#endif
  EXPECT_TRUE(finalized);
  // The weak-notify storage remains valid even if the regression returns.
  fl_gtk_frame_pacer_stop(pacer);
  EXPECT_TRUE(finalized);
  EXPECT_EQ(releases, 1);
}

TEST_F(FlGtkFramePacerTest, StopDropsAllPacerReferences) {
  bool finalized = false;
  g_object_weak_ref(
      G_OBJECT(pacer),
      [](gpointer data, GObject*) { *static_cast<bool*>(data) = true; },
      &finalized);
  Arm();
  fl_gtk_frame_pacer_stop(pacer);
  g_clear_object(&pacer);
  EXPECT_TRUE(finalized);
  pacer = fl_gtk_frame_pacer_new();
}

}  // namespace
