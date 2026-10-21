// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/window/pointer_data_packet_converter.h"

#include <cmath>
#include <cstring>

#include "flutter/fml/logging.h"

namespace flutter {

PointerDataPacketConverter::PointerDataPacketConverter(const Delegate& delegate)
    : delegate_(delegate) {}

PointerDataPacketConverter::~PointerDataPacketConverter() = default;

std::unique_ptr<PointerDataPacket> PointerDataPacketConverter::Convert(
    const PointerDataPacket& packet) {
  std::vector<PointerData> converted_pointers;
  // Converts each pointer data in the buffer and stores it in the
  // converted_pointers.
  for (size_t i = 0; i < packet.GetLength(); i++) {
    PointerData pointer_data = packet.GetPointerData(i);
    ConvertPointerData(pointer_data, converted_pointers);
  }

  // Writes converted_pointers into converted_packet.
  auto converted_packet =
      std::make_unique<flutter::PointerDataPacket>(converted_pointers.size());
  size_t count = 0;
  for (auto& converted_pointer : converted_pointers) {
    converted_packet->SetPointerData(count++, converted_pointer);
  }

  return converted_packet;
}

void PointerDataPacketConverter::ConvertPointerData(
    PointerData pointer_data,
    std::vector<PointerData>& converted_pointers) {
  // Ignores pointer events with an invalid view ID.
  if (!delegate_.ViewExists(pointer_data.view_id)) {
    return;
  }
  // Some devices occasionally report non-finite positions. Storing them in
  // `states_` would make every later delta of the pointer non-finite.
  if (!SanitizeNonFinitePosition(pointer_data)) {
    return;
  }
  if (pointer_data.signal_kind == PointerData::SignalKind::kNone) {
    switch (pointer_data.change) {
      case PointerData::Change::kCancel: {
        // Android's three finger gesture will send a cancel event
        // to a non-existing pointer. Drops the cancel if pointer
        // is not previously added.
        // https://github.com/flutter/flutter/issues/20517
        // The cancel is also dropped if the down was dropped because its
        // position was not finite.
        auto iter = states_.find(pointer_data.device);
        if (iter != states_.end() && iter->second.is_down) {
          PointerState state = iter->second;
          UpdatePointerIdentifier(pointer_data, state, false);

          if (LocationNeedsUpdate(pointer_data, state)) {
            // Synthesizes a move event if the location does not match.
            PointerData synthesized_move_event = pointer_data;
            synthesized_move_event.change = PointerData::Change::kMove;
            synthesized_move_event.synthesized = 1;

            UpdateDeltaAndState(synthesized_move_event, state);
            converted_pointers.push_back(synthesized_move_event);
          }

          state.is_down = false;
          states_[pointer_data.device] = state;
          converted_pointers.push_back(pointer_data);
        }
        break;
      }
      case PointerData::Change::kAdd: {
        auto iter = states_.find(pointer_data.device);
        if (iter != states_.end()) {
          // Synthesizes a remove event if the pointer was not previously
          // removed.
          PointerState state = iter->second;
          PointerData synthesized_data = pointer_data;
          synthesized_data.physical_x = state.physical_x;
          synthesized_data.physical_y = state.physical_y;
          synthesized_data.pan_x = state.pan_x;
          synthesized_data.pan_y = state.pan_y;
          synthesized_data.scale = state.scale;
          synthesized_data.rotation = state.rotation;
          synthesized_data.buttons = state.buttons;
          synthesized_data.synthesized = 1;

          // The framework expects an add event to always follow a remove event,
          // and remove events with invalid views are ignored.
          // To meet the framework's expectations, the view ID of the add event
          // is used for the remove event if the old view has been destroyed.
          if (delegate_.ViewExists(state.view_id)) {
            synthesized_data.view_id = state.view_id;

            if (state.is_down) {
              // Synthesizes cancel event if the pointer is down.
              PointerData synthesized_cancel_event = synthesized_data;
              synthesized_cancel_event.change = PointerData::Change::kCancel;
              UpdatePointerIdentifier(synthesized_cancel_event, state, false);

              state.is_down = false;
              converted_pointers.push_back(synthesized_cancel_event);
            }
          }

          PointerData synthesized_remove_event = synthesized_data;
          synthesized_remove_event.change = PointerData::Change::kRemove;

          converted_pointers.push_back(synthesized_remove_event);
        }

        EnsurePointerState(pointer_data);
        converted_pointers.push_back(pointer_data);
        break;
      }
      case PointerData::Change::kRemove: {
        // Drops the remove if the pointer was not added, which happens when
        // its add or down was dropped because its position was not finite.
        auto iter = states_.find(pointer_data.device);
        if (iter == states_.end()) {
          break;
        }
        PointerState state = iter->second;
        if (state.view_id != pointer_data.view_id) {
          // Ignores remove event if the pointer was previously added to a
          // different view.
          break;
        }

        if (state.is_down) {
          // Synthesizes cancel event if the pointer is down.
          PointerData synthesized_cancel_event = pointer_data;
          synthesized_cancel_event.change = PointerData::Change::kCancel;
          synthesized_cancel_event.synthesized = 1;
          UpdatePointerIdentifier(synthesized_cancel_event, state, false);

          state.is_down = false;
          states_[synthesized_cancel_event.device] = state;
          converted_pointers.push_back(synthesized_cancel_event);
        }

        if (LocationNeedsUpdate(pointer_data, state)) {
          // Synthesizes a hover event if the location does not match.
          PointerData synthesized_hover_event = pointer_data;
          synthesized_hover_event.change = PointerData::Change::kHover;
          synthesized_hover_event.synthesized = 1;

          UpdateDeltaAndState(synthesized_hover_event, state);
          converted_pointers.push_back(synthesized_hover_event);
        }

        states_.erase(pointer_data.device);
        converted_pointers.push_back(pointer_data);
        break;
      }
      case PointerData::Change::kHover: {
        auto iter = states_.find(pointer_data.device);
        PointerState state{};
        if (iter == states_.end()) {
          // Synthesizes add event if the pointer is not previously added.
          PointerData synthesized_add_event = pointer_data;
          synthesized_add_event.change = PointerData::Change::kAdd;
          synthesized_add_event.synthesized = 1;
          synthesized_add_event.buttons = 0;
          state = EnsurePointerState(synthesized_add_event);
          converted_pointers.push_back(synthesized_add_event);
        } else {
          state = iter->second;
        }

        FML_DCHECK(!state.is_down);
        state.buttons = pointer_data.buttons;
        if (LocationNeedsUpdate(pointer_data, state)) {
          UpdateDeltaAndState(pointer_data, state);
          converted_pointers.push_back(pointer_data);
        }
        break;
      }
      case PointerData::Change::kDown: {
        auto iter = states_.find(pointer_data.device);
        PointerState state{};
        if (iter == states_.end()) {
          // Synthesizes a add event if the pointer is not previously added.
          PointerData synthesized_add_event = pointer_data;
          synthesized_add_event.change = PointerData::Change::kAdd;
          synthesized_add_event.synthesized = 1;
          synthesized_add_event.buttons = 0;
          state = EnsurePointerState(synthesized_add_event);
          converted_pointers.push_back(synthesized_add_event);
        } else {
          state = iter->second;
        }

        FML_DCHECK(!state.is_down);
        if (LocationNeedsUpdate(pointer_data, state)) {
          // Synthesizes a hover event if the location does not match.
          PointerData synthesized_hover_event = pointer_data;
          synthesized_hover_event.change = PointerData::Change::kHover;
          synthesized_hover_event.synthesized = 1;
          synthesized_hover_event.buttons = 0;

          UpdateDeltaAndState(synthesized_hover_event, state);
          converted_pointers.push_back(synthesized_hover_event);
        }

        UpdatePointerIdentifier(pointer_data, state, true);
        state.is_down = true;
        state.buttons = pointer_data.buttons;
        states_[pointer_data.device] = state;
        converted_pointers.push_back(pointer_data);
        break;
      }
      case PointerData::Change::kMove: {
        // Drops the move if the pointer is not down, which happens when its
        // down was dropped because its position was not finite.
        auto iter = states_.find(pointer_data.device);
        if (iter == states_.end() || !iter->second.is_down) {
          break;
        }
        PointerState state = iter->second;

        UpdatePointerIdentifier(pointer_data, state, false);
        UpdateDeltaAndState(pointer_data, state);
        state.buttons = pointer_data.buttons;
        converted_pointers.push_back(pointer_data);
        break;
      }
      case PointerData::Change::kUp: {
        // Drops the up if the pointer is not down, which happens when its
        // down was dropped because its position was not finite.
        auto iter = states_.find(pointer_data.device);
        if (iter == states_.end() || !iter->second.is_down) {
          break;
        }
        PointerState state = iter->second;

        UpdatePointerIdentifier(pointer_data, state, false);

        if (LocationNeedsUpdate(pointer_data, state)) {
          // Synthesizes a move event if the location does not match.
          PointerData synthesized_move_event = pointer_data;
          synthesized_move_event.change = PointerData::Change::kMove;
          synthesized_move_event.buttons = state.buttons;
          synthesized_move_event.synthesized = 1;

          UpdateDeltaAndState(synthesized_move_event, state);
          converted_pointers.push_back(synthesized_move_event);
        }

        state.is_down = false;
        state.buttons = pointer_data.buttons;
        states_[pointer_data.device] = state;
        converted_pointers.push_back(pointer_data);
        break;
      }
      case PointerData::Change::kPanZoomStart: {
        // Makes sure we have an existing pointer
        auto iter = states_.find(pointer_data.device);
        PointerState state{};
        if (iter == states_.end()) {
          // Synthesizes add event if the pointer is not previously added.
          PointerData synthesized_add_event = pointer_data;
          synthesized_add_event.change = PointerData::Change::kAdd;
          synthesized_add_event.synthesized = 1;
          synthesized_add_event.buttons = 0;
          state = EnsurePointerState(synthesized_add_event);
          converted_pointers.push_back(synthesized_add_event);
        } else {
          state = iter->second;
        }
        FML_DCHECK(!state.is_down);
        FML_DCHECK(!state.is_pan_zoom_active);
        if (LocationNeedsUpdate(pointer_data, state)) {
          // Synthesizes a hover event if the location does not match.
          PointerData synthesized_hover_event = pointer_data;
          synthesized_hover_event.change = PointerData::Change::kHover;
          synthesized_hover_event.synthesized = 1;
          synthesized_hover_event.buttons = 0;

          UpdateDeltaAndState(synthesized_hover_event, state);
          converted_pointers.push_back(synthesized_hover_event);
        }

        UpdatePointerIdentifier(pointer_data, state, true);
        state.is_pan_zoom_active = true;
        state.pan_x = 0;
        state.pan_y = 0;
        state.scale = 1;
        state.rotation = 0;
        states_[pointer_data.device] = state;
        converted_pointers.push_back(pointer_data);
        break;
      }
      case PointerData::Change::kPanZoomUpdate: {
        // Drops the update if the pointer is not in a pan/zoom, which happens
        // when its pan/zoom start was dropped because its position was not
        // finite.
        auto iter = states_.find(pointer_data.device);
        if (iter == states_.end() || !iter->second.is_pan_zoom_active) {
          break;
        }
        PointerState state = iter->second;
        FML_DCHECK(!state.is_down);

        UpdatePointerIdentifier(pointer_data, state, false);
        UpdateDeltaAndState(pointer_data, state);

        converted_pointers.push_back(pointer_data);
        break;
      }
      case PointerData::Change::kPanZoomEnd: {
        // Drops the end if the pointer is not in a pan/zoom, which happens
        // when its pan/zoom start was dropped because its position was not
        // finite.
        auto iter = states_.find(pointer_data.device);
        if (iter == states_.end() || !iter->second.is_pan_zoom_active) {
          break;
        }
        PointerState state = iter->second;

        UpdatePointerIdentifier(pointer_data, state, false);

        if (LocationNeedsUpdate(pointer_data, state)) {
          // Synthesizes an update event if the location does not match.
          PointerData synthesized_move_event = pointer_data;
          synthesized_move_event.change = PointerData::Change::kPanZoomUpdate;
          synthesized_move_event.pan_x = state.pan_x;
          synthesized_move_event.pan_y = state.pan_y;
          synthesized_move_event.pan_delta_x = 0;
          synthesized_move_event.pan_delta_y = 0;
          synthesized_move_event.scale = state.scale;
          synthesized_move_event.rotation = state.rotation;
          synthesized_move_event.synthesized = 1;

          UpdateDeltaAndState(synthesized_move_event, state);
          converted_pointers.push_back(synthesized_move_event);
        }

        state.is_pan_zoom_active = false;
        states_[pointer_data.device] = state;
        converted_pointers.push_back(pointer_data);
        break;
      }
      default: {
        converted_pointers.push_back(pointer_data);
        break;
      }
    }
  } else {
    switch (pointer_data.signal_kind) {
      case PointerData::SignalKind::kScroll:
      case PointerData::SignalKind::kScrollInertiaCancel:
      case PointerData::SignalKind::kScale: {
        // Makes sure we have an existing pointer
        auto iter = states_.find(pointer_data.device);
        PointerState state{};

        if (iter == states_.end()) {
          // Synthesizes a add event if the pointer is not previously added.
          PointerData synthesized_add_event = pointer_data;
          synthesized_add_event.signal_kind = PointerData::SignalKind::kNone;
          synthesized_add_event.change = PointerData::Change::kAdd;
          synthesized_add_event.synthesized = 1;
          synthesized_add_event.buttons = 0;
          state = EnsurePointerState(synthesized_add_event);
          converted_pointers.push_back(synthesized_add_event);
        } else {
          state = iter->second;
        }

        if (LocationNeedsUpdate(pointer_data, state)) {
          if (state.is_down) {
            // Synthesizes a move event if the pointer is down.
            PointerData synthesized_move_event = pointer_data;
            synthesized_move_event.signal_kind = PointerData::SignalKind::kNone;
            synthesized_move_event.change = PointerData::Change::kMove;
            synthesized_move_event.buttons = state.buttons;
            synthesized_move_event.synthesized = 1;

            UpdateDeltaAndState(synthesized_move_event, state);
            converted_pointers.push_back(synthesized_move_event);
          } else {
            // Synthesizes a hover event if the pointer is up.
            PointerData synthesized_hover_event = pointer_data;
            synthesized_hover_event.signal_kind =
                PointerData::SignalKind::kNone;
            synthesized_hover_event.change = PointerData::Change::kHover;
            synthesized_hover_event.buttons = 0;
            synthesized_hover_event.synthesized = 1;

            UpdateDeltaAndState(synthesized_hover_event, state);
            converted_pointers.push_back(synthesized_hover_event);
          }
        }

        converted_pointers.push_back(pointer_data);
        break;
      }
      default: {
        // Ignores unknown signal kind.
        break;
      }
    }
  }
}

PointerState PointerDataPacketConverter::EnsurePointerState(
    PointerData pointer_data) {
  PointerState state{};
  state.pointer_identifier = 0;
  state.is_down = false;
  state.is_pan_zoom_active = false;
  state.physical_x = pointer_data.physical_x;
  state.physical_y = pointer_data.physical_y;
  state.pan_x = 0;
  state.pan_y = 0;
  state.view_id = pointer_data.view_id;
  states_[pointer_data.device] = state;
  return state;
}

void PointerDataPacketConverter::UpdateDeltaAndState(PointerData& pointer_data,
                                                     PointerState& state) {
  pointer_data.physical_delta_x = pointer_data.physical_x - state.physical_x;
  pointer_data.physical_delta_y = pointer_data.physical_y - state.physical_y;
  pointer_data.pan_delta_x = pointer_data.pan_x - state.pan_x;
  pointer_data.pan_delta_y = pointer_data.pan_y - state.pan_y;
  state.physical_x = pointer_data.physical_x;
  state.physical_y = pointer_data.physical_y;
  state.pan_x = pointer_data.pan_x;
  state.pan_y = pointer_data.pan_y;
  state.scale = pointer_data.scale;
  state.rotation = pointer_data.rotation;
  states_[pointer_data.device] = state;
}

bool PointerDataPacketConverter::SanitizeNonFinitePosition(
    PointerData& pointer_data) {
  if (std::isfinite(pointer_data.physical_x) &&
      std::isfinite(pointer_data.physical_y)) {
    return true;
  }
  if (pointer_data.signal_kind == PointerData::SignalKind::kNone) {
    switch (pointer_data.change) {
      case PointerData::Change::kDown:
      case PointerData::Change::kMove:
      case PointerData::Change::kHover:
        // The pointer keeps its last valid position, so the next valid event
        // gets a finite delta. A dropped down also drops the rest of the
        // gesture.
        return false;
      default:
        break;
    }
  }
  auto iter = states_.find(pointer_data.device);
  if (iter == states_.end()) {
    return false;
  }
  pointer_data.physical_x = iter->second.physical_x;
  pointer_data.physical_y = iter->second.physical_y;
  return true;
}

bool PointerDataPacketConverter::LocationNeedsUpdate(
    const PointerData pointer_data,
    const PointerState state) {
  return state.physical_x != pointer_data.physical_x ||
         state.physical_y != pointer_data.physical_y;
}

void PointerDataPacketConverter::UpdatePointerIdentifier(
    PointerData& pointer_data,
    PointerState& state,
    bool start_new_pointer) {
  if (start_new_pointer) {
    state.pointer_identifier = ++pointer_;
    states_[pointer_data.device] = state;
  }
  pointer_data.pointer_identifier = state.pointer_identifier;
}

}  // namespace flutter
