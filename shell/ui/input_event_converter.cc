// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/ui/input_event_converter.h"

#include "base/logging.h"
#include "base/time/time.h"
#include "sky/engine/public/platform/WebInputEvent.h"

namespace sky {
namespace {

scoped_ptr<blink::WebInputEvent> BuildWebPointerEvent(
    const InputEventPtr& event, float device_pixel_ratio) {
  scoped_ptr<blink::WebPointerEvent> web_event(new blink::WebPointerEvent);

  web_event->timeStampMS = event->time_stamp;

  switch (event->type) {
    case EVENT_TYPE_POINTER_DOWN:
      web_event->type = blink::WebInputEvent::PointerDown;
      break;
    case EVENT_TYPE_POINTER_UP:
      web_event->type = blink::WebInputEvent::PointerUp;
      break;
    case EVENT_TYPE_POINTER_MOVE:
      web_event->type = blink::WebInputEvent::PointerMove;
      break;
    case EVENT_TYPE_POINTER_CANCEL:
      web_event->type = blink::WebInputEvent::PointerCancel;
      break;
    default:
      NOTIMPLEMENTED() << "Received unexpected event: " << event->type;
      break;
  }

  if (event->pointer_data) {
    if (event->pointer_data->kind == POINTER_KIND_TOUCH)
        web_event->kind = blink::WebPointerEvent::Touch;
    web_event->pointer = event->pointer_data->pointer;
    web_event->x = event->pointer_data->x / device_pixel_ratio;
    web_event->y = event->pointer_data->y / device_pixel_ratio;
    web_event->pressure = event->pointer_data->pressure;
    web_event->pressureMin = event->pointer_data->pressure_min;
    web_event->pressureMax = event->pointer_data->pressure_max;
  }

  return web_event.Pass();
}

scoped_ptr<blink::WebInputEvent> BuildWebGestureEvent(
    const InputEventPtr& event, float device_pixel_ratio) {
  scoped_ptr<blink::WebGestureEvent> web_event(new blink::WebGestureEvent);

  web_event->timeStampMS = event->time_stamp;

  switch (event->type) {
    case EVENT_TYPE_GESTURE_SCROLL_BEGIN:
      web_event->type = blink::WebInputEvent::GestureScrollBegin;
      break;
    case EVENT_TYPE_GESTURE_SCROLL_END:
      web_event->type = blink::WebInputEvent::GestureScrollEnd;
      break;
    case EVENT_TYPE_GESTURE_SCROLL_UPDATE:
      web_event->type = blink::WebInputEvent::GestureScrollUpdate;
      web_event->data.scrollUpdate.deltaX =
          event->gesture_data->dx / device_pixel_ratio;
      web_event->data.scrollUpdate.deltaY =
          event->gesture_data->dy / device_pixel_ratio;
      break;
    case EVENT_TYPE_GESTURE_FLING_START:
      web_event->type = blink::WebInputEvent::GestureFlingStart;
      web_event->data.flingStart.velocityX =
          event->gesture_data->velocityX / device_pixel_ratio;
      web_event->data.flingStart.velocityY =
          event->gesture_data->velocityY / device_pixel_ratio;
      break;
    case EVENT_TYPE_GESTURE_FLING_CANCEL:
      web_event->type = blink::WebInputEvent::GestureFlingCancel;
      break;
    default:
      break;
  }

  if (event->gesture_data) {
    web_event->x = event->gesture_data->x / device_pixel_ratio;
    web_event->y = event->gesture_data->y / device_pixel_ratio;
  }

  return web_event.Pass();
}

}  // namespace

scoped_ptr<blink::WebInputEvent> ConvertEvent(const InputEventPtr& event,
                                              float device_pixel_ratio) {
  switch (event->type) {
    case EVENT_TYPE_POINTER_DOWN:
    case EVENT_TYPE_POINTER_UP:
    case EVENT_TYPE_POINTER_MOVE:
    case EVENT_TYPE_POINTER_CANCEL:
      return BuildWebPointerEvent(event, device_pixel_ratio);
    case EVENT_TYPE_GESTURE_SCROLL_BEGIN:
    case EVENT_TYPE_GESTURE_SCROLL_UPDATE:
    case EVENT_TYPE_GESTURE_SCROLL_END:
    case EVENT_TYPE_GESTURE_FLING_START:
    case EVENT_TYPE_GESTURE_FLING_CANCEL:
      return BuildWebGestureEvent(event, device_pixel_ratio);
    case EVENT_TYPE_UNKNOWN:
      NOTIMPLEMENTED() << "ConvertEvent received unexpected EVENT_TYPE_UNKNOWN";
  }

  return scoped_ptr<blink::WebInputEvent>();
}

}  // namespace mojo
