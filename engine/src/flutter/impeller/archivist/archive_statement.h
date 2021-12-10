// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <type_traits>

#include "flutter/fml/macros.h"
#include "impeller/base/allocation.h"

namespace impeller {

class ArchiveStatement {
 public:
  ~ArchiveStatement();

  ArchiveStatement(ArchiveStatement&& message);

  bool IsReady() const;

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

  enum class Result {
    kDone,
    kRow,
    kFailure,
  };

  [[nodiscard]] Result Run();

 private:
  void* statement_handle_ = nullptr;
  bool ready_ = false;

  friend class ArchiveDatabase;

  ArchiveStatement(void* db, const std::string& statememt);

  bool BindIntegral(size_t index, int64_t item);

  bool ColumnIntegral(size_t index, int64_t& item);

  FML_DISALLOW_COPY_AND_ASSIGN(ArchiveStatement);
};

}  // namespace impeller
