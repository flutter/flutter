// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_CALLBACK_CACHE_H_
#define FLUTTER_FML_CALLBACK_CACHE_H_

#include <cstdint>
#include <map>
#include <memory>
#include <mutex>
#include <string>

#include "flutter/fml/macros.h"

namespace fml {

struct CallbackRepresentation {
  std::string name;
  std::string class_name;
  std::string library_path;
};

using DartCallbackRepresentation = CallbackRepresentation;

class CallbackCache {
 public:
  static void SetCachePath(const std::string& path);
  static std::string GetCachePath();

  static int64_t GetCallbackHandle(const std::string& name,
                                   const std::string& class_name,
                                   const std::string& library_path);

  static std::unique_ptr<CallbackRepresentation> GetCallbackInformation(
      int64_t handle);

  static void LoadCacheFromDisk();

  static void ClearCacheForTesting();

 private:
  static void SaveCacheToDisk();

  static std::mutex mutex_;
  static std::string cache_path_;
  static std::map<int64_t, CallbackRepresentation> cache_;

  FML_DISALLOW_IMPLICIT_CONSTRUCTORS(CallbackCache);
};

using DartCallbackCache = CallbackCache;

}  // namespace fml

#endif  // FLUTTER_FML_CALLBACK_CACHE_H_
