// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

  std::optional<size_t> FindColumnIndex(const std::string& className,
                                        ArchiveDef::Member member) const;

  const std::string& GetClassName() const;

  size_t GetMemberCount() const;

  ArchiveStatement CreateInsertStatement() const;

  ArchiveStatement CreateQueryStatement(bool single) const;

 private:
  using MemberColumnMap = std::map<ArchiveDef::Member, size_t>;
  using ClassMap = std::map<std::string, MemberColumnMap>;

  friend class ArchiveDatabase;

  ArchiveClassRegistration(ArchiveDatabase& database, ArchiveDef definition);

  bool CreateTable(bool autoIncrement);

  ArchiveDatabase& database_;
  ClassMap class_map_;
  std::string class_name_;
  size_t member_count_ = 0;
  bool is_ready_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(ArchiveClassRegistration);
};

}  // namespace impeller
