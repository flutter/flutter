// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_C_TEST_SUPPORT_TEST_SUPPORT_H_
#define MOJO_PUBLIC_C_TEST_SUPPORT_TEST_SUPPORT_H_

// Note: This header should be compilable as C.

#include <stdio.h>

#include "mojo/public/c/test_support/test_support_export.h"

#ifdef __cplusplus
extern "C" {
#endif

// |sub_test_name| is optional. If not null, it usually describes one particular
// configuration of the test. For example, if |test_name| is "TestPacketRate",
// |sub_test_name| could be "100BytesPerPacket".
// When the perf data is visualized by the performance dashboard, data with
// different |sub_test_name|s (but the same |test_name|) are depicted as
// different traces on the same chart.
MOJO_TEST_SUPPORT_EXPORT void MojoTestSupportLogPerfResult(
    const char* test_name,
    const char* sub_test_name,
    double value,
    const char* units);

// Opens a "/"-delimited file path relative to the source root.
MOJO_TEST_SUPPORT_EXPORT FILE* MojoTestSupportOpenSourceRootRelativeFile(
    const char* source_root_relative_path);

// Enumerates a "/"-delimited directory path relative to the source root.
// Returns only regular files. The return value is a heap-allocated array of
// heap-allocated strings. Each must be free'd separately.
//
// The return value is built like so:
//
//   char** rv = (char**) calloc(N + 1, sizeof(char*));
//   rv[0] = strdup("a");
//   rv[1] = strdup("b");
//   rv[2] = strdup("c");
//   ...
//   rv[N] = NULL;
//
MOJO_TEST_SUPPORT_EXPORT
char** MojoTestSupportEnumerateSourceRootRelativeDirectory(
    const char* source_root_relative_path);

#ifdef __cplusplus
}  // extern "C"
#endif

#endif  // MOJO_PUBLIC_C_TEST_SUPPORT_TEST_SUPPORT_H_
