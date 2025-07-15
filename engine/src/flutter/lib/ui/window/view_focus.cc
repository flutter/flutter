// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/window/view_focus.h"

namespace flutter {
ViewFocusChangeRequest::ViewFocusChangeRequest(int64_t view_id,
                                               ViewFocusState state,
                                               ViewFocusDirection direction)
    : view_id_(view_id), state_(state), direction_(direction) {}

int64_t ViewFocusChangeRequest::view_id() const {
  return view_id_;
}
ViewFocusState ViewFocusChangeRequest::state() const {
  return state_;
}
ViewFocusDirection ViewFocusChangeRequest::direction() const {
  return direction_;
}

}  // namespace flutter
