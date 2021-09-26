// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_POINTER_DELEGATE_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_POINTER_DELEGATE_H_

#include <fuchsia/ui/pointer/cpp/fidl.h>

#include <functional>
#include <optional>
#include <unordered_map>
#include <vector>

#include "flutter/lib/ui/window/pointer_data.h"

namespace flutter_runner {

// Helper class for keying into a map.
struct IxnHasher {
  std::size_t operator()(
      const fuchsia::ui::pointer::TouchInteractionId& ixn) const {
    return std::hash<uint32_t>()(ixn.device_id) ^
           std::hash<uint32_t>()(ixn.pointer_id) ^
           std::hash<uint32_t>()(ixn.interaction_id);
  }
};

// Channel processor for fuchsia.ui.pointer.TouchSource protocol. It manages the
// channel state, collects touch events, and surfaces them to PlatformView as
// flutter::PointerData events for further processing and dispatch.
class PointerDelegate {
 public:
  PointerDelegate(
      fidl::InterfaceHandle<fuchsia::ui::pointer::TouchSource> touch_source)
      : touch_source_(touch_source.Bind()) {}

  // Each TouchEvent must carry a TouchPointerSample, and the supplied callback
  // will translate each to a flutter::PointerData, and the vector of
  // PointerData placed in a PointerDataPacket for transport to the Engine.
  void WatchLoop(
      std::function<void(std::vector<flutter::PointerData>)> callback);

 private:
  // Channel for touch events from Scenic.
  fuchsia::ui::pointer::TouchSourcePtr touch_source_;

  // Receive touch events from Scenic. Must be copyable.
  std::function<void(std::vector<fuchsia::ui::pointer::TouchEvent>)>
      watch_loop_;

  // Per-interaction buffer of touch events from Scenic. When an interaction
  // starts with event.pointer_sample.phase == ADD, we allocate a buffer and
  // store samples. When interaction ownership becomes
  // event.interaction_result.status == GRANTED, we flush the buffer to client,
  // delete the buffer, and all future events in this interaction are flushed
  // direct to client. When interaction ownership becomes DENIED, we delete the
  // buffer, and the client does not get any previous or future events in this
  // interaction.
  //
  // There are three basic interaction forms that we need to handle, and the API
  // guarantees we see only these three forms. S=sample, R(g)=result-granted,
  // R(d)=result-denied, and + means packaged in the same table. Time flows from
  // left to right. Samples start with ADD, and end in REMOVE or CANCEL. Each
  // interaction receives just one ownership result.
  //   (1) Late grant. S S S R(g) S S S
  //   (1-a) Combo.    S S S+R(g) S S S
  //   (2) Early grant. S+R(g) S S S S S
  //   (3) Late deny. S S S R(d)
  //   (3-a) Combo.   S S S+R(d)
  //
  // This results in the following high-level algorithm to correctly deal with
  // buffer allocation and deletion, and event flushing or event dropping based
  // on ownership.
  //   if event.sample.phase == ADD && !event.result
  //     allocate buffer[event.sample.interaction]
  //   if buffer[event.sample.interaction]
  //     buffer[event.sample.interaction].push(event.sample)
  //   else
  //     flush_to_client(event.sample)
  //   if event.result
  //     if event.result == GRANTED
  //       flush_to_client(buffer[event.result.interaction])
  //     delete buffer[event.result.interaction]
  std::unordered_map<fuchsia::ui::pointer::TouchInteractionId,
                     std::vector<flutter::PointerData>,
                     IxnHasher>
      buffer_;

  // The fuchsia.ui.pointer.TouchSource protocol allows one in-flight
  // hanging-get Watch() call to gather touch events, and the client is expected
  // to respond with consumption intent on the following hanging-get Watch()
  // call. Store responses here for the next call.
  std::vector<fuchsia::ui::pointer::TouchResponse> responses_;

  // The fuchsia.ui.pointer.TouchSource protocol issues a channel-global view
  // parameters on connection and on change. Events must apply these view
  // parameters to correctly map to logical view coordinates. The "nullopt"
  // state represents the absence of view parameters, early in the protocol
  // lifecycle.
  std::optional<fuchsia::ui::pointer::ViewParameters> view_parameters_;
};

}  // namespace flutter_runner
#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_POINTER_DELEGATE_H_
