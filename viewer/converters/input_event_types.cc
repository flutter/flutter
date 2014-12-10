// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/converters/input_event_types.h"

#include "base/logging.h"
#include "base/time/time.h"
#include "mojo/services/input_events/public/interfaces/input_event_constants.mojom.h"
#include "sky/engine/public/web/WebInputEvent.h"

namespace mojo {
namespace {

// Used for scrolling. This matches Firefox behavior.
const int kPixelsPerTick = 53;

int EventFlagsToWebEventModifiers(int flags) {
  int modifiers = 0;

  if (flags & mojo::EVENT_FLAGS_SHIFT_DOWN)
    modifiers |= blink::WebInputEvent::ShiftKey;
  if (flags & mojo::EVENT_FLAGS_CONTROL_DOWN)
    modifiers |= blink::WebInputEvent::ControlKey;
  if (flags & mojo::EVENT_FLAGS_ALT_DOWN)
    modifiers |= blink::WebInputEvent::AltKey;
  // TODO(beng): MetaKey/META_MASK
  if (flags & mojo::EVENT_FLAGS_LEFT_MOUSE_BUTTON)
    modifiers |= blink::WebInputEvent::LeftButtonDown;
  if (flags & mojo::EVENT_FLAGS_MIDDLE_MOUSE_BUTTON)
    modifiers |= blink::WebInputEvent::MiddleButtonDown;
  if (flags & mojo::EVENT_FLAGS_RIGHT_MOUSE_BUTTON)
    modifiers |= blink::WebInputEvent::RightButtonDown;
  if (flags & mojo::EVENT_FLAGS_CAPS_LOCK_DOWN)
    modifiers |= blink::WebInputEvent::CapsLockOn;
  return modifiers;
}

int EventFlagsToWebInputEventModifiers(int flags) {
  return
      (flags & mojo::EVENT_FLAGS_SHIFT_DOWN ?
       blink::WebInputEvent::ShiftKey : 0) |
      (flags & mojo::EVENT_FLAGS_CONTROL_DOWN ?
       blink::WebInputEvent::ControlKey : 0) |
      (flags & mojo::EVENT_FLAGS_CAPS_LOCK_DOWN ?
       blink::WebInputEvent::CapsLockOn : 0) |
      (flags & mojo::EVENT_FLAGS_ALT_DOWN ?
       blink::WebInputEvent::AltKey : 0);
}

int GetClickCount(int flags) {
  if (flags & mojo::MOUSE_EVENT_FLAGS_IS_TRIPLE_CLICK)
    return 3;
  else if (flags & mojo::MOUSE_EVENT_FLAGS_IS_DOUBLE_CLICK)
    return 2;

  return 1;
}

scoped_ptr<blink::WebInputEvent> BuildWebMouseEventFrom(const EventPtr& event) {
  scoped_ptr<blink::WebMouseEvent> web_event(new blink::WebMouseEvent);
  web_event->x = event->location_data->in_view_location->x;
  web_event->y = event->location_data->in_view_location->y;

  // TODO(erg): Remove this if check once we can rely on screen_location
  // actually being passed to us. As written today, getting the screen
  // location from ui::Event objects can only be done by querying the
  // underlying native events, so all synthesized events don't have screen
  // locations.
  if (!event->location_data->screen_location.is_null()) {
    web_event->globalX = event->location_data->screen_location->x;
    web_event->globalY = event->location_data->screen_location->y;
  }

  web_event->modifiers = EventFlagsToWebEventModifiers(event->flags);
  web_event->timeStampSeconds =
      base::TimeDelta::FromInternalValue(event->time_stamp).InSecondsF();

  web_event->button = blink::WebMouseEvent::ButtonNone;
  if (event->flags & mojo::EVENT_FLAGS_LEFT_MOUSE_BUTTON)
    web_event->button = blink::WebMouseEvent::ButtonLeft;
  if (event->flags & mojo::EVENT_FLAGS_MIDDLE_MOUSE_BUTTON)
    web_event->button = blink::WebMouseEvent::ButtonMiddle;
  if (event->flags & mojo::EVENT_FLAGS_RIGHT_MOUSE_BUTTON)
    web_event->button = blink::WebMouseEvent::ButtonRight;

  switch (event->action) {
    case EVENT_TYPE_MOUSE_PRESSED:
      web_event->type = blink::WebInputEvent::MouseDown;
      break;
    case EVENT_TYPE_MOUSE_RELEASED:
      web_event->type = blink::WebInputEvent::MouseUp;
      break;
    case EVENT_TYPE_MOUSE_ENTERED:
      web_event->type = blink::WebInputEvent::MouseLeave;
      web_event->button = blink::WebMouseEvent::ButtonNone;
      break;
    case EVENT_TYPE_MOUSE_EXITED:
    case EVENT_TYPE_MOUSE_MOVED:
    case EVENT_TYPE_MOUSE_DRAGGED:
      web_event->type = blink::WebInputEvent::MouseMove;
      break;
    default:
      NOTIMPLEMENTED() << "Received unexpected event: " << event->action;
      break;
  }

  web_event->clickCount = GetClickCount(event->flags);

  return web_event.Pass();
}

scoped_ptr<blink::WebInputEvent> BuildWebKeyboardEvent(
    const EventPtr& event) {
  scoped_ptr<blink::WebKeyboardEvent> web_event(new blink::WebKeyboardEvent);

  web_event->modifiers = EventFlagsToWebInputEventModifiers(event->flags);
  web_event->timeStampSeconds =
      base::TimeDelta::FromInternalValue(event->time_stamp).InSecondsF();

  switch (event->action) {
    case EVENT_TYPE_KEY_PRESSED:
      web_event->type = event->key_data->is_char ? blink::WebInputEvent::Char :
          blink::WebInputEvent::RawKeyDown;
      break;
    case EVENT_TYPE_KEY_RELEASED:
      web_event->type = blink::WebInputEvent::KeyUp;
      break;
    default:
      NOTREACHED();
  }

  if (web_event->modifiers & blink::WebInputEvent::AltKey)
    web_event->isSystemKey = true;

  web_event->windowsKeyCode = event->key_data->windows_key_code;
  web_event->nativeKeyCode = event->key_data->native_key_code;
  web_event->text[0] = event->key_data->text;
  web_event->unmodifiedText[0] = event->key_data->unmodified_text;

  web_event->setKeyIdentifierFromWindowsKeyCode();
  return web_event.Pass();
}

scoped_ptr<blink::WebInputEvent> BuildWebMouseWheelEventFrom(
    const EventPtr& event) {
  scoped_ptr<blink::WebMouseWheelEvent> web_event(
      new blink::WebMouseWheelEvent);
  web_event->type = blink::WebInputEvent::MouseWheel;
  web_event->button = blink::WebMouseEvent::ButtonNone;
  web_event->modifiers = EventFlagsToWebEventModifiers(event->flags);
  web_event->timeStampSeconds =
      base::TimeDelta::FromInternalValue(event->time_stamp).InSecondsF();

  web_event->x = event->location_data->in_view_location->x;
  web_event->y = event->location_data->in_view_location->y;

  // TODO(erg): Remove this null check as parallel to above.
  if (!event->location_data->screen_location.is_null()) {
    web_event->globalX = event->location_data->screen_location->x;
    web_event->globalY = event->location_data->screen_location->y;
  }

  if ((event->flags & mojo::EVENT_FLAGS_SHIFT_DOWN) != 0 &&
      event->wheel_data->x_offset == 0) {
    web_event->deltaX = event->wheel_data->y_offset;
    web_event->deltaY = 0;
  } else {
    web_event->deltaX = event->wheel_data->x_offset;
    web_event->deltaY = event->wheel_data->y_offset;
  }

  web_event->wheelTicksX = web_event->deltaX / kPixelsPerTick;
  web_event->wheelTicksY = web_event->deltaY / kPixelsPerTick;

  return web_event.Pass();
}

}  // namespace

// static
scoped_ptr<blink::WebInputEvent>
TypeConverter<scoped_ptr<blink::WebInputEvent>, EventPtr>::Convert(
    const EventPtr& event) {
  if (event->action == EVENT_TYPE_MOUSE_PRESSED ||
      event->action == EVENT_TYPE_MOUSE_RELEASED ||
      event->action == EVENT_TYPE_MOUSE_ENTERED ||
      event->action == EVENT_TYPE_MOUSE_EXITED ||
      event->action == EVENT_TYPE_MOUSE_MOVED ||
      event->action == EVENT_TYPE_MOUSE_DRAGGED) {
    return BuildWebMouseEventFrom(event);
  } else if ((event->action == EVENT_TYPE_KEY_PRESSED ||
              event->action == EVENT_TYPE_KEY_RELEASED) &&
             event->key_data) {
    return BuildWebKeyboardEvent(event);
  } else if (event->action == EVENT_TYPE_MOUSEWHEEL) {
    return BuildWebMouseWheelEventFrom(event);
  }

  return scoped_ptr<blink::WebInputEvent>();
}

}  // namespace mojo
