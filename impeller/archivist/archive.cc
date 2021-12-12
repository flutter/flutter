// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/archivist/archive.h"

#include <iterator>

#include "flutter/fml/logging.h"
#include "impeller/archivist/archive_class_registration.h"
#include "impeller/archivist/archive_database.h"
#include "impeller/archivist/archive_location.h"
#include "impeller/base/validation.h"

namespace impeller {

Archive::Archive(const std::string& path)
    : database_(std::make_unique<ArchiveDatabase>(path)) {}

Archive::~Archive() {
  FML_DCHECK(transaction_count_ == 0)
      << "There must be no pending transactions";
}

bool Archive::IsValid() const {
  return database_->IsValid();
}

std::optional<int64_t /* row id */> Archive::ArchiveInstance(
    const ArchiveDef& definition,
    const Archivable& archivable) {
  if (!IsValid()) {
    return std::nullopt;
  }

  auto transaction = database_->CreateTransaction(transaction_count_);

  const auto* registration =
      database_->GetRegistrationForDefinition(definition);

  if (registration == nullptr) {
    return std::nullopt;
  }

  auto statement = registration->CreateInsertStatement();

  if (!statement.IsValid() || !statement.Reset()) {
    /*
     *  Must be able to reset the statement for a new write
     */
    return std::nullopt;
  }

  auto primary_key = archivable.GetPrimaryKey();

  /*
   *  The lifecycle of the archive item is tied to this scope and there is no
   *  way for the user to create an instance of an archive item. So its safe
   *  for its members to be references. It does not manage the lifetimes of
   *  anything.
   */
  ArchiveLocation item(*this, statement, *registration, primary_key);

  /*
   *  If the item provides its own primary key, we need to bind it now.
   * Otherwise, one will be automatically assigned to it.
   */
  if (primary_key.has_value() &&
      !statement.WriteValue(ArchiveClassRegistration::kPrimaryKeyIndex,
                            primary_key.value())) {
    return std::nullopt;
  }

  if (!archivable.Write(item)) {
    return std::nullopt;
  }

  if (statement.Execute() != ArchiveStatement::Result::kDone) {
    return std::nullopt;
  }

  int64_t lastInsert = database_->GetLastInsertRowID();

  if (primary_key.has_value() &&
      lastInsert != static_cast<int64_t>(primary_key.value())) {
    return std::nullopt;
  }

  /*
   *  If any of the nested calls fail, we would have already checked for the
   *  failure and returned.
   */
  transaction.MarkWritesAsReadyForCommit();

  return lastInsert;
}

bool Archive::UnarchiveInstance(const ArchiveDef& definition,
                                PrimaryKey name,
                                Archivable& archivable) {
  UnarchiveStep stepper = [&archivable](ArchiveLocation& item) {
    archivable.Read(item);
    return false /* no-more after single read */;
  };

  return UnarchiveInstances(definition, stepper, name) == 1;
}

size_t Archive::UnarchiveInstances(const ArchiveDef& definition,
                                   Archive::UnarchiveStep stepper,
                                   PrimaryKey primary_key) {
  if (!IsValid()) {
    return 0;
  }

  const auto* registration =
      database_->GetRegistrationForDefinition(definition);

  if (registration == nullptr) {
    return 0;
  }

  const bool isQueryingSingle = primary_key.has_value();

  auto statement = registration->CreateQueryStatement(isQueryingSingle);

  if (!statement.IsValid() || !statement.Reset()) {
    return 0;
  }

  if (isQueryingSingle) {
    /*
     *  If a single statement is being queried for, bind the primary key as a
     * statement argument.
     */
    if (!statement.WriteValue(ArchiveClassRegistration::kPrimaryKeyIndex,
                              primary_key.value())) {
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

  while (statement.Execute() == ArchiveStatement::Result::kRow) {
    itemsRead++;

    /*
     *  Prepare a fresh archive item for the given statement
     */
    ArchiveLocation item(*this, statement, *registration, primary_key);

    if (!stepper(item)) {
      break;
    }

    if (isQueryingSingle) {
      break;
    }
  }

  return itemsRead;
}

}  // namespace impeller
