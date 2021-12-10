// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/archivist/archive.h"

#include <iterator>

#include "flutter/fml/logging.h"
#include "impeller/archivist/archive_class_registration.h"
#include "impeller/archivist/archive_database.h"
#include "impeller/archivist/archive_statement.h"
#include "impeller/archivist/archive_vector.h"

namespace impeller {

Archive::Archive(const std::string& path, bool recreate)
    : _db(std::make_unique<ArchiveDatabase>(path, recreate)) {}

Archive::~Archive() {
  FML_DCHECK(_transactionCount == 0) << "There must be no pending transactions";
}

bool Archive::isReady() const {
  return _db->isReady();
}

bool Archive::archiveInstance(const ArchiveDef& definition,
                              const ArchiveSerializable& archivable,
                              int64_t& lastInsertIDOut) {
  if (!isReady()) {
    return false;
  }

  auto transaction = _db->acquireTransaction(_transactionCount);

  const auto* registration = _db->registrationForDefinition(definition);

  if (registration == nullptr) {
    return false;
  }

  auto statement = registration->insertStatement();

  if (!statement.isReady() || !statement.reset()) {
    /*
     *  Must be able to reset the statement for a new write
     */
    return false;
  }

  auto itemName = archivable.archiveName();

  /*
   *  The lifecycle of the archive item is tied to this scope and there is no
   *  way for the user to create an instance of an archive item. So its safe
   *  for its members to be references. It does not manage the lifetimes of
   *  anything.
   */
  ArchiveItem item(*this, statement, *registration, itemName);

  /*
   *  We need to bind the primary key only if the item does not provide its own
   */
  if (!definition.autoAssignName &&
      !statement.bind(ArchiveClassRegistration::NameIndex, itemName)) {
    return false;
  }

  if (!archivable.serialize(item)) {
    return false;
  }

  if (statement.run() != ArchiveStatement::Result::Done) {
    return false;
  }

  int64_t lastInsert = _db->lastInsertRowID();

  if (!definition.autoAssignName &&
      lastInsert != static_cast<int64_t>(itemName)) {
    return false;
  }

  lastInsertIDOut = lastInsert;

  /*
   *  If any of the nested calls fail, we would have already checked for the
   *  failure and returned.
   */
  transaction.markWritesSuccessful();

  return true;
}

bool Archive::unarchiveInstance(const ArchiveDef& definition,
                                ArchiveSerializable::ArchiveName name,
                                ArchiveSerializable& archivable) {
  UnarchiveStep stepper = [&archivable](ArchiveItem& item) {
    archivable.deserialize(item);
    return false /* no-more after single read */;
  };

  return unarchiveInstances(definition, stepper, name) == 1;
}

size_t Archive::unarchiveInstances(const ArchiveDef& definition,
                                   Archive::UnarchiveStep stepper,
                                   ArchiveSerializable::ArchiveName name) {
  if (!isReady()) {
    return 0;
  }

  const auto* registration = _db->registrationForDefinition(definition);

  if (registration == nullptr) {
    return 0;
  }

  const bool isQueryingSingle = name != ArchiveNameAuto;

  auto statement = registration->queryStatement(isQueryingSingle);

  if (!statement.isReady() || !statement.reset()) {
    return 0;
  }

  if (isQueryingSingle) {
    /*
     *  If a single statement is being queried for, bind the name as a statement
     *  argument.
     */
    if (!statement.bind(ArchiveClassRegistration::NameIndex, name)) {
      return 0;
    }
  }

  if (statement.columnCount() !=
      registration->memberCount() + 1 /* primary key */) {
    return 0;
  }

  /*
   *  Acquire a transaction but never mark it successful since we will never
   *  be committing any writes to the database during unarchiving.
   */
  auto transaction = _db->acquireTransaction(_transactionCount);

  size_t itemsRead = 0;

  while (statement.run() == ArchiveStatement::Result::Row) {
    itemsRead++;

    /*
     *  Prepare a fresh archive item for the given statement
     */
    ArchiveItem item(*this, statement, *registration, name);

    if (!stepper(item)) {
      break;
    }

    if (isQueryingSingle) {
      break;
    }
  }

  return itemsRead;
}

ArchiveItem::ArchiveItem(Archive& context,
                         ArchiveStatement& statement,
                         const ArchiveClassRegistration& registration,
                         ArchiveSerializable::ArchiveName name)
    : _context(context),
      _statement(statement),
      _registration(registration),
      _name(name),
      _currentClass(registration.className()) {}

ArchiveSerializable::ArchiveName ArchiveItem::name() const {
  return _name;
}

bool ArchiveItem::encode(ArchiveSerializable::Member member,
                         const std::string& item) {
  auto found = _registration.findColumn(_currentClass, member);
  return found.second ? _statement.bind(found.first, item) : false;
}

bool ArchiveItem::encodeIntegral(ArchiveSerializable::Member member,
                                 int64_t item) {
  auto found = _registration.findColumn(_currentClass, member);
  return found.second ? _statement.bind(found.first, item) : false;
}

bool ArchiveItem::encode(ArchiveSerializable::Member member, double item) {
  auto found = _registration.findColumn(_currentClass, member);
  return found.second ? _statement.bind(found.first, item) : false;
}

bool ArchiveItem::encode(ArchiveSerializable::Member member,
                         const Allocation& item) {
  auto found = _registration.findColumn(_currentClass, member);
  return found.second ? _statement.bind(found.first, item) : false;
}

bool ArchiveItem::encode(ArchiveSerializable::Member member,
                         const ArchiveDef& otherDef,
                         const ArchiveSerializable& other) {
  auto found = _registration.findColumn(_currentClass, member);

  if (!found.second) {
    return false;
  }

  /*
   *  We need to fully archive the other instance first because it could
   *  have a name that is auto assigned. In that case, we cannot ask it before
   *  archival (via `other.archiveName()`).
   */
  int64_t lastInsert = 0;
  if (!_context.archiveInstance(otherDef, other, lastInsert)) {
    return false;
  }

  /*
   *  Bind the name of the serialiable
   */
  if (!_statement.bind(found.first, lastInsert)) {
    return false;
  }

  return true;
}

std::pair<bool, int64_t> ArchiveItem::encodeVectorKeys(
    std::vector<int64_t>&& members) {
  ArchiveVector vector(std::move(members));
  int64_t vectorID = 0;
  if (!_context.archiveInstance(ArchiveVector::ArchiveDefinition,  //
                                vector,                            //
                                vectorID)) {
    return {false, 0};
  }
  return {true, vectorID};
}

bool ArchiveItem::decodeVectorKeys(ArchiveSerializable::ArchiveName name,
                                   std::vector<int64_t>& members) {
  ArchiveVector vector;

  if (!_context.unarchiveInstance(ArchiveVector::ArchiveDefinition, name,
                                  vector)) {
    return false;
  }

  const auto& keys = vector.keys();

  std::move(keys.begin(), keys.end(), std::back_inserter(members));

  return true;
}

bool ArchiveItem::decode(ArchiveSerializable::Member member,
                         std::string& item) {
  auto found = _registration.findColumn(_currentClass, member);
  return found.second ? _statement.column(found.first, item) : false;
}

bool ArchiveItem::decodeIntegral(ArchiveSerializable::Member member,
                                 int64_t& item) {
  auto found = _registration.findColumn(_currentClass, member);
  return found.second ? _statement.column(found.first, item) : false;
}

bool ArchiveItem::decode(ArchiveSerializable::Member member, double& item) {
  auto found = _registration.findColumn(_currentClass, member);
  return found.second ? _statement.column(found.first, item) : false;
}

bool ArchiveItem::decode(ArchiveSerializable::Member member, Allocation& item) {
  auto found = _registration.findColumn(_currentClass, member);
  return found.second ? _statement.column(found.first, item) : false;
}

bool ArchiveItem::decode(ArchiveSerializable::Member member,
                         const ArchiveDef& otherDef,
                         ArchiveSerializable& other) {
  auto found = _registration.findColumn(_currentClass, member);

  /*
   *  Make sure a member is present at that column
   */
  if (!found.second) {
    return false;
  }

  /*
   *  Try to find the foreign key in the current items row
   */
  int64_t foreignKey = 0;
  if (!_statement.column(found.first, foreignKey)) {
    return false;
  }

  /*
   *  Find the other item and unarchive by this foreign key
   */
  if (!_context.unarchiveInstance(otherDef, foreignKey, other)) {
    return false;
  }

  return true;
}

}  // namespace impeller
