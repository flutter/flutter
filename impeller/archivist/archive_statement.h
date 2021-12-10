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

  bool isReady() const;

  bool reset();

  bool bind(size_t index, const std::string& item);

  template <class T, class = std::enable_if<std::is_integral<T>::value>>
  bool bind(size_t index, T item) {
    return bindIntegral(index, static_cast<int64_t>(item));
  }

  bool bind(size_t index, double item);

  bool bind(size_t index, const Allocation& item);

  template <class T, class = std::enable_if<std::is_integral<T>::value>>
  bool column(size_t index, T& item) {
    return columnIntegral(index, item);
  }

  bool column(size_t index, double& item);

  bool column(size_t index, std::string& item);

  bool column(size_t index, Allocation& item);

  size_t columnCount();

  enum class Result {
    Done,
    Row,
    Failure,
  };

  Result run();

 private:
  void* _statement = nullptr;
  bool _ready = false;

  friend class ArchiveDatabase;

  ArchiveStatement(void* db, const std::string& statememt);

  bool bindIntegral(size_t index, int64_t item);

  bool columnIntegral(size_t index, int64_t& item);

  FML_DISALLOW_COPY_AND_ASSIGN(ArchiveStatement);
};

}  // namespace impeller
