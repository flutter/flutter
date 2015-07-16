// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/process/process.h"

#include "base/mac/mac_util.h"
#include "base/mac/mach_logging.h"

#include <mach/mach.h>

// The following was added to <mach/task_policy.h> after 10.8.
// TODO(shrike): Remove the TASK_OVERRIDE_QOS_POLICY ifndef once builders
// reach 10.9 or higher.
#ifndef TASK_OVERRIDE_QOS_POLICY

#define TASK_OVERRIDE_QOS_POLICY 9

typedef struct task_category_policy task_category_policy_data_t;
typedef struct task_category_policy* task_category_policy_t;

enum task_latency_qos {
  LATENCY_QOS_TIER_UNSPECIFIED = 0x0,
  LATENCY_QOS_TIER_0 = ((0xFF << 16) | 1),
  LATENCY_QOS_TIER_1 = ((0xFF << 16) | 2),
  LATENCY_QOS_TIER_2 = ((0xFF << 16) | 3),
  LATENCY_QOS_TIER_3 = ((0xFF << 16) | 4),
  LATENCY_QOS_TIER_4 = ((0xFF << 16) | 5),
  LATENCY_QOS_TIER_5 = ((0xFF << 16) | 6)
};
typedef integer_t task_latency_qos_t;
enum task_throughput_qos {
  THROUGHPUT_QOS_TIER_UNSPECIFIED = 0x0,
  THROUGHPUT_QOS_TIER_0 = ((0xFE << 16) | 1),
  THROUGHPUT_QOS_TIER_1 = ((0xFE << 16) | 2),
  THROUGHPUT_QOS_TIER_2 = ((0xFE << 16) | 3),
  THROUGHPUT_QOS_TIER_3 = ((0xFE << 16) | 4),
  THROUGHPUT_QOS_TIER_4 = ((0xFE << 16) | 5),
  THROUGHPUT_QOS_TIER_5 = ((0xFE << 16) | 6),
};

#define LATENCY_QOS_LAUNCH_DEFAULT_TIER LATENCY_QOS_TIER_3
#define THROUGHPUT_QOS_LAUNCH_DEFAULT_TIER THROUGHPUT_QOS_TIER_3

typedef integer_t task_throughput_qos_t;

struct task_qos_policy {
  task_latency_qos_t task_latency_qos_tier;
  task_throughput_qos_t task_throughput_qos_tier;
};

typedef struct task_qos_policy* task_qos_policy_t;
#define TASK_QOS_POLICY_COUNT \
  ((mach_msg_type_number_t)(sizeof(struct task_qos_policy) / sizeof(integer_t)))

#endif  // TASK_OVERRIDE_QOS_POLICY

namespace base {

bool Process::CanBackgroundProcesses() {
  return true;
}

bool Process::IsProcessBackgrounded(mach_port_t task_port) const {
  // See SetProcessBackgrounded().
  DCHECK(IsValid());
  DCHECK_NE(task_port, TASK_NULL);

  task_category_policy_data_t category_policy;
  mach_msg_type_number_t task_info_count = TASK_CATEGORY_POLICY_COUNT;
  boolean_t get_default = FALSE;

  kern_return_t result =
      task_policy_get(task_port, TASK_CATEGORY_POLICY,
                      reinterpret_cast<task_policy_t>(&category_policy),
                      &task_info_count, &get_default);
  MACH_LOG_IF(ERROR, result != KERN_SUCCESS, result) <<
      "task_policy_get TASK_CATEGORY_POLICY";

  if (result == KERN_SUCCESS && get_default == FALSE) {
    return category_policy.role == TASK_BACKGROUND_APPLICATION;
  }
  return false;
}

bool Process::SetProcessBackgrounded(mach_port_t task_port, bool background) {
  DCHECK(IsValid());
  DCHECK_NE(task_port, TASK_NULL);

  if (!CanBackgroundProcesses()) {
    return false;
  } else if (IsProcessBackgrounded(task_port) == background) {
    return true;
  }

  task_category_policy category_policy;
  category_policy.role =
      background ? TASK_BACKGROUND_APPLICATION : TASK_FOREGROUND_APPLICATION;
  kern_return_t result =
      task_policy_set(task_port, TASK_CATEGORY_POLICY,
                      reinterpret_cast<task_policy_t>(&category_policy),
                      TASK_CATEGORY_POLICY_COUNT);

  if (result != KERN_SUCCESS) {
    MACH_LOG(ERROR, result) << "task_policy_set TASK_CATEGORY_POLICY";
    return false;
  } else if (!mac::IsOSMavericksOrLater()) {
    return true;
  }

  // Latency QoS regulates timer throttling/accuracy. Select default tier
  // on foreground because precise timer firing isn't needed.
  struct task_qos_policy qos_policy = {
      background ? LATENCY_QOS_TIER_5 : LATENCY_QOS_TIER_UNSPECIFIED,
      background ? THROUGHPUT_QOS_TIER_5 : THROUGHPUT_QOS_TIER_UNSPECIFIED
  };
  result = task_policy_set(task_port, TASK_OVERRIDE_QOS_POLICY,
                           reinterpret_cast<task_policy_t>(&qos_policy),
                           TASK_QOS_POLICY_COUNT);
  if (result != KERN_SUCCESS) {
    MACH_LOG(ERROR, result) << "task_policy_set TASK_OVERRIDE_QOS_POLICY";
    return false;
  }

  return true;
}

}  // namespace base
