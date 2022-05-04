// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <set>
#include <string>

#include "flutter/fml/macros.h"

namespace impeller {

class ProcTableGLES;

class GLDescription {
 public:
  GLDescription(const ProcTableGLES& gl);

  ~GLDescription();

  bool IsValid() const;

  std::string GetString() const;

 private:
  std::string vendor_;
  std::string renderer_;
  std::string gl_version_;
  std::string sl_version_;
  std::set<std::string> extensions_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(GLDescription);
};

}  // namespace impeller
