// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/process_memory_maps.h"

#include "base/format_macros.h"
#include "base/strings/stringprintf.h"
#include "base/trace_event/trace_event_argument.h"

namespace base {
namespace trace_event {

// static
const uint32 ProcessMemoryMaps::VMRegion::kProtectionFlagsRead = 4;
const uint32 ProcessMemoryMaps::VMRegion::kProtectionFlagsWrite = 2;
const uint32 ProcessMemoryMaps::VMRegion::kProtectionFlagsExec = 1;

ProcessMemoryMaps::VMRegion::VMRegion()
    : start_address(0),
      size_in_bytes(0),
      protection_flags(0),
      byte_stats_private_dirty_resident(0),
      byte_stats_private_clean_resident(0),
      byte_stats_shared_dirty_resident(0),
      byte_stats_shared_clean_resident(0),
      byte_stats_swapped(0),
      byte_stats_proportional_resident(0) {
}

ProcessMemoryMaps::ProcessMemoryMaps() {
}

ProcessMemoryMaps::~ProcessMemoryMaps() {
}

void ProcessMemoryMaps::AsValueInto(TracedValue* value) const {
  static const char kHexFmt[] = "%" PRIx64;

  // Refer to the design doc goo.gl/sxfFY8 for the semantic of these fields.
  value->BeginArray("vm_regions");
  for (const auto& region : vm_regions_) {
    value->BeginDictionary();

    value->SetString("sa", StringPrintf(kHexFmt, region.start_address));
    value->SetString("sz", StringPrintf(kHexFmt, region.size_in_bytes));
    value->SetInteger("pf", region.protection_flags);
    value->SetString("mf", region.mapped_file);

    value->BeginDictionary("bs");  // byte stats
    value->SetString(
        "pss", StringPrintf(kHexFmt, region.byte_stats_proportional_resident));
    value->SetString(
        "pd", StringPrintf(kHexFmt, region.byte_stats_private_dirty_resident));
    value->SetString(
        "pc", StringPrintf(kHexFmt, region.byte_stats_private_clean_resident));
    value->SetString(
        "sd", StringPrintf(kHexFmt, region.byte_stats_shared_dirty_resident));
    value->SetString(
        "sc", StringPrintf(kHexFmt, region.byte_stats_shared_clean_resident));
    value->SetString("sw", StringPrintf(kHexFmt, region.byte_stats_swapped));
    value->EndDictionary();

    value->EndDictionary();
  }
  value->EndArray();
}

void ProcessMemoryMaps::Clear() {
  vm_regions_.clear();
}

}  // namespace trace_event
}  // namespace base
