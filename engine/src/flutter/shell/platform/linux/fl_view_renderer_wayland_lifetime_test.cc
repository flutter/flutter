// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_view_renderer_subsurface.h"

#include <cerrno>
#include <tuple>

#include <epoxy/egl.h>
#include <gdk/gdkwayland.h>
#include <poll.h>
#include <wayland-client.h>

#include "flutter/shell/platform/linux/fl_compositor_opengl.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_framebuffer.h"
#include "flutter/shell/platform/linux/fl_gl_fence.h"
#include "flutter/shell/platform/linux/fl_subsurface_egl.h"
#include "flutter/shell/platform/linux/fl_task_runner.h"
#include "flutter/shell/platform/linux/fl_wayland_display.h"
#include "gtest/gtest.h"

namespace {

static constexpr gint64 kTimeout = 5 * G_TIME_SPAN_SECOND;
static constexpr size_t kFrameSize = 64;

enum Resource {
  kRenderer,
  kEngine,
  kManager,
  kRunner,
  kCompositor,
  kChild,
  kEGL,
  kFence,
  kResourceCount
};

// qdata destroy notifications observe finalization, unlike weak notifications
// which can run during forced dispose. The records own their counters, so even
// a failed leak assertion cannot leave a callback pointing into a dead fixture.
struct Counts {
  GThread* main_thread;
  gint created[kResourceCount];
  gint finalized[kResourceCount];
  gint finalized_on_main[kResourceCount];
  gint composites;
  gint presents;
  gint wakes;
  EGLDisplay display;
  gint child_contexts;
  struct wl_surface* parent;
  uint32_t parent_id;
};

struct Finalization {
  Counts* counts;
  Resource resource;
};

static void finalized_cb(gpointer data) {
  auto* observation = static_cast<Finalization*>(data);
  Counts* counts = observation->counts;
  Resource resource = observation->resource;
  if (g_thread_self() == counts->main_thread) {
    g_atomic_int_inc(&counts->finalized_on_main[resource]);
  }
  // A fence must finish destruction while the manager still keeps the shared
  // contexts alive, even after the engine and child surface are gone.
  if (resource == kFence) {
    EXPECT_EQ(g_atomic_int_get(&counts->finalized[kManager]), 0);
    EXPECT_NE(eglQueryString(counts->display, EGL_VERSION), nullptr);
    EXPECT_EQ(eglGetError(), static_cast<EGLint>(EGL_SUCCESS));
  }
  g_atomic_int_inc(&counts->finalized[resource]);
  g_atomic_rc_box_release(counts);
  g_free(observation);
}

static void observe(GObject* object, Counts* counts, Resource resource) {
  ASSERT_NE(object, nullptr);
  GQuark key = g_quark_from_static_string("flutter-wayland-lifetime");
  if (g_object_get_qdata(object, key) != nullptr) {
    return;
  }
  auto* observation = g_new0(Finalization, 1);
  observation->counts = static_cast<Counts*>(g_atomic_rc_box_acquire(counts));
  observation->resource = resource;
  g_atomic_int_inc(&counts->created[resource]);
  g_object_set_qdata_full(object, key, observation, finalized_cb);
}

class Gate {
 public:
  Gate() {
    g_mutex_init(&mutex_);
    g_cond_init(&condition_);
  }
  ~Gate() {
    g_cond_clear(&condition_);
    g_mutex_clear(&mutex_);
  }
  void Signal() {
    g_mutex_lock(&mutex_);
    signalled_ = TRUE;
    g_cond_broadcast(&condition_);
    g_mutex_unlock(&mutex_);
  }
  gboolean Wait() {
    gint64 deadline = g_get_monotonic_time() + kTimeout;
    g_mutex_lock(&mutex_);
    while (!signalled_) {
      if (!g_cond_wait_until(&condition_, &mutex_, deadline)) {
        break;
      }
    }
    gboolean result = signalled_;
    g_mutex_unlock(&mutex_);
    return result;
  }

 private:
  GMutex mutex_;
  GCond condition_;
  gboolean signalled_ = FALSE;
};

enum class Pause { kNone, kComposite, kPresent, kBeforeWake };

struct Presentation {
  Presentation(Counts* counts,
               FlViewRenderer* renderer,
               FlOpenGLManager* manager,
               Pause pause,
               gboolean without_fences,
               gboolean zero_layers)
      : counts(counts),
        renderer(renderer),
        manager(manager),
        pause(pause),
        without_fences(without_fences),
        zero_layers(zero_layers) {}

  Counts* counts;
  FlViewRenderer* renderer;
  FlOpenGLManager* manager;
  Pause pause;
  gboolean without_fences;
  gboolean zero_layers;
  gboolean in_present = FALSE;
  Gate entered;
  Gate release;
  Gate done;

  void StopAt(Pause point) {
    if (pause == point) {
      entered.Signal();
      EXPECT_TRUE(release.Wait()) << "Timed out releasing raster barrier";
    }
  }
};

// Only the raster worker and the GTK thread constructing this test's widgets
// are observed. All wrappers call the actual implementation, with the sole
// capability override being the explicitly tested glFinish fallback.
thread_local Counts* current_counts = nullptr;
thread_local Presentation* current_presentation = nullptr;

static gpointer present_thread(gpointer data) {
  auto* presentation = static_cast<Presentation*>(data);
  current_counts = presentation->counts;
  current_presentation = presentation;
  FlOpenGLManager* manager = presentation->manager;
  if (fl_opengl_manager_make_current(manager)) {
    {
      g_autoptr(FlFramebuffer) framebuffer =
          fl_framebuffer_new(GL_RGBA, kFrameSize, kFrameSize, FALSE);
      EXPECT_NE(fl_framebuffer_get_id(framebuffer), 0u);
      EXPECT_NE(fl_framebuffer_get_texture_id(framebuffer), 0u);
      glBindFramebuffer(GL_FRAMEBUFFER, fl_framebuffer_get_id(framebuffer));
      EXPECT_EQ(glCheckFramebufferStatus(GL_FRAMEBUFFER),
                static_cast<GLenum>(GL_FRAMEBUFFER_COMPLETE));
      glClearColor(0.25, 0.5, 0.75, 1.0);
      glClear(GL_COLOR_BUFFER_BIT);
      glBindFramebuffer(GL_FRAMEBUFFER, 0);

      FlutterBackingStore store = {};
      store.struct_size = sizeof(store);
      store.type = kFlutterBackingStoreTypeOpenGL;
      store.open_gl.type = kFlutterOpenGLTargetTypeFramebuffer;
      store.open_gl.framebuffer.target = GL_RGBA8;
      store.open_gl.framebuffer.name = fl_framebuffer_get_id(framebuffer);
      store.open_gl.framebuffer.user_data = framebuffer;
      FlutterLayer layer = {};
      layer.struct_size = sizeof(layer);
      layer.type = kFlutterLayerContentTypeBackingStore;
      layer.backing_store = &store;
      layer.size = {kFrameSize, kFrameSize};
      const FlutterLayer* layers[] = {&layer};
      fl_view_renderer_present_layers(
          presentation->renderer, presentation->zero_layers ? nullptr : layers,
          presentation->zero_layers ? 0 : 1);
      EXPECT_EQ(glGetError(), static_cast<GLenum>(GL_NO_ERROR));
    }
    EXPECT_TRUE(fl_opengl_manager_clear_current(manager));
  } else {
    ADD_FAILURE() << "Could not make the real engine EGL context current";
  }
  current_presentation = nullptr;
  current_counts = nullptr;
  g_object_unref(presentation->renderer);
  presentation->done.Signal();
  return nullptr;
}

// Always release and join, including on a fatal assertion in the main thread.
// A driver hang fails the process after a bounded wait instead of leaving an
// unbounded join. The normal engine test timeout is an additional backstop.
class RasterThread {
 public:
  RasterThread(Counts* counts,
               FlViewRenderer* renderer,
               FlOpenGLManager* manager,
               Pause pause,
               gboolean without_fences,
               gboolean zero_layers)
      : presentation_{counts,         FL_VIEW_RENDERER(g_object_ref(renderer)),
                      manager,        pause,
                      without_fences, zero_layers},
        thread_(
            g_thread_new("wayland-raster", present_thread, &presentation_)) {}
  ~RasterThread() { Join(); }
  gboolean WaitForEntry() { return presentation_.entered.Wait(); }
  void Release() { presentation_.release.Signal(); }
  void Join() {
    if (thread_ == nullptr) {
      return;
    }
    Release();
    if (!presentation_.done.Wait()) {
      g_error("Real Wayland raster worker did not finish within the timeout");
    }
    g_thread_join(thread_);
    thread_ = nullptr;
  }

 private:
  Presentation presentation_;
  GThread* thread_;
};

// GTK's unrealize signal runs before its default handler. The supervisor
// releases the held-frame_mutex barrier only after GTK has entered unrealize,
// without asking GTK's blocked thread to dispatch an idle or timeout.
class UnrealizeRelease {
 public:
  UnrealizeRelease(GtkWidget* widget, RasterThread* raster, Counts* counts)
      : widget_(widget), raster_(raster), counts_(counts) {
    handler_ =
        g_signal_connect(widget_, "unrealize", G_CALLBACK(Unrealize), this);
    thread_ = g_thread_new("wayland-release", Run, this);
  }
  ~UnrealizeRelease() {
    entered_.Signal();
    if (!done_.Wait()) {
      g_error("Wayland unrealize supervisor did not finish within the timeout");
    }
    g_thread_join(thread_);
    if (g_signal_handler_is_connected(widget_, handler_)) {
      g_signal_handler_disconnect(widget_, handler_);
    }
  }

 private:
  static void Unrealize(GtkWidget*, gpointer data) {
    static_cast<UnrealizeRelease*>(data)->entered_.Signal();
  }
  static gpointer Run(gpointer data) {
    auto* self = static_cast<UnrealizeRelease*>(data);
    EXPECT_TRUE(self->entered_.Wait()) << "GTK did not enter unrealize";
    EXPECT_EQ(g_atomic_int_get(&self->counts_->finalized[kCompositor]), 0);
    EXPECT_EQ(g_atomic_int_get(&self->counts_->finalized[kEGL]), 0);
    EXPECT_EQ(g_atomic_int_get(&self->counts_->finalized[kChild]), 0);
    self->raster_->Release();
    self->done_.Signal();
    return nullptr;
  }
  GtkWidget* widget_;
  RasterThread* raster_;
  Counts* counts_;
  Gate entered_;
  Gate done_;
  gulong handler_;
  GThread* thread_;
};

static void drain_main_context() {
  gint64 deadline = g_get_monotonic_time() + kTimeout;
  while (g_main_context_pending(nullptr)) {
    ASSERT_LT(g_get_monotonic_time(), deadline);
    g_main_context_iteration(nullptr, FALSE);
  }
}

class FlViewRendererWaylandLifetimeTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // LinuxTest forces X11 and links mocked Wayland/EGL; this executable must
    // initialize GTK itself. Skipping never counts as realized coverage.
    static gboolean gtk_initialized = []() {
      GLogLevelFlags fatal = g_log_set_always_fatal(G_LOG_LEVEL_ERROR);
      g_log_set_always_fatal(
          static_cast<GLogLevelFlags>(fatal | G_LOG_LEVEL_CRITICAL));
      g_setenv("GTK_IM_MODULE", "gtk-im-context-simple", FALSE);
      gdk_set_allowed_backends("wayland");
      return gtk_init_check(nullptr, nullptr);
    }();
    if (!gtk_initialized) {
      GTEST_SKIP()
          << "A real Wayland compositor is required (e.g. headless Weston)";
    }
    ASSERT_TRUE(GDK_IS_WAYLAND_DISPLAY(gdk_display_get_default()));
    counts_ = g_atomic_rc_box_new0(Counts);
    counts_->main_thread = g_thread_self();
    current_counts = counts_;
    g_autoptr(FlDartProject) project = fl_dart_project_new();
    // Do not start the native engine: Shutdown joins the raster thread, which
    // is intentionally held by this test. The objects and all graphics calls
    // here are real; only engine execution is absent.
    engine_ = fl_engine_new(project);
    observe(G_OBJECT(engine_), counts_, kEngine);
    manager_ = fl_engine_get_opengl_manager(engine_);
    observe(G_OBJECT(manager_), counts_, kManager);
    observe(G_OBJECT(fl_engine_get_task_runner(engine_)), counts_, kRunner);
    ASSERT_NE(fl_opengl_manager_get_display(manager_), EGL_NO_DISPLAY);
    ASSERT_NE(fl_opengl_manager_get_context(manager_), EGL_NO_CONTEXT);
    counts_->display = fl_opengl_manager_get_display(manager_);
    static gboolean printed_versions = FALSE;
    if (!printed_versions) {
      EGLDisplay display = fl_opengl_manager_get_display(manager_);
      g_print(
          "GTK %u.%u.%u; GLib %u.%u.%u\nEGL vendor: %s\nEGL version: %s\n"
          "EGL extensions: %s\n",
          gtk_get_major_version(), gtk_get_minor_version(),
          gtk_get_micro_version(), glib_major_version, glib_minor_version,
          glib_micro_version, eglQueryString(display, EGL_VENDOR),
          eglQueryString(display, EGL_VERSION),
          eglQueryString(display, EGL_EXTENSIONS));
      printed_versions = TRUE;
    }

    window_ = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    g_object_ref_sink(window_);
    gtk_window_set_default_size(GTK_WINDOW(window_), kFrameSize, kFrameSize);
    renderer_ =
        FL_VIEW_RENDERER(fl_view_renderer_subsurface_new(engine_, TRUE));
    g_object_ref_sink(renderer_);
    observe(G_OBJECT(renderer_), counts_, kRenderer);
    gtk_container_add(GTK_CONTAINER(window_), GTK_WIDGET(renderer_));
    gtk_widget_show_all(window_);
    drain_main_context();
    ASSERT_TRUE(gtk_widget_get_realized(GTK_WIDGET(renderer_)));
    GdkWindow* parent = gtk_widget_get_window(window_);
    ASSERT_TRUE(GDK_IS_WAYLAND_WINDOW(parent));
    ASSERT_NE(gdk_wayland_window_get_wl_surface(parent), nullptr);
    ASSERT_EQ(counts_->parent, gdk_wayland_window_get_wl_surface(parent));
    ASSERT_EQ(g_atomic_int_get(&counts_->created[kChild]), 1);
    ASSERT_EQ(g_atomic_int_get(&counts_->created[kEGL]), 1);
    ASSERT_TRUE(fl_opengl_manager_clear_current(manager_));

    // Require a completed nonzero-layer present before any destruction race.
    Present();
    ASSERT_GT(g_atomic_int_get(&counts_->composites), 0);
    ASSERT_GT(g_atomic_int_get(&counts_->presents), 0);
    ASSERT_GT(g_atomic_int_get(&counts_->child_contexts), 0);
    ASSERT_GT(g_atomic_int_get(&counts_->wakes), 0);
    drain_main_context();
    CheckProtocol();
  }

  void TearDown() override {
    if (window_ != nullptr) {
      gtk_widget_destroy(window_);
      g_clear_object(&window_);
    }
    // Unrealize clears the GTK thread's child context. Framebuffer cleanup at
    // the final owner/idle release still needs a current shared GL context.
    EGLDisplay display = MakeCurrentForFinalization();
    g_clear_object(&renderer_);
    g_clear_object(&engine_);
    drain_main_context();
    if (display != EGL_NO_DISPLAY) {
      EXPECT_TRUE(eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE,
                                 EGL_NO_CONTEXT));
    }
    if (counts_ != nullptr) {
      for (int i = 0; i < kResourceCount; ++i) {
        EXPECT_EQ(g_atomic_int_get(&counts_->finalized[i]),
                  g_atomic_int_get(&counts_->created[i]))
            << "Resource " << i;
      }
      EXPECT_EQ(g_atomic_int_get(&counts_->finalized_on_main[kRenderer]), 1);
      EXPECT_EQ(g_atomic_int_get(&counts_->finalized_on_main[kManager]), 1);
      EXPECT_EQ(g_atomic_int_get(&counts_->finalized_on_main[kRunner]), 1);
      CheckProtocol();
      current_counts = nullptr;
      g_atomic_rc_box_release(counts_);
      counts_ = nullptr;
    }
  }

  void Present(gboolean without_fences = FALSE, gboolean zero_layers = FALSE) {
    RasterThread raster(counts_, renderer_, manager_, Pause::kNone,
                        without_fences, zero_layers);
    raster.Join();
  }

  EGLDisplay MakeCurrentForFinalization() {
    if (manager_ == nullptr ||
        g_atomic_int_get(&counts_->finalized[kManager]) != 0) {
      return EGL_NO_DISPLAY;
    }
    EXPECT_TRUE(fl_opengl_manager_make_current(manager_));
    return fl_opengl_manager_get_display(manager_);
  }

  void CheckProtocol() {
    struct wl_display* display =
        gdk_wayland_display_get_wl_display(gdk_display_get_default());
    // A sync on a private queue checks for protocol errors without dispatching
    // the renderer's GTK idle or blocking indefinitely in roundtrip().
    struct wl_event_queue* queue = wl_display_create_queue(display);
    auto* wrapper =
        static_cast<struct wl_display*>(wl_proxy_create_wrapper(display));
    wl_proxy_set_queue(reinterpret_cast<struct wl_proxy*>(wrapper), queue);
    struct wl_callback* callback = wl_display_sync(wrapper);
    wl_proxy_wrapper_destroy(wrapper);
    gboolean done = FALSE;
    static const struct wl_callback_listener listener = {
        [](gpointer data, struct wl_callback*, uint32_t) {
          *static_cast<gboolean*>(data) = TRUE;
        }};
    wl_callback_add_listener(callback, &listener, &done);
    gint64 deadline = g_get_monotonic_time() + kTimeout;
    while (!done && g_get_monotonic_time() < deadline) {
      if (wl_display_prepare_read_queue(display, queue) != 0) {
        if (wl_display_dispatch_queue_pending(display, queue) < 0) {
          break;
        }
        continue;
      }
      int flushed = wl_display_flush(display);
      if (flushed < 0 && errno != EAGAIN) {
        wl_display_cancel_read(display);
        break;
      }
      struct pollfd fd = {wl_display_get_fd(display), POLLIN, 0};
      if (flushed < 0) {
        fd.events |= POLLOUT;
      }
      gint64 remaining = deadline - g_get_monotonic_time();
      int timeout = static_cast<int>(MAX(gint64{0}, (remaining + 999) / 1000));
      int result = poll(&fd, 1, timeout);
      if (result <= 0 || !(fd.revents & POLLIN)) {
        wl_display_cancel_read(display);
        if (result < 0 && errno != EINTR) {
          break;
        }
        continue;
      }
      if (wl_display_read_events(display) < 0 ||
          wl_display_dispatch_queue_pending(display, queue) < 0) {
        break;
      }
    }
    EXPECT_TRUE(done) << "Wayland sync failed or timed out";
    EXPECT_EQ(wl_display_get_error(display), 0);
    wl_callback_destroy(callback);
    wl_event_queue_destroy(queue);
  }

  void CheckChildrenReleased() {
    EXPECT_EQ(g_atomic_int_get(&counts_->finalized[kCompositor]), 1);
    EXPECT_EQ(g_atomic_int_get(&counts_->finalized[kEGL]), 1);
    EXPECT_EQ(g_atomic_int_get(&counts_->finalized[kChild]), 1);
  }

  Counts* counts_ = nullptr;
  FlEngine* engine_ = nullptr;
  FlOpenGLManager* manager_ =
      nullptr;  // Borrowed; do not mask renderer ownership.
  FlViewRenderer* renderer_ = nullptr;
  GtkWidget* window_ = nullptr;
};

class FlViewRendererWaylandRaceTest
    : public FlViewRendererWaylandLifetimeTest,
      public ::testing::WithParamInterface<std::tuple<Pause, bool, bool>> {};

TEST_P(FlViewRendererWaylandRaceTest, DestroyOrUnrealizeDuringPresentation) {
  Pause pause = std::get<0>(GetParam());
  gboolean destroy = std::get<1>(GetParam());
  gboolean without_fences = std::get<2>(GetParam());
  if (!without_fences && !fl_opengl_manager_can_fence(manager_)) {
    GTEST_SKIP() << "Native fence lifetime requires EGL_KHR_fence_sync";
  }
  RecordProperty("fence_path", without_fences
                                   ? "glFinish"
                                   : (fl_opengl_manager_can_wait_sync(manager_)
                                          ? "eglWaitSyncKHR"
                                          : "eglClientWaitSyncKHR"));
  RasterThread raster(counts_, renderer_, manager_, pause, without_fences,
                      FALSE);
  ASSERT_TRUE(raster.WaitForEntry()) << "Linker wrapper was not reached";
  if (pause == Pause::kBeforeWake) {
    // The frame mutex has been released, but the task runner and scoped fence
    // are still in use. No main-context dispatch occurs until the worker joins.
    if (destroy) {
      gtk_widget_destroy(GTK_WIDGET(renderer_));
    } else {
      gtk_widget_unrealize(GTK_WIDGET(renderer_));
    }
    CheckChildrenReleased();
    if (!destroy) {
      gtk_widget_destroy(GTK_WIDGET(renderer_));
    }
    g_clear_object(&engine_);
    EXPECT_EQ(g_atomic_int_get(&counts_->finalized[kEngine]), 1);
    EXPECT_EQ(g_atomic_int_get(&counts_->finalized[kManager]), 0);
    EXPECT_EQ(g_atomic_int_get(&counts_->finalized[kRunner]), 0);
    EXPECT_EQ(g_atomic_int_get(&counts_->finalized[kRenderer]), 0);
    EXPECT_EQ(g_atomic_int_get(&counts_->created[kFence]) -
                  g_atomic_int_get(&counts_->finalized[kFence]),
              without_fences ? 0 : 1);
  } else {
    GSignalQuery query = {};
    g_signal_query(g_signal_lookup("unrealize", GTK_TYPE_WIDGET), &query);
    ASSERT_NE(query.signal_flags & G_SIGNAL_RUN_LAST, 0);
    UnrealizeRelease release(GTK_WIDGET(renderer_), &raster, counts_);
    if (destroy) {
      gtk_widget_destroy(GTK_WIDGET(renderer_));
    } else {
      gtk_widget_unrealize(GTK_WIDGET(renderer_));
    }
    CheckChildrenReleased();
    if (!destroy) {
      // Keep the visible parent from re-realizing the explicitly unrealized
      // child when the pending GTK work is eventually dispatched.
      gtk_widget_destroy(GTK_WIDGET(renderer_));
    }
  }
  raster.Join();
  EXPECT_EQ(g_atomic_int_get(&counts_->created[kFence]),
            g_atomic_int_get(&counts_->finalized[kFence]));
  EXPECT_EQ(g_atomic_int_get(&counts_->finalized[kRenderer]), 0);
  drain_main_context();
  CheckProtocol();
}

INSTANTIATE_TEST_SUITE_P(
    RealWayland,
    FlViewRendererWaylandRaceTest,
    ::testing::Combine(::testing::Values(Pause::kComposite,
                                         Pause::kPresent,
                                         Pause::kBeforeWake),
                       ::testing::Bool(),
                       ::testing::Bool()));

TEST_F(FlViewRendererWaylandLifetimeTest, DestroyBeforeQueuedRedraw) {
  // Present returns after enqueueing the GTK idle. Keep it pending across
  // destruction and engine finalization, then let the idle release its owner.
  Present();
  gtk_widget_destroy(GTK_WIDGET(renderer_));
  CheckChildrenReleased();
  g_clear_object(&engine_);
  EGLDisplay display = MakeCurrentForFinalization();
  g_clear_object(&renderer_);
  EXPECT_EQ(g_atomic_int_get(&counts_->finalized[kRenderer]), 0);
  EXPECT_EQ(g_atomic_int_get(&counts_->finalized[kManager]), 0);
  EXPECT_EQ(g_atomic_int_get(&counts_->finalized[kRunner]), 0);
  drain_main_context();
  EXPECT_EQ(g_atomic_int_get(&counts_->finalized[kRenderer]), 1);
  EXPECT_EQ(g_atomic_int_get(&counts_->finalized[kManager]), 1);
  EXPECT_EQ(g_atomic_int_get(&counts_->finalized[kRunner]), 1);
  EXPECT_TRUE(
      eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT));
}

TEST_F(FlViewRendererWaylandLifetimeTest,
       HideShowReplacesParentAndPresentsAgain) {
  struct wl_surface* old_parent = counts_->parent;
  uint32_t old_parent_id = counts_->parent_id;
  gtk_widget_hide(window_);
  ASSERT_TRUE(gtk_widget_get_realized(GTK_WIDGET(renderer_)));
  EXPECT_EQ(gdk_wayland_window_get_wl_surface(gtk_widget_get_window(window_)),
            nullptr);
  gtk_widget_show_all(window_);
  drain_main_context();
  EXPECT_TRUE(counts_->parent != old_parent ||
              counts_->parent_id != old_parent_id);
  EXPECT_EQ(g_atomic_int_get(&counts_->created[kChild]), 2);
  EXPECT_EQ(g_atomic_int_get(&counts_->created[kEGL]), 2);
  EXPECT_EQ(g_atomic_int_get(&counts_->finalized[kChild]), 1);
  EXPECT_EQ(g_atomic_int_get(&counts_->finalized[kEGL]), 1);
  int presents = g_atomic_int_get(&counts_->presents);
  Present();
  Present(TRUE, TRUE);  // A zero-layer frame clears the existing real frame.
  EXPECT_EQ(g_atomic_int_get(&counts_->presents), presents + 2);
  CheckProtocol();
}

TEST_F(FlViewRendererWaylandLifetimeTest, UnrealizedRendererDropsFrames) {
  gtk_widget_unrealize(GTK_WIDGET(renderer_));
  CheckChildrenReleased();
  int composites = g_atomic_int_get(&counts_->composites);
  int presents = g_atomic_int_get(&counts_->presents);
  Present();
  EXPECT_EQ(g_atomic_int_get(&counts_->composites), composites);
  EXPECT_EQ(g_atomic_int_get(&counts_->presents), presents);
  // Do not re-realize: the existing realize path overwrites its retained task
  // runner reference. That separate leak is not changed by the lifetime fix.
}

}  // namespace

// These must have C linkage and remain separate from production translation
// units. The runtime counters and barriers fail if --wrap is bypassed.
extern "C" {
void __real_fl_compositor_opengl_composite_layers(FlCompositorOpenGL*,
                                                  const FlutterLayer**,
                                                  size_t);
void __wrap_fl_compositor_opengl_composite_layers(
    FlCompositorOpenGL* compositor,
    const FlutterLayer** layers,
    size_t layers_count) {
  __real_fl_compositor_opengl_composite_layers(compositor, layers,
                                               layers_count);
  if (current_presentation != nullptr) {
    observe(G_OBJECT(compositor), current_counts, kCompositor);
    g_atomic_int_inc(&current_counts->composites);
    current_presentation->StopAt(Pause::kComposite);
  }
}

gboolean __real_fl_compositor_opengl_can_fence(FlCompositorOpenGL*);
gboolean __wrap_fl_compositor_opengl_can_fence(FlCompositorOpenGL* compositor) {
  gboolean supported = __real_fl_compositor_opengl_can_fence(compositor);
  if (current_presentation != nullptr) {
    return supported && !current_presentation->without_fences;
  }
  return supported;
}

FlGLFence* __real_fl_gl_fence_new(FlOpenGLManager*);
FlGLFence* __wrap_fl_gl_fence_new(FlOpenGLManager* manager) {
  FlGLFence* fence = __real_fl_gl_fence_new(manager);
  if (current_counts != nullptr) {
    EXPECT_EQ(eglGetError(), static_cast<EGLint>(EGL_SUCCESS));
    observe(G_OBJECT(fence), current_counts, kFence);
  }
  return fence;
}

gboolean __real_fl_opengl_manager_make_current(FlOpenGLManager*);
gboolean __wrap_fl_opengl_manager_make_current(FlOpenGLManager* manager) {
  if (current_presentation != nullptr && current_presentation->in_present) {
    // Called from the real subsurface present just before restoring the engine
    // context. Prove that it actually used a distinct child context and native
    // EGL window surface, including on the glFinish path without a fence.
    EXPECT_EQ(eglGetCurrentDisplay(), fl_opengl_manager_get_display(manager));
    EXPECT_NE(eglGetCurrentContext(), EGL_NO_CONTEXT);
    EXPECT_NE(eglGetCurrentContext(), fl_opengl_manager_get_context(manager));
    EGLSurface surface = eglGetCurrentSurface(EGL_DRAW);
    EXPECT_NE(surface, EGL_NO_SURFACE);
    EGLint width = 0;
    EGLint height = 0;
    EXPECT_TRUE(
        eglQuerySurface(eglGetCurrentDisplay(), surface, EGL_WIDTH, &width));
    EXPECT_TRUE(
        eglQuerySurface(eglGetCurrentDisplay(), surface, EGL_HEIGHT, &height));
    EXPECT_GT(width, 0);
    EXPECT_GT(height, 0);
    EXPECT_EQ(eglGetError(), static_cast<EGLint>(EGL_SUCCESS));
    EXPECT_EQ(glGetError(), static_cast<GLenum>(GL_NO_ERROR));
    g_atomic_int_inc(&current_counts->child_contexts);
  }
  return __real_fl_opengl_manager_make_current(manager);
}

FlSubsurfaceEGL* __real_fl_subsurface_egl_new(FlOpenGLManager*,
                                              FlSubsurface*,
                                              size_t,
                                              size_t,
                                              gint);
FlSubsurfaceEGL* __wrap_fl_subsurface_egl_new(FlOpenGLManager* manager,
                                              FlSubsurface* subsurface,
                                              size_t width,
                                              size_t height,
                                              gint scale) {
  FlSubsurfaceEGL* egl =
      __real_fl_subsurface_egl_new(manager, subsurface, width, height, scale);
  if (current_counts != nullptr) {
    observe(G_OBJECT(egl), current_counts, kEGL);
  }
  return egl;
}

void __real_fl_subsurface_egl_present(FlSubsurfaceEGL*,
                                      GLuint,
                                      size_t,
                                      size_t,
                                      FlGLFence*);
void __wrap_fl_subsurface_egl_present(FlSubsurfaceEGL* egl,
                                      GLuint texture,
                                      size_t width,
                                      size_t height,
                                      FlGLFence* fence) {
  if (current_presentation != nullptr) {
    EXPECT_NE(texture, 0u);
    EXPECT_TRUE(glIsTexture(texture));
    current_presentation->in_present = TRUE;
  }
  __real_fl_subsurface_egl_present(egl, texture, width, height, fence);
  if (current_presentation != nullptr) {
    current_presentation->in_present = FALSE;
    g_atomic_int_inc(&current_counts->presents);
    current_presentation->StopAt(Pause::kPresent);
  }
}

void __real_fl_task_runner_stop_wait(FlTaskRunner*);
void __wrap_fl_task_runner_stop_wait(FlTaskRunner* runner) {
  if (current_presentation != nullptr) {
    current_presentation->StopAt(Pause::kBeforeWake);
    EXPECT_EQ(g_atomic_int_get(&current_counts->finalized[kRunner]), 0);
    EXPECT_EQ(g_atomic_int_get(&current_counts->finalized[kManager]), 0);
    g_atomic_int_inc(&current_counts->wakes);
  }
  __real_fl_task_runner_stop_wait(runner);
}

FlSubsurface* __real_fl_wayland_display_create_subsurface(FlWaylandDisplay*,
                                                          struct wl_surface*);
FlSubsurface* __wrap_fl_wayland_display_create_subsurface(
    FlWaylandDisplay* display,
    struct wl_surface* parent) {
  FlSubsurface* subsurface =
      __real_fl_wayland_display_create_subsurface(display, parent);
  if (current_counts != nullptr) {
    EXPECT_NE(parent, nullptr);
    EXPECT_NE(fl_subsurface_get_surface(subsurface), nullptr);
    current_counts->parent = parent;
    current_counts->parent_id =
        wl_proxy_get_id(reinterpret_cast<struct wl_proxy*>(parent));
    observe(G_OBJECT(subsurface), current_counts, kChild);
  }
  return subsurface;
}
}  // extern "C"
