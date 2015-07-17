// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_ANDROID_PATH_UTILS_H_
#define BASE_ANDROID_PATH_UTILS_H_

#include <jni.h>

#include "base/base_export.h"

namespace base {

class FilePath;

namespace android {

// Retrieves the absolute path to the data directory of the current
// application. The result is placed in the FilePath pointed to by 'result'.
// This method is dedicated for base_paths_android.c, Using
// PathService::Get(base::DIR_ANDROID_APP_DATA, ...) gets the data dir.
BASE_EXPORT bool GetDataDirectory(FilePath* result);

// Retrieves the absolute path to the database directory that Android
// framework's SQLiteDatabase class uses when creating database files.
BASE_EXPORT bool GetDatabaseDirectory(FilePath* result);

// Retrieves the absolute path to the cache directory. The result is placed in
// the FilePath pointed to by 'result'. This method is dedicated for
// base_paths_android.c, Using PathService::Get(base::DIR_CACHE, ...) gets the
// cache dir.
BASE_EXPORT bool GetCacheDirectory(FilePath* result);

// Retrieves the path to the thumbnail cache directory. The result is placed
// in the FilePath pointed to by 'result'.
BASE_EXPORT bool GetThumbnailCacheDirectory(FilePath* result);

// Retrieves the path to the public downloads directory. The result is placed
// in the FilePath pointed to by 'result'.
BASE_EXPORT bool GetDownloadsDirectory(FilePath* result);

// Retrieves the path to the native JNI libraries via
// ApplicationInfo.nativeLibraryDir on the Java side. The result is placed in
// the FilePath pointed to by 'result'.
BASE_EXPORT bool GetNativeLibraryDirectory(FilePath* result);

// Retrieves the absolute path to the external storage directory. The result
// is placed in the FilePath pointed to by 'result'.
BASE_EXPORT bool GetExternalStorageDirectory(FilePath* result);

bool RegisterPathUtils(JNIEnv* env);

}  // namespace android
}  // namespace base

#endif  // BASE_ANDROID_PATH_UTILS_H_
