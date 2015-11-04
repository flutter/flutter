// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#if __cplusplus
extern "C" {
#endif

#include <inttypes.h>
#include <stdint.h>
#include <stddef.h>

extern double FlutterApplicationVersionNumber;
extern const unsigned char FlutterApplicationVersionString[];

extern const uint8_t* kInstructionsSnapshot;
extern const uint8_t* kDartIsolateSnapshotBuffer;
extern const uint8_t* kDartVmIsolateSnapshotBuffer;

#if __cplusplus
}
#endif
