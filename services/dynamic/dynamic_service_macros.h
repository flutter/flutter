// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SERVICES_DYNAMIC_DYNAMIC_SERVICE_MACROS_H_
#define FLUTTER_SERVICES_DYNAMIC_DYNAMIC_SERVICE_MACROS_H_

#if defined(DYNAMIC_SERVICE_EMBEDDER)

// Embedder does not export any symbols
#define FLUTTER_EXPORT

#else  // defined(DYNAMIC_SERVICE_EMBEDDER)

#define FLUTTER_EXPORT __attribute__((visibility("default")))

#endif  // defined(DYNAMIC_SERVICE_EMBEDDER)

#ifdef __cplusplus

#define FLUTTER_C_API_START extern "C" {
#define FLUTTER_C_API_END }

#else  // __cplusplus

#define FLUTTER_C_API_START
#define FLUTTER_C_API_END

#endif  // __cplusplus

#endif  // FLUTTER_SERVICES_DYNAMIC_DYNAMIC_SERVICE_MACROS_H_
