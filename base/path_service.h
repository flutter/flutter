// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_PATH_SERVICE_H_
#define BASE_PATH_SERVICE_H_

#include <string>

#include "base/base_export.h"
#include "base/base_paths.h"
#include "base/gtest_prod_util.h"
#include "build/build_config.h"

namespace base {
class FilePath;
class ScopedPathOverride;
}  // namespace base

// The path service is a global table mapping keys to file system paths.  It is
// OK to use this service from multiple threads.
//
class BASE_EXPORT PathService {
 public:
  // Retrieves a path to a special directory or file and places it into the
  // string pointed to by 'path'. If you ask for a directory it is guaranteed
  // to NOT have a path separator at the end. For example, "c:\windows\temp"
  // Directories are also guaranteed to exist when this function succeeds.
  //
  // Returns true if the directory or file was successfully retrieved. On
  // failure, 'path' will not be changed.
  static bool Get(int key, base::FilePath* path);

  // Overrides the path to a special directory or file.  This cannot be used to
  // change the value of DIR_CURRENT, but that should be obvious.  Also, if the
  // path specifies a directory that does not exist, the directory will be
  // created by this method.  This method returns true if successful.
  //
  // If the given path is relative, then it will be resolved against
  // DIR_CURRENT.
  //
  // WARNING: Consumers of PathService::Get may expect paths to be constant
  // over the lifetime of the app, so this method should be used with caution.
  //
  // Unit tests generally should use ScopedPathOverride instead. Overrides from
  // one test should not carry over to another.
  static bool Override(int key, const base::FilePath& path);

  // This function does the same as PathService::Override but it takes extra
  // parameters:
  // - |is_absolute| indicates that |path| has already been expanded into an
  // absolute path, otherwise MakeAbsoluteFilePath() will be used. This is
  // useful to override paths that may not exist yet, since MakeAbsoluteFilePath
  // fails for those. Note that MakeAbsoluteFilePath also expands symbolic
  // links, even if path.IsAbsolute() is already true.
  // - |create| guides whether the directory to be overriden must
  // be created in case it doesn't exist already.
  static bool OverrideAndCreateIfNeeded(int key,
                                        const base::FilePath& path,
                                        bool is_absolute,
                                        bool create);

  // To extend the set of supported keys, you can register a path provider,
  // which is just a function mirroring PathService::Get.  The ProviderFunc
  // returns false if it cannot provide a non-empty path for the given key.
  // Otherwise, true is returned.
  //
  // WARNING: This function could be called on any thread from which the
  // PathService is used, so a the ProviderFunc MUST BE THREADSAFE.
  //
  typedef bool (*ProviderFunc)(int, base::FilePath*);

  // Call to register a path provider.  You must specify the range "[key_start,
  // key_end)" of supported path keys.
  static void RegisterProvider(ProviderFunc provider,
                               int key_start,
                               int key_end);

  // Disable internal cache.
  static void DisableCache();

 private:
  friend class base::ScopedPathOverride;
  FRIEND_TEST_ALL_PREFIXES(PathServiceTest, RemoveOverride);

  // Removes an override for a special directory or file. Returns true if there
  // was an override to remove or false if none was present.
  // NOTE: This function is intended to be used by tests only!
  static bool RemoveOverride(int key);
};

#endif  // BASE_PATH_SERVICE_H_
