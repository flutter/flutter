// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flatland_platform_view.h"

#include "flutter/fml/make_copyable.h"

namespace flutter_runner {

FlatlandPlatformView::FlatlandPlatformView(
    flutter::PlatformView::Delegate& delegate,
    std::string debug_label,
    fuchsia::ui::views::ViewRef view_ref,
    flutter::TaskRunners task_runners,
    std::shared_ptr<sys::ServiceDirectory> runner_services,
    fidl::InterfaceHandle<fuchsia::sys::ServiceProvider>
        parent_environment_service_provider,
    fuchsia::ui::composition::ParentViewportWatcherPtr parent_viewport_watcher,
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
        await_vsync_for_secondary_callback_callback)
    : PlatformView(delegate,
                   std::move(debug_label),
                   std::move(view_ref),
                   std::move(task_runners),
                   std::move(runner_services),
                   std::move(parent_environment_service_provider),
                   std::move(vrf),
                   std::move(focuser),
                   std::move(keyboard_listener),
                   std::move(wireframe_enabled_callback),
                   std::move(on_create_view_callback),
                   std::move(on_update_view_callback),
                   std::move(on_destroy_view_callback),
                   std::move(on_create_surface_callback),
                   std::move(on_semantics_node_update_callback),
                   std::move(on_request_announce_callback),
                   std::move(on_shader_warmup),
                   std::move(view_embedder),
                   std::move(await_vsync_callback),
                   std::move(await_vsync_for_secondary_callback_callback)),
      parent_viewport_watcher_(std::move(parent_viewport_watcher)) {
  parent_viewport_watcher_.set_error_handler([](zx_status_t status) {
    FML_LOG(ERROR) << "Interface error on: ParentViewportWatcher status: "
                   << status;
  });

  parent_viewport_watcher_->GetLayout(
      fit::bind_member(this, &FlatlandPlatformView::OnGetLayout));
}

FlatlandPlatformView::~FlatlandPlatformView() = default;

void FlatlandPlatformView::OnGetLayout(
    fuchsia::ui::composition::LayoutInfo info) {
  view_logical_size_ = {static_cast<float>(info.logical_size().width),
                        static_cast<float>(info.logical_size().height)};

  // TODO(fxbug.dev/64201): Set device pixel ratio.

  SetViewportMetrics({
      1,                              // device_pixel_ratio
      view_logical_size_.value()[0],  // physical_width
      view_logical_size_.value()[1],  // physical_height
      0.0f,                           // physical_padding_top
      0.0f,                           // physical_padding_right
      0.0f,                           // physical_padding_bottom
      0.0f,                           // physical_padding_left
      0.0f,                           // physical_view_inset_top
      0.0f,                           // physical_view_inset_right
      0.0f,                           // physical_view_inset_bottom
      0.0f,                           // physical_view_inset_left
      0.0f,                           // p_physical_system_gesture_inset_top
      0.0f,                           // p_physical_system_gesture_inset_right
      0.0f,                           // p_physical_system_gesture_inset_bottom
      0.0f,                           // p_physical_system_gesture_inset_left,
      -1.0,                           // p_physical_touch_slop,
      {},                             // p_physical_display_features_bounds
      {},                             // p_physical_display_features_type
      {},                             // p_physical_display_features_state
  });

  parent_viewport_watcher_->GetLayout(
      fit::bind_member(this, &FlatlandPlatformView::OnGetLayout));
}

}  // namespace flutter_runner
