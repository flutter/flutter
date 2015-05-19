// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "sky/engine/public/sky/sky_view.h"

#include "base/bind.h"
#include "sky/engine/core/script/dart_controller.h"
#include "sky/engine/core/script/dom_dart_state.h"
#include "sky/engine/core/view/View.h"
#include "sky/engine/platform/weborigin/KURL.h"
#include "sky/engine/public/sky/sky_view_client.h"

namespace blink {

class SkyView::Data {
 public:
  RefPtr<View> view_;
};

std::unique_ptr<SkyView> SkyView::Create(SkyViewClient* client) {
  return std::unique_ptr<SkyView>(new SkyView(client));
}

SkyView::SkyView(SkyViewClient* client)
    : client_(client),
      data_(new Data),
      weak_factory_(this) {
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
  data_->view_ = View::create(base::Bind(
      &SkyView::SchedulePaint, weak_factory_.GetWeakPtr()));

  dart_controller_.reset(new DartController);
  dart_controller_->CreateIsolateFor(adoptPtr(new DOMDartState(nullptr)), url);
  dart_controller_->InstallView(data_->view_.get());
  dart_controller_->LoadMainLibrary(url);
}

skia::RefPtr<SkPicture> SkyView::Paint() {
  if (Picture* picture = data_->view_->picture())
    return skia::SharePtr(picture->toSkia());
  return skia::RefPtr<SkPicture>();
}

bool SkyView::HandleInputEvent(const WebInputEvent& event) {
  return false;
}

void SkyView::SchedulePaint() {
  client_->SchedulePaint();
}

} // namespace blink
