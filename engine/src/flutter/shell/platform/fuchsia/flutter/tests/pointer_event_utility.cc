// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "pointer_event_utility.h"

namespace flutter_runner::testing {

using fup_EventPhase = fuchsia::ui::pointer::EventPhase;
using fup_TouchEvent = fuchsia::ui::pointer::TouchEvent;
using fup_TouchIxnId = fuchsia::ui::pointer::TouchInteractionId;
using fup_TouchIxnResult = fuchsia::ui::pointer::TouchInteractionResult;
using fup_TouchPointerSample = fuchsia::ui::pointer::TouchPointerSample;
using fup_ViewParameters = fuchsia::ui::pointer::ViewParameters;

TouchEventBuilder TouchEventBuilder::New() {
  return TouchEventBuilder();
}

TouchEventBuilder& TouchEventBuilder::AddTime(zx_time_t time) {
  time_ = time;
  return *this;
}

TouchEventBuilder& TouchEventBuilder::AddSample(fup_TouchIxnId id,
                                                fup_EventPhase phase,
                                                std::array<float, 2> position) {
  sample_ = std::make_optional<fup_TouchPointerSample>();
  sample_->set_interaction(id);
  sample_->set_phase(phase);
  sample_->set_position_in_viewport(position);
  return *this;
}

TouchEventBuilder& TouchEventBuilder::AddViewParameters(
    std::array<std::array<float, 2>, 2> view,
    std::array<std::array<float, 2>, 2> viewport,
    std::array<float, 9> transform) {
  params_ = std::make_optional<fup_ViewParameters>();
  fuchsia::ui::pointer::Rectangle view_rect;
  view_rect.min = view[0];
  view_rect.max = view[1];
  params_->view = view_rect;
  fuchsia::ui::pointer::Rectangle viewport_rect;
  viewport_rect.min = viewport[0];
  viewport_rect.max = viewport[1];
  params_->viewport = viewport_rect;
  params_->viewport_to_view_transform = transform;
  return *this;
}

TouchEventBuilder& TouchEventBuilder::AddResult(fup_TouchIxnResult result) {
  result_ = result;
  return *this;
}

fup_TouchEvent TouchEventBuilder::Build() {
  fup_TouchEvent event;
  if (time_) {
    event.set_timestamp(time_.value());
  }
  if (params_) {
    event.set_view_parameters(std::move(params_.value()));
  }
  if (sample_) {
    event.set_pointer_sample(std::move(sample_.value()));
  }
  if (result_) {
    event.set_interaction_result(std::move(result_.value()));
  }
  return event;
}

std::vector<fup_TouchEvent> TouchEventBuilder::BuildAsVector() {
  std::vector<fup_TouchEvent> events;
  events.emplace_back(Build());
  return events;
}

}  // namespace flutter_runner::testing
