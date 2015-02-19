// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_UI_INPUT_EVENT_CONVERTER_H_
#define SKY_SHELL_UI_INPUT_EVENT_CONVERTER_H_

#include "base/memory/scoped_ptr.h"
#include "sky/services/viewport/input_event.mojom.h"

namespace blink {
class WebInputEvent;
}

namespace sky {

scoped_ptr<blink::WebInputEvent> ConvertEvent(const InputEventPtr& event,
                                              float device_pixel_ratio);
}

#endif  // SKY_SHELL_UI_INPUT_EVENT_CONVERTER_H_
