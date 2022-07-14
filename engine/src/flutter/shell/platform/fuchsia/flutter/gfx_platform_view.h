// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_GFX_PLATFORM_VIEW_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_GFX_PLATFORM_VIEW_H_

#include "flutter/shell/platform/fuchsia/flutter/platform_view.h"

#include <fuchsia/ui/gfx/cpp/fidl.h>
#include <fuchsia/ui/pointer/cpp/fidl.h>

#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/shell/platform/fuchsia/flutter/gfx_external_view_embedder.h"

namespace flutter_runner {

using OnCreateGfxView =
    fit::function<void(int64_t, ViewCallback, GfxViewIdCallback, bool, bool)>;
using OnDestroyGfxView = fit::function<void(int64_t, GfxViewIdCallback)>;

// The GfxPlatformView implements SessionListener and gets Session events but it
// does *not* actually own the Session itself; that is owned by the
// GfxExternalViewEmbedder on the raster thread.
class GfxPlatformView final : public flutter_runner::PlatformView,
                              private fuchsia::ui::scenic::SessionListener {
 public:
  GfxPlatformView(
      flutter::PlatformView::Delegate& delegate,
      flutter::TaskRunners task_runners,
      fuchsia::ui::views::ViewRef view_ref,
      std::shared_ptr<flutter::ExternalViewEmbedder> external_view_embedder,
      fuchsia::ui::input::ImeServiceHandle ime_service,
      fuchsia::ui::input3::KeyboardHandle keyboard,
      fuchsia::ui::pointer::TouchSourceHandle touch_source,
      fuchsia::ui::pointer::MouseSourceHandle mouse_source,
      fuchsia::ui::views::FocuserHandle focuser,
      fuchsia::ui::views::ViewRefFocusedHandle view_ref_focused,
      fidl::InterfaceRequest<fuchsia::ui::scenic::SessionListener>
          session_listener_request,
      fit::closure on_session_listener_error_callback,
      OnEnableWireframe wireframe_enabled_callback,
      OnCreateGfxView on_create_view_callback,
      OnUpdateView on_update_view_callback,
      OnDestroyGfxView on_destroy_view_callback,
      OnCreateSurface on_create_surface_callback,
      OnSemanticsNodeUpdate on_semantics_node_update_callback,
      OnRequestAnnounce on_request_announce_callback,
      OnShaderWarmup on_shader_warmup,
      AwaitVsyncCallback await_vsync_callback,
      AwaitVsyncForSecondaryCallbackCallback
          await_vsync_for_secondary_callback_callback);

  ~GfxPlatformView() override;

 private:
  // |fuchsia::ui::scenic::SessionListener|
  void OnScenicError(std::string error) override;
  void OnScenicEvent(std::vector<fuchsia::ui::scenic::Event> events) override;

  // ViewHolder event handlers.  These return false if the ViewHolder
  // corresponding to `view_holder_id` could not be found and the evnt was
  // unhandled.
  bool OnChildViewConnected(scenic::ResourceId view_holder_id);
  bool OnChildViewDisconnected(scenic::ResourceId view_holder_id);
  bool OnChildViewStateChanged(scenic::ResourceId view_holder_id,
                               bool is_rendering);

  void OnCreateView(ViewCallback on_view_created,
                    int64_t view_id_raw,
                    bool hit_testable,
                    bool focusable) override;
  void OnDisposeView(int64_t view_id_raw) override;

  fidl::Binding<fuchsia::ui::scenic::SessionListener> session_listener_binding_;
  fit::closure session_listener_error_callback_;

  // child_view_ids_ maintains a persistent mapping from Scenic ResourceId's to
  // flutter view ids, which are really zx_handle_t of ViewHolderToken.
  std::unordered_map<scenic::ResourceId, zx_handle_t> child_view_ids_;

  OnCreateGfxView on_create_view_callback_;
  OnDestroyGfxView on_destroy_view_callback_;

  fml::WeakPtrFactory<GfxPlatformView>
      weak_factory_;  // Must be the last member.

  FML_DISALLOW_COPY_AND_ASSIGN(GfxPlatformView);
};

}  // namespace flutter_runner

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_GFX_PLATFORM_VIEW_H_
