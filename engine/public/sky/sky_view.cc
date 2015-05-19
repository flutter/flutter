// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "sky/engine/public/sky/sky_view.h"

#include "sky/engine/core/script/dart_controller.h"
#include "sky/engine/core/script/dom_dart_state.h"
#include "sky/engine/platform/weborigin/KURL.h"

namespace blink {

std::unique_ptr<SkyView> SkyView::Create() {
  return std::unique_ptr<SkyView>(new SkyView);
}

SkyView::SkyView() {
}

SkyView::~SkyView() {
  // TODO(abarth): Move this work into the DartController destructor once we
  // remove the Frame code path.
  if (dart_controller_)
    dart_controller_->ClearForClose();
}

void SkyView::SetDisplayMetrics(const SkyDisplayMetrics& metrics) {
}

void SkyView::Load(const WebURL& url) {
  dart_controller_.reset(new DartController);
  dart_controller_->CreateIsolateFor(adoptPtr(new DOMDartState(nullptr)), url);
  dart_controller_->LoadMainLibrary(url);
}

skia::RefPtr<SkPicture> SkyView::Paint() {
  return skia::RefPtr<SkPicture>();
}

bool SkyView::HandleInputEvent(const WebInputEvent& event) {
  return false;
}

} // namespace blink
