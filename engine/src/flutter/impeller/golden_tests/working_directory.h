// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <string>

#include "flutter/fml/macros.h"

namespace impeller {
namespace testing {

/// Keeps track of the global variable for the specified working
/// directory.
class WorkingDirectory {
 public:
  static WorkingDirectory* Instance();

  std::string GetFilenamePath(const std::string& filename) const;

  void SetPath(const std::string& path);

  const std::string& GetPath() const { return path_; }

 private:
  WorkingDirectory(const WorkingDirectory&) = delete;

  WorkingDirectory& operator=(const WorkingDirectory&) = delete;
  WorkingDirectory();
  static WorkingDirectory* instance_;
  std::string path_;
  bool did_set_ = false;
};

}  // namespace testing
}  // namespace impeller
