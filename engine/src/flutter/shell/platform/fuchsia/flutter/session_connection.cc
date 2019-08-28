// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "session_connection.h"

#include "flutter/fml/make_copyable.h"
#include "lib/fidl/cpp/optional.h"
#include "lib/ui/scenic/cpp/commands.h"
#include "vsync_recorder.h"
#include "vsync_waiter.h"

namespace flutter_runner {

SessionConnection::SessionConnection(
    std::string debug_label,
    fuchsia::ui::views::ViewToken view_token,
    fidl::InterfaceHandle<fuchsia::ui::scenic::Session> session,
    fml::closure session_error_callback,
    zx_handle_t vsync_event_handle)
    : debug_label_(std::move(debug_label)),
      session_wrapper_(session.Bind(), nullptr),
      root_view_(&session_wrapper_, std::move(view_token.value), debug_label),
      root_node_(&session_wrapper_),
      surface_producer_(
          std::make_unique<VulkanSurfaceProducer>(&session_wrapper_)),
      scene_update_context_(&session_wrapper_, surface_producer_.get()),
      vsync_event_handle_(vsync_event_handle) {
  session_wrapper_.set_error_handler(
      [callback = session_error_callback](zx_status_t status) { callback(); });

  session_wrapper_.SetDebugName(debug_label_);

  // TODO(SCN-975): Re-enable.
  //   view_->GetToken(std::bind(&PlatformView::ConnectSemanticsProvider, this,
  //                             std::placeholders::_1));

  root_view_.AddChild(root_node_);
  root_node_.SetEventMask(fuchsia::ui::gfx::kMetricsEventMask |
                          fuchsia::ui::gfx::kSizeChangeHintEventMask);

  // Signal is initially high indicating availability of the session.
  ToggleSignal(vsync_event_handle_, true);

  PresentSession();
}

SessionConnection::~SessionConnection() = default;

void SessionConnection::Present(
    flutter::CompositorContext::ScopedFrame& frame) {
  TRACE_EVENT0("gfx", "SessionConnection::Present");
  TRACE_FLOW_BEGIN("gfx", "SessionConnection::PresentSession",
                   next_present_session_trace_id_);
  next_present_session_trace_id_++;

  // Throttle vsync if presentation callback is already pending. This allows
  // the paint tasks for this frame to execute in parallel with presentation
  // of last frame but still provides back-pressure to prevent us from queuing
  // even more work.
  if (presentation_callback_pending_) {
    present_session_pending_ = true;
    ToggleSignal(vsync_event_handle_, false);
  } else {
    PresentSession();
  }

  // Execute paint tasks and signal fences.
  auto surfaces_to_submit = scene_update_context_.ExecutePaintTasks(frame);

  // Tell the surface producer that a present has occurred so it can perform
  // book-keeping on buffer caches.
  surface_producer_->OnSurfacesPresented(std::move(surfaces_to_submit));
}

void SessionConnection::OnSessionSizeChangeHint(float width_change_factor,
                                                float height_change_factor) {
  surface_producer_->OnSessionSizeChangeHint(width_change_factor,
                                             height_change_factor);
}

void SessionConnection::set_enable_wireframe(bool enable) {
  session_wrapper_.Enqueue(
      scenic::NewSetEnableDebugViewBoundsCmd(root_view_.id(), enable));
}

void SessionConnection::EnqueueClearOps() {
  // We are going to be sending down a fresh node hierarchy every frame. So just
  // enqueue a detach op on the imported root node.
  session_wrapper_.Enqueue(scenic::NewDetachChildrenCmd(root_node_.id()));
}

void SessionConnection::PresentSession() {
  TRACE_EVENT0("gfx", "SessionConnection::PresentSession");
  while (processed_present_session_trace_id_ < next_present_session_trace_id_) {
    TRACE_FLOW_END("gfx", "SessionConnection::PresentSession",
                   processed_present_session_trace_id_);
    processed_present_session_trace_id_++;
  }
  TRACE_FLOW_BEGIN("gfx", "Session::Present", next_present_trace_id_);
  next_present_trace_id_++;

  // Presentation callback is pending as a result of Present() call below.
  presentation_callback_pending_ = true;

  // Flush all session ops. Paint tasks may not yet have executed but those are
  // fenced. The compositor can start processing ops while we finalize paint
  // tasks.
  session_wrapper_.Present(
      0,  // presentation_time. (placeholder).
      [this, handle = vsync_event_handle_](
          fuchsia::images::PresentationInfo presentation_info) {
        presentation_callback_pending_ = false;
        VsyncRecorder::GetInstance().UpdateVsyncInfo(presentation_info);
        // Process pending PresentSession() calls.
        if (present_session_pending_) {
          present_session_pending_ = false;
          PresentSession();
        }
        ToggleSignal(handle, true);
      }  // callback
  );

  // Prepare for the next frame. These ops won't be processed till the next
  // present.
  EnqueueClearOps();
}

void SessionConnection::ToggleSignal(zx_handle_t handle, bool set) {
  const auto signal = VsyncWaiter::SessionPresentSignal;
  auto status = zx_object_signal(handle,            // handle
                                 set ? 0 : signal,  // clear mask
                                 set ? signal : 0   // set mask
  );
  if (status != ZX_OK) {
    FML_LOG(ERROR) << "Could not toggle vsync signal: " << set;
  }
}

}  // namespace flutter_runner
