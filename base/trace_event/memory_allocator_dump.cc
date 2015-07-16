// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/memory_allocator_dump.h"

#include "base/format_macros.h"
#include "base/strings/stringprintf.h"
#include "base/trace_event/memory_dump_manager.h"
#include "base/trace_event/memory_dump_provider.h"
#include "base/trace_event/process_memory_dump.h"
#include "base/trace_event/trace_event_argument.h"
#include "base/values.h"

namespace base {
namespace trace_event {

namespace {
// Returns the c-string pointer from a dictionary value without performing extra
// std::string copies. The ptr will be valid as long as the value exists.
bool GetDictionaryValueAsCStr(const DictionaryValue* dict_value,
                              const std::string& key,
                              const char** out_cstr) {
  const Value* value = nullptr;
  const StringValue* str_value = nullptr;
  if (!dict_value->GetWithoutPathExpansion(key, &value))
    return false;
  if (!value->GetAsString(&str_value))
    return false;
  *out_cstr = str_value->GetString().c_str();
  return true;
}
}  // namespace

// TODO(primiano): remove kName{Inner,Outer}Size below after all the existing
// dump providers have been rewritten.
const char MemoryAllocatorDump::kNameSize[] = "size";
const char MemoryAllocatorDump::kNameInnerSize[] = "inner_size";
const char MemoryAllocatorDump::kNameOuterSize[] = "outer_size";
const char MemoryAllocatorDump::kNameObjectsCount[] = "objects_count";
const char MemoryAllocatorDump::kTypeScalar[] = "scalar";
const char MemoryAllocatorDump::kTypeString[] = "string";
const char MemoryAllocatorDump::kUnitsBytes[] = "bytes";
const char MemoryAllocatorDump::kUnitsObjects[] = "objects";

MemoryAllocatorDump::MemoryAllocatorDump(const std::string& absolute_name,
                                         ProcessMemoryDump* process_memory_dump,
                                         const MemoryAllocatorDumpGuid& guid)
    : absolute_name_(absolute_name),
      process_memory_dump_(process_memory_dump),
      guid_(guid) {
  // The |absolute_name| cannot be empty.
  DCHECK(!absolute_name.empty());

  // The |absolute_name| can contain slash separator, but not leading or
  // trailing ones.
  DCHECK(absolute_name[0] != '/' && *absolute_name.rbegin() != '/');

  // Dots are not allowed anywhere as the underlying base::DictionaryValue
  // would treat them magically and split in sub-nodes, which is not intended.
  DCHECK_EQ(std::string::npos, absolute_name.find_first_of('.'));
}

// If the caller didn't provide a guid, make one up by hashing the
// absolute_name with the current PID.
// Rationale: |absolute_name| is already supposed to be unique within a
// process, the pid will make it unique among all processes.
MemoryAllocatorDump::MemoryAllocatorDump(const std::string& absolute_name,
                                         ProcessMemoryDump* process_memory_dump)
    : MemoryAllocatorDump(absolute_name,
                          process_memory_dump,
                          MemoryAllocatorDumpGuid(StringPrintf(
                              "%d:%s",
                              TraceLog::GetInstance()->process_id(),
                              absolute_name.c_str()))) {
}

MemoryAllocatorDump::~MemoryAllocatorDump() {
}

void MemoryAllocatorDump::Add(const std::string& name,
                              const char* type,
                              const char* units,
                              scoped_ptr<Value> value) {
  scoped_ptr<DictionaryValue> attribute(new DictionaryValue());
  DCHECK(!attributes_.HasKey(name));
  attribute->SetStringWithoutPathExpansion("type", type);
  attribute->SetStringWithoutPathExpansion("units", units);
  attribute->SetWithoutPathExpansion("value", value.Pass());
  attributes_.SetWithoutPathExpansion(name, attribute.Pass());
}

bool MemoryAllocatorDump::Get(const std::string& name,
                              const char** out_type,
                              const char** out_units,
                              const Value** out_value) const {
  const DictionaryValue* attribute = nullptr;
  if (!attributes_.GetDictionaryWithoutPathExpansion(name, &attribute))
    return false;

  if (!GetDictionaryValueAsCStr(attribute, "type", out_type))
    return false;

  if (!GetDictionaryValueAsCStr(attribute, "units", out_units))
    return false;

  if (!attribute->GetWithoutPathExpansion("value", out_value))
    return false;

  return true;
}

void MemoryAllocatorDump::AddScalar(const std::string& name,
                                    const char* units,
                                    uint64 value) {
  scoped_ptr<Value> hex_value(new StringValue(StringPrintf("%" PRIx64, value)));
  Add(name, kTypeScalar, units, hex_value.Pass());
}

void MemoryAllocatorDump::AddScalarF(const std::string& name,
                                     const char* units,
                                     double value) {
  Add(name, kTypeScalar, units, make_scoped_ptr(new FundamentalValue(value)));
}

void MemoryAllocatorDump::AddString(const std::string& name,
                                    const char* units,
                                    const std::string& value) {
  scoped_ptr<Value> str_value(new StringValue(value));
  Add(name, kTypeString, units, str_value.Pass());
}

void MemoryAllocatorDump::AsValueInto(TracedValue* value) const {
  value->BeginDictionary(absolute_name_.c_str());
  value->SetString("guid", guid_.ToString());

  value->BeginDictionary("attrs");

  for (DictionaryValue::Iterator it(attributes_); !it.IsAtEnd(); it.Advance())
    value->SetValue(it.key().c_str(), it.value().CreateDeepCopy());

  value->EndDictionary();  // "attrs": { ... }
  value->EndDictionary();  // "allocator_name/heap_subheap": { ... }
}

}  // namespace trace_event
}  // namespace base
