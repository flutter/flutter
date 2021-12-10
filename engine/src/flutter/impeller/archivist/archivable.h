// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <cstdint>

namespace impeller {

class ArchiveLocation;

//------------------------------------------------------------------------------
/// @brief      Instances of `Archivable`s can be read from and written to a
///             persistent archive.
///
class Archivable {
 public:
  using ArchiveName = uint64_t;

  virtual ArchiveName GetArchiveName() const = 0;

  virtual bool Write(ArchiveLocation& item) const = 0;

  virtual bool Read(ArchiveLocation& item) = 0;
};

}  // namespace impeller
