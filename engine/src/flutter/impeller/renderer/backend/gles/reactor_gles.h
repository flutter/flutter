// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/renderer/backend/gles/proc_table_gles.h"

namespace impeller {

class ReactorGLES {
 public:
  ReactorGLES();

  ~ReactorGLES();

  bool IsValid() const;

 private:
  std::unique_ptr<ProcTableGLES> proc_table_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(ReactorGLES);
};

}  // namespace impeller
