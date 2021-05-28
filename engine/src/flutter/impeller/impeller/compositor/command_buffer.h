// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>

#include "flutter/fml/macros.h"

namespace impeller {

class CommandBuffer {
 public:
  ~CommandBuffer();

  enum class CommitResult {
    kPending,
    kError,
    kCompleted,
  };

  using CommitCallback = std::function<void(CommitResult)>;
  void Commit(CommitCallback callback);

 private:
  CommandBuffer();

  FML_DISALLOW_COPY_AND_ASSIGN(CommandBuffer);
};

}  // namespace impeller
