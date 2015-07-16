// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/environment.h"

#include <vector>

#include "base/strings/string_piece.h"
#include "base/strings/string_util.h"
#include "base/strings/utf_string_conversions.h"

#if defined(OS_POSIX)
#include <stdlib.h>
#elif defined(OS_WIN)
#include <windows.h>
#endif

namespace base {

namespace {

class EnvironmentImpl : public Environment {
 public:
  bool GetVar(const char* variable_name, std::string* result) override {
    if (GetVarImpl(variable_name, result))
      return true;

    // Some commonly used variable names are uppercase while others
    // are lowercase, which is inconsistent. Let's try to be helpful
    // and look for a variable name with the reverse case.
    // I.e. HTTP_PROXY may be http_proxy for some users/systems.
    char first_char = variable_name[0];
    std::string alternate_case_var;
    if (first_char >= 'a' && first_char <= 'z')
      alternate_case_var = StringToUpperASCII(std::string(variable_name));
    else if (first_char >= 'A' && first_char <= 'Z')
      alternate_case_var = StringToLowerASCII(std::string(variable_name));
    else
      return false;
    return GetVarImpl(alternate_case_var.c_str(), result);
  }

  bool SetVar(const char* variable_name,
              const std::string& new_value) override {
    return SetVarImpl(variable_name, new_value);
  }

  bool UnSetVar(const char* variable_name) override {
    return UnSetVarImpl(variable_name);
  }

 private:
  bool GetVarImpl(const char* variable_name, std::string* result) {
#if defined(OS_POSIX)
    const char* env_value = getenv(variable_name);
    if (!env_value)
      return false;
    // Note that the variable may be defined but empty.
    if (result)
      *result = env_value;
    return true;
#elif defined(OS_WIN)
    DWORD value_length = ::GetEnvironmentVariable(
        UTF8ToWide(variable_name).c_str(), NULL, 0);
    if (value_length == 0)
      return false;
    if (result) {
      scoped_ptr<wchar_t[]> value(new wchar_t[value_length]);
      ::GetEnvironmentVariable(UTF8ToWide(variable_name).c_str(), value.get(),
                               value_length);
      *result = WideToUTF8(value.get());
    }
    return true;
#else
#error need to port
#endif
  }

  bool SetVarImpl(const char* variable_name, const std::string& new_value) {
#if defined(OS_POSIX)
    // On success, zero is returned.
    return !setenv(variable_name, new_value.c_str(), 1);
#elif defined(OS_WIN)
    // On success, a nonzero value is returned.
    return !!SetEnvironmentVariable(UTF8ToWide(variable_name).c_str(),
                                    UTF8ToWide(new_value).c_str());
#endif
  }

  bool UnSetVarImpl(const char* variable_name) {
#if defined(OS_POSIX)
    // On success, zero is returned.
    return !unsetenv(variable_name);
#elif defined(OS_WIN)
    // On success, a nonzero value is returned.
    return !!SetEnvironmentVariable(UTF8ToWide(variable_name).c_str(), NULL);
#endif
  }
};

// Parses a null-terminated input string of an environment block. The key is
// placed into the given string, and the total length of the line, including
// the terminating null, is returned.
size_t ParseEnvLine(const NativeEnvironmentString::value_type* input,
                    NativeEnvironmentString* key) {
  // Skip to the equals or end of the string, this is the key.
  size_t cur = 0;
  while (input[cur] && input[cur] != '=')
    cur++;
  *key = NativeEnvironmentString(&input[0], cur);

  // Now just skip to the end of the string.
  while (input[cur])
    cur++;
  return cur + 1;
}

}  // namespace

namespace env_vars {

#if defined(OS_POSIX)
// On Posix systems, this variable contains the location of the user's home
// directory. (e.g, /home/username/).
const char kHome[] = "HOME";
#endif

}  // namespace env_vars

Environment::~Environment() {}

// static
Environment* Environment::Create() {
  return new EnvironmentImpl();
}

bool Environment::HasVar(const char* variable_name) {
  return GetVar(variable_name, NULL);
}

#if defined(OS_WIN)

string16 AlterEnvironment(const wchar_t* env,
                          const EnvironmentMap& changes) {
  string16 result;

  // First copy all unmodified values to the output.
  size_t cur_env = 0;
  string16 key;
  while (env[cur_env]) {
    const wchar_t* line = &env[cur_env];
    size_t line_length = ParseEnvLine(line, &key);

    // Keep only values not specified in the change vector.
    EnvironmentMap::const_iterator found_change = changes.find(key);
    if (found_change == changes.end())
      result.append(line, line_length);

    cur_env += line_length;
  }

  // Now append all modified and new values.
  for (EnvironmentMap::const_iterator i = changes.begin();
       i != changes.end(); ++i) {
    if (!i->second.empty()) {
      result.append(i->first);
      result.push_back('=');
      result.append(i->second);
      result.push_back(0);
    }
  }

  // An additional null marks the end of the list. We always need a double-null
  // in case nothing was added above.
  if (result.empty())
    result.push_back(0);
  result.push_back(0);
  return result;
}

#elif defined(OS_POSIX)

scoped_ptr<char*[]> AlterEnvironment(const char* const* const env,
                                     const EnvironmentMap& changes) {
  std::string value_storage;  // Holds concatenated null-terminated strings.
  std::vector<size_t> result_indices;  // Line indices into value_storage.

  // First build up all of the unchanged environment strings. These are
  // null-terminated of the form "key=value".
  std::string key;
  for (size_t i = 0; env[i]; i++) {
    size_t line_length = ParseEnvLine(env[i], &key);

    // Keep only values not specified in the change vector.
    EnvironmentMap::const_iterator found_change = changes.find(key);
    if (found_change == changes.end()) {
      result_indices.push_back(value_storage.size());
      value_storage.append(env[i], line_length);
    }
  }

  // Now append all modified and new values.
  for (EnvironmentMap::const_iterator i = changes.begin();
       i != changes.end(); ++i) {
    if (!i->second.empty()) {
      result_indices.push_back(value_storage.size());
      value_storage.append(i->first);
      value_storage.push_back('=');
      value_storage.append(i->second);
      value_storage.push_back(0);
    }
  }

  size_t pointer_count_required =
      result_indices.size() + 1 +  // Null-terminated array of pointers.
      (value_storage.size() + sizeof(char*) - 1) / sizeof(char*);  // Buffer.
  scoped_ptr<char*[]> result(new char*[pointer_count_required]);

  // The string storage goes after the array of pointers.
  char* storage_data = reinterpret_cast<char*>(
      &result.get()[result_indices.size() + 1]);
  if (!value_storage.empty())
    memcpy(storage_data, value_storage.data(), value_storage.size());

  // Fill array of pointers at the beginning of the result.
  for (size_t i = 0; i < result_indices.size(); i++)
    result[i] = &storage_data[result_indices[i]];
  result[result_indices.size()] = 0;  // Null terminator.

  return result.Pass();
}

#endif  // OS_POSIX

}  // namespace base
