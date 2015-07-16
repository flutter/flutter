// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_LATENCY_INFO_H_
#define UI_EVENTS_LATENCY_INFO_H_

#include <utility>
#include <vector>

#include "base/basictypes.h"
#include "base/containers/small_map.h"
#include "base/time/time.h"
#include "ui/events/events_base_export.h"

namespace ui {

enum LatencyComponentType {
  // ---------------------------BEGIN COMPONENT-------------------------------
  // BEGIN COMPONENT is when we show the latency begin in chrome://tracing.
  // Timestamp when the input event is sent from RenderWidgetHost to renderer.
  INPUT_EVENT_LATENCY_BEGIN_RWH_COMPONENT,
  // Timestamp when the input event is received in plugin.
  INPUT_EVENT_LATENCY_BEGIN_PLUGIN_COMPONENT,
  // Timestamp when a scroll update for the main thread is begun.
  INPUT_EVENT_LATENCY_BEGIN_SCROLL_UPDATE_MAIN_COMPONENT,
  // ---------------------------NORMAL COMPONENT-------------------------------
  // The original timestamp of the touch event which converts to scroll update.
  INPUT_EVENT_LATENCY_SCROLL_UPDATE_ORIGINAL_COMPONENT,
  // The original timestamp of the touch event which converts to the *first*
  // scroll update in a scroll gesture sequence.
  INPUT_EVENT_LATENCY_FIRST_SCROLL_UPDATE_ORIGINAL_COMPONENT,
  // Original timestamp for input event (e.g. timestamp from kernel).
  INPUT_EVENT_LATENCY_ORIGINAL_COMPONENT,
  // Timestamp when the UI event is created.
  INPUT_EVENT_LATENCY_UI_COMPONENT,
  // This is special component indicating there is rendering scheduled for
  // the event associated with this LatencyInfo on main thread.
  INPUT_EVENT_LATENCY_RENDERING_SCHEDULED_MAIN_COMPONENT,
  // This is special component indicating there is rendering scheduled for
  // the event associated with this LatencyInfo on impl thread.
  INPUT_EVENT_LATENCY_RENDERING_SCHEDULED_IMPL_COMPONENT,
  // Timestamp when a scroll update is forwarded to the main thread.
  INPUT_EVENT_LATENCY_FORWARD_SCROLL_UPDATE_TO_MAIN_COMPONENT,
  // Timestamp when the event's ack is received by the RWH.
  INPUT_EVENT_LATENCY_ACK_RWH_COMPONENT,
  // Frame number when a window snapshot was requested. The snapshot
  // is taken when the rendering results actually reach the screen.
  WINDOW_SNAPSHOT_FRAME_NUMBER_COMPONENT,
  // Frame number for a snapshot requested via
  // gpuBenchmarking.beginWindowSnapshotPNG
  // TODO(vkuzkokov): remove when patch adding this hits Stable
  WINDOW_OLD_SNAPSHOT_FRAME_NUMBER_COMPONENT,
  // Timestamp when a tab is requested to be shown.
  TAB_SHOW_COMPONENT,
  // Timestamp when the frame is swapped in renderer.
  INPUT_EVENT_LATENCY_RENDERER_SWAP_COMPONENT,
  // Timestamp of when the browser process receives a buffer swap notification
  // from the renderer.
  INPUT_EVENT_BROWSER_RECEIVED_RENDERER_SWAP_COMPONENT,
  // Timestamp of when the gpu service began swap buffers, unlike
  // INPUT_EVENT_LATENCY_TERMINATED_FRAME_SWAP_COMPONENT which measures after.
  INPUT_EVENT_GPU_SWAP_BUFFER_COMPONENT,
  // ---------------------------TERMINAL COMPONENT-----------------------------
  // TERMINAL COMPONENT is when we show the latency end in chrome://tracing.
  // Timestamp when the mouse event is acked from renderer and it does not
  // cause any rendering scheduled.
  INPUT_EVENT_LATENCY_TERMINATED_MOUSE_COMPONENT,
  // Timestamp when the touch event is acked from renderer and it does not
  // cause any rendering schedueld and does not generate any gesture event.
  INPUT_EVENT_LATENCY_TERMINATED_TOUCH_COMPONENT,
  // Timestamp when the gesture event is acked from renderer, and it does not
  // cause any rendering schedueld.
  INPUT_EVENT_LATENCY_TERMINATED_GESTURE_COMPONENT,
  // Timestamp when the frame is swapped (i.e. when the rendering caused by
  // input event actually takes effect).
  INPUT_EVENT_LATENCY_TERMINATED_FRAME_SWAP_COMPONENT,
  // This component indicates that the input causes a commit to be scheduled
  // but the commit failed.
  INPUT_EVENT_LATENCY_TERMINATED_COMMIT_FAILED_COMPONENT,
  // This component indicates that the input causes a commit to be scheduled
  // but the commit was aborted since it carried no new information.
  INPUT_EVENT_LATENCY_TERMINATED_COMMIT_NO_UPDATE_COMPONENT,
  // This component indicates that the input causes a swap to be scheduled
  // but the swap failed.
  INPUT_EVENT_LATENCY_TERMINATED_SWAP_FAILED_COMPONENT,
  // Timestamp when the input event is considered not cause any rendering
  // damage in plugin and thus terminated.
  INPUT_EVENT_LATENCY_TERMINATED_PLUGIN_COMPONENT,
  LATENCY_COMPONENT_TYPE_LAST = INPUT_EVENT_LATENCY_TERMINATED_PLUGIN_COMPONENT
};

struct EVENTS_BASE_EXPORT LatencyInfo {
  struct LatencyComponent {
    // Nondecreasing number that can be used to determine what events happened
    // in the component at the time this struct was sent on to the next
    // component.
    int64 sequence_number;
    // Average time of events that happened in this component.
    base::TimeTicks event_time;
    // Count of events that happened in this component
    uint32 event_count;
  };

  struct EVENTS_BASE_EXPORT InputCoordinate {
    InputCoordinate();
    InputCoordinate(float x, float y);

    float x;
    float y;
  };

  // Empirically determined constant based on a typical scroll sequence.
  enum { kTypicalMaxComponentsPerLatencyInfo = 10 };

  enum { kMaxInputCoordinates = 2 };

  // Map a Latency Component (with a component-specific int64 id) to a
  // component info.
  typedef base::SmallMap<
      std::map<std::pair<LatencyComponentType, int64>, LatencyComponent>,
      kTypicalMaxComponentsPerLatencyInfo> LatencyMap;

  LatencyInfo();

  ~LatencyInfo();

  // Returns true if the vector |latency_info| is valid. Returns false
  // if it is not valid and log the |referring_msg|.
  // This function is mainly used to check the latency_info vector that
  // is passed between processes using IPC message has reasonable size
  // so that we are confident the IPC message is not corrupted/compromised.
  // This check will go away once the IPC system has better built-in scheme
  // for corruption/compromise detection.
  static bool Verify(const std::vector<LatencyInfo>& latency_info,
                     const char* referring_msg);

  // Copy LatencyComponents with type |type| from |other| into |this|.
  void CopyLatencyFrom(const LatencyInfo& other, LatencyComponentType type);

  // Add LatencyComponents that are in |other| but not in |this|.
  void AddNewLatencyFrom(const LatencyInfo& other);

  // Modifies the current sequence number for a component, and adds a new
  // sequence number with the current timestamp.
  void AddLatencyNumber(LatencyComponentType component,
                        int64 id,
                        int64 component_sequence_number);

  // Modifies the current sequence number and adds a certain number of events
  // for a specific component.
  void AddLatencyNumberWithTimestamp(LatencyComponentType component,
                                     int64 id,
                                     int64 component_sequence_number,
                                     base::TimeTicks time,
                                     uint32 event_count);

  // Returns true if the a component with |type| and |id| is found in
  // the latency_components and the component is stored to |output| if
  // |output| is not NULL. Returns false if no such component is found.
  bool FindLatency(LatencyComponentType type,
                   int64 id,
                   LatencyComponent* output) const;

  void RemoveLatency(LatencyComponentType type);

  void Clear();

  // Records the |event_type| in trace buffer as TRACE_EVENT_ASYNC_STEP.
  void TraceEventType(const char* event_type);

  LatencyMap latency_components;

  // These coordinates represent window coordinates of the original input event.
  uint32 input_coordinates_size;
  InputCoordinate input_coordinates[kMaxInputCoordinates];

  // The unique id for matching the ASYNC_BEGIN/END trace event.
  int64 trace_id;
  // Whether a terminal component has been added.
  bool terminated;
};

}  // namespace ui

#endif  // UI_EVENTS_LATENCY_INFO_H_
