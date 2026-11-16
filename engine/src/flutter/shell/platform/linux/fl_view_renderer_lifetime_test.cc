// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Included first as it collides with the X11 headers.
#include "flutter/shell/platform/linux/testing/linux_test.h"

#include <dlfcn.h>

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstring>
#include <mutex>
#include <thread>
#include <utility>

#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_framebuffer.h"
#include "flutter/shell/platform/linux/fl_renderable.h"
#include "flutter/shell/platform/linux/fl_task_runner.h"
#include "flutter/shell/platform/linux/fl_view_renderer.h"
#include "flutter/shell/platform/linux/fl_view_renderer_opengl.h"
#include "flutter/shell/platform/linux/fl_view_renderer_software.h"
#include "flutter/shell/platform/linux/fl_view_renderer_subsurface.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_view.h"
#include "flutter/shell/platform/linux/testing/fl_test_gtk_logs.h"
#include "flutter/shell/platform/linux/testing/mock_epoxy.h"
#include "flutter/shell/platform/linux/testing/mock_gtk.h"
#include "gtest/gtest.h"

namespace {

using namespace std::chrono_literals;

// Every wait releases on timeout, including when a fatal expectation unwinds
// the main-thread scope. No worker is detached or left holding a test barrier.
class CompositionBarrier {
 public:
  ~CompositionBarrier() { ReleaseAndJoin(); }

  template <class Callback>
  void Start(Callback callback) {
    worker_ = std::thread(std::move(callback));
  }

  void Enter() {
    std::unique_lock<std::mutex> lock(mutex_);
    entered_ = true;
    condition_.notify_all();
    EXPECT_TRUE(condition_.wait_for(lock, 5s, [&] { return released_; }));
  }

  bool WaitForEntry() {
    std::unique_lock<std::mutex> lock(mutex_);
    return condition_.wait_for(lock, 5s, [&] { return entered_; });
  }

  void ReleaseAndJoin() {
    {
      std::lock_guard<std::mutex> lock(mutex_);
      released_ = true;
    }
    condition_.notify_all();
    if (worker_.joinable()) {
      worker_.join();
    }
  }

 private:
  std::mutex mutex_;
  std::condition_variable condition_;
  bool entered_ = false;
  bool released_ = false;
  std::thread worker_;
};

// Only the explicitly selected raster thread intercepts Cairo. The actual
// compositor and actual Cairo operation still run, rather than a fake present.
thread_local CompositionBarrier* cairo_barrier = nullptr;

struct Finalization {
  std::atomic<int> count{0};
  std::thread::id thread;
  GObject* observed = nullptr;

  static GQuark Key() {
    return g_quark_from_static_string("flutter-renderer-lifetime-finalization");
  }

  ~Finalization() {
    // Workers are joined and main-context work is drained before scope exit.
    // Detach a failed lifetime observation before fixture teardown can fire it.
    if (count == 0 && observed != nullptr) {
      g_object_steal_qdata(observed, Key());
    }
  }

  static void Notify(gpointer data) {
    auto* self = static_cast<Finalization*>(data);
    self->thread = std::this_thread::get_id();
    ++self->count;
  }

  void Watch(gpointer object) {
    observed = G_OBJECT(object);
    // Weak notifications run on forced dispose, before finalization.
    g_object_set_qdata_full(observed, Key(), this, Notify);
  }
};

void DrainIdles() {
  // GTK may leave persistent sources; cap iterations instead of running an
  // unbounded main loop. A queued renderer idle must complete within this cap.
  for (int i = 0; i < 1000 && g_main_context_pending(nullptr); i++) {
    g_main_context_iteration(nullptr, FALSE);
  }
}

GtkWidget* FindRenderer(GtkWidget* widget) {
  if (FL_IS_VIEW_RENDERER(widget)) {
    return widget;
  }
  if (!GTK_IS_CONTAINER(widget)) {
    return nullptr;
  }
  GList* children = gtk_container_get_children(GTK_CONTAINER(widget));
  GtkWidget* result = nullptr;
  for (GList* child = children; child != nullptr && result == nullptr;
       child = child->next) {
    result = FindRenderer(GTK_WIDGET(child->data));
  }
  g_list_free(children);
  return result;
}

struct OpenGLLayer {
  OpenGLLayer() {
    framebuffer = fl_framebuffer_new(GL_RGBA, 1, 1, FALSE);
    backing_store.type = kFlutterBackingStoreTypeOpenGL;
    backing_store.open_gl.type = kFlutterOpenGLTargetTypeFramebuffer;
    backing_store.open_gl.framebuffer.target = GL_RGBA8;
    backing_store.open_gl.framebuffer.user_data = framebuffer;
    layer.type = kFlutterLayerContentTypeBackingStore;
    layer.backing_store = &backing_store;
    layer.size = {1, 1};
  }
  ~OpenGLLayer() { g_object_unref(framebuffer); }
  FlFramebuffer* framebuffer;
  FlutterBackingStore backing_store = {};
  FlutterLayer layer = {};
};

class FlViewRendererLifetimeTest : public flutter::testing::LinuxTest {
 protected:
  void SetUp() override {
    gtk.realize_widgets = true;
    // The token is only ref-counted by the renderer. Every GL context operation
    // is mocked with its exact GDK ABI; no real driver context is needed.
    ON_CALL(gtk, gdk_window_create_gl_context)
        .WillByDefault([](GdkWindow*, GError**) {
          return reinterpret_cast<GdkGLContext*>(
              g_object_new(G_TYPE_OBJECT, nullptr));
        });
    ON_CALL(gtk, gdk_gl_context_realize).WillByDefault(::testing::Return(TRUE));
  }

  GtkWidget* Realize(GtkWidget* child) {
    GtkWidget* window = gtk_offscreen_window_new();
    gtk_container_add(GTK_CONTAINER(window), child);
    gtk_widget_realize(window);
    gtk_widget_realize(child);
    EXPECT_TRUE(gtk_widget_get_realized(child));
    return window;
  }

  void ExpectReadback(CompositionBarrier& barrier) {
    EXPECT_CALL(epoxy, glReadPixels(0, 0, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE,
                                    ::testing::NotNull()))
        .WillOnce([&barrier](GLint, GLint, GLsizei, GLsizei, GLenum, GLenum,
                             void* pixels) {
          barrier.Enter();
          std::memset(pixels, 0, 4);
        });
  }

  void ExpectNoCritical() {
    EXPECT_FALSE(
        flutter::testing::fl_has_received_gtk_log_level(G_LOG_LEVEL_CRITICAL));
  }

  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
  ::testing::NiceMock<flutter::testing::MockGtk> gtk;
};

TEST_F(FlViewRendererLifetimeTest, OpenGLDisposeDuringComposite) {
  auto* renderer = fl_view_renderer_opengl_new(engine, FALSE);
  g_object_ref_sink(renderer);
  Finalization finalization;
  finalization.Watch(renderer);
  GtkWidget* window = Realize(GTK_WIDGET(renderer));
  OpenGLLayer frame;
  const FlutterLayer* layers[] = {&frame.layer};
  CompositionBarrier barrier;
  ExpectReadback(barrier);
  std::atomic<bool> completed{false};
  flutter::testing::fl_reset_received_gtk_log_levels();
  barrier.Start([&] {
    fl_view_renderer_present_layers(FL_VIEW_RENDERER(renderer), layers, 1);
    completed = true;
  });
  EXPECT_TRUE(barrier.WaitForEntry());
  // The fixture retains engine independently, excluding engine Shutdown's
  // raster join from the mutex regression. The caller retains renderer.
  fl_gtk_widget_destroy(GTK_WIDGET(renderer));
  EXPECT_EQ(finalization.count, 0);
  barrier.ReleaseAndJoin();
  EXPECT_TRUE(completed);
  // The queued idle owns the renderer until drained, even after its caller
  // releases its reference. This also exercises stop_wait after mutex unlock.
  g_object_unref(renderer);
  EXPECT_EQ(finalization.count, 0);
  DrainIdles();
  EXPECT_EQ(finalization.count, 1);
  EXPECT_EQ(finalization.thread, std::this_thread::get_id());
  fl_gtk_widget_destroy(window);
  ExpectNoCritical();
}

TEST_F(FlViewRendererLifetimeTest, SoftwareDisposeDuringComposite) {
  auto* renderer = fl_view_renderer_software_new(engine, FALSE);
  g_object_ref_sink(renderer);
  Finalization finalization;
  finalization.Watch(renderer);
  GtkWidget* window = Realize(GTK_WIDGET(renderer));
  unsigned char pixels[4] = {};
  FlutterBackingStore backing_store = {};
  backing_store.type = kFlutterBackingStoreTypeSoftware;
  backing_store.software.allocation = pixels;
  backing_store.software.row_bytes = 4;
  backing_store.software.height = 1;
  FlutterLayer layer = {};
  layer.type = kFlutterLayerContentTypeBackingStore;
  layer.backing_store = &backing_store;
  layer.size = {1, 1};
  const FlutterLayer* layers[] = {&layer};
  CompositionBarrier barrier;
  std::atomic<bool> completed{false};
  flutter::testing::fl_reset_received_gtk_log_levels();
  barrier.Start([&] {
    cairo_barrier = &barrier;
    fl_view_renderer_present_layers(FL_VIEW_RENDERER(renderer), layers, 1);
    cairo_barrier = nullptr;
    completed = true;
  });
  EXPECT_TRUE(barrier.WaitForEntry());
  fl_gtk_widget_destroy(GTK_WIDGET(renderer));
  EXPECT_EQ(finalization.count, 0);
  barrier.ReleaseAndJoin();
  EXPECT_TRUE(completed);
  g_object_unref(renderer);
  EXPECT_EQ(finalization.count, 0);
  DrainIdles();
  EXPECT_EQ(finalization.count, 1);
  EXPECT_EQ(finalization.thread, std::this_thread::get_id());
  fl_gtk_widget_destroy(window);
  ExpectNoCritical();
}

TEST_F(FlViewRendererLifetimeTest, ViewOwnsRendererDuringComposite) {
  FlView* view = fl_view_new(project);
  g_object_ref_sink(view);
  g_autoptr(FlEngine) retained_engine =
      FL_ENGINE(g_object_ref(fl_view_get_engine(view)));
  GtkWidget* window = Realize(GTK_WIDGET(view));
  GtkWidget* renderer = FindRenderer(GTK_WIDGET(view));
  ASSERT_NE(renderer, nullptr);
  ASSERT_TRUE(FL_IS_VIEW_RENDERER_OPENGL(renderer));
  ASSERT_TRUE(gtk_widget_get_realized(renderer));
  Finalization view_finalization;
  Finalization renderer_finalization;
  view_finalization.Watch(view);
  renderer_finalization.Watch(renderer);
  int first_frames = 0;
  g_signal_connect(view, "first-frame",
                   G_CALLBACK(+[](FlView*, int* count) { ++*count; }),
                   &first_frames);
  OpenGLLayer frame;
  const FlutterLayer* layers[] = {&frame.layer};
  CompositionBarrier barrier;
  ExpectReadback(barrier);
  std::atomic<bool> completed{false};
  // Match the engine callback: the raster thread owns only a view reference.
  // It must not independently retain renderer and conceal broken ownership.
  FlView* raster_view = FL_VIEW(g_object_ref(view));
  flutter::testing::fl_reset_received_gtk_log_levels();
  barrier.Start([&, raster_view] {
    fl_renderable_present_layers(FL_RENDERABLE(raster_view), layers, 1);
    completed = true;
    g_object_unref(raster_view);
  });
  EXPECT_TRUE(barrier.WaitForEntry());
  fl_gtk_widget_destroy(GTK_WIDGET(view));
  g_object_unref(view);
  EXPECT_EQ(view_finalization.count, 0);
  EXPECT_EQ(renderer_finalization.count, 0);
  barrier.ReleaseAndJoin();
  EXPECT_TRUE(completed);
  EXPECT_EQ(view_finalization.count, 1);
  DrainIdles();
  EXPECT_EQ(renderer_finalization.count, 1);
  EXPECT_EQ(first_frames, 0);
  EXPECT_EQ(renderer_finalization.thread, std::this_thread::get_id());
  fl_gtk_widget_destroy(window);
  ExpectNoCritical();
}

// No idle is scheduled for the early-drop path. Record which thread releases
// the last view/renderer reference rather than assuming GTK always does so.
TEST_F(FlViewRendererLifetimeTest, ViewEarlyDropFinalizationThread) {
  FlView* view = fl_view_new(project);
  g_object_ref_sink(view);
  GtkWidget* renderer = FindRenderer(GTK_WIDGET(view));
  ASSERT_NE(renderer, nullptr);
  Finalization view_finalization;
  Finalization renderer_finalization;
  view_finalization.Watch(view);
  renderer_finalization.Watch(renderer);
  FlView* raster_view = FL_VIEW(g_object_ref(view));
  fl_gtk_widget_destroy(GTK_WIDGET(view));
  g_object_unref(view);
  // Retaining only the view must retain the renderer even without a queued
  // redraw or a GTK container reference.
  EXPECT_EQ(renderer_finalization.count, 0);
  std::thread::id raster_id;
  std::thread raster([&] {
    raster_id = std::this_thread::get_id();
    fl_renderable_present_layers(FL_RENDERABLE(raster_view), nullptr, 0);
    g_object_unref(raster_view);
  });
  raster.join();
  EXPECT_EQ(view_finalization.count, 1);
  EXPECT_EQ(renderer_finalization.count, 1);
  EXPECT_EQ(view_finalization.thread, raster_id);
  EXPECT_EQ(renderer_finalization.thread, raster_id);
}

TEST_F(FlViewRendererLifetimeTest, SubsurfaceManagerBeforeRealizeIsReleased) {
  auto* renderer = fl_view_renderer_subsurface_new(engine, FALSE);
  g_object_ref_sink(renderer);
  Finalization manager_finalization;
  Finalization renderer_finalization;
  manager_finalization.Watch(fl_engine_get_opengl_manager(engine));
  renderer_finalization.Watch(renderer);
  g_object_run_dispose(G_OBJECT(renderer));
  g_clear_object(&engine);
  EXPECT_EQ(manager_finalization.count, 0);
  g_object_unref(renderer);
  EXPECT_EQ(renderer_finalization.count, 1);
  EXPECT_EQ(manager_finalization.count, 1);
}

TEST_F(FlViewRendererLifetimeTest, QueuedIdleAndTimerAfterEngineDispose) {
  auto* renderer = fl_view_renderer_opengl_new(engine, FALSE);
  g_object_ref_sink(renderer);
  Finalization renderer_finalization;
  Finalization runner_finalization;
  Finalization manager_finalization;
  renderer_finalization.Watch(renderer);
  FlTaskRunner* runner = fl_engine_get_task_runner(engine);
  runner_finalization.Watch(runner);
  manager_finalization.Watch(fl_engine_get_opengl_manager(engine));
  GtkWidget* window = Realize(GTK_WIDGET(renderer));
  FlutterTask task = {};
  fl_task_runner_post_flutter_task(
      runner, task, (g_get_monotonic_time() + 3600000000LL) * 1000);
  GSource* timer = g_main_context_find_source_by_user_data(nullptr, runner);
  ASSERT_NE(timer, nullptr);
  g_source_ref(timer);
  OpenGLLayer frame;
  const FlutterLayer* layers[] = {&frame.layer};
  flutter::testing::fl_reset_received_gtk_log_levels();
  fl_view_renderer_present_layers(FL_VIEW_RENDERER(renderer), layers, 1);
  fl_gtk_widget_destroy(GTK_WIDGET(renderer));
  // Forced engine disposal removes its ownership, while the pending redraw
  // and renderer keep the presentation resources alive through completion.
  g_object_run_dispose(G_OBJECT(engine));
  g_clear_object(&engine);
  EXPECT_EQ(runner_finalization.count, 0);
  g_object_unref(renderer);
  EXPECT_EQ(renderer_finalization.count, 0);
  DrainIdles();
  EXPECT_EQ(renderer_finalization.count, 1);
  EXPECT_EQ(runner_finalization.count, 1);
  EXPECT_EQ(manager_finalization.count, 1);
  EXPECT_TRUE(g_source_is_destroyed(timer));
  g_source_unref(timer);
  fl_gtk_widget_destroy(window);
  ExpectNoCritical();
}

TEST_F(FlViewRendererLifetimeTest, RepeatedDisposeBeforeRealize) {
  FlViewRenderer* renderers[] = {
      FL_VIEW_RENDERER(fl_view_renderer_opengl_new(engine, FALSE)),
      FL_VIEW_RENDERER(fl_view_renderer_software_new(engine, FALSE)),
      FL_VIEW_RENDERER(fl_view_renderer_subsurface_new(engine, FALSE)),
  };
  for (FlViewRenderer* renderer : renderers) {
    g_object_ref_sink(renderer);
    Finalization finalization;
    finalization.Watch(renderer);
    fl_gtk_widget_destroy(GTK_WIDGET(renderer));
    fl_gtk_widget_destroy(GTK_WIDGET(renderer));
    fl_view_renderer_present_layers(renderer, nullptr, 0);
    EXPECT_EQ(finalization.count, 0);
    g_object_unref(renderer);
    EXPECT_EQ(finalization.count, 1);
    EXPECT_EQ(finalization.thread, std::this_thread::get_id());
  }
  ExpectNoCritical();
}

}  // namespace

// Interposition is confined to this test executable and to the selected raster
// thread. Other suites, GTK drawing, and the actual Cairo paint are unchanged.
extern "C" void cairo_paint(cairo_t* cr) {
  if (cairo_barrier != nullptr) {
    CompositionBarrier* barrier = cairo_barrier;
    cairo_barrier = nullptr;
    barrier->Enter();
  }
  auto original =
      reinterpret_cast<void (*)(cairo_t*)>(dlsym(RTLD_NEXT, "cairo_paint"));
  original(cr);
}
