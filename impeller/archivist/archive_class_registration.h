// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <map>

#include "flutter/fml/macros.h"
#include "impeller/archivist/archive.h"

namespace impeller {

class ArchiveClassRegistration {
 public:
  using ColumnResult = std::pair<size_t, bool>;
  ColumnResult findColumn(const std::string& className,
                          ArchiveSerializable::Member member) const;

  const std::string& className() const;

  size_t memberCount() const;

  bool isReady() const;

  ArchiveStatement insertStatement() const;

  ArchiveStatement queryStatement(bool single) const;

  static const size_t NameIndex = 0;

 private:
  using MemberColumnMap = std::map<ArchiveSerializable::Member, size_t>;
  using ClassMap = std::map<std::string, MemberColumnMap>;

  friend class ArchiveDatabase;

  ArchiveClassRegistration(ArchiveDatabase& database, ArchiveDef definition);

  bool createTable(bool autoIncrement);

  ArchiveDatabase& _database;
  ClassMap _classMap;
  std::string _className;
  size_t _memberCount;
  bool _isReady;

  FML_DISALLOW_COPY_AND_ASSIGN(ArchiveClassRegistration);
};

}  // namespace impeller
