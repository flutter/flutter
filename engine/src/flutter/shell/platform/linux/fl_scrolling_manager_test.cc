// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_scrolling_manager.h"

#include <cstring>
#include <vector>

#include "gtest/gtest.h"
namespace {
typedef std::function<void(FlutterPointerPhase phase,
                           size_t timestamp,
                           double x,
                           double y,
                           FlutterPointerDeviceKind device_kind,
                           double scroll_delta_x,
                           double scroll_delta_y,
                           int64_t buttons)>
    MousePointerCallHandler;
typedef std::function<void(size_t timestamp,
                           double x,
                           double y,
                           FlutterPointerPhase phase,
                           double pan_x,
                           double pan_y,
                           double scale,
                           double rotation)>
    PointerPanZoomCallHandler;

typedef struct {
  FlutterPointerPhase phase;
  size_t timestamp;
  double x;
  double y;
  FlutterPointerDeviceKind device_kind;
  double scroll_delta_x;
  double scroll_delta_y;
  int64_t buttons;
} MousePointerEventRecord;

typedef struct {
  size_t timestamp;
  double x;
  double y;
  FlutterPointerPhase phase;
  double pan_x;
  double pan_y;
  double scale;
  double rotation;
} PointerPanZoomEventRecord;

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlMockScrollingViewDelegate,
                     fl_mock_scrolling_view_delegate,
                     FL,
                     MOCK_SCROLLING_VIEW_DELEGATE,
                     GObject)

G_END_DECLS

/***** FlMockScrollingViewDelegate *****/

struct _FlMockScrollingViewDelegate {
  GObject parent_instance;
};

struct FlMockScrollingViewDelegatePrivate {
  MousePointerCallHandler mouse_handler;
  PointerPanZoomCallHandler pan_zoom_handler;
};

static void fl_mock_view_scroll_delegate_iface_init(
    FlScrollingViewDelegateInterface* iface);

G_DEFINE_TYPE_WITH_CODE(
    FlMockScrollingViewDelegate,
    fl_mock_scrolling_view_delegate,
    G_TYPE_OBJECT,
    G_IMPLEMENT_INTERFACE(fl_scrolling_view_delegate_get_type(),
                          fl_mock_view_scroll_delegate_iface_init);
    G_ADD_PRIVATE(FlMockScrollingViewDelegate))

#define FL_MOCK_SCROLLING_VIEW_DELEGATE_GET_PRIVATE(obj)    \
  static_cast<FlMockScrollingViewDelegatePrivate*>(         \
      fl_mock_scrolling_view_delegate_get_instance_private( \
          FL_MOCK_SCROLLING_VIEW_DELEGATE(obj)))

static void fl_mock_scrolling_view_delegate_init(
    FlMockScrollingViewDelegate* self) {
  FlMockScrollingViewDelegatePrivate* priv =
      FL_MOCK_SCROLLING_VIEW_DELEGATE_GET_PRIVATE(self);

  new (priv) FlMockScrollingViewDelegatePrivate();
}

static void fl_mock_scrolling_view_delegate_dispose(GObject* object) {
  FL_MOCK_SCROLLING_VIEW_DELEGATE_GET_PRIVATE(object)
      ->~FlMockScrollingViewDelegatePrivate();

  G_OBJECT_CLASS(fl_mock_scrolling_view_delegate_parent_class)->dispose(object);
}

static void fl_mock_scrolling_view_delegate_class_init(
    FlMockScrollingViewDelegateClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_mock_scrolling_view_delegate_dispose;
}

static void fl_mock_view_send_mouse_pointer_event(
    FlScrollingViewDelegate* delegate,
    FlutterPointerPhase phase,
    size_t timestamp,
    double x,
    double y,
    FlutterPointerDeviceKind device_kind,
    double scroll_delta_x,
    double scroll_delta_y,
    int64_t buttons) {
  FlMockScrollingViewDelegatePrivate* priv =
      FL_MOCK_SCROLLING_VIEW_DELEGATE_GET_PRIVATE(delegate);
  priv->mouse_handler(phase, timestamp, x, y, device_kind, scroll_delta_x,
                      scroll_delta_y, buttons);
}

static void fl_mock_view_send_pointer_pan_zoom_event(
    FlScrollingViewDelegate* delegate,
    size_t timestamp,
    double x,
    double y,
    FlutterPointerPhase phase,
    double pan_x,
    double pan_y,
    double scale,
    double rotation) {
  FlMockScrollingViewDelegatePrivate* priv =
      FL_MOCK_SCROLLING_VIEW_DELEGATE_GET_PRIVATE(delegate);
  priv->pan_zoom_handler(timestamp, x, y, phase, pan_x, pan_y, scale, rotation);
}

static void fl_mock_view_scroll_delegate_iface_init(
    FlScrollingViewDelegateInterface* iface) {
  iface->send_mouse_pointer_event = fl_mock_view_send_mouse_pointer_event;
  iface->send_pointer_pan_zoom_event = fl_mock_view_send_pointer_pan_zoom_event;
}

static FlMockScrollingViewDelegate* fl_mock_scrolling_view_delegate_new() {
  FlMockScrollingViewDelegate* self = FL_MOCK_SCROLLING_VIEW_DELEGATE(
      g_object_new(fl_mock_scrolling_view_delegate_get_type(), nullptr));

  // Added to stop compiler complaining about an unused function.
  FL_IS_MOCK_SCROLLING_VIEW_DELEGATE(self);

  return self;
}

static void fl_mock_scrolling_view_set_mouse_handler(
    FlMockScrollingViewDelegate* self,
    MousePointerCallHandler handler) {
  FlMockScrollingViewDelegatePrivate* priv =
      FL_MOCK_SCROLLING_VIEW_DELEGATE_GET_PRIVATE(self);

  priv->mouse_handler = std::move(handler);
}

static void fl_mock_scrolling_view_set_pan_zoom_handler(
    FlMockScrollingViewDelegate* self,
    PointerPanZoomCallHandler handler) {
  FlMockScrollingViewDelegatePrivate* priv =
      FL_MOCK_SCROLLING_VIEW_DELEGATE_GET_PRIVATE(self);

  priv->pan_zoom_handler = std::move(handler);
}

/***** End FlMockScrollingViewDelegate *****/

class ScrollingTester {
 public:
  ScrollingTester() {
    view_ = fl_mock_scrolling_view_delegate_new();
    manager_ = fl_scrolling_manager_new(FL_SCROLLING_VIEW_DELEGATE(view_));
    fl_mock_scrolling_view_set_mouse_handler(
        view_,
        [](FlutterPointerPhase phase, size_t timestamp, double x, double y,
           FlutterPointerDeviceKind device_kind, double scroll_delta_x,
           double scroll_delta_y, int64_t buttons) {
          // do nothing
        });
    fl_mock_scrolling_view_set_pan_zoom_handler(
        view_,
        [](size_t timestamp, double x, double y, FlutterPointerPhase phase,
           double pan_x, double pan_y, double scale, double rotation) {
          // do nothing
        });
  }

  ~ScrollingTester() {
    g_clear_object(&view_);
    g_clear_object(&manager_);
  }

  FlScrollingManager* manager() { return manager_; }

  void recordMousePointerCallsTo(
      std::vector<MousePointerEventRecord>& storage) {
    fl_mock_scrolling_view_set_mouse_handler(
        view_, [&storage](FlutterPointerPhase phase, size_t timestamp, double x,
                          double y, FlutterPointerDeviceKind device_kind,
                          double scroll_delta_x, double scroll_delta_y,
                          int64_t buttons) {
          storage.push_back(MousePointerEventRecord{
              .phase = phase,
              .timestamp = timestamp,
              .x = x,
              .y = y,
              .device_kind = device_kind,
              .scroll_delta_x = scroll_delta_x,
              .scroll_delta_y = scroll_delta_y,
              .buttons = buttons,
          });
        });
  }

  void recordPointerPanZoomCallsTo(
      std::vector<PointerPanZoomEventRecord>& storage) {
    fl_mock_scrolling_view_set_pan_zoom_handler(
        view_, [&storage](size_t timestamp, double x, double y,
                          FlutterPointerPhase phase, double pan_x, double pan_y,
                          double scale, double rotation) {
          storage.push_back(PointerPanZoomEventRecord{
              .timestamp = timestamp,
              .x = x,
              .y = y,
              .phase = phase,
              .pan_x = pan_x,
              .pan_y = pan_y,
              .scale = scale,
              .rotation = rotation,
          });
        });
  }

 private:
  FlMockScrollingViewDelegate* view_;
  FlScrollingManager* manager_;
};

// Disgusting hack but could not find any way to create a GdkDevice
struct _FakeGdkDevice {
  GObject parent_instance;
  gchar* name;
  GdkInputSource source;
};
GdkDevice* makeFakeDevice(GdkInputSource source) {
  _FakeGdkDevice* device =
      static_cast<_FakeGdkDevice*>(g_malloc0(sizeof(_FakeGdkDevice)));
  device->source = source;
  // Bully the type checker
  (reinterpret_cast<GTypeInstance*>(device))->g_class =
      static_cast<GTypeClass*>(g_malloc0(sizeof(GTypeClass)));
  (reinterpret_cast<GTypeInstance*>(device))->g_class->g_type = GDK_TYPE_DEVICE;
  return reinterpret_cast<GdkDevice*>(device);
}

TEST(FlScrollingManagerTest, DiscreteDirectionional) {
  ScrollingTester tester;
  std::vector<MousePointerEventRecord> mouse_records;
  std::vector<PointerPanZoomEventRecord> pan_zoom_records;
  tester.recordMousePointerCallsTo(mouse_records);
  tester.recordPointerPanZoomCallsTo(pan_zoom_records);
  GdkDevice* mouse = makeFakeDevice(GDK_SOURCE_MOUSE);
  GdkEventScroll* event =
      reinterpret_cast<GdkEventScroll*>(gdk_event_new(GDK_SCROLL));
  event->time = 1;
  event->x = 4.0;
  event->y = 8.0;
  event->device = mouse;
  event->direction = GDK_SCROLL_UP;
  fl_scrolling_manager_handle_scroll_event(tester.manager(), event, 1.0);
  EXPECT_EQ(pan_zoom_records.size(), 0u);
  EXPECT_EQ(mouse_records.size(), 1u);
  EXPECT_EQ(mouse_records[0].x, 4.0);
  EXPECT_EQ(mouse_records[0].y, 8.0);
  EXPECT_EQ(mouse_records[0].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(mouse_records[0].timestamp,
            1000lu);  // Milliseconds -> Microseconds
  EXPECT_EQ(mouse_records[0].scroll_delta_x, 0);
  EXPECT_EQ(mouse_records[0].scroll_delta_y, 53 * -1.0);
  event->direction = GDK_SCROLL_DOWN;
  fl_scrolling_manager_handle_scroll_event(tester.manager(), event, 1.0);
  EXPECT_EQ(pan_zoom_records.size(), 0u);
  EXPECT_EQ(mouse_records.size(), 2u);
  EXPECT_EQ(mouse_records[1].x, 4.0);
  EXPECT_EQ(mouse_records[1].y, 8.0);
  EXPECT_EQ(mouse_records[1].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(mouse_records[1].timestamp,
            1000lu);  // Milliseconds -> Microseconds
  EXPECT_EQ(mouse_records[1].scroll_delta_x, 0);
  EXPECT_EQ(mouse_records[1].scroll_delta_y, 53 * 1.0);
  event->direction = GDK_SCROLL_LEFT;
  fl_scrolling_manager_handle_scroll_event(tester.manager(), event, 1.0);
  EXPECT_EQ(pan_zoom_records.size(), 0u);
  EXPECT_EQ(mouse_records.size(), 3u);
  EXPECT_EQ(mouse_records[2].x, 4.0);
  EXPECT_EQ(mouse_records[2].y, 8.0);
  EXPECT_EQ(mouse_records[2].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(mouse_records[2].timestamp,
            1000lu);  // Milliseconds -> Microseconds
  EXPECT_EQ(mouse_records[2].scroll_delta_x, 53 * -1.0);
  EXPECT_EQ(mouse_records[2].scroll_delta_y, 0);
  event->direction = GDK_SCROLL_RIGHT;
  fl_scrolling_manager_handle_scroll_event(tester.manager(), event, 1.0);
  EXPECT_EQ(pan_zoom_records.size(), 0u);
  EXPECT_EQ(mouse_records.size(), 4u);
  EXPECT_EQ(mouse_records[3].x, 4.0);
  EXPECT_EQ(mouse_records[3].y, 8.0);
  EXPECT_EQ(mouse_records[3].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(mouse_records[3].timestamp,
            1000lu);  // Milliseconds -> Microseconds
  EXPECT_EQ(mouse_records[3].scroll_delta_x, 53 * 1.0);
  EXPECT_EQ(mouse_records[3].scroll_delta_y, 0);
}

TEST(FlScrollingManagerTest, DiscreteScrolling) {
  ScrollingTester tester;
  std::vector<MousePointerEventRecord> mouse_records;
  std::vector<PointerPanZoomEventRecord> pan_zoom_records;
  tester.recordMousePointerCallsTo(mouse_records);
  tester.recordPointerPanZoomCallsTo(pan_zoom_records);
  GdkDevice* mouse = makeFakeDevice(GDK_SOURCE_MOUSE);
  GdkEventScroll* event =
      reinterpret_cast<GdkEventScroll*>(gdk_event_new(GDK_SCROLL));
  event->time = 1;
  event->x = 4.0;
  event->y = 8.0;
  event->delta_x = 1.0;
  event->delta_y = 2.0;
  event->device = mouse;
  event->direction = GDK_SCROLL_SMOOTH;
  fl_scrolling_manager_handle_scroll_event(tester.manager(), event, 1.0);
  EXPECT_EQ(pan_zoom_records.size(), 0u);
  EXPECT_EQ(mouse_records.size(), 1u);
  EXPECT_EQ(mouse_records[0].x, 4.0);
  EXPECT_EQ(mouse_records[0].y, 8.0);
  EXPECT_EQ(mouse_records[0].device_kind, kFlutterPointerDeviceKindMouse);
  EXPECT_EQ(mouse_records[0].timestamp,
            1000lu);  // Milliseconds -> Microseconds
  EXPECT_EQ(mouse_records[0].scroll_delta_x, 53 * 1.0);
  EXPECT_EQ(mouse_records[0].scroll_delta_y, 53 * 2.0);
}

TEST(FlScrollingManagerTest, Panning) {
  ScrollingTester tester;
  std::vector<MousePointerEventRecord> mouse_records;
  std::vector<PointerPanZoomEventRecord> pan_zoom_records;
  tester.recordMousePointerCallsTo(mouse_records);
  tester.recordPointerPanZoomCallsTo(pan_zoom_records);
  GdkDevice* touchpad = makeFakeDevice(GDK_SOURCE_TOUCHPAD);
  GdkEventScroll* event =
      reinterpret_cast<GdkEventScroll*>(gdk_event_new(GDK_SCROLL));
  event->time = 1;
  event->x = 4.0;
  event->y = 8.0;
  event->delta_x = 1.0;
  event->delta_y = 2.0;
  event->device = touchpad;
  event->direction = GDK_SCROLL_SMOOTH;
  fl_scrolling_manager_handle_scroll_event(tester.manager(), event, 1.0);
  EXPECT_EQ(pan_zoom_records.size(), 2u);
  EXPECT_EQ(mouse_records.size(), 0u);
  EXPECT_EQ(pan_zoom_records[0].x, 4.0);
  EXPECT_EQ(pan_zoom_records[0].y, 8.0);
  EXPECT_EQ(pan_zoom_records[0].timestamp,
            1000lu);  // Milliseconds -> Microseconds
  EXPECT_EQ(pan_zoom_records[0].phase, kPanZoomStart);
  EXPECT_EQ(pan_zoom_records[1].x, 4.0);
  EXPECT_EQ(pan_zoom_records[1].y, 8.0);
  EXPECT_EQ(pan_zoom_records[1].timestamp,
            1000lu);  // Milliseconds -> Microseconds
  EXPECT_EQ(pan_zoom_records[1].phase, kPanZoomUpdate);
  EXPECT_EQ(pan_zoom_records[1].pan_x, 53 * -1.0);  // directions get swapped
  EXPECT_EQ(pan_zoom_records[1].pan_y, 53 * -2.0);
  EXPECT_EQ(pan_zoom_records[1].scale, 1.0);
  EXPECT_EQ(pan_zoom_records[1].rotation, 0.0);
  fl_scrolling_manager_handle_scroll_event(tester.manager(), event, 1.0);
  EXPECT_EQ(pan_zoom_records.size(), 3u);
  EXPECT_EQ(mouse_records.size(), 0u);
  EXPECT_EQ(pan_zoom_records[2].x, 4.0);
  EXPECT_EQ(pan_zoom_records[2].y, 8.0);
  EXPECT_EQ(pan_zoom_records[2].timestamp,
            1000lu);  // Milliseconds -> Microseconds
  EXPECT_EQ(pan_zoom_records[2].phase, kPanZoomUpdate);
  EXPECT_EQ(pan_zoom_records[2].pan_x, 53 * -2.0);  // directions get swapped
  EXPECT_EQ(pan_zoom_records[2].pan_y, 53 * -4.0);
  EXPECT_EQ(pan_zoom_records[2].scale, 1.0);
  EXPECT_EQ(pan_zoom_records[2].rotation, 0.0);
  event->is_stop = true;
  fl_scrolling_manager_handle_scroll_event(tester.manager(), event, 1.0);
  EXPECT_EQ(pan_zoom_records.size(), 4u);
  EXPECT_EQ(mouse_records.size(), 0u);
  EXPECT_EQ(pan_zoom_records[3].x, 4.0);
  EXPECT_EQ(pan_zoom_records[3].y, 8.0);
  EXPECT_EQ(pan_zoom_records[3].timestamp,
            1000lu);  // Milliseconds -> Microseconds
  EXPECT_EQ(pan_zoom_records[3].phase, kPanZoomEnd);
}

TEST(FlScrollingManagerTest, Zooming) {
  ScrollingTester tester;
  std::vector<MousePointerEventRecord> mouse_records;
  std::vector<PointerPanZoomEventRecord> pan_zoom_records;
  tester.recordMousePointerCallsTo(mouse_records);
  tester.recordPointerPanZoomCallsTo(pan_zoom_records);
  size_t time_start = g_get_real_time();
  fl_scrolling_manager_handle_zoom_begin(tester.manager());
  EXPECT_EQ(pan_zoom_records.size(), 1u);
  EXPECT_EQ(mouse_records.size(), 0u);
  EXPECT_EQ(pan_zoom_records[0].x, 0);
  EXPECT_EQ(pan_zoom_records[0].y, 0);
  EXPECT_EQ(pan_zoom_records[0].phase, kPanZoomStart);
  EXPECT_GE(pan_zoom_records[0].timestamp, time_start);
  fl_scrolling_manager_handle_zoom_update(tester.manager(), 1.1);
  EXPECT_EQ(pan_zoom_records.size(), 2u);
  EXPECT_EQ(mouse_records.size(), 0u);
  EXPECT_EQ(pan_zoom_records[1].x, 0);
  EXPECT_EQ(pan_zoom_records[1].y, 0);
  EXPECT_EQ(pan_zoom_records[1].phase, kPanZoomUpdate);
  EXPECT_GE(pan_zoom_records[1].timestamp, pan_zoom_records[0].timestamp);
  EXPECT_EQ(pan_zoom_records[1].pan_x, 0);
  EXPECT_EQ(pan_zoom_records[1].pan_y, 0);
  EXPECT_EQ(pan_zoom_records[1].scale, 1.1);
  EXPECT_EQ(pan_zoom_records[1].rotation, 0);
  fl_scrolling_manager_handle_zoom_end(tester.manager());
  EXPECT_EQ(pan_zoom_records.size(), 3u);
  EXPECT_EQ(mouse_records.size(), 0u);
  EXPECT_EQ(pan_zoom_records[2].x, 0);
  EXPECT_EQ(pan_zoom_records[2].y, 0);
  EXPECT_EQ(pan_zoom_records[2].phase, kPanZoomEnd);
  EXPECT_GE(pan_zoom_records[2].timestamp, pan_zoom_records[1].timestamp);
}

TEST(FlScrollingManagerTest, Rotating) {
  ScrollingTester tester;
  std::vector<MousePointerEventRecord> mouse_records;
  std::vector<PointerPanZoomEventRecord> pan_zoom_records;
  tester.recordMousePointerCallsTo(mouse_records);
  tester.recordPointerPanZoomCallsTo(pan_zoom_records);
  size_t time_start = g_get_real_time();
  fl_scrolling_manager_handle_rotation_begin(tester.manager());
  EXPECT_EQ(pan_zoom_records.size(), 1u);
  EXPECT_EQ(mouse_records.size(), 0u);
  EXPECT_EQ(pan_zoom_records[0].x, 0);
  EXPECT_EQ(pan_zoom_records[0].y, 0);
  EXPECT_EQ(pan_zoom_records[0].phase, kPanZoomStart);
  EXPECT_GE(pan_zoom_records[0].timestamp, time_start);
  fl_scrolling_manager_handle_rotation_update(tester.manager(), 0.5);
  EXPECT_EQ(pan_zoom_records.size(), 2u);
  EXPECT_EQ(mouse_records.size(), 0u);
  EXPECT_EQ(pan_zoom_records[1].x, 0);
  EXPECT_EQ(pan_zoom_records[1].y, 0);
  EXPECT_EQ(pan_zoom_records[1].phase, kPanZoomUpdate);
  EXPECT_GE(pan_zoom_records[1].timestamp, pan_zoom_records[0].timestamp);
  EXPECT_EQ(pan_zoom_records[1].pan_x, 0);
  EXPECT_EQ(pan_zoom_records[1].pan_y, 0);
  EXPECT_EQ(pan_zoom_records[1].scale, 1.0);
  EXPECT_EQ(pan_zoom_records[1].rotation, 0.5);
  fl_scrolling_manager_handle_rotation_end(tester.manager());
  EXPECT_EQ(pan_zoom_records.size(), 3u);
  EXPECT_EQ(mouse_records.size(), 0u);
  EXPECT_EQ(pan_zoom_records[2].x, 0);
  EXPECT_EQ(pan_zoom_records[2].y, 0);
  EXPECT_EQ(pan_zoom_records[2].phase, kPanZoomEnd);
  EXPECT_GE(pan_zoom_records[2].timestamp, pan_zoom_records[1].timestamp);
}

TEST(FlScrollingManagerTest, SynchronizedZoomingAndRotating) {
  ScrollingTester tester;
  std::vector<MousePointerEventRecord> mouse_records;
  std::vector<PointerPanZoomEventRecord> pan_zoom_records;
  tester.recordMousePointerCallsTo(mouse_records);
  tester.recordPointerPanZoomCallsTo(pan_zoom_records);
  size_t time_start = g_get_real_time();
  fl_scrolling_manager_handle_zoom_begin(tester.manager());
  EXPECT_EQ(pan_zoom_records.size(), 1u);
  EXPECT_EQ(mouse_records.size(), 0u);
  EXPECT_EQ(pan_zoom_records[0].x, 0);
  EXPECT_EQ(pan_zoom_records[0].y, 0);
  EXPECT_EQ(pan_zoom_records[0].phase, kPanZoomStart);
  EXPECT_GE(pan_zoom_records[0].timestamp, time_start);
  fl_scrolling_manager_handle_zoom_update(tester.manager(), 1.1);
  EXPECT_EQ(pan_zoom_records.size(), 2u);
  EXPECT_EQ(mouse_records.size(), 0u);
  EXPECT_EQ(pan_zoom_records[1].x, 0);
  EXPECT_EQ(pan_zoom_records[1].y, 0);
  EXPECT_EQ(pan_zoom_records[1].phase, kPanZoomUpdate);
  EXPECT_GE(pan_zoom_records[1].timestamp, pan_zoom_records[0].timestamp);
  EXPECT_EQ(pan_zoom_records[1].pan_x, 0);
  EXPECT_EQ(pan_zoom_records[1].pan_y, 0);
  EXPECT_EQ(pan_zoom_records[1].scale, 1.1);
  EXPECT_EQ(pan_zoom_records[1].rotation, 0);
  fl_scrolling_manager_handle_rotation_begin(tester.manager());
  EXPECT_EQ(pan_zoom_records.size(), 2u);
  EXPECT_EQ(mouse_records.size(), 0u);
  fl_scrolling_manager_handle_rotation_update(tester.manager(), 0.5);
  EXPECT_EQ(pan_zoom_records.size(), 3u);
  EXPECT_EQ(pan_zoom_records[2].x, 0);
  EXPECT_EQ(pan_zoom_records[2].y, 0);
  EXPECT_EQ(pan_zoom_records[2].phase, kPanZoomUpdate);
  EXPECT_GE(pan_zoom_records[2].timestamp, pan_zoom_records[1].timestamp);
  EXPECT_EQ(pan_zoom_records[2].pan_x, 0);
  EXPECT_EQ(pan_zoom_records[2].pan_y, 0);
  EXPECT_EQ(pan_zoom_records[2].scale, 1.1);
  EXPECT_EQ(pan_zoom_records[2].rotation, 0.5);
  fl_scrolling_manager_handle_zoom_end(tester.manager());
  // End event should only be sent after both zoom and rotate complete.
  EXPECT_EQ(pan_zoom_records.size(), 3u);
  fl_scrolling_manager_handle_rotation_end(tester.manager());
  EXPECT_EQ(pan_zoom_records.size(), 4u);
  EXPECT_EQ(mouse_records.size(), 0u);
  EXPECT_EQ(pan_zoom_records[3].x, 0);
  EXPECT_EQ(pan_zoom_records[3].y, 0);
  EXPECT_EQ(pan_zoom_records[3].phase, kPanZoomEnd);
  EXPECT_GE(pan_zoom_records[3].timestamp, pan_zoom_records[2].timestamp);
}

// Make sure that zoom and rotate sequences which don't end at the same time
// don't cause any problems.
TEST(FlScrollingManagerTest, UnsynchronizedZoomingAndRotating) {
  ScrollingTester tester;
  std::vector<MousePointerEventRecord> mouse_records;
  std::vector<PointerPanZoomEventRecord> pan_zoom_records;
  tester.recordMousePointerCallsTo(mouse_records);
  tester.recordPointerPanZoomCallsTo(pan_zoom_records);
  size_t time_start = g_get_real_time();
  fl_scrolling_manager_handle_zoom_begin(tester.manager());
  EXPECT_EQ(pan_zoom_records.size(), 1u);
  EXPECT_EQ(mouse_records.size(), 0u);
  EXPECT_EQ(pan_zoom_records[0].x, 0);
  EXPECT_EQ(pan_zoom_records[0].y, 0);
  EXPECT_EQ(pan_zoom_records[0].phase, kPanZoomStart);
  EXPECT_GE(pan_zoom_records[0].timestamp, time_start);
  fl_scrolling_manager_handle_zoom_update(tester.manager(), 1.1);
  EXPECT_EQ(pan_zoom_records.size(), 2u);
  EXPECT_EQ(mouse_records.size(), 0u);
  EXPECT_EQ(pan_zoom_records[1].x, 0);
  EXPECT_EQ(pan_zoom_records[1].y, 0);
  EXPECT_EQ(pan_zoom_records[1].phase, kPanZoomUpdate);
  EXPECT_GE(pan_zoom_records[1].timestamp, pan_zoom_records[0].timestamp);
  EXPECT_EQ(pan_zoom_records[1].pan_x, 0);
  EXPECT_EQ(pan_zoom_records[1].pan_y, 0);
  EXPECT_EQ(pan_zoom_records[1].scale, 1.1);
  EXPECT_EQ(pan_zoom_records[1].rotation, 0);
  fl_scrolling_manager_handle_rotation_begin(tester.manager());
  EXPECT_EQ(pan_zoom_records.size(), 2u);
  EXPECT_EQ(mouse_records.size(), 0u);
  fl_scrolling_manager_handle_rotation_update(tester.manager(), 0.5);
  EXPECT_EQ(pan_zoom_records.size(), 3u);
  EXPECT_EQ(pan_zoom_records[2].x, 0);
  EXPECT_EQ(pan_zoom_records[2].y, 0);
  EXPECT_EQ(pan_zoom_records[2].phase, kPanZoomUpdate);
  EXPECT_GE(pan_zoom_records[2].timestamp, pan_zoom_records[1].timestamp);
  EXPECT_EQ(pan_zoom_records[2].pan_x, 0);
  EXPECT_EQ(pan_zoom_records[2].pan_y, 0);
  EXPECT_EQ(pan_zoom_records[2].scale, 1.1);
  EXPECT_EQ(pan_zoom_records[2].rotation, 0.5);
  fl_scrolling_manager_handle_zoom_end(tester.manager());
  EXPECT_EQ(pan_zoom_records.size(), 3u);
  fl_scrolling_manager_handle_rotation_update(tester.manager(), 1.0);
  EXPECT_EQ(pan_zoom_records.size(), 4u);
  EXPECT_EQ(mouse_records.size(), 0u);
  EXPECT_EQ(pan_zoom_records[3].x, 0);
  EXPECT_EQ(pan_zoom_records[3].y, 0);
  EXPECT_EQ(pan_zoom_records[3].phase, kPanZoomUpdate);
  EXPECT_GE(pan_zoom_records[3].timestamp, pan_zoom_records[2].timestamp);
  EXPECT_EQ(pan_zoom_records[3].pan_x, 0);
  EXPECT_EQ(pan_zoom_records[3].pan_y, 0);
  EXPECT_EQ(pan_zoom_records[3].scale, 1.1);
  EXPECT_EQ(pan_zoom_records[3].rotation, 1.0);
  fl_scrolling_manager_handle_rotation_end(tester.manager());
  EXPECT_EQ(pan_zoom_records.size(), 5u);
  EXPECT_EQ(mouse_records.size(), 0u);
  EXPECT_EQ(pan_zoom_records[4].x, 0);
  EXPECT_EQ(pan_zoom_records[4].y, 0);
  EXPECT_EQ(pan_zoom_records[4].phase, kPanZoomEnd);
  EXPECT_GE(pan_zoom_records[4].timestamp, pan_zoom_records[3].timestamp);
}

}  // namespace
