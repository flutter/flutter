// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/gesture_detection/gesture_provider.h"

#include <cmath>

#include "base/auto_reset.h"
#include "base/trace_event/trace_event.h"
#include "ui/events/event_constants.h"
#include "ui/events/gesture_detection/gesture_event_data.h"
#include "ui/events/gesture_detection/gesture_listeners.h"
#include "ui/events/gesture_detection/motion_event.h"
#include "ui/events/gesture_detection/scale_gesture_listeners.h"
#include "ui/gfx/geometry/point_f.h"

namespace ui {
namespace {

// Double-tap drag zoom sensitivity (speed).
const float kDoubleTapDragZoomSpeed = 0.005f;

const char* GetMotionEventActionName(MotionEvent::Action action) {
  switch (action) {
    case MotionEvent::ACTION_POINTER_DOWN:
      return "ACTION_POINTER_DOWN";
    case MotionEvent::ACTION_POINTER_UP:
      return "ACTION_POINTER_UP";
    case MotionEvent::ACTION_DOWN:
      return "ACTION_DOWN";
    case MotionEvent::ACTION_UP:
      return "ACTION_UP";
    case MotionEvent::ACTION_CANCEL:
      return "ACTION_CANCEL";
    case MotionEvent::ACTION_MOVE:
      return "ACTION_MOVE";
  }
  return "";
}

gfx::RectF ClampBoundingBox(const gfx::RectF& bounds,
                            float min_length,
                            float max_length) {
  float width = bounds.width();
  float height = bounds.height();
  if (min_length) {
    width = std::max(min_length, width);
    height = std::max(min_length, height);
  }
  if (max_length) {
    width = std::min(max_length, width);
    height = std::min(max_length, height);
  }
  const gfx::PointF center = bounds.CenterPoint();
  return gfx::RectF(
      center.x() - width / 2.f, center.y() - height / 2.f, width, height);
}

}  // namespace

// GestureProvider:::Config

GestureProvider::Config::Config()
    : display(gfx::Display::kInvalidDisplayID, gfx::Rect(1, 1)),
      disable_click_delay(false),
      gesture_begin_end_types_enabled(false),
      min_gesture_bounds_length(0),
      max_gesture_bounds_length(0) {
}

GestureProvider::Config::~Config() {
}

// GestureProvider::GestureListener

class GestureProvider::GestureListenerImpl : public ScaleGestureListener,
                                             public GestureListener,
                                             public DoubleTapListener {
 public:
  GestureListenerImpl(const GestureProvider::Config& config,
                      GestureProviderClient* client)
      : config_(config),
        client_(client),
        gesture_detector_(config.gesture_detector_config, this, this),
        scale_gesture_detector_(config.scale_gesture_detector_config, this),
        snap_scroll_controller_(config.display),
        ignore_multitouch_zoom_events_(false),
        ignore_single_tap_(false),
        pinch_event_sent_(false),
        scroll_event_sent_(false),
        max_diameter_before_show_press_(0),
        show_press_event_sent_(false) {}

  void OnTouchEvent(const MotionEvent& event) {
    const bool in_scale_gesture = IsScaleGestureDetectionInProgress();
    snap_scroll_controller_.SetSnapScrollingMode(event, in_scale_gesture);
    if (in_scale_gesture)
      SetIgnoreSingleTap(true);

    const MotionEvent::Action action = event.GetAction();
    if (action == MotionEvent::ACTION_DOWN) {
      current_down_time_ = event.GetEventTime();
      current_longpress_time_ = base::TimeTicks();
      ignore_single_tap_ = false;
      scroll_event_sent_ = false;
      pinch_event_sent_ = false;
      show_press_event_sent_ = false;
      gesture_detector_.set_longpress_enabled(true);
      tap_down_point_ = gfx::PointF(event.GetX(), event.GetY());
      max_diameter_before_show_press_ = event.GetTouchMajor();
    }

    gesture_detector_.OnTouchEvent(event);
    scale_gesture_detector_.OnTouchEvent(event);

    if (action == MotionEvent::ACTION_UP ||
        action == MotionEvent::ACTION_CANCEL) {
      // Note: This call will have no effect if a fling was just generated, as
      // |Fling()| will have already signalled an end to touch-scrolling.
      if (scroll_event_sent_)
        Send(CreateGesture(ET_GESTURE_SCROLL_END, event));
      current_down_time_ = base::TimeTicks();
    } else if (action == MotionEvent::ACTION_MOVE) {
      if (!show_press_event_sent_ && !scroll_event_sent_) {
        max_diameter_before_show_press_ =
            std::max(max_diameter_before_show_press_, event.GetTouchMajor());
      }
    }
  }

  void Send(GestureEventData gesture) {
    DCHECK(!gesture.time.is_null());
    // The only valid events that should be sent without an active touch
    // sequence are SHOW_PRESS and TAP, potentially triggered by the double-tap
    // delay timing out.
    DCHECK(!current_down_time_.is_null() || gesture.type() == ET_GESTURE_TAP ||
           gesture.type() == ET_GESTURE_SHOW_PRESS ||
           gesture.type() == ET_GESTURE_BEGIN ||
           gesture.type() == ET_GESTURE_END);

    if (gesture.primary_tool_type == MotionEvent::TOOL_TYPE_UNKNOWN ||
        gesture.primary_tool_type == MotionEvent::TOOL_TYPE_FINGER) {
      gesture.details.set_bounding_box(
          ClampBoundingBox(gesture.details.bounding_box_f(),
                           config_.min_gesture_bounds_length,
                           config_.max_gesture_bounds_length));
    }

    switch (gesture.type()) {
      case ET_GESTURE_LONG_PRESS:
        DCHECK(!IsScaleGestureDetectionInProgress());
        current_longpress_time_ = gesture.time;
        break;
      case ET_GESTURE_LONG_TAP:
        current_longpress_time_ = base::TimeTicks();
        break;
      case ET_GESTURE_SCROLL_BEGIN:
        DCHECK(!scroll_event_sent_);
        scroll_event_sent_ = true;
        break;
      case ET_GESTURE_SCROLL_END:
        DCHECK(scroll_event_sent_);
        if (pinch_event_sent_)
          Send(GestureEventData(ET_GESTURE_PINCH_END, gesture));
        scroll_event_sent_ = false;
        break;
      case ET_SCROLL_FLING_START:
        DCHECK(scroll_event_sent_);
        scroll_event_sent_ = false;
        break;
      case ET_GESTURE_PINCH_BEGIN:
        DCHECK(!pinch_event_sent_);
        if (!scroll_event_sent_)
          Send(GestureEventData(ET_GESTURE_SCROLL_BEGIN, gesture));
        pinch_event_sent_ = true;
        break;
      case ET_GESTURE_PINCH_END:
        DCHECK(pinch_event_sent_);
        pinch_event_sent_ = false;
        break;
      case ET_GESTURE_SHOW_PRESS:
        // It's possible that a double-tap drag zoom (from ScaleGestureDetector)
        // will start before the press gesture fires (from GestureDetector), in
        // which case the press should simply be dropped.
        if (pinch_event_sent_ || scroll_event_sent_)
          return;
      default:
        break;
    };

    client_->OnGestureEvent(gesture);
    GestureTouchUMAHistogram::RecordGestureEvent(gesture);
  }

  // ScaleGestureListener implementation.
  bool OnScaleBegin(const ScaleGestureDetector& detector,
                    const MotionEvent& e) override {
    if (ignore_multitouch_zoom_events_ && !detector.InDoubleTapMode())
      return false;
    return true;
  }

  void OnScaleEnd(const ScaleGestureDetector& detector,
                  const MotionEvent& e) override {
    if (!pinch_event_sent_)
      return;
    Send(CreateGesture(ET_GESTURE_PINCH_END, e));
  }

  bool OnScale(const ScaleGestureDetector& detector,
               const MotionEvent& e) override {
    if (ignore_multitouch_zoom_events_ && !detector.InDoubleTapMode())
      return false;
    if (!pinch_event_sent_) {
      Send(CreateGesture(ET_GESTURE_PINCH_BEGIN,
                         e.GetId(),
                         e.GetToolType(),
                         detector.GetEventTime(),
                         detector.GetFocusX(),
                         detector.GetFocusY(),
                         detector.GetFocusX() + e.GetRawOffsetX(),
                         detector.GetFocusY() + e.GetRawOffsetY(),
                         e.GetPointerCount(),
                         GetBoundingBox(e, ET_GESTURE_PINCH_BEGIN),
                         e.GetFlags()));
    }

    if (std::abs(detector.GetCurrentSpan() - detector.GetPreviousSpan()) <
        config_.scale_gesture_detector_config.min_pinch_update_span_delta) {
      return false;
    }

    float scale = detector.GetScaleFactor();
    if (scale == 1)
      return true;

    if (detector.InDoubleTapMode()) {
      // Relative changes in the double-tap scale factor computed by |detector|
      // diminish as the touch moves away from the original double-tap focus.
      // For historical reasons, Chrome has instead adopted a scale factor
      // computation that is invariant to the focal distance, where
      // the scale delta remains constant if the touch velocity is constant.
      float dy =
          (detector.GetCurrentSpanY() - detector.GetPreviousSpanY()) * 0.5f;
      scale = std::pow(scale > 1 ? 1.0f + kDoubleTapDragZoomSpeed
                                 : 1.0f - kDoubleTapDragZoomSpeed,
                       std::abs(dy));
    }
    GestureEventDetails pinch_details(ET_GESTURE_PINCH_UPDATE);
    pinch_details.set_scale(scale);
    Send(CreateGesture(pinch_details,
                       e.GetId(),
                       e.GetToolType(),
                       detector.GetEventTime(),
                       detector.GetFocusX(),
                       detector.GetFocusY(),
                       detector.GetFocusX() + e.GetRawOffsetX(),
                       detector.GetFocusY() + e.GetRawOffsetY(),
                       e.GetPointerCount(),
                       GetBoundingBox(e, pinch_details.type()),
                       e.GetFlags()));
    return true;
  }

  // GestureListener implementation.
  bool OnDown(const MotionEvent& e) override {
    GestureEventDetails tap_details(ET_GESTURE_TAP_DOWN);
    Send(CreateGesture(tap_details, e));

    // Return true to indicate that we want to handle touch.
    return true;
  }

  bool OnScroll(const MotionEvent& e1,
                const MotionEvent& e2,
                float raw_distance_x,
                float raw_distance_y) override {
    float distance_x = raw_distance_x;
    float distance_y = raw_distance_y;
    if (!scroll_event_sent_) {
      // Remove the touch slop region from the first scroll event to avoid a
      // jump.
      float distance =
          std::sqrt(distance_x * distance_x + distance_y * distance_y);
      float epsilon = 1e-3f;
      if (distance > epsilon) {
        float ratio =
            std::max(0.f,
                     distance - config_.gesture_detector_config.touch_slop) /
            distance;
        distance_x *= ratio;
        distance_y *= ratio;
      }

      // Note that scroll start hints are in distance traveled, where
      // scroll deltas are in the opposite direction.
      GestureEventDetails scroll_details(
          ET_GESTURE_SCROLL_BEGIN, -raw_distance_x, -raw_distance_y);

      // Use the co-ordinates from the touch down, as these co-ordinates are
      // used to determine which layer the scroll should affect.
      Send(CreateGesture(scroll_details,
                         e2.GetId(),
                         e2.GetToolType(),
                         e2.GetEventTime(),
                         e1.GetX(),
                         e1.GetY(),
                         e1.GetRawX(),
                         e1.GetRawY(),
                         e2.GetPointerCount(),
                         GetBoundingBox(e2, scroll_details.type()),
                         e2.GetFlags()));
      DCHECK(scroll_event_sent_);
    }

    snap_scroll_controller_.UpdateSnapScrollMode(distance_x, distance_y);
    if (snap_scroll_controller_.IsSnappingScrolls()) {
      if (snap_scroll_controller_.IsSnapHorizontal())
        distance_y = 0;
      else
        distance_x = 0;
    }

    if (distance_x || distance_y) {
      GestureEventDetails scroll_details(
          ET_GESTURE_SCROLL_UPDATE, -distance_x, -distance_y);
      const gfx::RectF bounding_box = GetBoundingBox(e2, scroll_details.type());
      const gfx::PointF center = bounding_box.CenterPoint();
      const gfx::PointF raw_center =
          center + gfx::Vector2dF(e2.GetRawOffsetX(), e2.GetRawOffsetY());
      Send(CreateGesture(scroll_details,
                         e2.GetId(),
                         e2.GetToolType(),
                         e2.GetEventTime(),
                         center.x(),
                         center.y(),
                         raw_center.x(),
                         raw_center.y(),
                         e2.GetPointerCount(),
                         bounding_box,
                         e2.GetFlags()));
    }

    return true;
  }

  bool OnFling(const MotionEvent& e1,
               const MotionEvent& e2,
               float velocity_x,
               float velocity_y) override {
    if (snap_scroll_controller_.IsSnappingScrolls()) {
      if (snap_scroll_controller_.IsSnapHorizontal()) {
        velocity_y = 0;
      } else {
        velocity_x = 0;
      }
    }

    if (!velocity_x && !velocity_y)
      return true;

    if (!scroll_event_sent_) {
      // The native side needs a ET_GESTURE_SCROLL_BEGIN before
      // ET_SCROLL_FLING_START to send the fling to the correct target.
      // The distance traveled in one second is a reasonable scroll start hint.
      GestureEventDetails scroll_details(
          ET_GESTURE_SCROLL_BEGIN, velocity_x, velocity_y);
      Send(CreateGesture(scroll_details, e2));
    }

    GestureEventDetails fling_details(
        ET_SCROLL_FLING_START, velocity_x, velocity_y);
    Send(CreateGesture(fling_details, e2));
    return true;
  }

  bool OnSwipe(const MotionEvent& e1,
               const MotionEvent& e2,
               float velocity_x,
               float velocity_y) override {
    GestureEventDetails swipe_details(ET_GESTURE_SWIPE, velocity_x, velocity_y);
    Send(CreateGesture(swipe_details, e2));
    return true;
  }

  bool OnTwoFingerTap(const MotionEvent& e1, const MotionEvent& e2) override {
    // The location of the two finger tap event should be the location of the
    // primary pointer.
    GestureEventDetails two_finger_tap_details(
        ET_GESTURE_TWO_FINGER_TAP, e1.GetTouchMajor(), e1.GetTouchMajor());
    Send(CreateGesture(two_finger_tap_details,
                       e2.GetId(),
                       e2.GetToolType(),
                       e2.GetEventTime(),
                       e1.GetX(),
                       e1.GetY(),
                       e1.GetRawX(),
                       e1.GetRawY(),
                       e2.GetPointerCount(),
                       GetBoundingBox(e2, two_finger_tap_details.type()),
                       e2.GetFlags()));
    return true;
  }

  void OnShowPress(const MotionEvent& e) override {
    GestureEventDetails show_press_details(ET_GESTURE_SHOW_PRESS);
    show_press_event_sent_ = true;
    Send(CreateGesture(show_press_details, e));
  }

  bool OnSingleTapUp(const MotionEvent& e) override {
    // This is a hack to address the issue where user hovers
    // over a link for longer than double_tap_timeout_, then
    // OnSingleTapConfirmed() is not triggered. But we still
    // want to trigger the tap event at UP. So we override
    // OnSingleTapUp() in this case. This assumes singleTapUp
    // gets always called before singleTapConfirmed.
    if (!ignore_single_tap_) {
      if (e.GetEventTime() - current_down_time_ >
          config_.gesture_detector_config.double_tap_timeout) {
        return OnSingleTapConfirmed(e);
      } else if (!IsDoubleTapEnabled() || config_.disable_click_delay) {
        // If double-tap has been disabled, there is no need to wait
        // for the double-tap timeout.
        return OnSingleTapConfirmed(e);
      } else {
        // Notify Blink about this tapUp event anyway, when none of the above
        // conditions applied.
        Send(CreateTapGesture(ET_GESTURE_TAP_UNCONFIRMED, e));
      }
    }

    if (e.GetAction() == MotionEvent::ACTION_UP &&
        !current_longpress_time_.is_null() &&
        !IsScaleGestureDetectionInProgress()) {
      GestureEventDetails long_tap_details(ET_GESTURE_LONG_TAP);
      Send(CreateGesture(long_tap_details, e));
      return true;
    }

    return false;
  }

  // DoubleTapListener implementation.
  bool OnSingleTapConfirmed(const MotionEvent& e) override {
    // Long taps in the edges of the screen have their events delayed by
    // ContentViewHolder for tab swipe operations. As a consequence of the delay
    // this method might be called after receiving the up event.
    // These corner cases should be ignored.
    if (ignore_single_tap_)
      return true;

    ignore_single_tap_ = true;

    Send(CreateTapGesture(ET_GESTURE_TAP, e));
    return true;
  }

  bool OnDoubleTap(const MotionEvent& e) override {
    return scale_gesture_detector_.OnDoubleTap(e);
  }

  bool OnDoubleTapEvent(const MotionEvent& e) override {
    switch (e.GetAction()) {
      case MotionEvent::ACTION_DOWN:
        gesture_detector_.set_longpress_enabled(false);
        break;

      case MotionEvent::ACTION_UP:
        if (!IsPinchInProgress() && !IsScrollInProgress()) {
          Send(CreateTapGesture(ET_GESTURE_DOUBLE_TAP, e));
          return true;
        }
        break;

      default:
        break;
    }
    return false;
  }

  void OnLongPress(const MotionEvent& e) override {
    DCHECK(!IsDoubleTapInProgress());
    SetIgnoreSingleTap(true);
    GestureEventDetails long_press_details(ET_GESTURE_LONG_PRESS);
    Send(CreateGesture(long_press_details, e));
  }

  GestureEventData CreateGesture(const GestureEventDetails& details,
                                 int motion_event_id,
                                 MotionEvent::ToolType primary_tool_type,
                                 base::TimeTicks time,
                                 float x,
                                 float y,
                                 float raw_x,
                                 float raw_y,
                                 size_t touch_point_count,
                                 const gfx::RectF& bounding_box,
                                 int flags) {
    return GestureEventData(details,
                            motion_event_id,
                            primary_tool_type,
                            time,
                            x,
                            y,
                            raw_x,
                            raw_y,
                            touch_point_count,
                            bounding_box,
                            flags);
  }

  GestureEventData CreateGesture(EventType type,
                                 int motion_event_id,
                                 MotionEvent::ToolType primary_tool_type,
                                 base::TimeTicks time,
                                 float x,
                                 float y,
                                 float raw_x,
                                 float raw_y,
                                 size_t touch_point_count,
                                 const gfx::RectF& bounding_box,
                                 int flags) {
    return GestureEventData(GestureEventDetails(type),
                            motion_event_id,
                            primary_tool_type,
                            time,
                            x,
                            y,
                            raw_x,
                            raw_y,
                            touch_point_count,
                            bounding_box,
                            flags);
  }

  GestureEventData CreateGesture(const GestureEventDetails& details,
                                 const MotionEvent& event) {
    return GestureEventData(details,
                            event.GetId(),
                            event.GetToolType(),
                            event.GetEventTime(),
                            event.GetX(),
                            event.GetY(),
                            event.GetRawX(),
                            event.GetRawY(),
                            event.GetPointerCount(),
                            GetBoundingBox(event, details.type()),
                            event.GetFlags());
  }

  GestureEventData CreateGesture(EventType type, const MotionEvent& event) {
    return CreateGesture(GestureEventDetails(type), event);
  }

  GestureEventData CreateTapGesture(EventType type, const MotionEvent& event) {
    // Set the tap count to 1 even for ET_GESTURE_DOUBLE_TAP, in order to be
    // consistent with double tap behavior on a mobile viewport. See
    // crbug.com/234986 for context.
    GestureEventDetails details(type);
    details.set_tap_count(1);
    return CreateGesture(details, event);
  }

  gfx::RectF GetBoundingBox(const MotionEvent& event, EventType type) {
    // Can't use gfx::RectF::Union, as it ignores touches with a radius of 0.
    float left = std::numeric_limits<float>::max();
    float top = std::numeric_limits<float>::max();
    float right = -std::numeric_limits<float>::max();
    float bottom = -std::numeric_limits<float>::max();
    for (size_t i = 0; i < event.GetPointerCount(); ++i) {
      float x, y, diameter;
      // Only for the show press and tap events, the bounding box is calculated
      // based on the touch start point and the maximum diameter before the
      // show press event is sent.
      if (type == ET_GESTURE_SHOW_PRESS || type == ET_GESTURE_TAP ||
          type == ET_GESTURE_TAP_UNCONFIRMED) {
        DCHECK_EQ(0U, i);
        diameter = max_diameter_before_show_press_;
        x = tap_down_point_.x();
        y = tap_down_point_.y();
      } else {
        diameter = event.GetTouchMajor(i);
        x = event.GetX(i);
        y = event.GetY(i);
      }
      x = x - diameter / 2;
      y = y - diameter / 2;
      left = std::min(left, x);
      right = std::max(right, x + diameter);
      top = std::min(top, y);
      bottom = std::max(bottom, y + diameter);
    }
    return gfx::RectF(left, top, right - left, bottom - top);
  }

  void SetDoubleTapEnabled(bool enabled) {
    DCHECK(!IsDoubleTapInProgress());
    gesture_detector_.SetDoubleTapListener(enabled ? this : NULL);
  }

  void SetMultiTouchZoomEnabled(bool enabled) {
    // Note that returning false from |OnScaleBegin()| or |OnScale()| prevents
    // the detector from emitting further scale updates for the current touch
    // sequence. Thus, if multitouch events are enabled in the middle of a
    // gesture, it will only take effect with the next gesture.
    ignore_multitouch_zoom_events_ = !enabled;
  }

  bool IsDoubleTapInProgress() const {
    return gesture_detector_.is_double_tapping() ||
           (IsScaleGestureDetectionInProgress() && InDoubleTapMode());
  }

  bool IsScrollInProgress() const { return scroll_event_sent_; }

  bool IsPinchInProgress() const { return pinch_event_sent_; }

 private:
  bool IsScaleGestureDetectionInProgress() const {
    return scale_gesture_detector_.IsInProgress();
  }

  bool InDoubleTapMode() const {
    return scale_gesture_detector_.InDoubleTapMode();
  }

  bool IsDoubleTapEnabled() const {
    return gesture_detector_.has_doubletap_listener();
  }

  void SetIgnoreSingleTap(bool value) { ignore_single_tap_ = value; }

  const GestureProvider::Config config_;
  GestureProviderClient* const client_;

  GestureDetector gesture_detector_;
  ScaleGestureDetector scale_gesture_detector_;
  SnapScrollController snap_scroll_controller_;

  base::TimeTicks current_down_time_;

  // Keeps track of the current GESTURE_LONG_PRESS event. If a context menu is
  // opened after a GESTURE_LONG_PRESS, this is used to insert a
  // GESTURE_TAP_CANCEL for removing any ::active styling.
  base::TimeTicks current_longpress_time_;

  // Completely silence multi-touch (pinch) scaling events. Used in WebView when
  // zoom support is turned off.
  bool ignore_multitouch_zoom_events_;

  // TODO(klobag): This is to avoid a bug in GestureDetector. With multi-touch,
  // always_in_tap_region_ is not reset. So when the last finger is up,
  // |OnSingleTapUp()| will be mistakenly fired.
  bool ignore_single_tap_;

  // Tracks whether {PINCH|SCROLL}_BEGIN events have been forwarded for the
  // current touch sequence.
  bool pinch_event_sent_;
  bool scroll_event_sent_;

  // Only track the maximum diameter before the show press event has been
  // sent and a tap must still be possible for this touch sequence.
  float max_diameter_before_show_press_;

  gfx::PointF tap_down_point_;

  // Tracks whether an ET_GESTURE_SHOW_PRESS event has been sent for this touch
  // sequence.
  bool show_press_event_sent_;

  DISALLOW_COPY_AND_ASSIGN(GestureListenerImpl);
};

// GestureProvider

GestureProvider::GestureProvider(const Config& config,
                                 GestureProviderClient* client)
    : double_tap_support_for_page_(true),
      double_tap_support_for_platform_(true),
      gesture_begin_end_types_enabled_(config.gesture_begin_end_types_enabled) {
  DCHECK(client);
  DCHECK(!config.min_gesture_bounds_length ||
         !config.max_gesture_bounds_length ||
         config.min_gesture_bounds_length <= config.max_gesture_bounds_length);
  TRACE_EVENT0("input", "GestureProvider::InitGestureDetectors");
  gesture_listener_.reset(new GestureListenerImpl(config, client));
  UpdateDoubleTapDetectionSupport();
}

GestureProvider::~GestureProvider() {
}

bool GestureProvider::OnTouchEvent(const MotionEvent& event) {
  TRACE_EVENT1("input",
               "GestureProvider::OnTouchEvent",
               "action",
               GetMotionEventActionName(event.GetAction()));

  DCHECK_NE(0u, event.GetPointerCount());

  if (!CanHandle(event))
    return false;

  OnTouchEventHandlingBegin(event);
  gesture_listener_->OnTouchEvent(event);
  OnTouchEventHandlingEnd(event);
  uma_histogram_.RecordTouchEvent(event);
  return true;
}

void GestureProvider::SetMultiTouchZoomSupportEnabled(bool enabled) {
  gesture_listener_->SetMultiTouchZoomEnabled(enabled);
}

void GestureProvider::SetDoubleTapSupportForPlatformEnabled(bool enabled) {
  if (double_tap_support_for_platform_ == enabled)
    return;
  double_tap_support_for_platform_ = enabled;
  UpdateDoubleTapDetectionSupport();
}

void GestureProvider::SetDoubleTapSupportForPageEnabled(bool enabled) {
  if (double_tap_support_for_page_ == enabled)
    return;
  double_tap_support_for_page_ = enabled;
  UpdateDoubleTapDetectionSupport();
}

bool GestureProvider::IsScrollInProgress() const {
  return gesture_listener_->IsScrollInProgress();
}

bool GestureProvider::IsPinchInProgress() const {
  return gesture_listener_->IsPinchInProgress();
}

bool GestureProvider::IsDoubleTapInProgress() const {
  return gesture_listener_->IsDoubleTapInProgress();
}

bool GestureProvider::CanHandle(const MotionEvent& event) const {
  // Aura requires one cancel event per touch point, whereas Android requires
  // one cancel event per touch sequence. Thus we need to allow extra cancel
  // events.
  return current_down_event_ || event.GetAction() == MotionEvent::ACTION_DOWN ||
         event.GetAction() == MotionEvent::ACTION_CANCEL;
}

void GestureProvider::OnTouchEventHandlingBegin(const MotionEvent& event) {
  switch (event.GetAction()) {
    case MotionEvent::ACTION_DOWN:
      current_down_event_ = event.Clone();
      if (gesture_begin_end_types_enabled_)
        gesture_listener_->Send(
            gesture_listener_->CreateGesture(ET_GESTURE_BEGIN, event));
      break;
    case MotionEvent::ACTION_POINTER_DOWN:
      if (gesture_begin_end_types_enabled_) {
        const int action_index = event.GetActionIndex();
        gesture_listener_->Send(gesture_listener_->CreateGesture(
            ET_GESTURE_BEGIN,
            event.GetId(),
            event.GetToolType(),
            event.GetEventTime(),
            event.GetX(action_index),
            event.GetY(action_index),
            event.GetRawX(action_index),
            event.GetRawY(action_index),
            event.GetPointerCount(),
            gesture_listener_->GetBoundingBox(event, ET_GESTURE_BEGIN),
            event.GetFlags()));
      }
      break;
    case MotionEvent::ACTION_POINTER_UP:
    case MotionEvent::ACTION_UP:
    case MotionEvent::ACTION_CANCEL:
    case MotionEvent::ACTION_MOVE:
      break;
  }
}

void GestureProvider::OnTouchEventHandlingEnd(const MotionEvent& event) {
  switch (event.GetAction()) {
    case MotionEvent::ACTION_UP:
    case MotionEvent::ACTION_CANCEL: {
      if (gesture_begin_end_types_enabled_)
        gesture_listener_->Send(
            gesture_listener_->CreateGesture(ET_GESTURE_END, event));

      current_down_event_.reset();

      UpdateDoubleTapDetectionSupport();
      break;
    }
    case MotionEvent::ACTION_POINTER_UP:
      if (gesture_begin_end_types_enabled_)
        gesture_listener_->Send(
            gesture_listener_->CreateGesture(ET_GESTURE_END, event));
      break;
    case MotionEvent::ACTION_DOWN:
    case MotionEvent::ACTION_POINTER_DOWN:
    case MotionEvent::ACTION_MOVE:
      break;
  }
}

void GestureProvider::UpdateDoubleTapDetectionSupport() {
  // The GestureDetector requires that any provided DoubleTapListener remain
  // attached to it for the duration of a touch sequence. Defer any potential
  // null'ing of the listener until the sequence has ended.
  if (current_down_event_)
    return;

  const bool double_tap_enabled =
      double_tap_support_for_page_ && double_tap_support_for_platform_;
  gesture_listener_->SetDoubleTapEnabled(double_tap_enabled);
}

}  //  namespace ui
