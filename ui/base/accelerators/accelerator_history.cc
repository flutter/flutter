// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/base/accelerators/accelerator_history.h"
#include "ui/events/event_constants.h"

namespace ui {

// ----------------------------------------------------------------------
// Public Methods
// ----------------------------------------------------------------------

AcceleratorHistory::AcceleratorHistory()
  : current_accelerator_(),
    previous_accelerator_() {
}

AcceleratorHistory::~AcceleratorHistory() {
}

void AcceleratorHistory::StoreCurrentAccelerator(
                            const Accelerator& accelerator) {
  if (accelerator != current_accelerator_) {
    previous_accelerator_ = current_accelerator_;
    current_accelerator_ = accelerator;
  }
}

} // namespace ui
