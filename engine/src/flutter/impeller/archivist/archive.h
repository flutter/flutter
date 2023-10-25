// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>
#include <optional>
#include <string>
#include <type_traits>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/archivist/archivable.h"

namespace impeller {

class ArchiveLocation;
class ArchiveDatabase;

class Archive {
 public:
  Archive(const std::string& path);

  ~Archive();

  bool IsValid() const;

  template <class T,
            class = std::enable_if_t<std::is_base_of<Archivable, T>::value>>
  [[nodiscard]] bool Write(const T& archivable) {
    const ArchiveDef& def = T::kArchiveDefinition;
    return ArchiveInstance(def, archivable).has_value();
  }

  template <class T,
            class = std::enable_if_t<std::is_base_of<Archivable, T>::value>>
  [[nodiscard]] bool Read(PrimaryKey name, T& archivable) {
    const ArchiveDef& def = T::kArchiveDefinition;
    return UnarchiveInstance(def, name, archivable);
  }

  using UnarchiveStep = std::function<bool(ArchiveLocation&)>;

  template <class T,
            class = std::enable_if_t<std::is_base_of<Archivable, T>::value>>
  [[nodiscard]] size_t Read(UnarchiveStep stepper) {
    const ArchiveDef& def = T::kArchiveDefinition;
    return UnarchiveInstances(def, stepper);
  }

 private:
  std::unique_ptr<ArchiveDatabase> database_;
  int64_t transaction_count_ = 0;

  friend class ArchiveLocation;

  std::optional<int64_t /* row id */> ArchiveInstance(
      const ArchiveDef& definition,
      const Archivable& archivable);

  bool UnarchiveInstance(const ArchiveDef& definition,
                         PrimaryKey name,
                         Archivable& archivable);

  size_t UnarchiveInstances(const ArchiveDef& definition,
                            const UnarchiveStep& stepper,
                            PrimaryKey primary_key = std::nullopt);

  Archive(const Archive&) = delete;

  Archive& operator=(const Archive&) = delete;
};

}  // namespace impeller
