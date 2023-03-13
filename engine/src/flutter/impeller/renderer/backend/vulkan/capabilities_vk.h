// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <set>
#include <string>

#include "flutter/fml/macros.h"

namespace impeller {

class CapabilitiesVK {
 public:
  CapabilitiesVK();

  ~CapabilitiesVK();

  bool HasExtension(const std::string& extension) const;

  bool HasLayer(const std::string& layer) const;

  bool HasLayerExtension(const std::string& layer,
                         const std::string& extension);

 private:
  std::set<std::string> extensions_;
  std::set<std::string> layers_;

  FML_DISALLOW_COPY_AND_ASSIGN(CapabilitiesVK);
};

}  // namespace impeller
