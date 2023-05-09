// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_FLATLAND_PLATFORM_VIEW_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_FLATLAND_PLATFORM_VIEW_H_

#include "flutter/shell/platform/fuchsia/flutter/platform_view.h"

#include <fuchsia/ui/composition/cpp/fidl.h>

#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/shell/platform/fuchsia/flutter/flatland_external_view_embedder.h"

namespace flutter_runner {

using OnCreateFlatlandView = fit::function<
    void(int64_t, ViewCallback, FlatlandViewCreatedCallback, bool, bool)>;
using OnDestroyFlatlandView =
    fit::function<void(int64_t, FlatlandViewIdCallback)>;

// The FlatlandPlatformView that does Flatland specific...
class FlatlandPlatformView final : public flutter_runner::PlatformView {
 public:
  FlatlandPlatformView(
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
      fuchsia::ui::composition::ParentViewportWatcherHandle
          parent_viewport_watcher,
      fuchsia::ui::pointerinjector::RegistryHandle pointerinjector_registry,
      OnEnableWireframe wireframe_enabled_callback,
      OnCreateFlatlandView on_create_view_callback,
      OnUpdateView on_update_view_callback,
      OnDestroyFlatlandView on_destroy_view_callback,
      OnCreateSurface on_create_surface_callback,
      OnSemanticsNodeUpdate on_semantics_node_update_callback,
      OnRequestAnnounce on_request_announce_callback,
      OnShaderWarmup on_shader_warmup,
      AwaitVsyncCallback await_vsync_callback,
      AwaitVsyncForSecondaryCallbackCallback
          await_vsync_for_secondary_callback_callback,
      std::shared_ptr<sys::ServiceDirectory> dart_application_svc);
  ~FlatlandPlatformView() override;

  void OnGetLayout(fuchsia::ui::composition::LayoutInfo info);
  void OnParentViewportStatus(
      fuchsia::ui::composition::ParentViewportStatus status);
  void OnChildViewStatus(uint64_t content_id,
                         fuchsia::ui::composition::ChildViewStatus status);
  void OnChildViewViewRef(uint64_t content_id,
                          uint64_t view_id,
                          fuchsia::ui::views::ViewRef view_ref);

 private:
  void OnCreateView(ViewCallback on_view_created,
                    int64_t view_id_raw,
                    bool hit_testable,
                    bool focusable) override;
  void OnDisposeView(int64_t view_id_raw) override;

  // Sends a 'View.viewConnected' platform message over 'flutter/platform_views'
  // channel when a view gets created.
  void OnChildViewConnected(uint64_t content_id);

  // Sends a 'View.viewDisconnected' platform message over
  // 'flutter/platform_views' channel when a view gets destroyed or the child
  // view watcher channel of a view closes.
  void OnChildViewDisconnected(uint64_t content_id);

  // child_view_ids_ maintains a persistent mapping from Flatland ContentId's to
  // flutter view ids, which are really zx_handle_t of ViewCreationToken.
  struct ChildViewInfo {
    ChildViewInfo(zx_handle_t token,
                  fuchsia::ui::composition::ChildViewWatcherPtr watcher)
        : view_id(token), child_view_watcher(std::move(watcher)) {}
    zx_handle_t view_id;
    fuchsia::ui::composition::ChildViewWatcherPtr child_view_watcher;
  };
  std::unordered_map<uint64_t /*fuchsia::ui::composition::ContentId*/,
                     ChildViewInfo>
      child_view_info_;

  fuchsia::ui::composition::ParentViewportWatcherPtr parent_viewport_watcher_;

  OnCreateFlatlandView on_create_view_callback_;
  OnDestroyFlatlandView on_destroy_view_callback_;

  fuchsia::ui::composition::ParentViewportStatus parent_viewport_status_;

  fml::WeakPtrFactory<FlatlandPlatformView>
      weak_factory_;  // Must be the last member.

  FML_DISALLOW_COPY_AND_ASSIGN(FlatlandPlatformView);
};

}  // namespace flutter_runner

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_FLATLAND_PLATFORM_VIEW_H_
