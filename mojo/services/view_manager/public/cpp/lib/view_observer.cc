// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "view_manager/public/cpp/view_observer.h"

namespace mojo {

////////////////////////////////////////////////////////////////////////////////
// ViewObserver, public:

ViewObserver::TreeChangeParams::TreeChangeParams()
    : target(nullptr),
      old_parent(nullptr),
      new_parent(nullptr),
      receiver(nullptr) {
}

}  // namespace mojo
