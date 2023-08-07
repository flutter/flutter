// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#if FML_OS_WIN
#define FLUTTER_GPU_EXPORT __declspec(dllexport)
#else  // FML_OS_WIN
#define FLUTTER_GPU_EXPORT __attribute__((visibility("default")))
#endif  // FML_OS_WIN
