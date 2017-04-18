// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTERMACROS_H_
#define FLUTTER_FLUTTERMACROS_H_

#if defined(FLUTTER_FRAMEWORK)

#define FLUTTER_EXPORT __attribute__((visibility("default")))

#else  // defined(FLUTTER_SDK)

#define FLUTTER_EXPORT

#endif  // defined(FLUTTER_SDK)

#ifndef NS_ASSUME_NONNULL_BEGIN
#define NS_ASSUME_NONNULL_BEGIN _Pragma("clang assume_nonnull begin")
#define NS_ASSUME_NONNULL_END _Pragma("clang assume_nonnull end")
#endif  // defined(NS_ASSUME_NONNULL_BEGIN)

#endif  // FLUTTER_FLUTTERMACROS_H_
