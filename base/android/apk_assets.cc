// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <jni.h>

#include "base/android/apk_assets.h"

#include "base/android/jni_array.h"
#include "base/android/jni_string.h"
#include "base/android/scoped_java_ref.h"
#include "jni/ApkAssets_jni.h"

namespace base {
namespace android {

bool RegisterApkAssets(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

int OpenApkAsset(const std::string& file_path,
                 base::MemoryMappedFile::Region* region) {
  // The AAssetManager API of the NDK is does not expose a method for accessing
  // raw resources :(.
  JNIEnv* env = base::android::AttachCurrentThread();
  ScopedJavaLocalRef<jlongArray> jarr = Java_ApkAssets_open(
      env,
      base::android::GetApplicationContext(),
      base::android::ConvertUTF8ToJavaString(env, file_path).Release());
  std::vector<jlong> results;
  base::android::JavaLongArrayToLongVector(env, jarr.obj(), &results);
  CHECK_EQ(3U, results.size());
  int fd = static_cast<int>(results[0]);
  region->offset = results[1];
  region->size = results[2];
  return fd;
}

bool RegisterApkAssetWithGlobalDescriptors(base::GlobalDescriptors::Key key,
                                           const std::string& file_path) {
  base::MemoryMappedFile::Region region =
      base::MemoryMappedFile::Region::kWholeFile;
  int asset_fd = OpenApkAsset(file_path, &region);
  if (asset_fd != -1) {
    base::GlobalDescriptors::GetInstance()->Set(key, asset_fd, region);
  }
  return asset_fd != -1;
}

}  // namespace android
}  // namespace base
