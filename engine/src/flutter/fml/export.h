// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_EXPORT_H_
#define FLUTTER_FML_EXPORT_H_

#include "flutter/fml/build_config.h"

#if OS_WIN
#define FML_EXPORT __declspec(dllimport)
#else
#define FML_EXPORT __attribute__((visibility("default")))
#endif

#endif  // FLUTTER_FML_EXPORT_H_
