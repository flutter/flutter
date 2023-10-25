// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/archivist/archive_statement.h"

#include <string>

#include "flutter/fml/logging.h"
#include "third_party/sqlite/sqlite3.h"

namespace impeller {

struct ArchiveStatement::Handle {
  Handle(void* db, const std::string& statememt) {
    if (db == nullptr) {
      return;
    }
    ::sqlite3_stmt* handle = nullptr;
    if (::sqlite3_prepare_v2(reinterpret_cast<sqlite3*>(db),      //
                             statememt.c_str(),                   //
                             static_cast<int>(statememt.size()),  //
                             &handle,                             //
                             nullptr) == SQLITE_OK) {
      handle_ = handle;
    }
  }

  ~Handle() {
    if (handle_ == nullptr) {
      return;
    }
    auto res = ::sqlite3_finalize(handle_);
    FML_CHECK(res == SQLITE_OK) << "Unable to finalize the archive.";
  }

  bool IsValid() const { return handle_ != nullptr; }

  ::sqlite3_stmt* Get() const { return handle_; }

 private:
  ::sqlite3_stmt* handle_ = nullptr;

  Handle(const Handle&) = delete;

  Handle& operator=(const Handle&) = delete;
};

ArchiveStatement::ArchiveStatement(void* db, const std::string& statememt)
    : statement_handle_(std::make_unique<Handle>(db, statememt)) {
  if (!statement_handle_->IsValid()) {
    statement_handle_.reset();
  }
}

ArchiveStatement::~ArchiveStatement() = default;

bool ArchiveStatement::IsValid() const {
  return statement_handle_ != nullptr;
}

bool ArchiveStatement::Reset() {
  if (!IsValid()) {
    return false;
  }
  if (::sqlite3_reset(statement_handle_->Get()) != SQLITE_OK) {
    return false;
  }

  if (::sqlite3_clear_bindings(statement_handle_->Get()) != SQLITE_OK) {
    return false;
  }

  return true;
}

static constexpr int ToParam(size_t index) {
  /*
   *  sqlite parameters begin from 1
   */
  return static_cast<int>(index + 1);
}

static constexpr int ToColumn(size_t index) {
  /*
   *  sqlite columns begin from 0
   */
  return static_cast<int>(index);
}

size_t ArchiveStatement::GetColumnCount() {
  if (!IsValid()) {
    return 0u;
  }
  return ::sqlite3_column_count(statement_handle_->Get());
}

/*
 *  Bind Variants
 */
bool ArchiveStatement::WriteValue(size_t index, const std::string& item) {
  if (!IsValid()) {
    return false;
  }
  return ::sqlite3_bind_text(statement_handle_->Get(),       //
                             ToParam(index),                 //
                             item.data(),                    //
                             static_cast<int>(item.size()),  //
                             SQLITE_TRANSIENT) == SQLITE_OK;
}

bool ArchiveStatement::BindIntegral(size_t index, int64_t item) {
  if (!IsValid()) {
    return false;
  }
  return ::sqlite3_bind_int64(statement_handle_->Get(),  //
                              ToParam(index),            //
                              item) == SQLITE_OK;
}

bool ArchiveStatement::WriteValue(size_t index, double item) {
  if (!IsValid()) {
    return false;
  }
  return ::sqlite3_bind_double(statement_handle_->Get(),  //
                               ToParam(index),            //
                               item) == SQLITE_OK;
}

bool ArchiveStatement::WriteValue(size_t index, const Allocation& item) {
  if (!IsValid()) {
    return false;
  }
  return ::sqlite3_bind_blob(statement_handle_->Get(),            //
                             ToParam(index),                      //
                             item.GetBuffer(),                    //
                             static_cast<int>(item.GetLength()),  //
                             SQLITE_TRANSIENT) == SQLITE_OK;
}

/*
 *  Column Variants
 */
bool ArchiveStatement::ColumnIntegral(size_t index, int64_t& item) {
  if (!IsValid()) {
    return false;
  }
  item = ::sqlite3_column_int64(statement_handle_->Get(), ToColumn(index));
  return true;
}

bool ArchiveStatement::ReadValue(size_t index, double& item) {
  if (!IsValid()) {
    return false;
  }
  item = ::sqlite3_column_double(statement_handle_->Get(), ToColumn(index));
  return true;
}

/*
 *  For cases where byte sizes of column data is necessary, the
 *  recommendations in https://www.sqlite.org/c3ref/column_blob.html regarding
 *  type conversions are followed.
 *
 *  TL;DR: Access blobs then bytes.
 */

bool ArchiveStatement::ReadValue(size_t index, std::string& item) {
  if (!IsValid()) {
    return false;
  }
  /*
   *  Get the character data
   */
  auto chars = reinterpret_cast<const char*>(
      ::sqlite3_column_text(statement_handle_->Get(), ToColumn(index)));

  /*
   *  Get the length of the string (in bytes)
   */
  size_t textByteSize =
      ::sqlite3_column_bytes(statement_handle_->Get(), ToColumn(index));

  std::string text(chars, textByteSize);
  item.swap(text);

  return true;
}

bool ArchiveStatement::ReadValue(size_t index, Allocation& item) {
  if (!IsValid()) {
    return false;
  }
  /*
   *  Get a blob pointer
   */
  auto blob = reinterpret_cast<const uint8_t*>(
      ::sqlite3_column_blob(statement_handle_->Get(), ToColumn(index)));

  /*
   *  Decode the number of bytes in the blob
   */
  size_t byteSize =
      ::sqlite3_column_bytes(statement_handle_->Get(), ToColumn(index));

  /*
   *  Reszie the host allocation and move the blob contents into it
   */
  if (!item.Truncate(byteSize, false /* npot */)) {
    return false;
  }

  memmove(item.GetBuffer(), blob, byteSize);
  return true;
}

ArchiveStatement::Result ArchiveStatement::Execute() {
  if (!IsValid()) {
    return Result::kFailure;
  }
  switch (::sqlite3_step(statement_handle_->Get())) {
    case SQLITE_DONE:
      return Result::kDone;
    case SQLITE_ROW:
      return Result::kRow;
    default:
      return Result::kFailure;
  }
}

}  // namespace impeller
