// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#pragma once

#include <cstdint>

#include "flutter/fml/macros.h"

namespace impeller {

class ArchiveStatement;

class ArchiveTransaction {
 public:
  ArchiveTransaction(ArchiveTransaction&& transaction);

  ~ArchiveTransaction();

  void markWritesSuccessful();

 private:
  ArchiveStatement& _endStatement;
  ArchiveStatement& _rollbackStatement;
  int64_t& _transactionCount;
  bool _cleanup = false;
  bool _successful = false;
  bool _abandoned = false;

  friend class ArchiveDatabase;

  ArchiveTransaction(int64_t& transactionCount,
                     ArchiveStatement& beginStatement,
                     ArchiveStatement& endStatement,
                     ArchiveStatement& rollbackStatement);

  FML_DISALLOW_COPY_AND_ASSIGN(ArchiveTransaction);
};

}  // namespace impeller
