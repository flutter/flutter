// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gfx_platform_view.h"

#include "flutter/fml/make_copyable.h"

namespace flutter_runner {

GfxPlatformView::GfxPlatformView(
    flutter::PlatformView::Delegate& delegate,
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
      session_listener_binding_(this, std::move(session_listener_request)),
      session_listener_error_callback_(
          std::move(on_session_listener_error_callback)),
      weak_factory_(this) {
  session_listener_binding_.set_error_handler([](zx_status_t status) {
    FML_LOG(ERROR) << "Interface error on: SessionListener, status: " << status;
  });
}

GfxPlatformView::~GfxPlatformView() = default;

void GfxPlatformView::OnScenicError(std::string error) {
  FML_LOG(ERROR) << "Session error: " << error;
  session_listener_error_callback_();
}

void GfxPlatformView::OnScenicEvent(
    std::vector<fuchsia::ui::scenic::Event> events) {
  TRACE_EVENT0("flutter", "PlatformView::OnScenicEvent");

  std::vector<fuchsia::ui::gfx::Event> deferred_view_events;
  bool metrics_changed = false;
  for (auto& event : events) {
    switch (event.Which()) {
      case fuchsia::ui::scenic::Event::Tag::kGfx:
        switch (event.gfx().Which()) {
          case fuchsia::ui::gfx::Event::Tag::kMetrics: {
            const fuchsia::ui::gfx::Metrics& metrics =
                event.gfx().metrics().metrics;
            const float new_view_pixel_ratio = metrics.scale_x;
            if (new_view_pixel_ratio <= 0.f) {
              FML_DLOG(ERROR)
                  << "Got an invalid pixel ratio from Scenic; ignoring: "
                  << new_view_pixel_ratio;
              break;
            }

            // Avoid metrics update when possible -- it is computationally
            // expensive.
            if (view_pixel_ratio_.has_value() &&
                *view_pixel_ratio_ == new_view_pixel_ratio) {
              FML_DLOG(ERROR)
                  << "Got an identical pixel ratio from Scenic; ignoring: "
                  << new_view_pixel_ratio;
              break;
            }

            view_pixel_ratio_ = new_view_pixel_ratio;
            metrics_changed = true;
            break;
          }
          case fuchsia::ui::gfx::Event::Tag::kViewPropertiesChanged: {
            const fuchsia::ui::gfx::BoundingBox& bounding_box =
                event.gfx().view_properties_changed().properties.bounding_box;
            const std::array<float, 2> new_view_size = {
                std::max(bounding_box.max.x - bounding_box.min.x, 0.0f),
                std::max(bounding_box.max.y - bounding_box.min.y, 0.0f)};
            if (new_view_size[0] <= 0.f || new_view_size[1] <= 0.f) {
              FML_DLOG(ERROR)
                  << "Got an invalid view size from Scenic; ignoring: "
                  << new_view_size[0] << " " << new_view_size[1];
              break;
            }

            // Avoid metrics update when possible -- it is computationally
            // expensive.
            if (view_logical_size_.has_value() &&
                *view_logical_size_ == new_view_size) {
              FML_DLOG(ERROR)
                  << "Got an identical view size from Scenic; ignoring: "
                  << new_view_size[0] << " " << new_view_size[1];
              break;
            }

            view_logical_size_ = new_view_size;
            view_logical_origin_ = {bounding_box.min.x, bounding_box.min.y};
            metrics_changed = true;
            break;
          }
          case fuchsia::ui::gfx::Event::Tag::kViewConnected:
            if (!OnChildViewConnected(
                    event.gfx().view_connected().view_holder_id)) {
              deferred_view_events.push_back(std::move(event.gfx()));
            }
            break;
          case fuchsia::ui::gfx::Event::Tag::kViewDisconnected:
            if (!OnChildViewDisconnected(
                    event.gfx().view_disconnected().view_holder_id)) {
              deferred_view_events.push_back(std::move(event.gfx()));
            }
            break;
          case fuchsia::ui::gfx::Event::Tag::kViewStateChanged:
            if (!OnChildViewStateChanged(
                    event.gfx().view_state_changed().view_holder_id,
                    event.gfx().view_state_changed().state.is_rendering)) {
              deferred_view_events.push_back(std::move(event.gfx()));
            }
            break;
          case fuchsia::ui::gfx::Event::Tag::Invalid:
            FML_DCHECK(false) << "Flutter PlatformView::OnScenicEvent: Got "
                                 "an invalid GFX event.";
            break;
          default:
            // We don't care about some event types, so not handling them is OK.
            break;
        }
        break;
      case fuchsia::ui::scenic::Event::Tag::kInput:
        switch (event.input().Which()) {
          case fuchsia::ui::input::InputEvent::Tag::kFocus:
            break;
          case fuchsia::ui::input::InputEvent::Tag::kPointer: {
            OnHandlePointerEvent(event.input().pointer());
            break;
          }
          case fuchsia::ui::input::InputEvent::Tag::kKeyboard: {
            // All devices should receive key events via input3.KeyboardListener
            // instead.
            FML_LOG(WARNING) << "Keyboard event from Scenic: ignored";
            break;
          }
          case fuchsia::ui::input::InputEvent::Tag::Invalid: {
            FML_DCHECK(false)
                << "Flutter PlatformView::OnScenicEvent: Got an invalid INPUT "
                   "event.";
          }
        }
        break;
      default: {
        break;
      }
    }
  }

  // If some View events went unmatched, try processing them again one more time
  // in case they arrived out-of-order with the View creation callback.
  if (!deferred_view_events.empty()) {
    task_runners_.GetPlatformTaskRunner()->PostTask(fml::MakeCopyable(
        [weak = weak_factory_.GetWeakPtr(),
         deferred_view_events = std::move(deferred_view_events)]() {
          if (!weak) {
            FML_LOG(WARNING)
                << "PlatformView already destroyed when "
                   "processing deferred view events; dropping events.";
            return;
          }

          for (const auto& event : deferred_view_events) {
            switch (event.Which()) {
              case fuchsia::ui::gfx::Event::Tag::kViewConnected: {
                bool view_found = weak->OnChildViewConnected(
                    event.view_connected().view_holder_id);
                FML_DCHECK(view_found);
                break;
              }
              case fuchsia::ui::gfx::Event::Tag::kViewDisconnected: {
                bool view_found = weak->OnChildViewDisconnected(
                    event.view_disconnected().view_holder_id);
                FML_DCHECK(view_found);
                break;
              }
              case fuchsia::ui::gfx::Event::Tag::kViewStateChanged: {
                bool view_found = weak->OnChildViewStateChanged(
                    event.view_state_changed().view_holder_id,
                    event.view_state_changed().state.is_rendering);
                FML_DCHECK(view_found);
                break;
              }
              default:
                FML_DCHECK(false) << "Flutter PlatformView::OnScenicEvent: Got "
                                     "an invalid deferred GFX event.";
                break;
            }
          }
        }));
  }

  // If any of the viewport metrics changed, inform the engine now.
  if (view_pixel_ratio_.has_value() && view_logical_size_.has_value() &&
      metrics_changed) {
    const float pixel_ratio = *view_pixel_ratio_;
    const std::array<float, 2> logical_size = *view_logical_size_;
    SetViewportMetrics({
        pixel_ratio,                    // device_pixel_ratio
        logical_size[0] * pixel_ratio,  // physical_width
        logical_size[1] * pixel_ratio,  // physical_height
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
        0.0f,  // p_physical_system_gesture_inset_bottom
        0.0f,  // p_physical_system_gesture_inset_left,
        -1.0,  // p_physical_touch_slop,
        {},    // p_physical_display_features_bounds
        {},    // p_physical_display_features_type
        {},    // p_physical_display_features_state
    });
  }
}

}  // namespace flutter_runner
