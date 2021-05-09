// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <dispatch/dispatch.h>

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/compositor/context.h"

namespace impeller {

class Surface {
 public:
  Surface(std::shared_ptr<Context> context);

  ~Surface();

  bool IsValid() const;

  bool Render() const;

 private:
  std::shared_ptr<Context> context_;
  dispatch_semaphore_t frames_in_flight_sema_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(Surface);
};

}  // namespace impeller
