// Copyright (c) 2005, Google Inc.
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
// 
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// ---
// This file is a compatibility layer that defines Google's version of
// command line flags that are used for configuration.
//
// We put flags into their own namespace.  It is purposefully
// named in an opaque way that people should have trouble typing
// directly.  The idea is that DEFINE puts the flag in the weird
// namespace, and DECLARE imports the flag from there into the
// current namespace.  The net result is to force people to use
// DECLARE to get access to a flag, rather than saying
//   extern bool FLAGS_logtostderr;
// or some such instead.  We want this so we can put extra
// functionality (like sanity-checking) in DECLARE if we want,
// and make sure it is picked up everywhere.
//
// We also put the type of the variable in the namespace, so that
// people can't DECLARE_int32 something that they DEFINE_bool'd
// elsewhere.
#ifndef BASE_COMMANDLINEFLAGS_H_
#define BASE_COMMANDLINEFLAGS_H_

#include <config.h>
#include <string>
#include <string.h>               // for memchr
#include <stdlib.h>               // for getenv
#include "base/basictypes.h"

#if defined(__ANDROID__) || defined(ANDROID)
#include <sys/system_properties.h>
#endif

#define DECLARE_VARIABLE(type, name)                                          \
  namespace FLAG__namespace_do_not_use_directly_use_DECLARE_##type##_instead {\
  extern PERFTOOLS_DLL_DECL type FLAGS_##name;                                \
  }                                                                           \
  using FLAG__namespace_do_not_use_directly_use_DECLARE_##type##_instead::FLAGS_##name

#define DEFINE_VARIABLE(type, name, value, meaning) \
  namespace FLAG__namespace_do_not_use_directly_use_DECLARE_##type##_instead {\
  PERFTOOLS_DLL_DECL type FLAGS_##name(value);                                \
  char FLAGS_no##name;                                                        \
  }                                                                           \
  using FLAG__namespace_do_not_use_directly_use_DECLARE_##type##_instead::FLAGS_##name

// bool specialization
#define DECLARE_bool(name) \
  DECLARE_VARIABLE(bool, name)
#define DEFINE_bool(name, value, meaning) \
  DEFINE_VARIABLE(bool, name, value, meaning)

// int32 specialization
#define DECLARE_int32(name) \
  DECLARE_VARIABLE(int32, name)
#define DEFINE_int32(name, value, meaning) \
  DEFINE_VARIABLE(int32, name, value, meaning)

// int64 specialization
#define DECLARE_int64(name) \
  DECLARE_VARIABLE(int64, name)
#define DEFINE_int64(name, value, meaning) \
  DEFINE_VARIABLE(int64, name, value, meaning)

#define DECLARE_uint64(name) \
  DECLARE_VARIABLE(uint64, name)
#define DEFINE_uint64(name, value, meaning) \
  DEFINE_VARIABLE(uint64, name, value, meaning)

// double specialization
#define DECLARE_double(name) \
  DECLARE_VARIABLE(double, name)
#define DEFINE_double(name, value, meaning) \
  DEFINE_VARIABLE(double, name, value, meaning)

// Special case for string, because of the pointer type.
#define DECLARE_string(name)                                          \
  namespace FLAG__namespace_do_not_use_directly_use_DECLARE_string_instead {  \
  extern const char* FLAGS_##name;                                            \
  }                                                                           \
  using FLAG__namespace_do_not_use_directly_use_DECLARE_string_instead::FLAGS_##name
#define DEFINE_string(name, value, meaning) \
  namespace FLAG__namespace_do_not_use_directly_use_DECLARE_string_instead {  \
  const char* FLAGS_##name = value;                                           \
  char FLAGS_no##name;                                                        \
  }                                                                           \
  using FLAG__namespace_do_not_use_directly_use_DECLARE_string_instead::FLAGS_##name

// These macros (could be functions, but I don't want to bother with a .cc
// file), make it easier to initialize flags from the environment.
// They are functions in Android because __system_property_get() doesn't
// return a string.

#if defined(ENABLE_PROFILING)

#if defined(__ANDROID__) || defined(ANDROID)

// Returns a pointer to a static variable.  The string pointed by the returned
// pointer must not be modified.
inline const char* const EnvToString(const char* envname, const char* dflt) {
  static char system_property_value[PROP_VALUE_MAX];
  if (__system_property_get(envname, system_property_value) > 0)
    return system_property_value;
  return dflt;
}

inline bool EnvToBool(const char* envname, bool dflt) {
  static const char kTrueValues[] = "tTyY1";
  char system_property_value[PROP_VALUE_MAX];
  if (__system_property_get(envname, system_property_value) > 0)
    return memchr(kTrueValues, system_property_value[0], sizeof(kTrueValues));
  return dflt;
}

inline int EnvToInt(const char* envname, int dflt) {
  char system_property_value[PROP_VALUE_MAX];
  if (__system_property_get(envname, system_property_value) > 0)
    return strtol(system_property_value, NULL, 10);
  return dflt;
}

inline int64 EnvToInt64(const char* envname, int64 dflt) {
  char system_property_value[PROP_VALUE_MAX];
  if (__system_property_get(envname, system_property_value) > 0)
    return strtoll(system_property_value, NULL, 10);
  return dflt;
}

inline double EnvToDouble(const char* envname, double dflt) {
  char system_property_value[PROP_VALUE_MAX];
  if (__system_property_get(envname, system_property_value) > 0)
    return strtod(system_property_value, NULL);
  return dflt;
}

#else  // defined(__ANDROID__) || defined(ANDROID)

#define EnvToString(envname, dflt)   \
  (!getenv(envname) ? (dflt) : getenv(envname))

#define EnvToBool(envname, dflt)   \
  (!getenv(envname) ? (dflt) : memchr("tTyY1\0", getenv(envname)[0], 6) != NULL)

#define EnvToInt(envname, dflt)  \
  (!getenv(envname) ? (dflt) : strtol(getenv(envname), NULL, 10))

#define EnvToInt64(envname, dflt)  \
  (!getenv(envname) ? (dflt) : strtoll(getenv(envname), NULL, 10))

#define EnvToDouble(envname, dflt)  \
  (!getenv(envname) ? (dflt) : strtod(getenv(envname), NULL))

#endif  // defined(__ANDROID__) || defined(ANDROID)

#else  // defined(ENABLE_PROFILING)

#define EnvToString(envname, dflt) (dflt)
#define EnvToBool(envname, dflt) (dflt)
#define EnvToInt(envname, dflt) (dflt)
#define EnvToInt64(envname, dflt) (dflt)
#define EnvToDouble(envname, dflt) (dflt)

#endif  // defined(ENABLE_PROFILING)

#endif  // BASE_COMMANDLINEFLAGS_H_
