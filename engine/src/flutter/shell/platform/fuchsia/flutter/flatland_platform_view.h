// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_FLATLAND_PLATFORM_VIEW_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_FLATLAND_PLATFORM_VIEW_H_

#include "platform_view.h"

namespace flutter_runner {

// The FlatlandPlatformView...
class FlatlandPlatformView final : public flutter_runner::PlatformView {
 public:
  FlatlandPlatformView(
      flutter::PlatformView::Delegate& delegate,
      std::string debug_label,
      fuchsia::ui::views::ViewRef view_ref,
      flutter::TaskRunners task_runners,
      std::shared_ptr<sys::ServiceDirectory> runner_services,
      fidl::InterfaceHandle<fuchsia::sys::ServiceProvider>
          parent_environment_service_provider,
      fuchsia::ui::composition::ParentViewportWatcherPtr
          parent_viewport_watcher,
      fidl::InterfaceHandle<fuchsia::ui::views::ViewRefFocused> vrf,
      fidl::InterfaceHandle<fuchsia::ui::views::Focuser> focuser,
      fidl::InterfaceRequest<fuchsia::ui::input3::KeyboardListener>
          keyboard_listener,
      OnEnableWireframe wireframe_enabled_callback,
      OnCreateView on_create_view_callback,
      OnUpdateView on_update_view_callback,
      OnDestroyView on_destroy_view_callback,
      OnCreateSurface on_create_surface_callback,
      OnSemanticsNodeUpdate on_semantics_node_update_callback,
      OnRequestAnnounce on_request_announce_callback,
      OnShaderWarmup on_shader_warmup,
      std::shared_ptr<flutter::ExternalViewEmbedder> view_embedder,
      AwaitVsyncCallback await_vsync_callback,
      AwaitVsyncForSecondaryCallbackCallback
          await_vsync_for_secondary_callback_callback);
  ~FlatlandPlatformView();

  void OnGetLayout(fuchsia::ui::composition::LayoutInfo info);

 private:
  fuchsia::ui::composition::ParentViewportWatcherPtr parent_viewport_watcher_;

  FML_DISALLOW_COPY_AND_ASSIGN(FlatlandPlatformView);
};

}  // namespace flutter_runner

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_FLATLAND_PLATFORM_VIEW_H_
