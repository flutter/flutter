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

struct ArchiveDatabase::Handle {
  explicit Handle(const std::string& filename) {
    if (::sqlite3_initialize() != SQLITE_OK) {
      VALIDATION_LOG << "Could not initialize sqlite.";
      return;
    }

    sqlite3* db = nullptr;
    auto res = ::sqlite3_open(filename.c_str(), &db);

    if (res != SQLITE_OK || db == nullptr) {
      return;
    }

    handle_ = db;
  }

  ~Handle() {
    if (handle_ == nullptr) {
      return;
    }
    ::sqlite3_close(handle_);
  }

  ::sqlite3* Get() const { return handle_; }

  bool IsValid() const { return handle_ != nullptr; }

 private:
  ::sqlite3* handle_ = nullptr;

  Handle(const Handle&) = delete;

  Handle& operator=(const Handle&) = delete;
};

ArchiveDatabase::ArchiveDatabase(const std::string& filename)
    : handle_(std::make_unique<Handle>(filename)) {
  if (!handle_->IsValid()) {
    handle_.reset();
    return;
  }

  begin_transaction_stmt_ = std::unique_ptr<ArchiveStatement>(
      new ArchiveStatement(handle_->Get(), "BEGIN TRANSACTION;"));

  if (!begin_transaction_stmt_->IsValid()) {
    return;
  }

  end_transaction_stmt_ = std::unique_ptr<ArchiveStatement>(
      new ArchiveStatement(handle_->Get(), "END TRANSACTION;"));

  if (!end_transaction_stmt_->IsValid()) {
    return;
  }

  rollback_transaction_stmt_ = std::unique_ptr<ArchiveStatement>(
      new ArchiveStatement(handle_->Get(), "ROLLBACK TRANSACTION;"));

  if (!rollback_transaction_stmt_->IsValid()) {
    return;
  }
}

ArchiveDatabase::~ArchiveDatabase() = default;

bool ArchiveDatabase::IsValid() const {
  return handle_ != nullptr;
}

int64_t ArchiveDatabase::GetLastInsertRowID() {
  if (!IsValid()) {
    return 0u;
  }
  return ::sqlite3_last_insert_rowid(handle_->Get());
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
  return ArchiveStatement{handle_ ? handle_->Get() : nullptr, statementString};
}

ArchiveTransaction ArchiveDatabase::CreateTransaction(
    int64_t& transactionCount) {
  return ArchiveTransaction{transactionCount,          //
                            *begin_transaction_stmt_,  //
                            *end_transaction_stmt_,    //
                            *rollback_transaction_stmt_};
}

}  // namespace impeller
