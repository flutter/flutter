// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <string>
#include <type_traits>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/archivist/archivable.h"

namespace impeller {

class ArchiveLocation;
class ArchiveDatabase;

static const Archivable::ArchiveName ArchiveNameAuto = 0;

class Archive {
 public:
  Archive(const std::string& path);

  ~Archive();

  bool IsValid() const;

  template <class T,
            class = std::enable_if<std::is_base_of<Archivable, T>::value>>
  bool Write(const T& archivable) {
    const ArchiveDef& def = T::ArchiveDefinition;
    int64_t unused_last = 0;
    return ArchiveInstance(def, archivable, unused_last);
  }

  template <class T,
            class = std::enable_if<std::is_base_of<Archivable, T>::value>>
  bool Read(Archivable::ArchiveName name, T& archivable) {
    const ArchiveDef& def = T::ArchiveDefinition;
    return UnarchiveInstance(def, name, archivable);
  }

  using UnarchiveStep = std::function<bool /*continue*/ (ArchiveLocation&)>;

  template <class T,
            class = std::enable_if<std::is_base_of<Archivable, T>::value>>
  size_t Read(UnarchiveStep stepper) {
    const ArchiveDef& def = T::ArchiveDefinition;
    return UnarchiveInstances(def, stepper, ArchiveNameAuto);
  }

 private:
  std::unique_ptr<ArchiveDatabase> database_;
  int64_t transaction_count_ = 0;

  friend class ArchiveLocation;

  bool ArchiveInstance(const ArchiveDef& definition,
                       const Archivable& archivable,
                       int64_t& lastInsertID);
  bool UnarchiveInstance(const ArchiveDef& definition,
                         Archivable::ArchiveName name,
                         Archivable& archivable);
  size_t UnarchiveInstances(const ArchiveDef& definition,
                            UnarchiveStep stepper,
                            Archivable::ArchiveName optionalName);

  FML_DISALLOW_COPY_AND_ASSIGN(Archive);
};

}  // namespace impeller
