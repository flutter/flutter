// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_GFX_PLATFORM_VIEW_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_GFX_PLATFORM_VIEW_H_

#include "platform_view.h"

#include <fuchsia/ui/gfx/cpp/fidl.h>

namespace flutter_runner {

// The GfxPlatformView implements SessionListener and gets Session events but it
// does *not* actually own the Session itself; that is owned by the
// FuchsiaExternalViewEmbedder on the raster thread.
class GfxPlatformView final : public flutter_runner::PlatformView,
                              private fuchsia::ui::scenic::SessionListener {
 public:
  GfxPlatformView(flutter::PlatformView::Delegate& delegate,
                  std::string debug_label,
                  fuchsia::ui::views::ViewRef view_ref,
                  flutter::TaskRunners task_runners,
                  std::shared_ptr<sys::ServiceDirectory> runner_services,
                  fidl::InterfaceHandle<fuchsia::sys::ServiceProvider>
                      parent_environment_service_provider,
                  fidl::InterfaceRequest<fuchsia::ui::scenic::SessionListener>
                      session_listener_request,
                  fidl::InterfaceHandle<fuchsia::ui::views::ViewRefFocused> vrf,
                  fidl::InterfaceHandle<fuchsia::ui::views::Focuser> focuser,
                  fidl::InterfaceRequest<fuchsia::ui::input3::KeyboardListener>
                      keyboard_listener,
                  fit::closure on_session_listener_error_callback,
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
  ~GfxPlatformView();

 private:
  // |fuchsia::ui::scenic::SessionListener|
  void OnScenicError(std::string error) override;
  void OnScenicEvent(std::vector<fuchsia::ui::scenic::Event> events) override;

  fidl::Binding<fuchsia::ui::scenic::SessionListener> session_listener_binding_;
  fit::closure session_listener_error_callback_;

  fml::WeakPtrFactory<GfxPlatformView>
      weak_factory_;  // Must be the last member.

  FML_DISALLOW_COPY_AND_ASSIGN(GfxPlatformView);
};

}  // namespace flutter_runner

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_GFX_PLATFORM_VIEW_H_
