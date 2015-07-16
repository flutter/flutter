// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/converters/input_events/mojo_extended_key_event_data.h"

namespace mojo {

MojoExtendedKeyEventData::MojoExtendedKeyEventData(int32_t windows_key_code,
                                                   uint16_t text,
                                                   uint16_t unmodified_text)
    : windows_key_code_(windows_key_code),
      text_(text),
      unmodified_text_(unmodified_text) {
}

MojoExtendedKeyEventData::~MojoExtendedKeyEventData() {}

ui::ExtendedKeyEventData* MojoExtendedKeyEventData::Clone() const {
  return new MojoExtendedKeyEventData(windows_key_code_,
                                      text_,
                                      unmodified_text_);
}

}  // namespace mojo
