// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_C_GLES2_GLES2_EXPORT_H_
#define MOJO_PUBLIC_C_GLES2_GLES2_EXPORT_H_

#if defined(COMPONENT_BUILD) && defined(MOJO_USE_GLES2_IMPL)
#if defined(WIN32)

#if defined(MOJO_GLES2_IMPLEMENTATION)
#define MOJO_GLES2_EXPORT __declspec(dllexport)
#else
#define MOJO_GLES2_EXPORT __declspec(dllimport)
#endif

#else  // !defined(WIN32)

#if defined(MOJO_GLES2_IMPLEMENTATION)
#define MOJO_GLES2_EXPORT __attribute__((visibility("default")))
#else
#define MOJO_GLES2_EXPORT
#endif

#endif  // defined(WIN32)

#else  // !defined(COMPONENT_BUILD) || !defined(MOJO_USE_GLES2_IMPL)

#define MOJO_GLES2_EXPORT

#endif  // defined(COMPONENT_BUILD) && defined(MOJO_USE_GLES2_IMPL)

#endif  // MOJO_PUBLIC_C_GLES2_GLES2_EXPORT_H_
