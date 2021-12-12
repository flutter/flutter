// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <cstdint>
#include <optional>
#include <string>
#include <vector>

namespace impeller {

struct ArchiveDef {
  const std::string table_name;
  const std::vector<std::string> members;
};

class ArchiveLocation;

using PrimaryKey = std::optional<int64_t>;

//------------------------------------------------------------------------------
/// @brief      Instances of `Archivable`s can be read from and written to a
///             persistent archive.
///
class Archivable {
 public:
  virtual ~Archivable() = default;

  virtual PrimaryKey GetPrimaryKey() const = 0;

  virtual bool Write(ArchiveLocation& item) const = 0;

  virtual bool Read(ArchiveLocation& item) = 0;
};

}  // namespace impeller
