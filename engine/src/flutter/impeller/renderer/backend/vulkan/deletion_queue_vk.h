// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <deque>
#include <functional>

#include "flutter/fml/macros.h"

namespace impeller {

class DeletionQueueVK {
 public:
  using Deletor = std::function<void()>;

  explicit DeletionQueueVK();

  ~DeletionQueueVK();

  void Flush();

  void Push(Deletor&& deletor);

 private:
  std::deque<Deletor> deletors_;

  FML_DISALLOW_COPY_AND_ASSIGN(DeletionQueueVK);
};

}  // namespace impeller
