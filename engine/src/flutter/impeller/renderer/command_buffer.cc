// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/command_buffer.h"

namespace impeller {

CommandBuffer::CommandBuffer() = default;

CommandBuffer::~CommandBuffer() = default;

bool CommandBuffer::SubmitCommands() {
  return SubmitCommands(nullptr);
}

}  // namespace impeller
