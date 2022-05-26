// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <set>
#include <string>

#include "flutter/fml/macros.h"
#include "impeller/base/version.h"

namespace impeller {

class ProcTableGLES;

class DescriptionGLES {
 public:
  DescriptionGLES(const ProcTableGLES& gl);

  ~DescriptionGLES();

  bool IsValid() const;

  bool IsES() const;

  std::string GetString() const;

  bool HasExtension(const std::string& ext) const;

  bool HasDebugExtension() const;

 private:
  Version gl_version_;
  Version sl_version_;
  bool is_es_ = true;
  std::string vendor_;
  std::string renderer_;
  std::string gl_version_string_;
  std::string sl_version_string_;
  std::set<std::string> extensions_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(DescriptionGLES);
};

}  // namespace impeller
