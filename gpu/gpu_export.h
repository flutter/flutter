// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_GPU_EXPORT_H_
#define GPU_GPU_EXPORT_H_

#if defined(COMPONENT_BUILD) && !defined(NACL_WIN64)
#if defined(WIN32)

#if defined(GPU_IMPLEMENTATION)
#define GPU_EXPORT __declspec(dllexport)
#else
#define GPU_EXPORT __declspec(dllimport)
#endif  // defined(GPU_IMPLEMENTATION)

#else  // defined(WIN32)
#if defined(GPU_IMPLEMENTATION)
#define GPU_EXPORT __attribute__((visibility("default")))
#else
#define GPU_EXPORT
#endif
#endif

#else  // defined(COMPONENT_BUILD)
#define GPU_EXPORT
#endif

#endif  // GPU_GPU_EXPORT_H_
