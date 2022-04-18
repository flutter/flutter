// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/reactor_gles.h"

#include "impeller/base/validation.h"

namespace impeller {

ReactorGLES::ReactorGLES() {
  proc_table_ = std::make_unique<ProcTableGLES>();

  if (!proc_table_->IsValid()) {
    VALIDATION_LOG << "Could not create valid proc table.";
    return;
  }

  is_valid_ = true;
}

ReactorGLES::~ReactorGLES() = default;

bool ReactorGLES::IsValid() const {
  return is_valid_;
}

}  // namespace impeller
