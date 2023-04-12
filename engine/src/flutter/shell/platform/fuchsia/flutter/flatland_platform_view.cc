// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flatland_platform_view.h"

#include "flutter/fml/make_copyable.h"

namespace flutter_runner {

FlatlandPlatformView::FlatlandPlatformView(
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
        await_vsync_for_secondary_callback_callback)
    : PlatformView(true /* is_flatland */,
                   delegate,
                   std::move(task_runners),
                   std::move(view_ref),
                   std::move(external_view_embedder),
                   std::move(ime_service),
                   std::move(keyboard),
                   std::move(touch_source),
                   std::move(mouse_source),
                   std::move(focuser),
                   std::move(view_ref_focused),
                   std::move(pointerinjector_registry),
                   std::move(wireframe_enabled_callback),
                   std::move(on_update_view_callback),
                   std::move(on_create_surface_callback),
                   std::move(on_semantics_node_update_callback),
                   std::move(on_request_announce_callback),
                   std::move(on_shader_warmup),
                   std::move(await_vsync_callback),
                   std::move(await_vsync_for_secondary_callback_callback)),
      parent_viewport_watcher_(parent_viewport_watcher.Bind()),
      on_create_view_callback_(std::move(on_create_view_callback)),
      on_destroy_view_callback_(std::move(on_destroy_view_callback)),
      weak_factory_(this) {
  parent_viewport_watcher_.set_error_handler([](zx_status_t status) {
    FML_LOG(ERROR) << "Interface error on: ParentViewportWatcher status: "
                   << status;
  });

  parent_viewport_watcher_->GetLayout(
      fit::bind_member(this, &FlatlandPlatformView::OnGetLayout));
  parent_viewport_watcher_->GetStatus(
      fit::bind_member(this, &FlatlandPlatformView::OnParentViewportStatus));
}

FlatlandPlatformView::~FlatlandPlatformView() = default;

void FlatlandPlatformView::OnGetLayout(
    fuchsia::ui::composition::LayoutInfo info) {
  view_logical_size_ = {static_cast<float>(info.logical_size().width),
                        static_cast<float>(info.logical_size().height)};

  if (info.has_device_pixel_ratio()) {
    // Flatland returns a Vec2 for DPR but both values should be identical.
    FML_DCHECK(info.device_pixel_ratio().x == info.device_pixel_ratio().y);
    view_pixel_ratio_ = info.device_pixel_ratio().x;
  }

  float pixel_ratio = view_pixel_ratio_ ? *view_pixel_ratio_ : 1.0f;

  SetViewportMetrics({
      pixel_ratio,  // device_pixel_ratio
      std::round(view_logical_size_.value()[0] *
                 pixel_ratio),  // physical_width
      std::round(view_logical_size_.value()[1] *
                 pixel_ratio),  // physical_height
      0.0f,                     // physical_padding_top
      0.0f,                     // physical_padding_right
      0.0f,                     // physical_padding_bottom
      0.0f,                     // physical_padding_left
      0.0f,                     // physical_view_inset_top
      0.0f,                     // physical_view_inset_right
      0.0f,                     // physical_view_inset_bottom
      0.0f,                     // physical_view_inset_left
      0.0f,                     // p_physical_system_gesture_inset_top
      0.0f,                     // p_physical_system_gesture_inset_right
      0.0f,                     // p_physical_system_gesture_inset_bottom
      0.0f,                     // p_physical_system_gesture_inset_left,
      -1.0,                     // p_physical_touch_slop,
      {},                       // p_physical_display_features_bounds
      {},                       // p_physical_display_features_type
      {},                       // p_physical_display_features_state
  });

  parent_viewport_watcher_->GetLayout(
      fit::bind_member(this, &FlatlandPlatformView::OnGetLayout));
}

void FlatlandPlatformView::OnParentViewportStatus(
    fuchsia::ui::composition::ParentViewportStatus status) {
  // TODO(fxbug.dev/116001): Investigate if it is useful to send hidden/shown
  // signals.
  parent_viewport_status_ = status;
  parent_viewport_watcher_->GetStatus(
      fit::bind_member(this, &FlatlandPlatformView::OnParentViewportStatus));
}

void FlatlandPlatformView::OnChildViewStatus(
    uint64_t content_id,
    fuchsia::ui::composition::ChildViewStatus status) {
  FML_DCHECK(child_view_info_.count(content_id) == 1);

  std::ostringstream out;
  out << "{"
      << "\"method\":\"View.viewStateChanged\","
      << "\"args\":{"
      << "  \"viewId\":" << child_view_info_.at(content_id).view_id
      << ","                         // ViewId
      << "  \"is_rendering\":true,"  // IsViewRendering
      << "  \"state\":true"          // IsViewRendering
      << "  }"
      << "}";
  auto call = out.str();

  std::unique_ptr<flutter::PlatformMessage> message =
      std::make_unique<flutter::PlatformMessage>(
          "flutter/platform_views",
          fml::MallocMapping::Copy(call.c_str(), call.size()), nullptr);
  DispatchPlatformMessage(std::move(message));

  child_view_info_.at(content_id)
      .child_view_watcher->GetStatus(
          [this, content_id](fuchsia::ui::composition::ChildViewStatus status) {
            OnChildViewStatus(content_id, status);
          });
}

void FlatlandPlatformView::OnChildViewViewRef(
    uint64_t content_id,
    uint64_t view_id,
    fuchsia::ui::views::ViewRef view_ref) {
  FML_CHECK(child_view_info_.count(content_id) == 1);

  fuchsia::ui::views::ViewRef view_ref_clone;
  fidl::Clone(view_ref, &view_ref_clone);

  focus_delegate_->OnChildViewViewRef(view_id, std::move(view_ref));

  pointer_injector_delegate_->OnCreateView(view_id, std::move(view_ref_clone));
  OnChildViewConnected(content_id);
}

void FlatlandPlatformView::OnCreateView(ViewCallback on_view_created,
                                        int64_t view_id_raw,
                                        bool hit_testable,
                                        bool focusable) {
  auto on_view_bound = [weak = weak_factory_.GetWeakPtr(),
                        platform_task_runner =
                            task_runners_.GetPlatformTaskRunner(),
                        view_id = view_id_raw](
                           fuchsia::ui::composition::ContentId content_id,
                           fuchsia::ui::composition::ChildViewWatcherHandle
                               child_view_watcher_handle) {
    FML_CHECK(weak);
    FML_CHECK(weak->child_view_info_.count(content_id.value) == 0);

    // Bind the child view watcher to the platform thread so that the FIDL calls
    // are handled on the platform thread.
    fuchsia::ui::composition::ChildViewWatcherPtr child_view_watcher =
        child_view_watcher_handle.Bind();
    FML_CHECK(child_view_watcher);

    child_view_watcher.set_error_handler(
        [weak, view_id, content_id](zx_status_t status) {
          FML_LOG(WARNING) << "Child disconnected. ChildViewWatcher status: "
                           << status;

          if (!weak) {
            FML_LOG(WARNING)
                << "Flatland View bound to PlatformView after PlatformView was "
                   "destroyed; ignoring.";
            return;
          }

          // Disconnected views cannot listen to pointer events.
          weak->pointer_injector_delegate_->OnDestroyView(view_id);

          weak->OnChildViewDisconnected(content_id.value);
        });

    platform_task_runner->PostTask(
        fml::MakeCopyable([weak, view_id, content_id,
                           watcher = std::move(child_view_watcher)]() mutable {
          if (!weak) {
            FML_LOG(WARNING)
                << "Flatland View bound to PlatformView after PlatformView was "
                   "destroyed; ignoring.";
            return;
          }

          weak->child_view_info_.emplace(
              std::piecewise_construct, std::forward_as_tuple(content_id.value),
              std::forward_as_tuple(view_id, std::move(watcher)));

          weak->child_view_info_.at(content_id.value)
              .child_view_watcher->GetStatus(
                  [weak, id = content_id.value](
                      fuchsia::ui::composition::ChildViewStatus status) {
                    weak->OnChildViewStatus(id, status);
                  });

          weak->child_view_info_.at(content_id.value)
              .child_view_watcher->GetViewRef(
                  [weak, content_id = content_id.value,
                   view_id](fuchsia::ui::views::ViewRef view_ref) {
                    weak->OnChildViewViewRef(content_id, view_id,
                                             std::move(view_ref));
                  });
        }));
  };

  on_create_view_callback_(view_id_raw, std::move(on_view_created),
                           std::move(on_view_bound), hit_testable, focusable);
}

void FlatlandPlatformView::OnDisposeView(int64_t view_id_raw) {
  auto on_view_unbound =
      [weak = weak_factory_.GetWeakPtr(),
       platform_task_runner = task_runners_.GetPlatformTaskRunner(),
       view_id_raw](fuchsia::ui::composition::ContentId content_id) {
        platform_task_runner->PostTask([weak, content_id, view_id_raw]() {
          if (!weak) {
            FML_LOG(WARNING)
                << "Flatland View unbound from PlatformView after PlatformView"
                   "was destroyed; ignoring.";
            return;
          }

          FML_DCHECK(weak->child_view_info_.count(content_id.value) == 1);
          weak->OnChildViewDisconnected(content_id.value);
          weak->child_view_info_.erase(content_id.value);
          weak->focus_delegate_->OnDisposeChildView(view_id_raw);
          weak->pointer_injector_delegate_->OnDestroyView(view_id_raw);
        });
      };
  on_destroy_view_callback_(view_id_raw, std::move(on_view_unbound));
}

void FlatlandPlatformView::OnChildViewConnected(uint64_t content_id) {
  FML_CHECK(child_view_info_.count(content_id) == 1);
  std::ostringstream out;
  out << "{"
      << "\"method\":\"View.viewConnected\","
      << "\"args\":{"
      << "  \"viewId\":" << child_view_info_.at(content_id).view_id << "  }"
      << "}";
  auto call = out.str();

  std::unique_ptr<flutter::PlatformMessage> message =
      std::make_unique<flutter::PlatformMessage>(
          "flutter/platform_views",
          fml::MallocMapping::Copy(call.c_str(), call.size()), nullptr);
  DispatchPlatformMessage(std::move(message));
}

void FlatlandPlatformView::OnChildViewDisconnected(uint64_t content_id) {
  FML_CHECK(child_view_info_.count(content_id) == 1);
  std::ostringstream out;
  out << "{"
      << "\"method\":\"View.viewDisconnected\","
      << "\"args\":{"
      << "  \"viewId\":" << child_view_info_.at(content_id).view_id << "  }"
      << "}";
  auto call = out.str();

  std::unique_ptr<flutter::PlatformMessage> message =
      std::make_unique<flutter::PlatformMessage>(
          "flutter/platform_views",
          fml::MallocMapping::Copy(call.c_str(), call.size()), nullptr);
  DispatchPlatformMessage(std::move(message));
}

}  // namespace flutter_runner
