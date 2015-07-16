// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CRYPTO_CRYPTO_EXPORT_H_
#define CRYPTO_CRYPTO_EXPORT_H_

// Defines CRYPTO_EXPORT so that functionality implemented by the crypto module
// can be exported to consumers, and CRYPTO_EXPORT_PRIVATE that allows unit
// tests to access features not intended to be used directly by real consumers.

#if defined(COMPONENT_BUILD)
#if defined(WIN32)

#if defined(CRYPTO_IMPLEMENTATION)
#define CRYPTO_EXPORT __declspec(dllexport)
#define CRYPTO_EXPORT_PRIVATE __declspec(dllexport)
#else
#define CRYPTO_EXPORT __declspec(dllimport)
#define CRYPTO_EXPORT_PRIVATE __declspec(dllimport)
#endif  // defined(CRYPTO_IMPLEMENTATION)

#else  // defined(WIN32)
#if defined(CRYPTO_IMPLEMENTATION)
#define CRYPTO_EXPORT __attribute__((visibility("default")))
#define CRYPTO_EXPORT_PRIVATE __attribute__((visibility("default")))
#else
#define CRYPTO_EXPORT
#define CRYPTO_EXPORT_PRIVATE
#endif
#endif

#else  // defined(COMPONENT_BUILD)
#define CRYPTO_EXPORT
#define CRYPTO_EXPORT_PRIVATE
#endif

#endif  // CRYPTO_CRYPTO_EXPORT_H_
