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

  template <class T, class = std::enable_if<std::is_integral<T>::value>>
  bool Write(ArchiveDef::Member member, T item) {
    return WriteIntegral(member, static_cast<int64_t>(item));
  }

  bool Write(ArchiveDef::Member member, double item);

  bool Write(ArchiveDef::Member member, const std::string& item);

  bool Write(ArchiveDef::Member member, const Allocation& allocation);

  template <class T,
            class = std::enable_if<std::is_base_of<Archivable, T>::value>>
  bool WriteArchivable(ArchiveDef::Member member, const T& other) {
    const ArchiveDef& otherDef = T::ArchiveDefinition;
    return Write(member, otherDef, other);
  }

  template <class T, class = std::enable_if<std::is_enum<T>::value>>
  bool WriteEnum(ArchiveDef::Member member, const T& item) {
    return WriteIntegral(member, static_cast<int64_t>(item));
  }

  template <class T,
            class = std::enable_if<std::is_base_of<Archivable, T>::value>>
  bool Write(ArchiveDef::Member member, const std::vector<T>& items) {
    /*
     *  All items in the vector are individually encoded and their keys noted
     */
    std::vector<int64_t> members;
    members.reserve(items.size());

    const ArchiveDef& itemDefinition = T::ArchiveDefinition;
    for (const auto& item : items) {
      int64_t added = 0;
      bool result = context_.ArchiveInstance(itemDefinition, item, added);
      if (!result) {
        return false;
      }
      members.emplace_back(added);
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

  template <class Super,
            class Current,
            class = std::enable_if<std::is_base_of<Archivable, Super>::value &&
                                   std::is_base_of<Archivable, Current>::value>>
  bool WriteSuper(const Current& thiz) {
    std::string oldClass = current_class_;
    current_class_ = Super::ArchiveDefinition.className;
    auto success = thiz.Super::serialize(*this);
    current_class_ = oldClass;
    return success;
  }

  template <class T, class = std::enable_if<std::is_integral<T>::value>>
  bool Read(ArchiveDef::Member member, T& item) {
    int64_t decoded = 0;
    auto result = ReadIntegral(member, decoded);
    item = static_cast<T>(decoded);
    return result;
  }

  bool Read(ArchiveDef::Member member, double& item);

  bool Read(ArchiveDef::Member member, std::string& item);

  bool Read(ArchiveDef::Member member, Allocation& allocation);

  template <class T,
            class = std::enable_if<std::is_base_of<Archivable, T>::value>>
  bool ReadArchivable(ArchiveDef::Member member, T& other) {
    const ArchiveDef& otherDef = T::ArchiveDefinition;
    return decode(member, otherDef, other);
  }

  template <class T, class = std::enable_if<std::is_enum<T>::value>>
  bool ReadEnum(ArchiveDef::Member member, T& item) {
    int64_t desugared = 0;
    if (ReadIntegral(member, desugared)) {
      item = static_cast<T>(desugared);
      return true;
    }
    return false;
  }

  template <class T,
            class = std::enable_if<std::is_base_of<Archivable, T>::value>>
  bool Read(ArchiveDef::Member member, std::vector<T>& items) {
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

    const ArchiveDef& otherDef = T::ArchiveDefinition;
    for (const auto& key : keys) {
      items.emplace_back();

      if (!context_.UnarchiveInstance(otherDef, key, items.back())) {
        return false;
      }
    }

    return true;
  }

  template <class Super,
            class Current,
            class = std::enable_if<std::is_base_of<Archivable, Super>::value &&
                                   std::is_base_of<Archivable, Current>::value>>
  bool ReadSuper(Current& thiz) {
    std::string oldClass = current_class_;
    current_class_ = Super::ArchiveDefinition.className;
    auto success = thiz.Super::deserialize(*this);
    current_class_ = oldClass;
    return success;
  }

 private:
  Archive& context_;
  ArchiveStatement& statement_;
  const ArchiveClassRegistration& registration_;
  PrimaryKey primary_key_;
  std::string current_class_;

  friend class Archive;

  ArchiveLocation(Archive& context,
                  ArchiveStatement& statement,
                  const ArchiveClassRegistration& registration,
                  PrimaryKey name);

  bool WriteIntegral(ArchiveDef::Member member, int64_t item);

  bool ReadIntegral(ArchiveDef::Member member, int64_t& item);

  std::optional<int64_t> WriteVectorKeys(std::vector<int64_t>&& members);

  bool ReadVectorKeys(PrimaryKey name, std::vector<int64_t>& members);

  bool Write(ArchiveDef::Member member,
             const ArchiveDef& otherDef,
             const Archivable& other);

  bool Read(ArchiveDef::Member member,
            const ArchiveDef& otherDef,
            Archivable& other);

  FML_DISALLOW_COPY_AND_ASSIGN(ArchiveLocation);
};

}  // namespace impeller
