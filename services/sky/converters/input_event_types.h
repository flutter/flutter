// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_CONVERTERS_INPUT_EVENT_TYPES_H_
#define SKY_VIEWER_CONVERTERS_INPUT_EVENT_TYPES_H_

#include "base/memory/scoped_ptr.h"
#include "mojo/services/input_events/interfaces/input_events.mojom.h"
#include "sky/services/pointer/pointer.mojom.h"

namespace blink {
class WebInputEvent;
}

namespace sky {
bool IsPointerEvent(const mojo::EventPtr& event);

scoped_ptr<blink::WebInputEvent> ConvertEvent(const mojo::EventPtr& event,
                                              float device_pixel_ratio);

pointer::PointerPacketPtr ConvertPointerEvent(const mojo::EventPtr& event,
                                              float device_pixel_ratio);
}

#endif  // SKY_VIEWER_CONVERTERS_INPUT_EVENT_TYPES_H_
