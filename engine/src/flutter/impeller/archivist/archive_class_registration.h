// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <map>

#include "flutter/fml/macros.h"
#include "impeller/archivist/archive.h"
#include "impeller/archivist/archive_statement.h"

namespace impeller {

class ArchiveClassRegistration {
 public:
  using ColumnResult = std::pair<size_t, bool>;
  ColumnResult FindColumn(const std::string& className,
                          ArchiveDef::Member member) const;

  const std::string& GetClassName() const;

  size_t GetMemberCount() const;

  bool IsValid() const;

  ArchiveStatement GetInsertStatement() const;

  ArchiveStatement GetQueryStatement(bool single) const;

  static const size_t NameIndex = 0;

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
