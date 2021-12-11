// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <optional>
#include <type_traits>

#include "flutter/fml/macros.h"
#include "impeller/archivist/archivable.h"
#include "impeller/archivist/archive.h"
#include "impeller/base/allocation.h"

namespace impeller {

class Archive;
class ArchiveClassRegistration;
class ArchiveStatement;

class ArchiveLocation {
 public:
  PrimaryKey GetPrimaryKey() const;

  template <class T, class = std::enable_if_t<std::is_integral<T>::value>>
  bool Write(const std::string& member, T item) {
    return WriteIntegral(member, static_cast<int64_t>(item));
  }

  bool Write(const std::string& member, double item);

  bool Write(const std::string& member, const std::string& item);

  bool Write(const std::string& member, const Allocation& allocation);

  template <class T,
            class = std::enable_if_t<std::is_base_of<Archivable, T>::value>>
  bool WriteArchivable(const std::string& member, const T& other) {
    const ArchiveDef& otherDef = T::ArchiveDefinition;
    return Write(member, otherDef, other);
  }

  template <class T, class = std::enable_if_t<std::is_enum<T>::value>>
  bool WriteEnum(const std::string& member, const T& item) {
    return WriteIntegral(member, static_cast<int64_t>(item));
  }

  template <class T,
            class = std::enable_if_t<std::is_base_of<Archivable, T>::value>>
  bool Write(const std::string& member, const std::vector<T>& items) {
    /*
     *  All items in the vector are individually encoded and their keys noted
     */
    std::vector<int64_t> members;
    members.reserve(items.size());

    const ArchiveDef& itemDefinition = T::kArchiveDefinition;
    for (const auto& item : items) {
      auto row_id = context_.ArchiveInstance(itemDefinition, item);
      if (!row_id.has_value()) {
        return false;
      }
      members.emplace_back(row_id.value());
    }

    /*
     *  The keys are flattened into the vectors table. Write to that table
     */
    auto vectorInsert = WriteVectorKeys(std::move(members));

    if (!vectorInsert.has_value()) {
      return false;
    }

    return WriteIntegral(member, vectorInsert.value());
  }

  template <class T, class = std::enable_if_t<std::is_integral<T>::value>>
  bool Read(const std::string& member, T& item) {
    int64_t decoded = 0;
    auto result = ReadIntegral(member, decoded);
    item = static_cast<T>(decoded);
    return result;
  }

  bool Read(const std::string& member, double& item);

  bool Read(const std::string& member, std::string& item);

  bool Read(const std::string& member, Allocation& allocation);

  template <class T,
            class = std::enable_if_t<std::is_base_of<Archivable, T>::value>>
  bool ReadArchivable(const std::string& member, T& other) {
    const ArchiveDef& otherDef = T::ArchiveDefinition;
    return decode(member, otherDef, other);
  }

  template <class T, class = std::enable_if_t<std::is_enum<T>::value>>
  bool ReadEnum(const std::string& member, T& item) {
    int64_t desugared = 0;
    if (ReadIntegral(member, desugared)) {
      item = static_cast<T>(desugared);
      return true;
    }
    return false;
  }

  template <class T,
            class = std::enable_if_t<std::is_base_of<Archivable, T>::value>>
  bool Read(const std::string& member, std::vector<T>& items) {
    /*
     *  From the member, find the foreign key of the vector
     */
    int64_t vectorForeignKey = 0;
    if (!ReadIntegral(member, vectorForeignKey)) {
      return false;
    }

    /*
     *  Get vector keys
     */
    std::vector<int64_t> keys;
    if (!ReadVectorKeys(vectorForeignKey, keys)) {
      return false;
    }

    const ArchiveDef& otherDef = T::kArchiveDefinition;
    for (const auto& key : keys) {
      items.emplace_back();

      if (!context_.UnarchiveInstance(otherDef, key, items.back())) {
        return false;
      }
    }

    return true;
  }

 private:
  Archive& context_;
  ArchiveStatement& statement_;
  const ArchiveClassRegistration& registration_;
  PrimaryKey primary_key_;

  friend class Archive;

  ArchiveLocation(Archive& context,
                  ArchiveStatement& statement,
                  const ArchiveClassRegistration& registration,
                  PrimaryKey name);

  bool WriteIntegral(const std::string& member, int64_t item);

  bool ReadIntegral(const std::string& member, int64_t& item);

  std::optional<int64_t> WriteVectorKeys(std::vector<int64_t>&& members);

  bool ReadVectorKeys(PrimaryKey name, std::vector<int64_t>& members);

  bool Write(const std::string& member,
             const ArchiveDef& otherDef,
             const Archivable& other);

  bool Read(const std::string& member,
            const ArchiveDef& otherDef,
            Archivable& other);

  FML_DISALLOW_COPY_AND_ASSIGN(ArchiveLocation);
};

}  // namespace impeller
