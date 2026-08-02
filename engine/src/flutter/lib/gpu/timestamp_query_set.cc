// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/timestamp_query_set.h"

#include <utility>

#include "dart_api.h"
#include "fml/memory/ref_ptr.h"

namespace flutter {
namespace gpu {

IMPLEMENT_WRAPPERTYPEINFO(flutter_gpu, TimestampQuerySet);

TimestampQuerySet::TimestampQuerySet(
    std::shared_ptr<impeller::TimestampQueryPool> pool)
    : pool_(std::move(pool)) {}

TimestampQuerySet::~TimestampQuerySet() = default;

const std::shared_ptr<impeller::TimestampQueryPool>&
TimestampQuerySet::GetPool() const {
  return pool_;
}

}  // namespace gpu
}  // namespace flutter

//----------------------------------------------------------------------------
/// Exports
///

bool InternalFlutterGpu_TimestampQuerySet_Initialize(
    Dart_Handle wrapper,
    flutter::gpu::Context* context,
    int query_count) {
  if (query_count <= 0) {
    return false;
  }
  std::shared_ptr<impeller::TimestampQueryPool> pool =
      context->GetContext().CreateTimestampQueryPool(query_count);
  if (!pool) {
    return false;
  }
  auto res =
      fml::MakeRefCounted<flutter::gpu::TimestampQuerySet>(std::move(pool));
  res->AssociateWithDartWrapper(wrapper);
  return true;
}

bool InternalFlutterGpu_TimestampQuerySet_Resolve(
    flutter::gpu::TimestampQuerySet* wrapper,
    Dart_Handle timestamps) {
  const impeller::TimestampQueryResults results = wrapper->GetPool()->Resolve();

  Dart_TypedData_Type type = Dart_TypedData_kInvalid;
  void* data = nullptr;
  intptr_t length = 0;
  if (Dart_IsError(
          Dart_TypedDataAcquireData(timestamps, &type, &data, &length))) {
    return results.disjoint;
  }
  if (type == Dart_TypedData_kInt64 && data != nullptr) {
    int64_t* out = static_cast<int64_t*>(data);
    for (intptr_t i = 0; i < length; i++) {
      out[i] = (static_cast<size_t>(i) < results.timestamps.size() &&
                results.timestamps[i].has_value())
                   ? static_cast<int64_t>(results.timestamps[i].value())
                   : -1;
    }
  }
  Dart_TypedDataReleaseData(timestamps);

  return results.disjoint;
}
