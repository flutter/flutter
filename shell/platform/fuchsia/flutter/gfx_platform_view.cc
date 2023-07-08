// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gfx_platform_view.h"

#include "flutter/fml/make_copyable.h"

namespace flutter_runner {

static constexpr int64_t kFlutterImplicitViewId = 0ll;

GfxPlatformView::GfxPlatformView(
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
    fuchsia::ui::pointerinjector::RegistryHandle pointerinjector_registry,
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
        await_vsync_for_secondary_callback_callback,
    std::shared_ptr<sys::ServiceDirectory> dart_application_svc)
    : PlatformView(false /* is_flatland */,
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
                   std::move(await_vsync_for_secondary_callback_callback),
                   std::move(dart_application_svc)),
      session_listener_binding_(this, std::move(session_listener_request)),
      session_listener_error_callback_(
          std::move(on_session_listener_error_callback)),
      on_create_view_callback_(std::move(on_create_view_callback)),
      on_destroy_view_callback_(std::move(on_destroy_view_callback)),
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
              FML_LOG(ERROR)
                  << "Got an invalid pixel ratio from Scenic; ignoring: "
                  << new_view_pixel_ratio;
              break;
            }

            // Avoid metrics update when possible -- it is computationally
            // expensive.
            if (view_pixel_ratio_.has_value() &&
                *view_pixel_ratio_ == new_view_pixel_ratio) {
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
              FML_LOG(ERROR)
                  << "Got an invalid view size from Scenic; ignoring: "
                  << new_view_size[0] << " " << new_view_size[1];
              break;
            }

            // Avoid metrics update when possible -- it is computationally
            // expensive.
            if (view_logical_size_.has_value() &&
                *view_logical_size_ == new_view_size) {
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
    flutter::ViewportMetrics metrics{
        pixel_ratio,                                // device_pixel_ratio
        std::round(logical_size[0] * pixel_ratio),  // physical_width
        std::round(logical_size[1] * pixel_ratio),  // physical_height
        0.0f,                                       // physical_padding_top
        0.0f,                                       // physical_padding_right
        0.0f,                                       // physical_padding_bottom
        0.0f,                                       // physical_padding_left
        0.0f,                                       // physical_view_inset_top
        0.0f,                                       // physical_view_inset_right
        0.0f,  // physical_view_inset_bottom
        0.0f,  // physical_view_inset_left
        0.0f,  // p_physical_system_gesture_inset_top
        0.0f,  // p_physical_system_gesture_inset_right
        0.0f,  // p_physical_system_gesture_inset_bottom
        0.0f,  // p_physical_system_gesture_inset_left,
        -1.0,  // p_physical_touch_slop,
        {},    // p_physical_display_features_bounds
        {},    // p_physical_display_features_type
        {},    // p_physical_display_features_state
        0,     // pdisplay_id
    };
    SetViewportMetrics(kFlutterImplicitViewId, metrics);
  }
}

bool GfxPlatformView::OnChildViewConnected(scenic::ResourceId view_holder_id) {
  auto view_id_mapping = child_view_ids_.find(view_holder_id);
  if (view_id_mapping == child_view_ids_.end()) {
    return false;
  }

  std::ostringstream out;
  out << "{"
      << "\"method\":\"View.viewConnected\","
      << "\"args\":{"
      << "  \"viewId\":" << view_id_mapping->second  // ViewHolderToken handle
      << "  }"
      << "}";
  auto call = out.str();

  std::unique_ptr<flutter::PlatformMessage> message =
      std::make_unique<flutter::PlatformMessage>(
          "flutter/platform_views",
          fml::MallocMapping::Copy(call.c_str(), call.size()), nullptr);
  DispatchPlatformMessage(std::move(message));

  return true;
}

bool GfxPlatformView::OnChildViewDisconnected(
    scenic::ResourceId view_holder_id) {
  auto view_id_mapping = child_view_ids_.find(view_holder_id);
  if (view_id_mapping == child_view_ids_.end()) {
    return false;
  }

  std::ostringstream out;
  out << "{"
      << "\"method\":\"View.viewDisconnected\","
      << "\"args\":{"
      << "  \"viewId\":" << view_id_mapping->second  // ViewHolderToken handle
      << "  }"
      << "}";
  auto call = out.str();

  // A disconnected view cannot listen to pointer events.
  pointer_injector_delegate_->OnDestroyView(view_id_mapping->second);

  std::unique_ptr<flutter::PlatformMessage> message =
      std::make_unique<flutter::PlatformMessage>(
          "flutter/platform_views",
          fml::MallocMapping::Copy(call.c_str(), call.size()), nullptr);
  DispatchPlatformMessage(std::move(message));

  return true;
}

bool GfxPlatformView::OnChildViewStateChanged(scenic::ResourceId view_holder_id,
                                              bool is_rendering) {
  auto view_id_mapping = child_view_ids_.find(view_holder_id);
  if (view_id_mapping == child_view_ids_.end()) {
    return false;
  }

  const std::string is_rendering_str = is_rendering ? "true" : "false";
  std::ostringstream out;
  out << "{"
      << "\"method\":\"View.viewStateChanged\","
      << "\"args\":{"
      << "  \"viewId\":" << view_id_mapping->second << ","  // ViewHolderToken
      << "  \"is_rendering\":" << is_rendering_str << ","   // IsViewRendering
      << "  \"state\":" << is_rendering_str                 // IsViewRendering
      << "  }"
      << "}";
  auto call = out.str();

  std::unique_ptr<flutter::PlatformMessage> message =
      std::make_unique<flutter::PlatformMessage>(
          "flutter/platform_views",
          fml::MallocMapping::Copy(call.c_str(), call.size()), nullptr);
  DispatchPlatformMessage(std::move(message));

  return true;
}

void GfxPlatformView::OnCreateView(ViewCallback on_view_created,
                                   int64_t view_id_raw,
                                   bool hit_testable,
                                   bool focusable) {
  auto on_view_bound =
      [weak = weak_factory_.GetWeakPtr(),
       platform_task_runner = task_runners_.GetPlatformTaskRunner(),
       view_id = view_id_raw](scenic::ResourceId resource_id) {
        platform_task_runner->PostTask([weak, view_id, resource_id]() {
          if (!weak) {
            FML_LOG(WARNING)
                << "ViewHolder bound to PlatformView after PlatformView was "
                   "destroyed; ignoring.";
            return;
          }

          FML_DCHECK(weak->child_view_ids_.count(resource_id) == 0);
          weak->child_view_ids_[resource_id] = view_id;
          weak->pointer_injector_delegate_->OnCreateView(view_id);
        });
      };
  on_create_view_callback_(view_id_raw, std::move(on_view_created),
                           std::move(on_view_bound), hit_testable, focusable);
}

void GfxPlatformView::OnDisposeView(int64_t view_id_raw) {
  auto on_view_unbound =
      [weak = weak_factory_.GetWeakPtr(), view_id = view_id_raw,
       platform_task_runner = task_runners_.GetPlatformTaskRunner()](
          scenic::ResourceId resource_id) {
        platform_task_runner->PostTask([weak, resource_id, view_id]() {
          if (!weak) {
            FML_LOG(WARNING)
                << "ViewHolder unbound from PlatformView after PlatformView"
                   "was destroyed; ignoring.";
            return;
          }

          FML_DCHECK(weak->child_view_ids_.count(resource_id) == 1);
          weak->child_view_ids_.erase(resource_id);
          weak->pointer_injector_delegate_->OnDestroyView(view_id);
        });
      };
  on_destroy_view_callback_(view_id_raw, std::move(on_view_unbound));
}

}  // namespace flutter_runner
