// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <map>
#include <memory>
#include <string>

#include "flutter/fml/macros.h"
#include "impeller/archivist/archive_transaction.h"

namespace impeller {

class ArchiveStatement;
class ArchiveClassRegistration;
struct ArchiveDef;

//------------------------------------------------------------------------------
/// @brief      A handle to the underlying database connection for an archive.
///
class ArchiveDatabase {
 public:
  ArchiveDatabase(const std::string& filename);

  ~ArchiveDatabase();

  bool IsValid() const;

  int64_t GetLastInsertRowID();

  const ArchiveClassRegistration* GetRegistrationForDefinition(
      const ArchiveDef& definition);

  ArchiveTransaction CreateTransaction(int64_t& transactionCount);

 private:
  struct Handle;
  std::unique_ptr<Handle> handle_;
  std::map<std::string, std::unique_ptr<ArchiveClassRegistration>>
      registrations_;
  std::unique_ptr<ArchiveStatement> begin_transaction_stmt_;
  std::unique_ptr<ArchiveStatement> end_transaction_stmt_;
  std::unique_ptr<ArchiveStatement> rollback_transaction_stmt_;

  friend class ArchiveClassRegistration;

  ArchiveStatement CreateStatement(const std::string& statementString) const;

  ArchiveDatabase(const ArchiveDatabase&) = delete;

  ArchiveDatabase& operator=(const ArchiveDatabase&) = delete;
};

}  // namespace impeller
