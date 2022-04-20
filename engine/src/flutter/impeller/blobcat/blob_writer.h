// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <string>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "impeller/blobcat/blob.h"

namespace impeller {

class BlobWriter {
 public:
  BlobWriter();

  ~BlobWriter();

  [[nodiscard]] bool AddBlobAtPath(const std::string& path);

  [[nodiscard]] bool AddBlob(Blob::ShaderType type,
                             std::string name,
                             std::shared_ptr<fml::Mapping> mapping);

  std::shared_ptr<fml::Mapping> CreateMapping() const;

 private:
  std::vector<BlobDescription> blob_descriptions_;

  FML_DISALLOW_COPY_AND_ASSIGN(BlobWriter);
};

}  // namespace impeller
