// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <map>
#include <optional>

#include "flutter/fml/macros.h"
#include "impeller/archivist/archive.h"
#include "impeller/archivist/archive_statement.h"

namespace impeller {

class ArchiveClassRegistration {
 public:
  static constexpr size_t kPrimaryKeyIndex = 0u;

  bool IsValid() const;

  std::optional<size_t> FindColumnIndex(const std::string& member) const;

  const std::string& GetClassName() const;

  size_t GetMemberCount() const;

  ArchiveStatement CreateInsertStatement() const;

  ArchiveStatement CreateQueryStatement(bool single) const;

 private:
  using MemberColumnMap = std::map<std::string, size_t>;

  friend class ArchiveDatabase;

  ArchiveClassRegistration(ArchiveDatabase& database, ArchiveDef definition);

  bool CreateTable();

  ArchiveDatabase& database_;
  const ArchiveDef definition_;
  MemberColumnMap column_map_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(ArchiveClassRegistration);
};

}  // namespace impeller
