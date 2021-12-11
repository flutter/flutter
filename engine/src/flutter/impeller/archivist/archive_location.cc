// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/archivist/archive_location.h"

#include "impeller/archivist/archive_class_registration.h"
#include "impeller/archivist/archive_vector.h"

namespace impeller {

ArchiveLocation::ArchiveLocation(Archive& context,
                                 ArchiveStatement& statement,
                                 const ArchiveClassRegistration& registration,
                                 PrimaryKey name)
    : context_(context),
      statement_(statement),
      registration_(registration),
      primary_key_(name) {}

PrimaryKey ArchiveLocation::GetPrimaryKey() const {
  return primary_key_;
}

bool ArchiveLocation::Write(const std::string& member,
                            const std::string& item) {
  auto index = registration_.FindColumnIndex(member);
  return index.has_value() ? statement_.WriteValue(index.value(), item) : false;
}

bool ArchiveLocation::WriteIntegral(const std::string& member, int64_t item) {
  auto index = registration_.FindColumnIndex(member);
  return index.has_value() ? statement_.WriteValue(index.value(), item) : false;
}

bool ArchiveLocation::Write(const std::string& member, double item) {
  auto index = registration_.FindColumnIndex(member);
  return index.has_value() ? statement_.WriteValue(index.value(), item) : false;
}

bool ArchiveLocation::Write(const std::string& member, const Allocation& item) {
  auto index = registration_.FindColumnIndex(member);
  return index.has_value() ? statement_.WriteValue(index.value(), item) : false;
}

bool ArchiveLocation::Write(const std::string& member,
                            const ArchiveDef& otherDef,
                            const Archivable& other) {
  auto index = registration_.FindColumnIndex(member);

  if (!index.has_value()) {
    return false;
  }

  /*
   *  We need to fully archive the other instance first because it could
   *  have a name that is auto assigned. In that case, we cannot ask it before
   *  archival (via `other.archiveName()`).
   */
  auto row_id = context_.ArchiveInstance(otherDef, other);
  if (!row_id.has_value()) {
    return false;
  }

  /*
   *  Bind the name of the serializable
   */
  if (!statement_.WriteValue(index.value(), row_id.value())) {
    return false;
  }

  return true;
}

std::optional<int64_t> ArchiveLocation::WriteVectorKeys(
    std::vector<int64_t>&& members) {
  ArchiveVector vector(std::move(members));
  return context_.ArchiveInstance(ArchiveVector::kArchiveDefinition, vector);
}

bool ArchiveLocation::ReadVectorKeys(PrimaryKey name,
                                     std::vector<int64_t>& members) {
  ArchiveVector vector;
  if (!context_.UnarchiveInstance(ArchiveVector::kArchiveDefinition, name,
                                  vector)) {
    return false;
  }
  const auto& keys = vector.GetKeys();
  std::move(keys.begin(), keys.end(), std::back_inserter(members));
  return true;
}

bool ArchiveLocation::Read(const std::string& member, std::string& item) {
  auto index = registration_.FindColumnIndex(member);
  return index.has_value() ? statement_.ReadValue(index.value(), item) : false;
}

bool ArchiveLocation::ReadIntegral(const std::string& member, int64_t& item) {
  auto index = registration_.FindColumnIndex(member);
  return index.has_value() ? statement_.ReadValue(index.value(), item) : false;
}

bool ArchiveLocation::Read(const std::string& member, double& item) {
  auto index = registration_.FindColumnIndex(member);
  return index.has_value() ? statement_.ReadValue(index.value(), item) : false;
}

bool ArchiveLocation::Read(const std::string& member, Allocation& item) {
  auto index = registration_.FindColumnIndex(member);
  return index.has_value() ? statement_.ReadValue(index.value(), item) : false;
}

bool ArchiveLocation::Read(const std::string& member,
                           const ArchiveDef& otherDef,
                           Archivable& other) {
  auto index = registration_.FindColumnIndex(member);

  /*
   *  Make sure a member is present at that column
   */
  if (!index.has_value()) {
    return false;
  }

  /*
   *  Try to find the foreign key in the current items row
   */
  int64_t foreignKey = 0;
  if (!statement_.ReadValue(index.value(), foreignKey)) {
    return false;
  }

  /*
   *  Find the other item and unarchive by this foreign key
   */
  if (!context_.UnarchiveInstance(otherDef, foreignKey, other)) {
    return false;
  }

  return true;
}

}  // namespace impeller
