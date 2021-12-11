// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/archivist/archive_vector.h"

#include <sstream>

#include "impeller/archivist/archive_location.h"

namespace impeller {

ArchiveVector::ArchiveVector(std::vector<int64_t>&& keys)
    : keys_(std::move(keys)) {}

ArchiveVector::ArchiveVector() {}

const ArchiveDef ArchiveVector::ArchiveDefinition = {
    /* .superClass = */ nullptr,
    /* .className = */ "Meta_Vector",
    /* .autoAssignName = */ true,
    /* .members = */ {0},
};

Archivable::ArchiveName ArchiveVector::GetArchivePrimaryKey() const {
  return ArchiveNameAuto;
}

const std::vector<int64_t> ArchiveVector::GetKeys() const {
  return keys_;
}

bool ArchiveVector::Write(ArchiveLocation& item) const {
  std::stringstream stream;
  for (size_t i = 0, count = keys_.size(); i < count; i++) {
    stream << keys_[i];
    if (i != count - 1) {
      stream << ",";
    }
  }
  return item.Write(0, stream.str());
}

bool ArchiveVector::Read(ArchiveLocation& item) {
  std::string flattened;
  if (!item.Read(0, flattened)) {
    return false;
  }

  std::stringstream stream(flattened);
  int64_t single = 0;
  while (stream >> single) {
    keys_.emplace_back(single);
    stream.ignore();
  }

  return true;
}

}  // namespace impeller
