// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/shell/platform/mojo/pointer_converter_mojo.h"

#include "base/logging.h"

namespace sky {
namespace shell {
namespace {

pointer::PointerType GetTypeFromAction(mojo::EventType type) {
  switch (type) {
    case mojo::EventType::POINTER_CANCEL:
      return pointer::PointerType::CANCEL;
    case mojo::EventType::POINTER_DOWN:
      return pointer::PointerType::DOWN;
    case mojo::EventType::POINTER_MOVE:
      return pointer::PointerType::MOVE;
    case mojo::EventType::POINTER_UP:
      return pointer::PointerType::UP;
    default:
      DCHECK(false);
      return pointer::PointerType::CANCEL;
  }
}

pointer::PointerKind GetKindFromKind(mojo::PointerKind kind) {
  switch (kind) {
    case mojo::PointerKind::TOUCH:
      return pointer::PointerKind::TOUCH;
    case mojo::PointerKind::MOUSE:
      return pointer::PointerKind::MOUSE;
  }
  DCHECK(false);
  return pointer::PointerKind::TOUCH;
}

}  // namespace

PointerConverterMojo::PointerConverterMojo() {
}

PointerConverterMojo::~PointerConverterMojo() {
}

pointer::PointerPacketPtr PointerConverterMojo::ConvertEvent(
    mojo::EventPtr event) {
  DCHECK(event->action == mojo::EventType::POINTER_CANCEL
      || event->action == mojo::EventType::POINTER_DOWN
      || event->action == mojo::EventType::POINTER_MOVE
      || event->action == mojo::EventType::POINTER_UP);
  mojo::PointerDataPtr data = event->pointer_data.Pass();
  if (!data)
    return nullptr;
  pointer::PointerPacketPtr packet;
  int packetIndex = 0;
  if (pointer_positions_.count(data->pointer_id) > 0) {
    if (event->action == mojo::EventType::POINTER_UP ||
        event->action == mojo::EventType::POINTER_CANCEL) {
      auto last_position = pointer_positions_[data->pointer_id];
      if (last_position.first != data->x || last_position.second != data->y) {
        packet = pointer::PointerPacket::New();
        packet->pointers = mojo::Array<pointer::PointerPtr>::New(2);
        packet->pointers[packetIndex] = CreatePointer(
            pointer::PointerType::MOVE, event.get(), data.get());
        packetIndex += 1;
      }
      pointer_positions_.erase(data->pointer_id);
    }
  } else {
    // We don't currently support hover moves.
    // If we want to support those, we have to first implement
    // added/removed events for pointers.
    // See: https://github.com/flutter/flutter/issues/720
    if (event->action != mojo::EventType::POINTER_DOWN)
      return nullptr;
  }
  if (packetIndex == 0) {
    packet = pointer::PointerPacket::New();
    packet->pointers = mojo::Array<pointer::PointerPtr>::New(1);
  }
  packet->pointers[packetIndex] = CreatePointer(
      GetTypeFromAction(event->action), event.get(), data.get());
  return packet.Pass();
}

pointer::PointerPtr PointerConverterMojo::CreatePointer(
    pointer::PointerType type, mojo::Event* event, mojo::PointerData* data) {
  DCHECK(data);
  pointer::PointerPtr pointer = pointer::Pointer::New();
  pointer->time_stamp = event->time_stamp;
  pointer->pointer = data->pointer_id;
  pointer->type = type;
  pointer->kind = GetKindFromKind(data->kind);
  pointer->x = data->x;
  pointer->y = data->y;
  pointer->buttons = static_cast<int32_t>(event->flags);
  pointer->pressure = data->pressure;
  pointer->radius_major = data->radius_major;
  pointer->radius_minor = data->radius_minor;
  pointer->orientation = data->orientation;
  if (event->action != mojo::EventType::POINTER_UP &&
      event->action != mojo::EventType::POINTER_CANCEL)
    pointer_positions_[data->pointer_id] = { data->x, data->y };
  return pointer.Pass();
}

}  // namespace shell
}  // namespace sky
