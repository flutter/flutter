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

Archive::Archive(const std::string& path)
    : database_(std::make_unique<ArchiveDatabase>(path)) {}

Archive::~Archive() {
  FML_DCHECK(transaction_count_ == 0)
      << "There must be no pending transactions";
}

bool Archive::IsReady() const {
  return database_->IsReady();
}

bool Archive::ArchiveInstance(const ArchiveDef& definition,
                              const Archivable& archivable,
                              int64_t& lastInsertIDOut) {
  if (!IsReady()) {
    return false;
  }

  auto transaction = database_->CreateTransaction(transaction_count_);

  const auto* registration =
      database_->GetRegistrationForDefinition(definition);

  if (registration == nullptr) {
    return false;
  }

  auto statement = registration->GetInsertStatement();

  if (!statement.IsReady() || !statement.Reset()) {
    /*
     *  Must be able to reset the statement for a new write
     */
    return false;
  }

  auto itemName = archivable.GetArchiveName();

  /*
   *  The lifecycle of the archive item is tied to this scope and there is no
   *  way for the user to create an instance of an archive item. So its safe
   *  for its members to be references. It does not manage the lifetimes of
   *  anything.
   */
  ArchiveLocation item(*this, statement, *registration, itemName);

  /*
   *  We need to bind the primary key only if the item does not provide its own
   */
  if (!definition.auto_key &&
      !statement.WriteValue(ArchiveClassRegistration::NameIndex, itemName)) {
    return false;
  }

  if (!archivable.Write(item)) {
    return false;
  }

  if (statement.Run() != ArchiveStatement::Result::kDone) {
    return false;
  }

  int64_t lastInsert = database_->GetLastInsertRowID();

  if (!definition.auto_key && lastInsert != static_cast<int64_t>(itemName)) {
    return false;
  }

  lastInsertIDOut = lastInsert;

  /*
   *  If any of the nested calls fail, we would have already checked for the
   *  failure and returned.
   */
  transaction.MarkWritesAsReadyForCommit();

  return true;
}

bool Archive::UnarchiveInstance(const ArchiveDef& definition,
                                Archivable::ArchiveName name,
                                Archivable& archivable) {
  UnarchiveStep stepper = [&archivable](ArchiveLocation& item) {
    archivable.Read(item);
    return false /* no-more after single read */;
  };

  return UnarchiveInstances(definition, stepper, name) == 1;
}

size_t Archive::UnarchiveInstances(const ArchiveDef& definition,
                                   Archive::UnarchiveStep stepper,
                                   Archivable::ArchiveName name) {
  if (!IsReady()) {
    return 0;
  }

  const auto* registration =
      database_->GetRegistrationForDefinition(definition);

  if (registration == nullptr) {
    return 0;
  }

  const bool isQueryingSingle = name != ArchiveNameAuto;

  auto statement = registration->GetQueryStatement(isQueryingSingle);

  if (!statement.IsReady() || !statement.Reset()) {
    return 0;
  }

  if (isQueryingSingle) {
    /*
     *  If a single statement is being queried for, bind the name as a statement
     *  argument.
     */
    if (!statement.WriteValue(ArchiveClassRegistration::NameIndex, name)) {
      return 0;
    }
  }

  if (statement.GetColumnCount() !=
      registration->GetMemberCount() + 1 /* primary key */) {
    return 0;
  }

  /*
   *  Acquire a transaction but never mark it successful since we will never
   *  be committing any writes to the database during unarchiving.
   */
  auto transaction = database_->CreateTransaction(transaction_count_);

  size_t itemsRead = 0;

  while (statement.Run() == ArchiveStatement::Result::kRow) {
    itemsRead++;

    /*
     *  Prepare a fresh archive item for the given statement
     */
    ArchiveLocation item(*this, statement, *registration, name);

    if (!stepper(item)) {
      break;
    }

    if (isQueryingSingle) {
      break;
    }
  }

  return itemsRead;
}

ArchiveLocation::ArchiveLocation(Archive& context,
                                 ArchiveStatement& statement,
                                 const ArchiveClassRegistration& registration,
                                 Archivable::ArchiveName name)
    : context_(context),
      statement_(statement),
      registration_(registration),
      name_(name),
      current_class_(registration.GetClassName()) {}

Archivable::ArchiveName ArchiveLocation::Name() const {
  return name_;
}

bool ArchiveLocation::Write(ArchiveDef::Member member,
                            const std::string& item) {
  auto found = registration_.FindColumn(current_class_, member);
  return found.second ? statement_.WriteValue(found.first, item) : false;
}

bool ArchiveLocation::WriteIntegral(ArchiveDef::Member member, int64_t item) {
  auto found = registration_.FindColumn(current_class_, member);
  return found.second ? statement_.WriteValue(found.first, item) : false;
}

bool ArchiveLocation::Write(ArchiveDef::Member member, double item) {
  auto found = registration_.FindColumn(current_class_, member);
  return found.second ? statement_.WriteValue(found.first, item) : false;
}

bool ArchiveLocation::Write(ArchiveDef::Member member, const Allocation& item) {
  auto found = registration_.FindColumn(current_class_, member);
  return found.second ? statement_.WriteValue(found.first, item) : false;
}

bool ArchiveLocation::Write(ArchiveDef::Member member,
                            const ArchiveDef& otherDef,
                            const Archivable& other) {
  auto found = registration_.FindColumn(current_class_, member);

  if (!found.second) {
    return false;
  }

  /*
   *  We need to fully archive the other instance first because it could
   *  have a name that is auto assigned. In that case, we cannot ask it before
   *  archival (via `other.archiveName()`).
   */
  int64_t lastInsert = 0;
  if (!context_.ArchiveInstance(otherDef, other, lastInsert)) {
    return false;
  }

  /*
   *  Bind the name of the serialiable
   */
  if (!statement_.WriteValue(found.first, lastInsert)) {
    return false;
  }

  return true;
}

std::pair<bool, int64_t> ArchiveLocation::WriteVectorKeys(
    std::vector<int64_t>&& members) {
  ArchiveVector vector(std::move(members));
  int64_t vectorID = 0;
  if (!context_.ArchiveInstance(ArchiveVector::ArchiveDefinition,  //
                                vector,                            //
                                vectorID)) {
    return {false, 0};
  }
  return {true, vectorID};
}

bool ArchiveLocation::ReadVectorKeys(Archivable::ArchiveName name,
                                     std::vector<int64_t>& members) {
  ArchiveVector vector;

  if (!context_.UnarchiveInstance(ArchiveVector::ArchiveDefinition, name,
                                  vector)) {
    return false;
  }

  const auto& keys = vector.GetKeys();

  std::move(keys.begin(), keys.end(), std::back_inserter(members));

  return true;
}

bool ArchiveLocation::Read(ArchiveDef::Member member, std::string& item) {
  auto found = registration_.FindColumn(current_class_, member);
  return found.second ? statement_.ReadValue(found.first, item) : false;
}

bool ArchiveLocation::ReadIntegral(ArchiveDef::Member member, int64_t& item) {
  auto found = registration_.FindColumn(current_class_, member);
  return found.second ? statement_.ReadValue(found.first, item) : false;
}

bool ArchiveLocation::Read(ArchiveDef::Member member, double& item) {
  auto found = registration_.FindColumn(current_class_, member);
  return found.second ? statement_.ReadValue(found.first, item) : false;
}

bool ArchiveLocation::Read(ArchiveDef::Member member, Allocation& item) {
  auto found = registration_.FindColumn(current_class_, member);
  return found.second ? statement_.ReadValue(found.first, item) : false;
}

bool ArchiveLocation::Read(ArchiveDef::Member member,
                           const ArchiveDef& otherDef,
                           Archivable& other) {
  auto found = registration_.FindColumn(current_class_, member);

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
  if (!statement_.ReadValue(found.first, foreignKey)) {
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
