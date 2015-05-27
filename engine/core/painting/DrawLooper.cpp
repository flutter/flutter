// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/painting/DrawLooper.h"

namespace blink {

DrawLooper::DrawLooper(PassRefPtr<SkDrawLooper> looper)
    : looper_(looper) {
}

DrawLooper::~DrawLooper() {
}

} // namespace blink
