// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_TOOLS_PACKAGER_LOGGING_H_
#define SKY_TOOLS_PACKAGER_LOGGING_H_

#include <string>

#include "dart/runtime/include/dart_api.h"

bool LogIfError(Dart_Handle handle);
std::string StringFromDart(Dart_Handle string);
Dart_Handle StringToDart(const std::string& string);

#endif  // SKY_TOOLS_PACKAGER_LOGGING_H_
