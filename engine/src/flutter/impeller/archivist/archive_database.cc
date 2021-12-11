// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/archivist/archive_database.h"

#include "third_party/sqlite/sqlite3.h"

#include <sstream>
#include <string>

#include "impeller/archivist/archive.h"
#include "impeller/archivist/archive_class_registration.h"
#include "impeller/archivist/archive_statement.h"
#include "impeller/base/validation.h"

namespace impeller {

#define DB_HANDLE reinterpret_cast<sqlite3*>(database_)

ArchiveDatabase::ArchiveDatabase(const std::string& filename) {
  if (::sqlite3_initialize() != SQLITE_OK) {
    VALIDATION_LOG << "Could not initialize sqlite.";
    return;
  }

  sqlite3* db = nullptr;
  auto res = ::sqlite3_open(filename.c_str(), &db);
  database_ = db;

  if (res != SQLITE_OK || database_ == nullptr) {
    return;
  }

  begin_transaction_stmt_ = std::unique_ptr<ArchiveStatement>(
      new ArchiveStatement(database_, "BEGIN TRANSACTION;"));

  if (!begin_transaction_stmt_->IsValid()) {
    return;
  }

  end_transaction_stmt_ = std::unique_ptr<ArchiveStatement>(
      new ArchiveStatement(database_, "END TRANSACTION;"));

  if (!end_transaction_stmt_->IsValid()) {
    return;
  }

  rollback_transaction_stmt_ = std::unique_ptr<ArchiveStatement>(
      new ArchiveStatement(database_, "ROLLBACK TRANSACTION;"));

  if (!rollback_transaction_stmt_->IsValid()) {
    return;
  }

  ready_ = true;
}

ArchiveDatabase::~ArchiveDatabase() {
  ::sqlite3_close(DB_HANDLE);
}

bool ArchiveDatabase::IsValid() const {
  return ready_;
}

int64_t ArchiveDatabase::GetLastInsertRowID() {
  return ::sqlite3_last_insert_rowid(DB_HANDLE);
}

static inline const ArchiveClassRegistration* RegistrationIfReady(
    const ArchiveClassRegistration* registration) {
  if (registration == nullptr) {
    return nullptr;
  }
  return registration->IsValid() ? registration : nullptr;
}

const ArchiveClassRegistration* ArchiveDatabase::GetRegistrationForDefinition(
    const ArchiveDef& definition) {
  auto found = registrations_.find(definition.table_name);
  if (found != registrations_.end()) {
    /*
     *  This class has already been registered.
     */
    return RegistrationIfReady(found->second.get());
  }

  /*
   *  Initialize a new class registration for the given class definition.
   */
  auto registration = std::unique_ptr<ArchiveClassRegistration>(
      new ArchiveClassRegistration(*this, definition));
  auto res =
      registrations_.emplace(definition.table_name, std::move(registration));

  /*
   *  If the new class registration is ready, return it to the caller.
   */
  return res.second ? RegistrationIfReady((*(res.first)).second.get())
                    : nullptr;
}

ArchiveStatement ArchiveDatabase::CreateStatement(
    const std::string& statementString) const {
  return ArchiveStatement{database_, statementString};
}

ArchiveTransaction ArchiveDatabase::CreateTransaction(
    int64_t& transactionCount) {
  return ArchiveTransaction{transactionCount,          //
                            *begin_transaction_stmt_,  //
                            *end_transaction_stmt_,    //
                            *rollback_transaction_stmt_};
}

}  // namespace impeller
