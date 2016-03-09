// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_TOOLS_SKY_SNAPSHOT_LOADER_H_
#define SKY_TOOLS_SKY_SNAPSHOT_LOADER_H_

#include <set>
#include <string>

#include "dart/runtime/include/dart_api.h"

Dart_Handle HandleLibraryTag(Dart_LibraryTag tag,
                             Dart_Handle library,
                             Dart_Handle url);
void LoadScript(const std::string& url);
const std::set<std::string>& GetDependencies();

#endif  // SKY_TOOLS_SKY_SNAPSHOT_LOADER_H_
