// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <map>
#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/archivist/archive_transaction.h"

namespace impeller {

class ArchiveStatement;
class ArchiveClassRegistration;
struct ArchiveDef;

class ArchiveDatabase {
 public:
  ArchiveDatabase(const std::string& filename, bool recreate);

  ~ArchiveDatabase();

  bool isReady() const;

  int64_t lastInsertRowID();

  const ArchiveClassRegistration* registrationForDefinition(
      const ArchiveDef& definition);

  ArchiveTransaction acquireTransaction(int64_t& transactionCount);

 private:
  void* _db = nullptr;
  bool _ready = false;
  std::map<std::string, std::unique_ptr<ArchiveClassRegistration>>
      _registrations;
  std::unique_ptr<ArchiveStatement> _beginTransaction;
  std::unique_ptr<ArchiveStatement> _endTransaction;
  std::unique_ptr<ArchiveStatement> _rollbackTransaction;

  friend class ArchiveClassRegistration;

  ArchiveStatement acquireStatement(const std::string& statementString) const;

  FML_DISALLOW_COPY_AND_ASSIGN(ArchiveDatabase);
};

}  // namespace impeller
