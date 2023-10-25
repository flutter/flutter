// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <type_traits>

#include "flutter/fml/macros.h"
#include "impeller/base/allocation.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      Represents a read/write query to an archive database. Statements
///             are expensive to create and must be cached for as long as
///             possible.
///
class ArchiveStatement {
 public:
  ~ArchiveStatement();

  bool IsValid() const;

  enum class Result {
    //--------------------------------------------------------------------------
    /// The statement is done executing.
    ///
    kDone,
    //--------------------------------------------------------------------------
    /// The statement found a row of information ready for reading.
    ///
    kRow,
    //--------------------------------------------------------------------------
    /// Statement execution was a failure.
    ///
    kFailure,
  };

  //----------------------------------------------------------------------------
  /// @brief      Execute the given statement with the provided data.
  ///
  /// @return     Is the execution was succeessful.
  ///
  [[nodiscard]] Result Execute();

  //----------------------------------------------------------------------------
  /// @brief      All writes after the last successfull `Run` call are reset.
  ///             Since statements are expensive to create, reset them for new
  ///             writes instead of creating new statements.
  ///
  /// @return     If the statement writes were reset.
  ///
  bool Reset();

  bool WriteValue(size_t index, const std::string& item);

  template <class T, class = std::enable_if<std::is_integral<T>::value>>
  bool WriteValue(size_t index, T item) {
    return BindIntegral(index, static_cast<int64_t>(item));
  }

  bool WriteValue(size_t index, double item);

  bool WriteValue(size_t index, const Allocation& item);

  template <class T, class = std::enable_if<std::is_integral<T>::value>>
  bool ReadValue(size_t index, T& item) {
    return ColumnIntegral(index, item);
  }

  bool ReadValue(size_t index, double& item);

  bool ReadValue(size_t index, std::string& item);

  bool ReadValue(size_t index, Allocation& item);

  size_t GetColumnCount();

 private:
  struct Handle;
  std::unique_ptr<Handle> statement_handle_;

  friend class ArchiveDatabase;

  ArchiveStatement(void* db, const std::string& statement);

  bool BindIntegral(size_t index, int64_t item);

  bool ColumnIntegral(size_t index, int64_t& item);

  ArchiveStatement(const ArchiveStatement&) = delete;

  ArchiveStatement& operator=(const ArchiveStatement&) = delete;
};

}  // namespace impeller
