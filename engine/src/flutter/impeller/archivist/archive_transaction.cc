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
    : _endStatement(endStatement),
      _rollbackStatement(rollbackStatement),
      _transactionCount(transactionCount) {
  if (_transactionCount == 0) {
    _cleanup = beginStatement.run() == ArchiveStatement::Result::Done;
  }
  _transactionCount++;
}

ArchiveTransaction::ArchiveTransaction(ArchiveTransaction&& other)
    : _endStatement(other._endStatement),
      _rollbackStatement(other._rollbackStatement),
      _transactionCount(other._transactionCount),
      _cleanup(other._cleanup),
      _successful(other._successful) {
  other._abandoned = true;
}

ArchiveTransaction::~ArchiveTransaction() {
  if (_abandoned) {
    return;
  }

  FML_CHECK(_transactionCount != 0);
  if (_transactionCount == 1 && _cleanup) {
    auto res = _successful ? _endStatement.run() : _rollbackStatement.run();
    FML_CHECK(res == ArchiveStatement::Result::Done)
        << "Must be able to commit the nested transaction";
  }
  _transactionCount--;
}

void ArchiveTransaction::markWritesSuccessful() {
  _successful = true;
}

}  // namespace impeller
