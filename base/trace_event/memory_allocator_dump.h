// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TRACE_EVENT_MEMORY_ALLOCATOR_DUMP_H_
#define BASE_TRACE_EVENT_MEMORY_ALLOCATOR_DUMP_H_

#include <string>

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/logging.h"
#include "base/memory/ref_counted.h"
#include "base/trace_event/memory_allocator_dump_guid.h"
#include "base/values.h"

namespace base {
namespace trace_event {

class MemoryDumpManager;
class ProcessMemoryDump;
class TracedValue;

// Data model for user-land memory allocator dumps.
class BASE_EXPORT MemoryAllocatorDump {
 public:
  // MemoryAllocatorDump is owned by ProcessMemoryDump.
  MemoryAllocatorDump(const std::string& absolute_name,
                      ProcessMemoryDump* process_memory_dump,
                      const MemoryAllocatorDumpGuid& guid);
  MemoryAllocatorDump(const std::string& absolute_name,
                      ProcessMemoryDump* process_memory_dump);
  ~MemoryAllocatorDump();

  // Standard attribute |name|s for the AddScalar and AddString() methods.
  static const char kNameSize[];          // To represent allocated space.
  static const char kNameObjectsCount[];  // To represent number of objects.

  // Standard attribute |unit|s for the AddScalar and AddString() methods.
  static const char kUnitsBytes[];    // Unit name to represent bytes.
  static const char kUnitsObjects[];  // Unit name to represent #objects.

  // Constants used only internally and by tests.
  static const char kTypeScalar[];  // Type name for scalar attributes.
  static const char kTypeString[];  // Type name for string attributes.

  // Setters for scalar attributes. Some examples:
  // - "size" column (all dumps are expected to have at least this one):
  //     AddScalar(kNameSize, kUnitsBytes, 1234);
  // - Some extra-column reporting internal details of the subsystem:
  //    AddScalar("number_of_freelist_entires", kUnitsObjects, 42)
  // - Other informational column (will not be auto-added in the UI)
  //    AddScalarF("kittens_ratio", "ratio", 42.0f)
  void AddScalar(const char* name, const char* units, uint64 value);
  void AddScalarF(const char* name, const char* units, double value);
  void AddString(const char* name, const char* units, const std::string& value);

  // Absolute name, unique within the scope of an entire ProcessMemoryDump.
  const std::string& absolute_name() const { return absolute_name_; }

  // Called at trace generation time to populate the TracedValue.
  void AsValueInto(TracedValue* value) const;

  // Get the ProcessMemoryDump instance that owns this.
  ProcessMemoryDump* process_memory_dump() const {
    return process_memory_dump_;
  }

  // |guid| is an optional global dump identifier, unique across all processes
  // within the scope of a global dump. It is only required when using the
  // graph APIs (see TODO_method_name) to express retention / suballocation or
  // cross process sharing. See crbug.com/492102 for design docs.
  // Subsequent MemoryAllocatorDump(s) with the same |absolute_name| are
  // expected to have the same guid.
  const MemoryAllocatorDumpGuid& guid() const { return guid_; }

  TracedValue* attributes_for_testing() const { return attributes_.get(); }

 private:
  const std::string absolute_name_;
  ProcessMemoryDump* const process_memory_dump_;  // Not owned (PMD owns this).
  scoped_refptr<TracedValue> attributes_;
  MemoryAllocatorDumpGuid guid_;

  // A local buffer for Sprintf conversion on fastpath. Avoids allocating
  // temporary strings on each AddScalar() call.
  std::string string_conversion_buffer_;

  DISALLOW_COPY_AND_ASSIGN(MemoryAllocatorDump);
};

}  // namespace trace_event
}  // namespace base

#endif  // BASE_TRACE_EVENT_MEMORY_ALLOCATOR_DUMP_H_
