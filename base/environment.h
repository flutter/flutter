// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_ENVIRONMENT_H_
#define BASE_ENVIRONMENT_H_

#include <map>
#include <string>

#include "base/base_export.h"
#include "base/memory/scoped_ptr.h"
#include "base/strings/string16.h"
#include "build/build_config.h"

namespace base {

namespace env_vars {

#if defined(OS_POSIX)
BASE_EXPORT extern const char kHome[];
#endif

}  // namespace env_vars

class BASE_EXPORT Environment {
 public:
  virtual ~Environment();

  // Static factory method that returns the implementation that provide the
  // appropriate platform-specific instance.
  static Environment* Create();

  // Gets an environment variable's value and stores it in |result|.
  // Returns false if the key is unset.
  virtual bool GetVar(const char* variable_name, std::string* result) = 0;

  // Syntactic sugar for GetVar(variable_name, NULL);
  virtual bool HasVar(const char* variable_name);

  // Returns true on success, otherwise returns false.
  virtual bool SetVar(const char* variable_name,
                      const std::string& new_value) = 0;

  // Returns true on success, otherwise returns false.
  virtual bool UnSetVar(const char* variable_name) = 0;
};


#if defined(OS_WIN)

typedef string16 NativeEnvironmentString;
typedef std::map<NativeEnvironmentString, NativeEnvironmentString>
    EnvironmentMap;

// Returns a modified environment vector constructed from the given environment
// and the list of changes given in |changes|. Each key in the environment is
// matched against the first element of the pairs. In the event of a match, the
// value is replaced by the second of the pair, unless the second is empty, in
// which case the key-value is removed.
//
// This Windows version takes and returns a Windows-style environment block
// which is a concatenated list of null-terminated 16-bit strings. The end is
// marked by a double-null terminator. The size of the returned string will
// include the terminators.
BASE_EXPORT string16 AlterEnvironment(const wchar_t* env,
                                      const EnvironmentMap& changes);

#elif defined(OS_POSIX)

typedef std::string NativeEnvironmentString;
typedef std::map<NativeEnvironmentString, NativeEnvironmentString>
    EnvironmentMap;

// See general comments for the Windows version above.
//
// This Posix version takes and returns a Posix-style environment block, which
// is a null-terminated list of pointers to null-terminated strings. The
// returned array will have appended to it the storage for the array itself so
// there is only one pointer to manage, but this means that you can't copy the
// array without keeping the original around.
BASE_EXPORT scoped_ptr<char*[]> AlterEnvironment(
    const char* const* env,
    const EnvironmentMap& changes);

#endif

}  // namespace base

#endif  // BASE_ENVIRONMENT_H_
