// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_MAC_PLATFORM_MAC_H_
#define SKY_SHELL_MAC_PLATFORM_MAC_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef int(^PlatformMacMainCallback)(void);

int PlatformMacMain(int argc, const char *argv[],
    PlatformMacMainCallback callback);

#ifdef __cplusplus
}
#endif

#endif  // SKY_SHELL_MAC_PLATFORM_MAC_H_
