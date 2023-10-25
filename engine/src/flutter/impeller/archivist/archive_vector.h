// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/archivist/archive.h"

namespace impeller {

class ArchiveVector : public Archivable {
 public:
  static ArchiveDef kArchiveDefinition;

  PrimaryKey GetPrimaryKey() const override;

  const std::vector<int64_t> GetKeys() const;

  bool Write(ArchiveLocation& item) const override;

  bool Read(ArchiveLocation& item) override;

 private:
  std::vector<int64_t> keys_;

  friend class ArchiveLocation;

  ArchiveVector();

  ArchiveVector(std::vector<int64_t> keys);

  ArchiveVector(const ArchiveVector&) = delete;

  ArchiveVector& operator=(const ArchiveVector&) = delete;
};

}  // namespace impeller
