// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "view_manager/public/cpp/lib/view_private.h"

namespace mojo {

ViewPrivate::ViewPrivate(View* view)
    : view_(view) {
  CHECK(view);
}

ViewPrivate::~ViewPrivate() {
}

// static
View* ViewPrivate::LocalCreate() {
  return new View;
}

}  // namespace mojo
