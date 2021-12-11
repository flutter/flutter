// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/archivist/archive_transaction.h"

#include "flutter/fml/logging.h"
#include "impeller/archivist/archive_statement.h"

namespace impeller {

ArchiveTransaction::ArchiveTransaction(int64_t& transactionCount,
                                       ArchiveStatement& beginStatement,
                                       ArchiveStatement& endStatement,
                                       ArchiveStatement& rollbackStatement)
    : end_stmt_(endStatement),
      rollback_stmt_(rollbackStatement),
      transaction_count_(transactionCount) {
  if (transaction_count_ == 0) {
    cleanup_ = beginStatement.Execute() == ArchiveStatement::Result::kDone;
  }
  transaction_count_++;
}

ArchiveTransaction::ArchiveTransaction(ArchiveTransaction&& other)
    : end_stmt_(other.end_stmt_),
      rollback_stmt_(other.rollback_stmt_),
      transaction_count_(other.transaction_count_),
      cleanup_(other.cleanup_),
      successful_(other.successful_) {
  other.abandoned_ = true;
}

ArchiveTransaction::~ArchiveTransaction() {
  if (abandoned_) {
    return;
  }

  FML_CHECK(transaction_count_ != 0);
  if (transaction_count_ == 1 && cleanup_) {
    auto res = successful_ ? end_stmt_.Execute() : rollback_stmt_.Execute();
    FML_CHECK(res == ArchiveStatement::Result::kDone)
        << "Must be able to commit the nested transaction";
  }
  transaction_count_--;
}

void ArchiveTransaction::MarkWritesAsReadyForCommit() {
  successful_ = true;
}

}  // namespace impeller
