// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/config/gpu_util.h"

#include <vector>

#include "base/command_line.h"
#include "base/logging.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_split.h"
#include "gpu/config/gpu_control_list_jsons.h"
#include "gpu/config/gpu_driver_bug_list.h"
#include "gpu/config/gpu_info_collector.h"
#include "gpu/config/gpu_switches.h"
#include "ui/gl/gl_switches.h"

namespace gpu {

namespace {

// Combine the integers into a string, seperated by ','.
std::string IntSetToString(const std::set<int>& list) {
  std::string rt;
  for (std::set<int>::const_iterator it = list.begin();
       it != list.end(); ++it) {
    if (!rt.empty())
      rt += ",";
    rt += base::IntToString(*it);
  }
  return rt;
}

void StringToIntSet(const std::string& str, std::set<int>* list) {
  DCHECK(list);
  std::vector<std::string> pieces;
  base::SplitString(str, ',', &pieces);
  for (size_t i = 0; i < pieces.size(); ++i) {
    int number = 0;
    bool succeed = base::StringToInt(pieces[i], &number);
    DCHECK(succeed);
    list->insert(number);
  }
}

}  // namespace anonymous

void MergeFeatureSets(std::set<int>* dst, const std::set<int>& src) {
  DCHECK(dst);
  if (src.empty())
    return;
  dst->insert(src.begin(), src.end());
}

void ApplyGpuDriverBugWorkarounds(base::CommandLine* command_line) {
  GPUInfo gpu_info;
  CollectBasicGraphicsInfo(&gpu_info);

  ApplyGpuDriverBugWorkarounds(gpu_info, command_line);
}

void ApplyGpuDriverBugWorkarounds(const GPUInfo& gpu_info,
                                  base::CommandLine* command_line) {
  scoped_ptr<GpuDriverBugList> list(GpuDriverBugList::Create());
  list->LoadList(kGpuDriverBugListJson,
                 GpuControlList::kCurrentOsOnly);
  std::set<int> workarounds = list->MakeDecision(
      GpuControlList::kOsAny, std::string(), gpu_info);
  GpuDriverBugList::AppendWorkaroundsFromCommandLine(
      &workarounds, *command_line);
  if (!workarounds.empty()) {
    command_line->AppendSwitchASCII(switches::kGpuDriverBugWorkarounds,
                                    IntSetToString(workarounds));
  }
}

void StringToFeatureSet(
    const std::string& str, std::set<int>* feature_set) {
  StringToIntSet(str, feature_set);
}

}  // namespace gpu
