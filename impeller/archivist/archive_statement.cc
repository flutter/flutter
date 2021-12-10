// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/archivist/archive_statement.h"

#include <string>

#include "flutter/fml/logging.h"
#include "third_party/sqlite/sqlite3.h"

namespace impeller {

#define STATEMENT_HANDLE reinterpret_cast<::sqlite3_stmt*>(_statement)

ArchiveStatement::ArchiveStatement(void* db, const std::string& statememt) {
  ::sqlite3_stmt* statementHandle = nullptr;
  auto res = ::sqlite3_prepare_v2(reinterpret_cast<sqlite3*>(db),      //
                                  statememt.c_str(),                   //
                                  static_cast<int>(statememt.size()),  //
                                  &statementHandle,                    //
                                  nullptr);
  _statement = statementHandle;
  _ready = res == SQLITE_OK && _statement != nullptr;
}

ArchiveStatement::ArchiveStatement(ArchiveStatement&& other)
    : _statement(other._statement), _ready(other._ready) {
  other._statement = nullptr;
  other._ready = false;
}

ArchiveStatement::~ArchiveStatement() {
  if (_statement != nullptr) {
    auto res = ::sqlite3_finalize(STATEMENT_HANDLE);
    FML_CHECK(res == SQLITE_OK) << "Unable to finalize the archive.";
  }
}

bool ArchiveStatement::isReady() const {
  return _ready;
}

bool ArchiveStatement::reset() {
  if (::sqlite3_reset(STATEMENT_HANDLE) != SQLITE_OK) {
    return false;
  }

  if (::sqlite3_clear_bindings(STATEMENT_HANDLE) != SQLITE_OK) {
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
   *  sqlite columns begin from 1
   */
  return static_cast<int>(index);
}

size_t ArchiveStatement::columnCount() {
  return ::sqlite3_column_count(STATEMENT_HANDLE);
}

/*
 *  Bind Variants
 */
bool ArchiveStatement::bind(size_t index, const std::string& item) {
  return ::sqlite3_bind_text(STATEMENT_HANDLE,               //
                             ToParam(index),                 //
                             item.data(),                    //
                             static_cast<int>(item.size()),  //
                             SQLITE_TRANSIENT) == SQLITE_OK;
}

bool ArchiveStatement::bindIntegral(size_t index, int64_t item) {
  return ::sqlite3_bind_int64(STATEMENT_HANDLE,  //
                              ToParam(index),    //
                              item) == SQLITE_OK;
}

bool ArchiveStatement::bind(size_t index, double item) {
  return ::sqlite3_bind_double(STATEMENT_HANDLE,  //
                               ToParam(index),    //
                               item) == SQLITE_OK;
}

bool ArchiveStatement::bind(size_t index, const Allocation& item) {
  return ::sqlite3_bind_blob(STATEMENT_HANDLE,                    //
                             ToParam(index),                      //
                             item.GetBuffer(),                    //
                             static_cast<int>(item.GetLength()),  //
                             SQLITE_TRANSIENT) == SQLITE_OK;
}

/*
 *  Column Variants
 */
bool ArchiveStatement::columnIntegral(size_t index, int64_t& item) {
  item = ::sqlite3_column_int64(STATEMENT_HANDLE, ToColumn(index));
  return true;
}

bool ArchiveStatement::column(size_t index, double& item) {
  item = ::sqlite3_column_double(STATEMENT_HANDLE, ToColumn(index));
  return true;
}

/*
 *  For cases where byte sizes of column data is necessary, the
 *  recommendations in https://www.sqlite.org/c3ref/column_blob.html regarding
 *  type conversions are followed.
 *
 *  TL;DR: Access blobs then bytes.
 */

bool ArchiveStatement::column(size_t index, std::string& item) {
  /*
   *  Get the character data
   */
  auto chars = reinterpret_cast<const char*>(
      ::sqlite3_column_text(STATEMENT_HANDLE, ToColumn(index)));

  /*
   *  Get the length of the string (in bytes)
   */
  size_t textByteSize =
      ::sqlite3_column_bytes(STATEMENT_HANDLE, ToColumn(index));

  std::string text(chars, textByteSize);
  item.swap(text);

  return true;
}

bool ArchiveStatement::column(size_t index, Allocation& item) {
  /*
   *  Get a blob pointer
   */
  auto blob = reinterpret_cast<const uint8_t*>(
      ::sqlite3_column_blob(STATEMENT_HANDLE, ToColumn(index)));

  /*
   *  Decode the number of bytes in the blob
   */
  size_t byteSize = ::sqlite3_column_bytes(STATEMENT_HANDLE, ToColumn(index));

  /*
   *  Reszie the host allocation and move the blob contents into it
   */
  if (!item.Truncate(byteSize, false /* npot */)) {
    return false;
  }

  memmove(item.GetBuffer(), blob, byteSize);
  return true;
}

ArchiveStatement::Result ArchiveStatement::run() {
  switch (::sqlite3_step(STATEMENT_HANDLE)) {
    case SQLITE_DONE:
      return Result::Done;
    case SQLITE_ROW:
      return Result::Row;
    default:
      return Result::Failure;
  }
}

}  // namespace impeller
