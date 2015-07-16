// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/scoped_path_override.h"

#include "base/logging.h"
#include "base/path_service.h"

namespace base {

ScopedPathOverride::ScopedPathOverride(int key) : key_(key) {
  bool result = temp_dir_.CreateUniqueTempDir();
  CHECK(result);
  result = PathService::Override(key, temp_dir_.path());
  CHECK(result);
}

ScopedPathOverride::ScopedPathOverride(int key, const base::FilePath& dir)
    : key_(key) {
  bool result = PathService::Override(key, dir);
  CHECK(result);
}

ScopedPathOverride::ScopedPathOverride(int key,
                                       const FilePath& path,
                                       bool is_absolute,
                                       bool create)
    : key_(key) {
  bool result =
      PathService::OverrideAndCreateIfNeeded(key, path, is_absolute, create);
  CHECK(result);
}

ScopedPathOverride::~ScopedPathOverride() {
   bool result = PathService::RemoveOverride(key_);
   CHECK(result) << "The override seems to have been removed already!";
}

}  // namespace base
