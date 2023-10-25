// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <map>
#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "impeller/shader_archive/shader_archive.h"
#include "impeller/shader_archive/shader_archive_types.h"

namespace impeller {

class MultiArchShaderArchive {
 public:
  static std::shared_ptr<ShaderArchive> CreateArchiveFromMapping(
      const std::shared_ptr<const fml::Mapping>& mapping,
      ArchiveRenderingBackend backend);

  explicit MultiArchShaderArchive(
      const std::shared_ptr<const fml::Mapping>& mapping);

  ~MultiArchShaderArchive();

  std::shared_ptr<const fml::Mapping> GetArchive(
      ArchiveRenderingBackend backend) const;

  std::shared_ptr<ShaderArchive> GetShaderArchive(
      ArchiveRenderingBackend backend) const;

  bool IsValid() const;

 private:
  std::map<ArchiveRenderingBackend, std::shared_ptr<const fml::Mapping>>
      backend_mappings_;
  bool is_valid_ = false;

  MultiArchShaderArchive(const MultiArchShaderArchive&) = delete;

  MultiArchShaderArchive& operator=(const MultiArchShaderArchive&) = delete;
};

}  // namespace impeller
