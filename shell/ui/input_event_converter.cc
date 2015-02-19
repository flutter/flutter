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

  web_event->timeStampMS =
      base::TimeDelta::FromInternalValue(event->time_stamp).InMillisecondsF();

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
  }

  return web_event.Pass();
}

}  // namespace

scoped_ptr<blink::WebInputEvent> ConvertEvent(const InputEventPtr& event,
                                              float device_pixel_ratio) {
  if (event->type == EVENT_TYPE_POINTER_DOWN ||
      event->type == EVENT_TYPE_POINTER_UP ||
      event->type == EVENT_TYPE_POINTER_MOVE ||
      event->type == EVENT_TYPE_POINTER_CANCEL) {
    return BuildWebPointerEvent(event, device_pixel_ratio);
  }

  return scoped_ptr<blink::WebInputEvent>();
}

}  // namespace mojo
