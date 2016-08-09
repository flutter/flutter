// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_PLATFORM_PLATFORM_HANDLE_UTILS_POSIX_H_
#define MOJO_EDK_PLATFORM_PLATFORM_HANDLE_UTILS_POSIX_H_

#include "mojo/edk/platform/scoped_platform_handle.h"
#include "mojo/edk/util/scoped_file.h"

namespace mojo {
namespace platform {

// Gets a (scoped) |PlatformHandle| from the given (scoped) |FILE|.
ScopedPlatformHandle PlatformHandleFromFILE(util::ScopedFILE fp);

// Gets a (scoped) |FILE| from a (scoped) |PlatformHandle|. |mode| is as for
// |fopen()| (and |fdopen()|, etc.).
util::ScopedFILE FILEFromPlatformHandle(ScopedPlatformHandle h,
                                        const char* mode);

}  // namespace platform
}  // namespace mojo

#endif  // MOJO_EDK_PLATFORM_PLATFORM_HANDLE_UTILS_POSIX_H_
