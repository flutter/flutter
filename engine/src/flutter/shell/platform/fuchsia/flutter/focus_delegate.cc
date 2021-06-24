// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <ostream>

#include "focus_delegate.h"

namespace flutter_runner {

void FocusDelegate::WatchLoop(std::function<void(bool)> callback) {
  if (watch_loop_) {
    FML_LOG(ERROR) << "FocusDelegate::WatchLoop() cannot be called twice.";
    return;
  }

  watch_loop_ = [this, callback = std::move(callback)](auto focus_state) {
    callback(is_focused_ = focus_state.focused());
    if (next_focus_request_) {
      CompleteCurrentFocusState(std::exchange(next_focus_request_, nullptr));
    }
    view_ref_focused_->Watch(watch_loop_);
  };
  view_ref_focused_->Watch(watch_loop_);
}

void FocusDelegate::CompleteCurrentFocusState(
    fml::RefPtr<flutter::PlatformMessageResponse> response) {
  std::string result(is_focused_ ? "[true]" : "[false]");
  response->Complete(std::make_unique<fml::DataMapping>(
      std::vector<uint8_t>(result.begin(), result.end())));
}

void FocusDelegate::CompleteNextFocusState(
    fml::RefPtr<flutter::PlatformMessageResponse> response) {
  if (next_focus_request_) {
    FML_LOG(ERROR) << "An outstanding PlatformMessageResponse already exists "
                      "for the next focus state!";
    response->CompleteEmpty();
  } else {
    next_focus_request_ = std::move(response);
  }
}

void FocusDelegate::RequestFocus(
    rapidjson::Value request,
    fml::RefPtr<flutter::PlatformMessageResponse> response) {
  auto args_it = request.FindMember("args");
  if (args_it == request.MemberEnd() || !args_it->value.IsObject()) {
    FML_LOG(ERROR) << "No arguments found.";
    return;
  }
  const auto& args = args_it->value;

  auto view_ref = args.FindMember("viewRef");
  if (!view_ref->value.IsUint64()) {
    FML_LOG(ERROR) << "Argument 'viewRef' is not a int64";
    return;
  }

  zx_handle_t handle = view_ref->value.GetUint64();
  zx_handle_t out_handle;
  zx_status_t status =
      zx_handle_duplicate(handle, ZX_RIGHT_SAME_RIGHTS, &out_handle);
  if (status != ZX_OK) {
    FML_LOG(ERROR) << "Argument 'viewRef' is not valid";
    return;
  }
  auto ref = fuchsia::ui::views::ViewRef({
      .reference = zx::eventpair(out_handle),
  });
  focuser_->RequestFocus(
      std::move(ref),
      [view_ref = view_ref->value.GetUint64(), response = std::move(response)](
          fuchsia::ui::views::Focuser_RequestFocus_Result result) {
        if (!response.get()) {
          return;
        }
        int result_code =
            result.is_err()
                ? static_cast<
                      std::underlying_type_t<fuchsia::ui::views::Error>>(
                      result.err())
                : 0;

        std::ostringstream out;
        out << "[" << result_code << "]";
        std::string output = out.str();
        response->Complete(std::make_unique<fml::DataMapping>(
            std::vector<uint8_t>(output.begin(), output.end())));
      });
}

}  // namespace flutter_runner
