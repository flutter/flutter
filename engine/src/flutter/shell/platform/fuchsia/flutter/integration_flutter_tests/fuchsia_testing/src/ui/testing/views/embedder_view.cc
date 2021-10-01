// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <zircon/status.h>

#include "flutter/fml/logging.h"
#include "src/ui/testing/views/embedder_view.h"

namespace scenic {

EmbedderView::EmbedderView(ViewContext context, const std::string& debug_name)
    : binding_(this, std::move(context.session_and_listener_request.second)),
      session_(std::move(context.session_and_listener_request.first)),
      view_(&session_, std::move(context.view_token), debug_name),
      top_node_(&session_) {
  binding_.set_error_handler([](zx_status_t status) {
    FML_LOG(FATAL) << "Session listener binding: "
                   << zx_status_get_string(status);
  });
  view_.AddChild(top_node_);
  // Call |Session::Present| in order to flush events having to do with
  // creation of |view_| and |top_node_|.
  session_.Present(0, [](auto) {});
}

// Sets the EmbeddedViewInfo and attaches the embedded View to the scene. Any
// callbacks for the embedded View's ViewState are delivered to the supplied
// callback.
void EmbedderView::EmbedView(EmbeddedViewInfo info,
                             std::function<void(fuchsia::ui::gfx::ViewState)>
                                 view_state_changed_callback) {
  // Only one EmbeddedView is currently supported.
  FML_CHECK(!embedded_view_);
  embedded_view_ = std::make_unique<EmbeddedView>(
      std::move(info), &session_, std::move(view_state_changed_callback));

  // Attach the embedded view to the scene.
  top_node_.Attach(embedded_view_->view_holder);

  // Call |Session::Present| to apply the embedded view to the scene graph.
  session_.Present(0, [](auto) {});
}

void EmbedderView::OnScenicEvent(
    std::vector<fuchsia::ui::scenic::Event> events) {
  for (const auto& event : events) {
    if (event.Which() == fuchsia::ui::scenic::Event::Tag::kGfx &&
        event.gfx().Which() ==
            fuchsia::ui::gfx::Event::Tag::kViewPropertiesChanged) {
      const auto& evt = event.gfx().view_properties_changed();
      // Naively apply the parent's ViewProperties to any EmbeddedViews.
      if (embedded_view_) {
        embedded_view_->view_holder.SetViewProperties(
            std::move(evt.properties));
        session_.Present(0, [](auto) {});
      }
    } else if (event.Which() == fuchsia::ui::scenic::Event::Tag::kGfx &&
               event.gfx().Which() ==
                   fuchsia::ui::gfx::Event::Tag::kViewStateChanged) {
      const auto& evt = event.gfx().view_state_changed();
      if (embedded_view_ &&
          evt.view_holder_id == embedded_view_->view_holder.id()) {
        // Clients of |EmbedderView| *must* set a view state changed
        // callback.  Failure to do so is a usage error.
        FML_CHECK(embedded_view_->view_state_changed_callback);
        embedded_view_->view_state_changed_callback(evt.state);
      }
    }
  }
}

void EmbedderView::OnScenicError(std::string error) {
  FML_LOG(FATAL) << "OnScenicError: " << error;
}

EmbedderView::EmbeddedView::EmbeddedView(
    EmbeddedViewInfo info,
    Session* session,
    std::function<void(fuchsia::ui::gfx::ViewState)> view_state_callback,
    const std::string& debug_name)
    : embedded_info(std::move(info)),
      view_holder(session,
                  std::move(embedded_info.view_holder_token),
                  debug_name + " ViewHolder"),
      view_state_changed_callback(std::move(view_state_callback)) {}

}  // namespace scenic
