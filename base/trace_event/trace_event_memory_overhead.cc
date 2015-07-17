// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/trace_event_memory_overhead.h"

#include <algorithm>

#include "base/memory/ref_counted_memory.h"
#include "base/strings/stringprintf.h"
#include "base/trace_event/memory_allocator_dump.h"
#include "base/trace_event/process_memory_dump.h"
#include "base/values.h"

namespace {
size_t RoundUp(size_t size, size_t alignment) {
  return (size + alignment - 1) & ~(alignment - 1);
}
}  // namespace

namespace base {
namespace trace_event {

TraceEventMemoryOverhead::TraceEventMemoryOverhead() {
}

TraceEventMemoryOverhead::~TraceEventMemoryOverhead() {
}

void TraceEventMemoryOverhead::AddOrCreateInternal(
    const char* object_type,
    size_t count,
    size_t allocated_size_in_bytes,
    size_t resident_size_in_bytes) {
  auto it = allocated_objects_.find(object_type);
  if (it == allocated_objects_.end()) {
    allocated_objects_.insert(std::make_pair(
        object_type,
        ObjectCountAndSize(
            {count, allocated_size_in_bytes, resident_size_in_bytes})));
    return;
  }
  it->second.count += count;
  it->second.allocated_size_in_bytes += allocated_size_in_bytes;
  it->second.resident_size_in_bytes += resident_size_in_bytes;
}

void TraceEventMemoryOverhead::Add(const char* object_type,
                                   size_t allocated_size_in_bytes) {
  Add(object_type, allocated_size_in_bytes, allocated_size_in_bytes);
}

void TraceEventMemoryOverhead::Add(const char* object_type,
                                   size_t allocated_size_in_bytes,
                                   size_t resident_size_in_bytes) {
  AddOrCreateInternal(object_type, 1, allocated_size_in_bytes,
                      resident_size_in_bytes);
}

void TraceEventMemoryOverhead::AddString(const std::string& str) {
  // The number below are empirical and mainly based on profiling of real-world
  // std::string implementations:
  //  - even short string end up malloc()-inc at least 32 bytes.
  //  - longer stings seem to malloc() multiples of 16 bytes.
  Add("std::string",
      sizeof(std::string) + std::max<size_t>(RoundUp(str.capacity(), 16), 32u));
}

void TraceEventMemoryOverhead::AddRefCountedString(
    const RefCountedString& str) {
  Add("RefCountedString", sizeof(RefCountedString));
  AddString(str.data());
}

void TraceEventMemoryOverhead::AddValue(const Value& value) {
  switch (value.GetType()) {
    case Value::TYPE_NULL:
    case Value::TYPE_BOOLEAN:
    case Value::TYPE_INTEGER:
    case Value::TYPE_DOUBLE:
      Add("FundamentalValue", sizeof(Value));
      break;

    case Value::TYPE_STRING: {
      const StringValue* string_value = nullptr;
      value.GetAsString(&string_value);
      Add("StringValue", sizeof(StringValue));
      AddString(string_value->GetString());
    } break;

    case Value::TYPE_BINARY: {
      const BinaryValue* binary_value = nullptr;
      value.GetAsBinary(&binary_value);
      Add("BinaryValue", sizeof(BinaryValue) + binary_value->GetSize());
    } break;

    case Value::TYPE_DICTIONARY: {
      const DictionaryValue* dictionary_value = nullptr;
      value.GetAsDictionary(&dictionary_value);
      Add("DictionaryValue", sizeof(DictionaryValue));
      for (DictionaryValue::Iterator it(*dictionary_value); !it.IsAtEnd();
           it.Advance()) {
        AddString(it.key());
        AddValue(it.value());
      }
    } break;

    case Value::TYPE_LIST: {
      const ListValue* list_value = nullptr;
      value.GetAsList(&list_value);
      Add("ListValue", sizeof(ListValue));
      for (const Value* v : *list_value)
        AddValue(*v);
    } break;

    default:
      NOTREACHED();
  }
}

void TraceEventMemoryOverhead::AddSelf() {
  size_t estimated_size = sizeof(*this);
  // If the SmallMap did overflow its static capacity, its elements will be
  // allocated on the heap and have to be accounted separately.
  if (allocated_objects_.UsingFullMap())
    estimated_size += sizeof(map_type::value_type) * allocated_objects_.size();
  Add("TraceEventMemoryOverhead", estimated_size);
}

void TraceEventMemoryOverhead::Update(const TraceEventMemoryOverhead& other) {
  for (const auto& it : other.allocated_objects_) {
    AddOrCreateInternal(it.first, it.second.count,
                        it.second.allocated_size_in_bytes,
                        it.second.resident_size_in_bytes);
  }
}

void TraceEventMemoryOverhead::DumpInto(const char* base_name,
                                        ProcessMemoryDump* pmd) const {
  for (const auto& it : allocated_objects_) {
    std::string dump_name = StringPrintf("%s/%s", base_name, it.first);
    MemoryAllocatorDump* mad = pmd->CreateAllocatorDump(dump_name);
    mad->AddScalar(MemoryAllocatorDump::kNameSize,
                   MemoryAllocatorDump::kUnitsBytes,
                   it.second.allocated_size_in_bytes);
    mad->AddScalar("resident_size", MemoryAllocatorDump::kUnitsBytes,
                   it.second.resident_size_in_bytes);
    mad->AddScalar(MemoryAllocatorDump::kNameObjectsCount,
                   MemoryAllocatorDump::kUnitsObjects, it.second.count);
  }
}

}  // namespace trace_event
}  // namespace base
