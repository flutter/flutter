// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/public/sky/sky_headless.h"

#include "sky/engine/core/script/dart_controller.h"
#include "sky/engine/core/script/dom_dart_state.h"

namespace blink {

SkyHeadless::SkyHeadless() {
}

SkyHeadless::~SkyHeadless() {
}

void SkyHeadless::Init(const String& name) {
  DCHECK(!dart_controller_);

  dart_controller_ = adoptPtr(new DartController);
  dart_controller_->CreateIsolateFor(adoptPtr(new DOMDartState(name)));
}

void SkyHeadless::RunFromSnapshotBuffer(const uint8_t* buffer, size_t size) {
  dart_controller_->RunFromSnapshotBuffer(buffer, size);
}

} // namespace blink
