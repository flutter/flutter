// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/memory_allocator_dump_guid.h"

#include "base/format_macros.h"
#include "base/sha1.h"
#include "base/strings/stringprintf.h"

namespace base {
namespace trace_event {

namespace {
uint64 HashString(const std::string& str) {
  uint64 hash[(kSHA1Length + sizeof(uint64) - 1) / sizeof(uint64)] = { 0 };
  SHA1HashBytes(reinterpret_cast<const unsigned char*>(str.data()), str.size(),
                reinterpret_cast<unsigned char*>(hash));
  return hash[0];
}
}  // namespace

MemoryAllocatorDumpGuid::MemoryAllocatorDumpGuid(uint64 guid) : guid_(guid) {
}

MemoryAllocatorDumpGuid::MemoryAllocatorDumpGuid()
    : MemoryAllocatorDumpGuid(0u) {
}

MemoryAllocatorDumpGuid::MemoryAllocatorDumpGuid(const std::string& guid_str)
    : MemoryAllocatorDumpGuid(HashString(guid_str)) {
}

std::string MemoryAllocatorDumpGuid::ToString() const {
  return StringPrintf("%" PRIx64, guid_);
}

}  // namespace trace_event
}  // namespace base
