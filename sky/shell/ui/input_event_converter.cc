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

scoped_ptr<blink::WebInputEvent> BuildWebBackEvent(const InputEventPtr& event) {
  scoped_ptr<blink::WebInputEvent> web_event(blink::WebInputEvent::create());
  web_event->type = blink::WebInputEvent::Back;
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
    case EVENT_TYPE_BACK:
      return BuildWebBackEvent(event);
    case EVENT_TYPE_UNKNOWN:
      NOTIMPLEMENTED() << "ConvertEvent received unexpected EVENT_TYPE_UNKNOWN";
  }

  return scoped_ptr<blink::WebInputEvent>();
}

}  // namespace mojo
