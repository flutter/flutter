// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/archivist/archive_class_registration.h"

#include <sstream>

#include "impeller/archivist/archive_database.h"
#include "impeller/archivist/archive_statement.h"

namespace impeller {

static const char* const ArchiveColumnPrefix = "col_";
static const char* const ArchivePrimaryKeyColumnName = "primary_key";

ArchiveClassRegistration::ArchiveClassRegistration(ArchiveDatabase& database,
                                                   ArchiveDef definition)
    : database_(database), class_name_(definition.table_name) {
  /*
   *  Each class in the archive class hierarchy is assigned an entry in the
   *  class map.
   */
  const ArchiveDef* current = &definition;
  size_t currentMember = 1;
  while (current != nullptr) {
    auto membersInCurrent = current->members.size();
    member_count_ += membersInCurrent;
    MemberColumnMap map;
    for (const auto& member : current->members) {
      map[member] = currentMember++;
    }
    class_map_[current->table_name] = map;
    current = current->isa;
  }

  is_ready_ = CreateTable(definition.auto_key);
}

const std::string& ArchiveClassRegistration::GetClassName() const {
  return class_name_;
}

size_t ArchiveClassRegistration::GetMemberCount() const {
  return member_count_;
}

bool ArchiveClassRegistration::IsValid() const {
  return is_ready_;
}

ArchiveClassRegistration::ColumnResult ArchiveClassRegistration::FindColumn(
    const std::string& className,
    ArchiveDef::Member member) const {
  auto found = class_map_.find(className);

  if (found == class_map_.end()) {
    return {0, false};
  }

  const auto& memberToColumns = found->second;

  auto foundColumn = memberToColumns.find(member);

  if (foundColumn == memberToColumns.end()) {
    return {0, false};
  }

  return {foundColumn->second, true};
}

bool ArchiveClassRegistration::CreateTable(bool autoIncrement) {
  if (class_name_.size() == 0 || member_count_ == 0) {
    return false;
  }

  std::stringstream stream;

  /*
   *  Table names cannot participate in parameter substitution, so we prepare
   *  a statement and check its validity before running.
   */
  stream << "CREATE TABLE IF NOT EXISTS " << class_name_.c_str() << " ("
         << ArchivePrimaryKeyColumnName;

  if (autoIncrement) {
    stream << " INTEGER PRIMARY KEY AUTOINCREMENT, ";
  } else {
    stream << " INTEGER PRIMARY KEY, ";
  }
  for (size_t i = 0, columns = member_count_; i < columns; i++) {
    stream << ArchiveColumnPrefix << std::to_string(i + 1);
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

ArchiveStatement ArchiveClassRegistration::GetQueryStatement(
    bool single) const {
  std::stringstream stream;
  stream << "SELECT " << ArchivePrimaryKeyColumnName << ", ";
  for (size_t i = 0, members = member_count_; i < members; i++) {
    stream << ArchiveColumnPrefix << std::to_string(i + 1);
    if (i != members - 1) {
      stream << ",";
    }
  }
  stream << " FROM " << class_name_;

  if (single) {
    stream << " WHERE " << ArchivePrimaryKeyColumnName << " = ?";
  } else {
    stream << " ORDER BY  " << ArchivePrimaryKeyColumnName << " ASC";
  }

  stream << ";";

  return database_.CreateStatement(stream.str());
}

ArchiveStatement ArchiveClassRegistration::GetInsertStatement() const {
  std::stringstream stream;
  stream << "INSERT OR REPLACE INTO " << class_name_ << " VALUES ( ?, ";
  for (size_t i = 0; i < member_count_; i++) {
    stream << "?";
    if (i != member_count_ - 1) {
      stream << ", ";
    }
  }
  stream << ");";

  return database_.CreateStatement(stream.str());
}

}  // namespace impeller
