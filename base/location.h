// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_LOCATION_H_
#define BASE_LOCATION_H_

#include <cassert>
#include <string>

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/containers/hash_tables.h"

namespace tracked_objects {

// Location provides basic info where of an object was constructed, or was
// significantly brought to life.
class BASE_EXPORT Location {
 public:
  // Constructor should be called with a long-lived char*, such as __FILE__.
  // It assumes the provided value will persist as a global constant, and it
  // will not make a copy of it.
  Location(const char* function_name,
           const char* file_name,
           int line_number,
           const void* program_counter);

  // Provide a default constructor for easy of debugging.
  Location();

  // Copy constructor.
  Location(const Location& other);

  // Comparator for hash map insertion.
  // No need to use |function_name_| since the other two fields uniquely
  // identify this location.
  bool operator==(const Location& other) const {
    return line_number_ == other.line_number_ &&
           file_name_ == other.file_name_;
  }

  const char* function_name()   const { return function_name_; }
  const char* file_name()       const { return file_name_; }
  int line_number()             const { return line_number_; }
  const void* program_counter() const { return program_counter_; }

  std::string ToString() const;

  // Hash operator for hash maps.
  struct Hash {
    size_t operator()(const Location& location) const {
      // Compute the hash value using file name pointer and line number.
      // No need to use |function_name_| since the other two fields uniquely
      // identify this location.

      // The file name will always be uniquely identified by its pointer since
      // it comes from __FILE__, so no need to check the contents of the string.
      // See the definition of FROM_HERE in location.h, and how it is used
      // elsewhere.

      // Due to inconsistent definitions of uint64_t and uintptr_t, casting the
      // file name pointer to a uintptr_t causes a compiler error for some
      // platforms. The solution is to explicitly cast it to a uint64_t.
      return base::HashPair(reinterpret_cast<uint64_t>(location.file_name()),
                            location.line_number());
    }
  };

  // Translate the some of the state in this instance into a human readable
  // string with HTML characters in the function names escaped, and append that
  // string to |output|.  Inclusion of the file_name_ and function_name_ are
  // optional, and controlled by the boolean arguments.
  void Write(bool display_filename, bool display_function_name,
             std::string* output) const;

  // Write function_name_ in HTML with '<' and '>' properly encoded.
  void WriteFunctionName(std::string* output) const;

 private:
  const char* function_name_;
  const char* file_name_;
  int line_number_;
  const void* program_counter_;
};

// A "snapshotted" representation of the Location class that can safely be
// passed across process boundaries.
struct BASE_EXPORT LocationSnapshot {
  // The default constructor is exposed to support the IPC serialization macros.
  LocationSnapshot();
  explicit LocationSnapshot(const tracked_objects::Location& location);
  ~LocationSnapshot();

  std::string file_name;
  std::string function_name;
  int line_number;
};

BASE_EXPORT const void* GetProgramCounter();

// Define a macro to record the current source location.
#define FROM_HERE FROM_HERE_WITH_EXPLICIT_FUNCTION(__FUNCTION__)

#define FROM_HERE_WITH_EXPLICIT_FUNCTION(function_name)                        \
    ::tracked_objects::Location(function_name,                                 \
                                __FILE__,                                      \
                                __LINE__,                                      \
                                ::tracked_objects::GetProgramCounter())

}  // namespace tracked_objects

#endif  // BASE_LOCATION_H_
