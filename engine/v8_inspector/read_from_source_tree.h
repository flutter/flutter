// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_V8_INSPECTOR_READ_FROM_SOURCE_TREE_H_
#define SKY_ENGINE_V8_INSPECTOR_READ_FROM_SOURCE_TREE_H_

#include <string>

namespace inspector {

// TODO(eseidel): This is a horrible hack and only works when run
// inside its source tree!  crbug.com/434513
void ReadFileFromSourceTree(const char* name, std::string* buffer);

}  // namespace inspector

#endif  // SKY_ENGINE_V8_INSPECTOR_READ_FROM_SOURCE_TREE_H_
