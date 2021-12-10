// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/archivist/archive_vector.h"

#include <sstream>

namespace impeller {

ArchiveVector::ArchiveVector(std::vector<int64_t>&& keys)
    : _keys(std::move(keys)) {}

ArchiveVector::ArchiveVector() {}

const ArchiveDef ArchiveVector::ArchiveDefinition = {
    /* .superClass = */ nullptr,
    /* .className = */ "Meta_Vector",
    /* .autoAssignName = */ true,
    /* .members = */ {0},
};

ArchiveSerializable::ArchiveName ArchiveVector::archiveName() const {
  return ArchiveNameAuto;
}

const std::vector<int64_t> ArchiveVector::keys() const {
  return _keys;
}

bool ArchiveVector::serialize(ArchiveItem& item) const {
  std::stringstream stream;
  for (size_t i = 0, count = _keys.size(); i < count; i++) {
    stream << _keys[i];
    if (i != count - 1) {
      stream << ",";
    }
  }
  return item.encode(0, stream.str());
}

bool ArchiveVector::deserialize(ArchiveItem& item) {
  std::string flattened;
  if (!item.decode(0, flattened)) {
    return false;
  }

  std::stringstream stream(flattened);
  int64_t single = 0;
  while (stream >> single) {
    _keys.emplace_back(single);
    stream.ignore();
  }

  return true;
}

}  // namespace impeller
