// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SRC_UI_TESTING_VIEWS_EMBEDDER_VIEW_H_
#define SRC_UI_TESTING_VIEWS_EMBEDDER_VIEW_H_

#include <fuchsia/ui/scenic/cpp/fidl.h>
#include <lib/ui/scenic/cpp/resources.h>
#include <lib/ui/scenic/cpp/session.h>

#include "src/lib/ui/base_view/base_view.h"

namespace scenic {

// This is a simplified |BaseView| that exposes view state events.
//
// See also lib/ui/base_view.
class EmbedderView : public fuchsia::ui::scenic::SessionListener {
 public:
  EmbedderView(ViewContext context,
               const std::string& debug_name = "EmbedderView");

  // Sets the EmbeddedViewInfo and attaches the embedded View to the scene. Any
  // callbacks for the embedded View's ViewState are delivered to the supplied
  // callback.
  void EmbedView(EmbeddedViewInfo info,
                 std::function<void(fuchsia::ui::gfx::ViewState)>
                     view_state_changed_callback);

 private:
  // |fuchsia::ui::scenic::SessionListener|
  void OnScenicEvent(std::vector<fuchsia::ui::scenic::Event> events) override;
  // |fuchsia::ui::scenic::SessionListener|
  void OnScenicError(std::string error) override;

  struct EmbeddedView {
    EmbeddedView(
        EmbeddedViewInfo info,
        Session* session,
        std::function<void(fuchsia::ui::gfx::ViewState)> view_state_callback,
        const std::string& debug_name = "EmbedderView");

    EmbeddedViewInfo embedded_info;
    ViewHolder view_holder;
    std::function<void(fuchsia::ui::gfx::ViewState)>
        view_state_changed_callback;
  };

  fidl::Binding<fuchsia::ui::scenic::SessionListener> binding_;
  Session session_;
  View view_;
  EntityNode top_node_;
  std::optional<fuchsia::ui::gfx::ViewProperties> embedded_view_properties_;
  std::unique_ptr<EmbeddedView> embedded_view_;
};

}  // namespace scenic
#endif  // SRC_UI_TESTING_VIEWS_EMBEDDER_VIEW_H_
