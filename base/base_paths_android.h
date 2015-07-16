// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_BASE_PATHS_ANDROID_H_
#define BASE_BASE_PATHS_ANDROID_H_

// This file declares Android-specific path keys for the base module.
// These can be used with the PathService to access various special
// directories and files.

namespace base {

enum {
  PATH_ANDROID_START = 300,

  DIR_ANDROID_APP_DATA,  // Directory where to put Android app's data.
  DIR_ANDROID_EXTERNAL_STORAGE,  // Android external storage directory.

  PATH_ANDROID_END
};

}  // namespace base

#endif  // BASE_BASE_PATHS_ANDROID_H_
