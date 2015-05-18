// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "sky/engine/public/sky/sky_view.h"

namespace blink {

std::unique_ptr<SkyView> SkyView::Create() {
  return std::unique_ptr<SkyView>(new SkyView);
}

SkyView::SkyView() {
}

SkyView::~SkyView() {
}

void SkyView::SetDisplayMetrics(const SkyDisplayMetrics& metrics) {
}

void SkyView::Load(const WebURL& url) {
}

skia::RefPtr<SkPicture> SkyView::Paint() {
  return skia::RefPtr<SkPicture>();
}

bool SkyView::HandleInputEvent(const WebInputEvent& event) {
  return false;
}

} // namespace blink
