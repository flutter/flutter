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

#define DB_HANDLE reinterpret_cast<sqlite3*>(_db)

ArchiveDatabase::ArchiveDatabase(const std::string& filename, bool recreate) {
  if (recreate) {
    ::remove(filename.c_str());
  }

  if (::sqlite3_initialize() != SQLITE_OK) {
    VALIDATION_LOG << "Could not initialize sqlite.";
    return;
  }

  sqlite3* db = nullptr;
  auto res = ::sqlite3_open(filename.c_str(), &db);
  _db = db;

  if (res != SQLITE_OK || _db == nullptr) {
    return;
  }

  _beginTransaction = std::unique_ptr<ArchiveStatement>(
      new ArchiveStatement(_db, "BEGIN TRANSACTION;"));

  if (!_beginTransaction->isReady()) {
    return;
  }

  _endTransaction = std::unique_ptr<ArchiveStatement>(
      new ArchiveStatement(_db, "END TRANSACTION;"));

  if (!_endTransaction->isReady()) {
    return;
  }

  _rollbackTransaction = std::unique_ptr<ArchiveStatement>(
      new ArchiveStatement(_db, "ROLLBACK TRANSACTION;"));

  if (!_rollbackTransaction->isReady()) {
    return;
  }

  _ready = true;
}

ArchiveDatabase::~ArchiveDatabase() {
  ::sqlite3_close(DB_HANDLE);
}

bool ArchiveDatabase::isReady() const {
  return _ready;
}

int64_t ArchiveDatabase::lastInsertRowID() {
  return ::sqlite3_last_insert_rowid(DB_HANDLE);
}

static inline const ArchiveClassRegistration* RegistrationIfReady(
    const ArchiveClassRegistration* registration) {
  if (registration == nullptr) {
    return nullptr;
  }
  return registration->isReady() ? registration : nullptr;
}

const ArchiveClassRegistration* ArchiveDatabase::registrationForDefinition(
    const ArchiveDef& definition) {
  auto found = _registrations.find(definition.className);
  if (found != _registrations.end()) {
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
      _registrations.emplace(definition.className, std::move(registration));

  /*
   *  If the new class registation is ready, return it to the caller.
   */
  return res.second ? RegistrationIfReady((*(res.first)).second.get())
                    : nullptr;
}

ArchiveStatement ArchiveDatabase::acquireStatement(
    const std::string& statementString) const {
  return ArchiveStatement{_db, statementString};
}

ArchiveTransaction ArchiveDatabase::acquireTransaction(
    int64_t& transactionCount) {
  return ArchiveTransaction{transactionCount,    //
                            *_beginTransaction,  //
                            *_endTransaction,    //
                            *_rollbackTransaction};
}

}  // namespace impeller
