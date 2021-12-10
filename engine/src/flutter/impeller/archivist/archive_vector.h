// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/archivist/archive.h"

namespace impeller {

class ArchiveVector : public ArchiveSerializable {
 public:
  static const ArchiveDef ArchiveDefinition;

  ArchiveName archiveName() const override;

  const std::vector<int64_t> keys() const;

  bool serialize(ArchiveItem& item) const override;

  bool deserialize(ArchiveItem& item) override;

 private:
  std::vector<int64_t> _keys;

  friend class ArchiveItem;

  ArchiveVector();

  ArchiveVector(std::vector<int64_t>&& keys);

  FML_DISALLOW_COPY_AND_ASSIGN(ArchiveVector);
};

}  // namespace impeller
