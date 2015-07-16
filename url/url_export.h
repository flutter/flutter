// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef URL_URL_EXPORT_H_
#define URL_URL_EXPORT_H_

#if defined(COMPONENT_BUILD)
#if defined(WIN32)

#if defined(URL_IMPLEMENTATION)
#define URL_EXPORT __declspec(dllexport)
#else
#define URL_EXPORT __declspec(dllimport)
#endif  // defined(URL_IMPLEMENTATION)

#else  // !defined(WIN32)

#if defined(URL_IMPLEMENTATION)
#define URL_EXPORT __attribute__((visibility("default")))
#else
#define URL_EXPORT
#endif  // defined(URL_IMPLEMENTATION)

#endif  // defined(WIN32)

#else  // !defined(COMPONENT_BUILD)

#define URL_EXPORT

#endif  // define(COMPONENT_BUILD)

#endif  // URL_URL_EXPORT_H_
