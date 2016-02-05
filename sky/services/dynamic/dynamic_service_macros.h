// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SERVICES_DYNAMIC_DYNAMIC_SERVICE_MACROS_H_
#define SKY_SERVICES_DYNAMIC_DYNAMIC_SERVICE_MACROS_H_

#define FLUTTER_EXPORT __attribute__((visibility("default")))

#ifdef __cplusplus

#define FLUTTER_C_API_START extern "C" {
#define FLUTTER_C_API_END }

#else  // __cplusplus

#define FLUTTER_C_API_START
#define FLUTTER_C_API_END

#endif  // __cplusplus

#endif  // SKY_SERVICES_DYNAMIC_DYNAMIC_SERVICE_MACROS_H_
