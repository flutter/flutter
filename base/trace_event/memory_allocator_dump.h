// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TRACE_EVENT_MEMORY_ALLOCATOR_DUMP_H_
#define BASE_TRACE_EVENT_MEMORY_ALLOCATOR_DUMP_H_

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/logging.h"
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

  // Standard attribute name to model allocated space.
  static const char kNameSize[];

  // Standard attribute name to model total space requested by the allocator
  // (e.g., amount of pages requested to the system).
  static const char kNameOuterSize[];

  // Standard attribute name to model space for allocated objects, without
  // taking into account allocator metadata or fragmentation.
  static const char kNameInnerSize[];

  // Standard attribute name to model the number of objects allocated.
  static const char kNameObjectsCount[];

  static const char kTypeScalar[];    // Type name for scalar attributes.
  static const char kTypeString[];    // Type name for string attributes.
  static const char kUnitsBytes[];    // Unit name to represent bytes.
  static const char kUnitsObjects[];  // Unit name to represent #objects.

  // Absolute name, unique within the scope of an entire ProcessMemoryDump.
  const std::string& absolute_name() const { return absolute_name_; }

  // Generic attribute setter / getter.
  void Add(const std::string& name,
           const char* type,
           const char* units,
           scoped_ptr<Value> value);
  bool Get(const std::string& name,
           const char** out_type,
           const char** out_units,
           const Value** out_value) const;

  // Helper setter for scalar attributes.
  void AddScalar(const std::string& name, const char* units, uint64 value);
  void AddScalarF(const std::string& name, const char* units, double value);
  void AddString(const std::string& name,
                 const char* units,
                 const std::string& value);

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

 private:
  const std::string absolute_name_;
  ProcessMemoryDump* const process_memory_dump_;  // Not owned (PMD owns this).
  DictionaryValue attributes_;
  MemoryAllocatorDumpGuid guid_;

  DISALLOW_COPY_AND_ASSIGN(MemoryAllocatorDump);
};

}  // namespace trace_event
}  // namespace base

#endif  // BASE_TRACE_EVENT_MEMORY_ALLOCATOR_DUMP_H_
