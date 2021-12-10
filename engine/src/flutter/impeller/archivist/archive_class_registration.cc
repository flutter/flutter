// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/archivist/archive_class_registration.h"

#include <sstream>

#include "impeller/archivist/archive_database.h"
#include "impeller/archivist/archive_statement.h"

namespace impeller {

static const char* const ArchiveColumnPrefix = "item";
static const char* const ArchivePrimaryKeyColumnName = "name";
static const char* const ArchiveTablePrefix = "RL_";

ArchiveClassRegistration::ArchiveClassRegistration(ArchiveDatabase& database,
                                                   ArchiveDef definition)
    : _database(database), _className(definition.className), _memberCount(0) {
  /*
   *  Each class in the archive class hierarchy is assigned an entry in the
   *  class map.
   */
  const ArchiveDef* current = &definition;
  size_t currentMember = 1;
  while (current != nullptr) {
    auto membersInCurrent = current->members.size();
    _memberCount += membersInCurrent;
    MemberColumnMap map;
    for (const auto& member : current->members) {
      map[member] = currentMember++;
    }
    _classMap[current->className] = map;
    current = current->superClass;
  }

  _isReady = createTable(definition.autoAssignName);
}

const std::string& ArchiveClassRegistration::className() const {
  return _className;
}

size_t ArchiveClassRegistration::memberCount() const {
  return _memberCount;
}

bool ArchiveClassRegistration::isReady() const {
  return _isReady;
}

ArchiveClassRegistration::ColumnResult ArchiveClassRegistration::findColumn(
    const std::string& className,
    ArchiveSerializable::Member member) const {
  auto found = _classMap.find(className);

  if (found == _classMap.end()) {
    return {0, false};
  }

  const auto& memberToColumns = found->second;

  auto foundColumn = memberToColumns.find(member);

  if (foundColumn == memberToColumns.end()) {
    return {0, false};
  }

  return {foundColumn->second, true};
}

bool ArchiveClassRegistration::createTable(bool autoIncrement) {
  if (_className.size() == 0 || _memberCount == 0) {
    return false;
  }

  std::stringstream stream;

  /*
   *  Table names cannot participate in parameter substitution, so we prepare
   *  a statement and check its validity before running.
   */
  stream << "CREATE TABLE IF NOT EXISTS " << ArchiveTablePrefix
         << _className.c_str() << " (" << ArchivePrimaryKeyColumnName;

  if (autoIncrement) {
    stream << " INTEGER PRIMARY KEY AUTOINCREMENT, ";
  } else {
    stream << " INTEGER PRIMARY KEY, ";
  }
  for (size_t i = 0, columns = _memberCount; i < columns; i++) {
    stream << ArchiveColumnPrefix << std::to_string(i + 1);
    if (i != columns - 1) {
      stream << ", ";
    }
  }
  stream << ");";

  auto statement = _database.acquireStatement(stream.str());

  if (!statement.isReady()) {
    return false;
  }

  if (!statement.reset()) {
    return false;
  }

  return statement.run() == ArchiveStatement::Result::Done;
}

ArchiveStatement ArchiveClassRegistration::queryStatement(bool single) const {
  std::stringstream stream;
  stream << "SELECT " << ArchivePrimaryKeyColumnName << ", ";
  for (size_t i = 0, members = _memberCount; i < members; i++) {
    stream << ArchiveColumnPrefix << std::to_string(i + 1);
    if (i != members - 1) {
      stream << ",";
    }
  }
  stream << " FROM " << ArchiveTablePrefix << _className;

  if (single) {
    stream << " WHERE " << ArchivePrimaryKeyColumnName << " = ?";
  } else {
    stream << " ORDER BY  " << ArchivePrimaryKeyColumnName << " ASC";
  }

  stream << ";";

  return _database.acquireStatement(stream.str());
}

ArchiveStatement ArchiveClassRegistration::insertStatement() const {
  std::stringstream stream;
  stream << "INSERT OR REPLACE INTO " << ArchiveTablePrefix << _className
         << " VALUES ( ?, ";
  for (size_t i = 0; i < _memberCount; i++) {
    stream << "?";
    if (i != _memberCount - 1) {
      stream << ", ";
    }
  }
  stream << ");";

  return _database.acquireStatement(stream.str());
}

}  // namespace impeller
