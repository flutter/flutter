// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_CONVERTERS_INPUT_EVENT_TYPES_H_
#define SKY_VIEWER_CONVERTERS_INPUT_EVENT_TYPES_H_

#include "base/memory/scoped_ptr.h"
#include "mojo/services/input_events/public/interfaces/input_events.mojom.h"

namespace blink {
class WebInputEvent;
}

namespace mojo {

template <>
struct TypeConverter<scoped_ptr<blink::WebInputEvent>, EventPtr> {
  static scoped_ptr<blink::WebInputEvent> Convert(const EventPtr& input);
};

}  // namespace mojo

#endif  // SKY_VIEWER_CONVERTERS_INPUT_EVENT_TYPES_H_
