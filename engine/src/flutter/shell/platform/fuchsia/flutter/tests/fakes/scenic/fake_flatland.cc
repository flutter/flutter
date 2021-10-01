// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fake_flatland.h"

#include "flutter/fml/logging.h"

namespace flutter_runner::testing {

FakeFlatland::FakeFlatland()
    : binding_(this), present_handler_([](auto args) {}) {}

fidl::InterfaceHandle<fuchsia::ui::composition::Flatland> FakeFlatland::Connect(
    async_dispatcher_t* dispatcher) {
  FML_CHECK(!binding_.is_bound());

  fidl::InterfaceHandle<fuchsia::ui::composition::Flatland> flatland;
  binding_.Bind(flatland.NewRequest(), dispatcher);

  return flatland;
}

void FakeFlatland::Disconnect(fuchsia::ui::composition::FlatlandError error) {
  binding_.events().OnError(std::move(error));
  binding_.Unbind();
}

void FakeFlatland::SetPresentHandler(PresentHandler present_handler) {
  present_handler_ =
      present_handler ? std::move(present_handler) : [](auto args) {};
}

void FakeFlatland::FireOnNextFrameBeginEvent(
    fuchsia::ui::composition::OnNextFrameBeginValues
        on_next_frame_begin_values) {
  binding_.events().OnNextFrameBegin(std::move(on_next_frame_begin_values));
}

void FakeFlatland::FireOnFramePresentedEvent(
    fuchsia::scenic::scheduling::FramePresentedInfo frame_presented_info) {
  binding_.events().OnFramePresented(std::move(frame_presented_info));
}

void FakeFlatland::NotImplemented_(const std::string& name) {
  FML_LOG(FATAL) << "FakeFlatland does not implement " << name;
}

void FakeFlatland::Present(fuchsia::ui::composition::PresentArgs args) {
  // TODO(fxb/85619): ApplyCommands()
  present_handler_(std::move(args));
}

void FakeFlatland::SetDebugName(std::string debug_name) {
  debug_name_ = std::move(debug_name);
}

}  // namespace flutter_runner::testing
