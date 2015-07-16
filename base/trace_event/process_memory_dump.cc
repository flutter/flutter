// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/process_memory_dump.h"

#include "base/trace_event/process_memory_totals.h"
#include "base/trace_event/trace_event_argument.h"

namespace base {
namespace trace_event {

namespace {
const char kEdgeTypeOwnership[] = "ownership";

std::string GetSharedGlobalAllocatorDumpName(
    const MemoryAllocatorDumpGuid& guid) {
  return "global/" + guid.ToString();
}
}  // namespace

ProcessMemoryDump::ProcessMemoryDump(
    const scoped_refptr<MemoryDumpSessionState>& session_state)
    : has_process_totals_(false),
      has_process_mmaps_(false),
      session_state_(session_state) {
}

ProcessMemoryDump::~ProcessMemoryDump() {
}

MemoryAllocatorDump* ProcessMemoryDump::CreateAllocatorDump(
    const std::string& absolute_name) {
  MemoryAllocatorDump* mad = new MemoryAllocatorDump(absolute_name, this);
  AddAllocatorDumpInternal(mad);  // Takes ownership of |mad|.
  return mad;
}

MemoryAllocatorDump* ProcessMemoryDump::CreateAllocatorDump(
    const std::string& absolute_name,
    const MemoryAllocatorDumpGuid& guid) {
  MemoryAllocatorDump* mad = new MemoryAllocatorDump(absolute_name, this, guid);
  AddAllocatorDumpInternal(mad);  // Takes ownership of |mad|.
  return mad;
}

void ProcessMemoryDump::AddAllocatorDumpInternal(MemoryAllocatorDump* mad) {
  DCHECK_EQ(0ul, allocator_dumps_.count(mad->absolute_name()));
  allocator_dumps_storage_.push_back(mad);
  allocator_dumps_[mad->absolute_name()] = mad;
}

MemoryAllocatorDump* ProcessMemoryDump::GetAllocatorDump(
    const std::string& absolute_name) const {
  auto it = allocator_dumps_.find(absolute_name);
  return it == allocator_dumps_.end() ? nullptr : it->second;
}

MemoryAllocatorDump* ProcessMemoryDump::CreateSharedGlobalAllocatorDump(
    const MemoryAllocatorDumpGuid& guid) {
  return CreateAllocatorDump(GetSharedGlobalAllocatorDumpName(guid), guid);
}

MemoryAllocatorDump* ProcessMemoryDump::GetSharedGlobalAllocatorDump(
    const MemoryAllocatorDumpGuid& guid) const {
  return GetAllocatorDump(GetSharedGlobalAllocatorDumpName(guid));
}

void ProcessMemoryDump::Clear() {
  if (has_process_totals_) {
    process_totals_.Clear();
    has_process_totals_ = false;
  }

  if (has_process_mmaps_) {
    process_mmaps_.Clear();
    has_process_mmaps_ = false;
  }

  allocator_dumps_storage_.clear();
  allocator_dumps_.clear();
  allocator_dumps_edges_.clear();
}

void ProcessMemoryDump::TakeAllDumpsFrom(ProcessMemoryDump* other) {
  DCHECK(!other->has_process_totals() && !other->has_process_mmaps());

  // Moves the ownership of all MemoryAllocatorDump(s) contained in |other|
  // into this ProcessMemoryDump.
  for (MemoryAllocatorDump* mad : other->allocator_dumps_storage_) {
    // Check that we don't merge duplicates.
    DCHECK_EQ(0ul, allocator_dumps_.count(mad->absolute_name()));
    allocator_dumps_storage_.push_back(mad);
    allocator_dumps_[mad->absolute_name()] = mad;
  }
  other->allocator_dumps_storage_.weak_clear();
  other->allocator_dumps_.clear();

  // Move all the edges.
  allocator_dumps_edges_.insert(allocator_dumps_edges_.end(),
                                other->allocator_dumps_edges_.begin(),
                                other->allocator_dumps_edges_.end());
  other->allocator_dumps_edges_.clear();
}

void ProcessMemoryDump::AsValueInto(TracedValue* value) const {
  if (has_process_totals_) {
    value->BeginDictionary("process_totals");
    process_totals_.AsValueInto(value);
    value->EndDictionary();
  }

  if (has_process_mmaps_) {
    value->BeginDictionary("process_mmaps");
    process_mmaps_.AsValueInto(value);
    value->EndDictionary();
  }

  if (allocator_dumps_storage_.size() > 0) {
    value->BeginDictionary("allocators");
    for (const MemoryAllocatorDump* allocator_dump : allocator_dumps_storage_)
      allocator_dump->AsValueInto(value);
    value->EndDictionary();
  }

  value->BeginArray("allocators_graph");
  for (const MemoryAllocatorDumpEdge& edge : allocator_dumps_edges_) {
    value->BeginDictionary();
    value->SetString("source", edge.source.ToString());
    value->SetString("target", edge.target.ToString());
    value->SetInteger("importance", edge.importance);
    value->SetString("type", edge.type);
    value->EndDictionary();
  }
  value->EndArray();
}

void ProcessMemoryDump::AddOwnershipEdge(const MemoryAllocatorDumpGuid& source,
                                         const MemoryAllocatorDumpGuid& target,
                                         int importance) {
  allocator_dumps_edges_.push_back(
      {source, target, importance, kEdgeTypeOwnership});
}

void ProcessMemoryDump::AddOwnershipEdge(
    const MemoryAllocatorDumpGuid& source,
    const MemoryAllocatorDumpGuid& target) {
  AddOwnershipEdge(source, target, 0 /* importance */);
}

void ProcessMemoryDump::AddSuballocation(const MemoryAllocatorDumpGuid& source,
                                         const std::string& target_node_name) {
  std::string child_mad_name = target_node_name + "/__" + source.ToString();
  MemoryAllocatorDump* target_child_mad = CreateAllocatorDump(child_mad_name);
  AddOwnershipEdge(source, target_child_mad->guid());
}

}  // namespace trace_event
}  // namespace base
