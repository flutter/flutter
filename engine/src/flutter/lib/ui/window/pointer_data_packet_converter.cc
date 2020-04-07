// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/window/pointer_data_packet_converter.h"
#include "flutter/fml/logging.h"

#include <string.h>

namespace flutter {

PointerDataPacketConverter::PointerDataPacketConverter() : pointer_(0) {}

PointerDataPacketConverter::~PointerDataPacketConverter() = default;

std::unique_ptr<PointerDataPacket> PointerDataPacketConverter::Convert(
    std::unique_ptr<PointerDataPacket> packet) {
  size_t kBytesPerPointerData = kPointerDataFieldCount * kBytesPerField;
  auto buffer = packet->data();
  size_t buffer_length = buffer.size();

  std::vector<PointerData> converted_pointers;
  // Converts each pointer data in the buffer and stores it in the
  // converted_pointers.
  for (size_t i = 0; i < buffer_length / kBytesPerPointerData; i++) {
    PointerData pointer_data;
    memcpy(&pointer_data, &buffer[i * kBytesPerPointerData],
           sizeof(PointerData));
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
  if (pointer_data.signal_kind == PointerData::SignalKind::kNone) {
    switch (pointer_data.change) {
      case PointerData::Change::kCancel: {
        // Android's three finger gesture will send a cancel event
        // to a non-existing pointer. Drops the cancel if pointer
        // is not previously added.
        // https://github.com/flutter/flutter/issues/20517
        auto iter = states_.find(pointer_data.device);
        if (iter != states_.end()) {
          PointerState state = iter->second;
          FML_DCHECK(state.isDown);
          UpdatePointerIdentifier(pointer_data, state, false);

          if (LocationNeedsUpdate(pointer_data, state)) {
            // Synthesizes a move event if the location does not match.
            PointerData synthesized_move_event = pointer_data;
            synthesized_move_event.change = PointerData::Change::kMove;
            synthesized_move_event.synthesized = 1;

            UpdateDeltaAndState(synthesized_move_event, state);
            converted_pointers.push_back(synthesized_move_event);
          }

          state.isDown = false;
          states_[pointer_data.device] = state;
          converted_pointers.push_back(pointer_data);
        }
        break;
      }
      case PointerData::Change::kAdd: {
        FML_DCHECK(states_.find(pointer_data.device) == states_.end());
        EnsurePointerState(pointer_data);
        converted_pointers.push_back(pointer_data);
        break;
      }
      case PointerData::Change::kRemove: {
        // Makes sure we have an existing pointer
        auto iter = states_.find(pointer_data.device);
        FML_DCHECK(iter != states_.end());
        PointerState state = iter->second;

        if (state.isDown) {
          // Synthesizes cancel event if the pointer is down.
          PointerData synthesized_cancel_event = pointer_data;
          synthesized_cancel_event.change = PointerData::Change::kCancel;
          synthesized_cancel_event.synthesized = 1;
          UpdatePointerIdentifier(synthesized_cancel_event, state, false);

          state.isDown = false;
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
        PointerState state;
        if (iter == states_.end()) {
          // Synthesizes add event if the pointer is not previously added.
          PointerData synthesized_add_event = pointer_data;
          synthesized_add_event.change = PointerData::Change::kAdd;
          synthesized_add_event.synthesized = 1;
          state = EnsurePointerState(synthesized_add_event);
          converted_pointers.push_back(synthesized_add_event);
        } else {
          state = iter->second;
        }

        FML_DCHECK(!state.isDown);
        if (LocationNeedsUpdate(pointer_data, state)) {
          UpdateDeltaAndState(pointer_data, state);
          converted_pointers.push_back(pointer_data);
        }
        break;
      }
      case PointerData::Change::kDown: {
        auto iter = states_.find(pointer_data.device);
        PointerState state;
        if (iter == states_.end()) {
          // Synthesizes a add event if the pointer is not previously added.
          PointerData synthesized_add_event = pointer_data;
          synthesized_add_event.change = PointerData::Change::kAdd;
          synthesized_add_event.synthesized = 1;
          state = EnsurePointerState(synthesized_add_event);
          converted_pointers.push_back(synthesized_add_event);
        } else {
          state = iter->second;
        }

        FML_DCHECK(!state.isDown);
        if (LocationNeedsUpdate(pointer_data, state)) {
          // Synthesizes a hover event if the location does not match.
          PointerData synthesized_hover_event = pointer_data;
          synthesized_hover_event.change = PointerData::Change::kHover;
          synthesized_hover_event.synthesized = 1;

          UpdateDeltaAndState(synthesized_hover_event, state);
          converted_pointers.push_back(synthesized_hover_event);
        }

        UpdatePointerIdentifier(pointer_data, state, true);
        state.isDown = true;
        states_[pointer_data.device] = state;
        converted_pointers.push_back(pointer_data);
        break;
      }
      case PointerData::Change::kMove: {
        // Makes sure we have an existing pointer in down state
        auto iter = states_.find(pointer_data.device);
        FML_DCHECK(iter != states_.end());
        PointerState state = iter->second;
        FML_DCHECK(state.isDown);

        UpdatePointerIdentifier(pointer_data, state, false);
        UpdateDeltaAndState(pointer_data, state);
        converted_pointers.push_back(pointer_data);
        break;
      }
      case PointerData::Change::kUp: {
        // Makes sure we have an existing pointer in down state
        auto iter = states_.find(pointer_data.device);
        FML_DCHECK(iter != states_.end());
        PointerState state = iter->second;
        FML_DCHECK(state.isDown);

        UpdatePointerIdentifier(pointer_data, state, false);

        if (LocationNeedsUpdate(pointer_data, state)) {
          // Synthesizes a move event if the location does not match.
          PointerData synthesized_move_event = pointer_data;
          synthesized_move_event.change = PointerData::Change::kMove;
          synthesized_move_event.synthesized = 1;

          UpdateDeltaAndState(synthesized_move_event, state);
          converted_pointers.push_back(synthesized_move_event);
        }

        state.isDown = false;
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
      case PointerData::SignalKind::kScroll: {
        // Makes sure we have an existing pointer
        auto iter = states_.find(pointer_data.device);
        FML_DCHECK(iter != states_.end());

        PointerState state = iter->second;
        if (LocationNeedsUpdate(pointer_data, state)) {
          if (state.isDown) {
            // Synthesizes a move event if the pointer is down.
            PointerData synthesized_move_event = pointer_data;
            synthesized_move_event.signal_kind = PointerData::SignalKind::kNone;
            synthesized_move_event.change = PointerData::Change::kMove;
            synthesized_move_event.synthesized = 1;

            UpdateDeltaAndState(synthesized_move_event, state);
            converted_pointers.push_back(synthesized_move_event);
          } else {
            // Synthesizes a hover event if the pointer is up.
            PointerData synthesized_hover_event = pointer_data;
            synthesized_hover_event.signal_kind =
                PointerData::SignalKind::kNone;
            synthesized_hover_event.change = PointerData::Change::kHover;
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
  PointerState state;
  state.pointer_identifier = 0;
  state.isDown = false;
  state.physical_x = pointer_data.physical_x;
  state.physical_y = pointer_data.physical_y;
  states_[pointer_data.device] = state;
  return state;
}

void PointerDataPacketConverter::UpdateDeltaAndState(PointerData& pointer_data,
                                                     PointerState& state) {
  pointer_data.physical_delta_x = pointer_data.physical_x - state.physical_x;
  pointer_data.physical_delta_y = pointer_data.physical_y - state.physical_y;
  state.physical_x = pointer_data.physical_x;
  state.physical_y = pointer_data.physical_y;
  states_[pointer_data.device] = state;
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
