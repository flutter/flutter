// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "src/lib/ui/base_view/base_view.h"

#include <lib/trace/event.h>
#include <lib/ui/scenic/cpp/commands.h>
#include <lib/ui/scenic/cpp/view_token_pair.h>
#include <zircon/status.h>
#include "flutter/fml/logging.h"

namespace scenic {

BaseView::BaseView(ViewContext context, const std::string& debug_name)
    : component_context_(context.component_context),
      listener_binding_(this,
                        std::move(context.session_and_listener_request.second)),
      session_(std::move(context.session_and_listener_request.first)),
      root_node_(&session_),
      ime_client_(this),
      enable_ime_(context.enable_ime) {
  if (!context.view_ref_pair) {
    context.view_ref_pair = scenic::ViewRefPair::New();
  }
  view_.emplace(&session_, std::move(context.view_token),
                std::move(context.view_ref_pair->control_ref),
                std::move(context.view_ref_pair->view_ref), debug_name);
  FML_DCHECK(view_);

  session_.SetDebugName(debug_name);

  // Listen for metrics events on our top node.
  root_node_.SetEventMask(fuchsia::ui::gfx::kMetricsEventMask);
  view_->AddChild(root_node_);

  if (enable_ime_) {
    ime_manager_ =
        component_context_->svc()->Connect<fuchsia::ui::input::ImeService>();

    ime_.set_error_handler([](zx_status_t status) {
      FML_LOG(ERROR) << "Interface error on: Input Method Editor "
                     << zx_status_get_string(status);
    });
    ime_manager_.set_error_handler([](zx_status_t status) {
      FML_LOG(ERROR) << "Interface error on: Text Sync Service "
                     << zx_status_get_string(status);
    });
  }

  // We must immediately invalidate the scene, otherwise we wouldn't ever hook
  // the View up to the ViewHolder.  An alternative would be to require
  // subclasses to call an Init() method to set up the initial connection.
  InvalidateScene();
}

void BaseView::SetReleaseHandler(fit::function<void(zx_status_t)> callback) {
  listener_binding_.set_error_handler(std::move(callback));
}

void BaseView::InvalidateScene(PresentCallback present_callback) {
  TRACE_DURATION("view", "BaseView::InvalidateScene");
  if (present_callback) {
    callbacks_for_next_present_.push_back(std::move(present_callback));
  }
  if (invalidate_pending_)
    return;

  invalidate_pending_ = true;

  // Present the scene ASAP. Pass in the last presentation time; otherwise, if
  // presentation_time argument is less than the previous time passed to
  // PresentScene, the Session will be closed.
  // (We cannot use the current time because the last requested presentation
  // time, |last_presentation_time_|, could still be in the future. This is
  // because Session.Present() returns after it _begins_ preparing the given
  // frame, not after it is presented.)
  if (!present_pending_)
    PresentScene(last_presentation_time_);
}

void BaseView::PresentScene() {
  PresentScene(last_presentation_time_);
}

void BaseView::OnScenicEvent(std::vector<fuchsia::ui::scenic::Event> events) {
  TRACE_DURATION("view", "BaseView::OnScenicEvent");
  for (auto& event : events) {
    switch (event.Which()) {
      case ::fuchsia::ui::scenic::Event::Tag::kGfx:
        switch (event.gfx().Which()) {
          case ::fuchsia::ui::gfx::Event::Tag::kViewPropertiesChanged: {
            auto& evt = event.gfx().view_properties_changed();
            FML_DCHECK(view_->id() == evt.view_id);
            auto old_props = view_properties_;
            view_properties_ = evt.properties;

            ::fuchsia::ui::gfx::BoundingBox layout_box =
                ViewPropertiesLayoutBox(view_properties_);

            logical_size_ = scenic::Max(layout_box.max - layout_box.min, 0.f);
            physical_size_.x = logical_size_.x * metrics_.scale_x;
            physical_size_.y = logical_size_.y * metrics_.scale_y;
            physical_size_.z = logical_size_.z * metrics_.scale_z;

            OnPropertiesChanged(std::move(old_props));
            InvalidateScene();
            break;
          }
          case fuchsia::ui::gfx::Event::Tag::kMetrics: {
            auto& evt = event.gfx().metrics();
            if (evt.node_id == root_node_.id()) {
              auto old_metrics = metrics_;
              metrics_ = std::move(evt.metrics);
              physical_size_.x = logical_size_.x * metrics_.scale_x;
              physical_size_.y = logical_size_.y * metrics_.scale_y;
              physical_size_.z = logical_size_.z * metrics_.scale_z;
              OnMetricsChanged(std::move(old_metrics));
              InvalidateScene();
            }
            break;
          }
          default: {
            OnScenicEvent(std::move(event));
          }
        }
        break;
      case ::fuchsia::ui::scenic::Event::Tag::kInput: {
        if (event.input().Which() ==
                fuchsia::ui::input::InputEvent::Tag::kFocus &&
            enable_ime_) {
          OnHandleFocusEvent(event.input().focus());
        }
        OnInputEvent(std::move(event.input()));
        break;
      }
      case ::fuchsia::ui::scenic::Event::Tag::kUnhandled: {
        OnUnhandledCommand(std::move(event.unhandled()));
        break;
      }
      default: {
        OnScenicEvent(std::move(event));
      }
    }
  }
}

void BaseView::PresentScene(zx_time_t presentation_time) {
  TRACE_DURATION("view", "BaseView::PresentScene");
  // TODO(fxbug.dev/24406): Remove this when BaseView::PresentScene() is
  // deprecated, see fxbug.dev/24573.
  if (present_pending_)
    return;

  present_pending_ = true;

  // Keep track of the most recent presentation time we've passed to
  // Session.Present(), for use in InvalidateScene().
  last_presentation_time_ = presentation_time;

  TRACE_FLOW_BEGIN("gfx", "Session::Present", session_present_count_);
  ++session_present_count_;

  session()->Present(
      presentation_time,
      [this, present_callbacks = std::move(callbacks_for_next_present_)](
          fuchsia::images::PresentationInfo info) mutable {
        TRACE_DURATION("view", "BaseView::PresentationCallback");
        TRACE_FLOW_END("gfx", "present_callback", info.presentation_time);

        FML_DCHECK(present_pending_);

        zx_time_t next_presentation_time =
            info.presentation_time + info.presentation_interval;

        bool present_needed = false;
        if (invalidate_pending_) {
          invalidate_pending_ = false;
          OnSceneInvalidated(std::move(info));
          present_needed = true;
        }

        for (auto& callback : present_callbacks) {
          callback(info);
        }

        present_pending_ = false;
        if (present_needed)
          PresentScene(next_presentation_time);
      });
  callbacks_for_next_present_.clear();
}

// |fuchsia::ui::input::InputMethodEditorClient|
void BaseView::DidUpdateState(
    fuchsia::ui::input::TextInputState state,
    std::unique_ptr<fuchsia::ui::input::InputEvent> input_event) {
  if (input_event) {
    const fuchsia::ui::input::InputEvent& input = *input_event;
    fuchsia::ui::input::InputEvent input_event_copy;
    fidl::Clone(input, &input_event_copy);
    OnInputEvent(std::move(input_event_copy));
  }
}

// |fuchsia::ui::input::InputMethodEditorClient|
void BaseView::OnAction(fuchsia::ui::input::InputMethodAction action) {}

bool BaseView::OnHandleFocusEvent(const fuchsia::ui::input::FocusEvent& focus) {
  if (focus.focused) {
    ActivateIme();
    return true;
  } else if (!focus.focused) {
    DeactivateIme();
    return true;
  }
  return false;
}

void BaseView::ActivateIme() {
  ime_manager_->GetInputMethodEditor(
      fuchsia::ui::input::KeyboardType::TEXT,       // keyboard type
      fuchsia::ui::input::InputMethodAction::DONE,  // input method action
      fuchsia::ui::input::TextInputState{},         // initial state
      ime_client_.NewBinding(),                     // client
      ime_.NewRequest()                             // editor
  );
}

void BaseView::DeactivateIme() {
  if (ime_) {
    ime_manager_->HideKeyboard();
    ime_ = nullptr;
  }
  if (ime_client_.is_bound()) {
    ime_client_.Unbind();
  }
}

}  // namespace scenic
