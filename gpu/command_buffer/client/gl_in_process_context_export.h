// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GL_IN_PROCESS_CONTEXT_EXPORT_H_
#define GL_IN_PROCESS_CONTEXT_EXPORT_H_

#if defined(COMPONENT_BUILD)
#if defined(WIN32)

#if defined(GL_IN_PROCESS_CONTEXT_IMPLEMENTATION)
#define GL_IN_PROCESS_CONTEXT_EXPORT __declspec(dllexport)
#else
#define GL_IN_PROCESS_CONTEXT_EXPORT __declspec(dllimport)
#endif  // defined(GL_IN_PROCESS_CONTEXT_IMPLEMENTATION)

#else  // defined(WIN32)
#if defined(GL_IN_PROCESS_CONTEXT_IMPLEMENTATION)
#define GL_IN_PROCESS_CONTEXT_EXPORT __attribute__((visibility("default")))
#else
#define GL_IN_PROCESS_CONTEXT_EXPORT
#endif
#endif

#else  // defined(COMPONENT_BUILD)
#define GL_IN_PROCESS_CONTEXT_EXPORT
#endif

#endif  // GL_IN_PROCESS_CONTEXT_EXPORT_H_
