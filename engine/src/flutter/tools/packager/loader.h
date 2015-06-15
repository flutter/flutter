// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_TOOLS_PACKAGER_LOADER_H_
#define SKY_TOOLS_PACKAGER_LOADER_H_

#include <string>

#include "dart/runtime/include/dart_api.h"

Dart_Handle HandleLibraryTag(Dart_LibraryTag tag,
                             Dart_Handle library,
                             Dart_Handle url);
void LoadSkyInternals();
void LoadScript(std::string url);

#endif  // SKY_TOOLS_PACKAGER_LOADER_H_
