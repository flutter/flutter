// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#pragma once

#include <cstdint>

#include "flutter/fml/macros.h"

namespace impeller {

class ArchiveStatement;

//------------------------------------------------------------------------------
/// @brief      All writes made to the archive within a transaction that is not
///             marked as ready for commit will be rolled back with the
///             transaction ends.
///
///             All transactions are obtained from the `ArchiveDatabase`.
///
/// @see        `ArchiveDatabase`
///
class ArchiveTransaction {
 public:
  ArchiveTransaction(ArchiveTransaction&& transaction);

  ~ArchiveTransaction();

  void MarkWritesAsReadyForCommit();

 private:
  ArchiveStatement& end_stmt_;
  ArchiveStatement& rollback_stmt_;
  int64_t& transaction_count_;
  bool cleanup_ = false;
  bool successful_ = false;
  bool abandoned_ = false;

  friend class ArchiveDatabase;

  ArchiveTransaction(int64_t& transactionCount,
                     ArchiveStatement& beginStatement,
                     ArchiveStatement& endStatement,
                     ArchiveStatement& rollbackStatement);

  ArchiveTransaction(const ArchiveTransaction&) = delete;

  ArchiveTransaction& operator=(const ArchiveTransaction&) = delete;
};

}  // namespace impeller
