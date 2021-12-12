// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/archivist/archive_class_registration.h"

#include <sstream>

#include "impeller/archivist/archive_database.h"
#include "impeller/archivist/archive_statement.h"
#include "impeller/base/validation.h"

namespace impeller {

static constexpr const char* kArchivePrimaryKeyColumnName = "primary_key";

ArchiveClassRegistration::ArchiveClassRegistration(ArchiveDatabase& database,
                                                   ArchiveDef definition)
    : database_(database), definition_(std::move(definition)) {
  for (size_t i = 0; i < definition.members.size(); i++) {
    // The first index entry is the primary key. So add one to the index.
    column_map_[definition.members[i]] = i + 1;
  }
  is_valid_ = CreateTable();
}

const std::string& ArchiveClassRegistration::GetClassName() const {
  return definition_.table_name;
}

size_t ArchiveClassRegistration::GetMemberCount() const {
  return column_map_.size();
}

bool ArchiveClassRegistration::IsValid() const {
  return is_valid_;
}

std::optional<size_t> ArchiveClassRegistration::FindColumnIndex(
    const std::string& member) const {
  auto found = column_map_.find(member);
  if (found == column_map_.end()) {
    VALIDATION_LOG << "No member named '" << member << "' in class '"
                   << definition_.table_name
                   << "'. Did you forget to register it?";
    return std::nullopt;
  }
  return found->second;
}

bool ArchiveClassRegistration::CreateTable() {
  if (definition_.table_name.empty() || definition_.members.empty()) {
    return false;
  }

  std::stringstream stream;

  /*
   *  Table names cannot participate in parameter substitution, so we prepare
   *  a statement and check its validity before running.
   */
  stream << "CREATE TABLE IF NOT EXISTS " << definition_.table_name << " ("
         << kArchivePrimaryKeyColumnName << " INTEGER PRIMARY KEY, ";

  for (size_t i = 0, columns = definition_.members.size(); i < columns; i++) {
    stream << definition_.members[i];
    if (i != columns - 1) {
      stream << ", ";
    }
  }
  stream << ");";

  auto statement = database_.CreateStatement(stream.str());

  if (!statement.IsValid()) {
    return false;
  }

  if (!statement.Reset()) {
    return false;
  }

  return statement.Execute() == ArchiveStatement::Result::kDone;
}

ArchiveStatement ArchiveClassRegistration::CreateQueryStatement(
    bool single) const {
  std::stringstream stream;
  stream << "SELECT " << kArchivePrimaryKeyColumnName << ", ";
  for (size_t i = 0, columns = definition_.members.size(); i < columns; i++) {
    stream << definition_.members[i];
    if (i != columns - 1) {
      stream << ",";
    }
  }
  stream << " FROM " << definition_.table_name;

  if (single) {
    stream << " WHERE " << kArchivePrimaryKeyColumnName << " = ?";
  } else {
    stream << " ORDER BY  " << kArchivePrimaryKeyColumnName << " ASC";
  }

  stream << ";";

  return database_.CreateStatement(stream.str());
}

ArchiveStatement ArchiveClassRegistration::CreateInsertStatement() const {
  std::stringstream stream;
  stream << "INSERT OR REPLACE INTO " << definition_.table_name
         << " VALUES ( ?, ";
  for (size_t i = 0, columns = definition_.members.size(); i < columns; i++) {
    stream << "?";
    if (i != columns - 1) {
      stream << ", ";
    }
  }
  stream << ");";

  return database_.CreateStatement(stream.str());
}

}  // namespace impeller
