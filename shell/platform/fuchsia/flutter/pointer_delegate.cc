// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "pointer_delegate.h"

#include <lib/trace/event.h>

#include <limits>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace fuchsia::ui::pointer {
// For using TouchInteractionId as a map key.
bool operator==(const fuchsia::ui::pointer::TouchInteractionId& a,
                const fuchsia::ui::pointer::TouchInteractionId& b) {
  return a.device_id == b.device_id && a.pointer_id == b.pointer_id &&
         a.interaction_id == b.interaction_id;
}
}  // namespace fuchsia::ui::pointer

namespace flutter_runner {

using fup_EventPhase = fuchsia::ui::pointer::EventPhase;
using fup_TouchEvent = fuchsia::ui::pointer::TouchEvent;
using fup_TouchIxnStatus = fuchsia::ui::pointer::TouchInteractionStatus;
using fup_TouchResponse = fuchsia::ui::pointer::TouchResponse;
using fup_TouchResponseType = fuchsia::ui::pointer::TouchResponseType;
using fup_ViewParameters = fuchsia::ui::pointer::ViewParameters;

namespace {
void MaybeIssueTraceEvent(const fup_TouchEvent& event) {
  if (event.has_trace_flow_id()) {
    TRACE_FLOW_END("input", "dispatch_event_to_client", event.trace_flow_id());
  }
}

bool HasValidatedPointerSample(const fup_TouchEvent& event) {
  if (!event.has_pointer_sample()) {
    return false;
  }
  FML_DCHECK(event.pointer_sample().has_interaction()) << "API guarantee";
  FML_DCHECK(event.pointer_sample().has_phase()) << "API guarantee";
  FML_DCHECK(event.pointer_sample().has_position_in_viewport())
      << "API guarantee";
  return true;
}

std::array<float, 2> ViewportToViewCoordinates(
    std::array<float, 2> viewport_coordinates,
    const std::array<float, 9>& viewport_to_view_transform) {
  // The transform matrix is a FIDL array with matrix data in column-major
  // order. For a matrix with data [a b c d e f g h i], and with the viewport
  // coordinates expressed as homogeneous coordinates, the logical view
  // coordinates are obtained with the following formula:
  //   |a d g|   |x|   |x'|
  //   |b e h| * |y| = |y'|
  //   |c f i|   |1|   |w'|
  // which we then normalize based on the w component:
  //   if z' not zero: (x'/w', y'/w')
  //   else (x', y')
  const auto& M = viewport_to_view_transform;
  const float x = viewport_coordinates[0];
  const float y = viewport_coordinates[1];
  const float xp = M[0] * x + M[3] * y + M[6];
  const float yp = M[1] * x + M[4] * y + M[7];
  const float wp = M[2] * x + M[5] * y + M[8];
  if (wp != 0) {
    return {xp / wp, yp / wp};
  } else {
    return {xp, yp};
  }
}

flutter::PointerData::Change GetChangeFromPointerEventPhase(
    fup_EventPhase phase) {
  switch (phase) {
    case fup_EventPhase::ADD:
      return flutter::PointerData::Change::kAdd;
    case fup_EventPhase::CHANGE:
      return flutter::PointerData::Change::kMove;
    case fup_EventPhase::REMOVE:
      return flutter::PointerData::Change::kRemove;
    case fup_EventPhase::CANCEL:
      return flutter::PointerData::Change::kCancel;
    default:
      return flutter::PointerData::Change::kCancel;
  }
}

std::array<float, 2> ClampToViewSpace(const float x,
                                      const float y,
                                      const fup_ViewParameters& p) {
  const float min_x = p.view.min[0];
  const float min_y = p.view.min[1];
  const float max_x = p.view.max[0];
  const float max_y = p.view.max[1];
  if (min_x <= x && x < max_x && min_y <= y && y < max_y) {
    return {x, y};  // No clamping to perform.
  }

  // View boundary is [min_x, max_x) x [min_y, max_y). Note that min is
  // inclusive, but max is exclusive - so we subtract epsilon.
  const float max_x_inclusive = max_x - std::numeric_limits<float>::epsilon();
  const float max_y_inclusive = max_y - std::numeric_limits<float>::epsilon();
  const float& clamped_x = std::clamp(x, min_x, max_x_inclusive);
  const float& clamped_y = std::clamp(y, min_y, max_y_inclusive);
  FML_LOG(INFO) << "Clamped (" << x << ", " << y << ") to (" << clamped_x
                << ", " << clamped_y << ").";
  return {clamped_x, clamped_y};
}

// It returns a "draft" because the coordinates are logical. Later, view pixel
// ratio is applied to obtain physical coordinates.
//
// The flutter pointerdata state machine has extra phases, which this function
// synthesizes on the fly. Hence the return data is a flutter pointerdata, and
// optionally a second synthesized one.
// For example: <ADD, DOWN>, <MOVE, nullopt>, <UP, REMOVE>.
//
// Flutter gestures expect a gesture to start within the logical view space, and
// is not tolerant of floating point drift. This function coerces just the DOWN
// event's coordinate to start within the logical view.
std::pair<flutter::PointerData, std::optional<flutter::PointerData>>
CreatePointerDraft(const fup_TouchEvent& event,
                   const fup_ViewParameters& view_parameters) {
  FML_DCHECK(HasValidatedPointerSample(event)) << "precondition";
  const auto& sample = event.pointer_sample();
  flutter::PointerData ptr;
  ptr.Clear();
  ptr.time_stamp = event.timestamp() / 1000;  // in microseconds
  ptr.change = GetChangeFromPointerEventPhase(sample.phase());
  ptr.kind = flutter::PointerData::DeviceKind::kTouch;
  ptr.device = sample.interaction().device_id;
  ptr.pointer_identifier = sample.interaction().pointer_id;
  // View parameters can change mid-interaction; apply transform on the fly.
  auto logical =
      ViewportToViewCoordinates(sample.position_in_viewport(),
                                view_parameters.viewport_to_view_transform);
  ptr.physical_x = logical[0];  // Not yet physical; adjusted in PlatformView.
  ptr.physical_y = logical[1];  // Not yet physical; adjusted in PlatformView.

  // Match Flutter pointer's state machine with synthesized events.
  if (ptr.change == flutter::PointerData::Change::kAdd) {
    flutter::PointerData down;
    memcpy(&down, &ptr, sizeof(flutter::PointerData));
    down.change = flutter::PointerData::Change::kDown;
    {  // DOWN event needs to start in the logical view space.
      auto [x, y] =
          ClampToViewSpace(down.physical_x, down.physical_y, view_parameters);
      down.physical_x = x;
      down.physical_y = y;
    }
    return {std::move(ptr), std::move(down)};
  } else if (ptr.change == flutter::PointerData::Change::kRemove) {
    flutter::PointerData up;
    memcpy(&up, &ptr, sizeof(flutter::PointerData));
    up.change = flutter::PointerData::Change::kUp;
    return {std::move(up), std::move(ptr)};
  } else {
    return {std::move(ptr), std::nullopt};
  }
}

// Helper to insert one or two events into a vector buffer.
void InsertIntoBuffer(
    std::pair<flutter::PointerData, std::optional<flutter::PointerData>> events,
    std::vector<flutter::PointerData>* buffer) {
  FML_DCHECK(buffer);
  buffer->emplace_back(std::move(events.first));
  if (events.second.has_value()) {
    buffer->emplace_back(std::move(events.second.value()));
  }
}
}  // namespace

// Core logic of this class.
void PointerDelegate::WatchLoop(
    std::function<void(std::vector<flutter::PointerData>)> callback) {
  FML_LOG(INFO) << "Flutter - PointerDelegate started.";
  if (watch_loop_) {
    FML_LOG(ERROR) << "PointerDelegate::WatchLoop() must be called once.";
    return;
  }

  watch_loop_ = [this, callback](std::vector<fup_TouchEvent> events) {
    TRACE_EVENT0("flutter", "PointerDelegate::TouchHandler");
    FML_DCHECK(responses_.empty()) << "precondition";
    std::vector<flutter::PointerData> to_client;
    for (const fup_TouchEvent& event : events) {
      MaybeIssueTraceEvent(event);
      fup_TouchResponse
          response;  // Response per event, matched on event's index.
      if (event.has_view_parameters()) {
        view_parameters_ = std::move(event.view_parameters());
      }
      if (HasValidatedPointerSample(event)) {
        const auto& sample = event.pointer_sample();
        const auto& ixn = sample.interaction();
        if (sample.phase() == fup_EventPhase::ADD &&
            !event.has_interaction_result()) {
          buffer_.emplace(ixn, std::vector<flutter::PointerData>());
        }

        FML_DCHECK(view_parameters_.has_value()) << "API guarantee";
        auto events = CreatePointerDraft(event, view_parameters_.value());
        if (buffer_.count(ixn) > 0) {
          InsertIntoBuffer(std::move(events), &buffer_[ixn]);
        } else {
          InsertIntoBuffer(std::move(events), &to_client);
        }
        // For this simple client, always claim we want the gesture.
        response.set_response_type(fup_TouchResponseType::YES_PRIORITIZE);
      }
      if (event.has_interaction_result()) {
        const auto& result = event.interaction_result();
        const auto& ixn = result.interaction;
        if (result.status == fup_TouchIxnStatus::GRANTED &&
            buffer_.count(ixn) > 0) {
          FML_DCHECK(to_client.empty()) << "invariant";
          to_client.insert(to_client.end(), buffer_[ixn].begin(),
                           buffer_[ixn].end());
        }
        buffer_.erase(ixn);  // Result seen, delete the buffer.
      }
      responses_.push_back(std::move(response));
    }
    callback(std::move(to_client));  // Notify client of touch events, if any.

    touch_source_->Watch(std::move(responses_), /*copy*/ watch_loop_);
    responses_.clear();
  };

  touch_source_->Watch(std::move(responses_), /*copy*/ watch_loop_);
  responses_.clear();
}

}  // namespace flutter_runner
