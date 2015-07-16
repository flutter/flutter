// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_ANDROID_FIFO_UTILS_H_
#define BASE_ANDROID_FIFO_UTILS_H_

#include <stdio.h>

#include "base/base_export.h"
#include "base/basictypes.h"

namespace base {

class FilePath;

namespace android {

// Creates a fifo at the given |path| with POSIX permissions set to |mode|,
// returning true if it was successfully created and permissions were set.
BASE_EXPORT bool CreateFIFO(const FilePath& path, int mode);

// Redirects the |stream| to the file provided by |path| with |mode|
// permissions, returning true if successful.
BASE_EXPORT bool RedirectStream(FILE* stream,
                                const FilePath& path,
                                const char* mode);

}  // namespace android
}  // namespace base

#endif  // BASE_ANDROID_FIFO_UTILS_H_
