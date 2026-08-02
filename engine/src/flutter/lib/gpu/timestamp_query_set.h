// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_GPU_TIMESTAMP_QUERY_SET_H_
#define FLUTTER_LIB_GPU_TIMESTAMP_QUERY_SET_H_

#include <memory>

#include "flutter/lib/gpu/context.h"
#include "flutter/lib/gpu/export.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "impeller/renderer/timestamp_query_pool.h"

namespace flutter {
namespace gpu {

class TimestampQuerySet : public RefCountedDartWrappable<TimestampQuerySet> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(TimestampQuerySet);

 public:
  explicit TimestampQuerySet(
      std::shared_ptr<impeller::TimestampQueryPool> pool);

  ~TimestampQuerySet() override;

  const std::shared_ptr<impeller::TimestampQueryPool>& GetPool() const;

 private:
  std::shared_ptr<impeller::TimestampQueryPool> pool_;

  FML_DISALLOW_COPY_AND_ASSIGN(TimestampQuerySet);
};

}  // namespace gpu
}  // namespace flutter

//----------------------------------------------------------------------------
/// Exports
///

extern "C" {

FLUTTER_GPU_EXPORT
extern bool InternalFlutterGpu_TimestampQuerySet_Initialize(
    Dart_Handle wrapper,
    flutter::gpu::Context* context,
    int query_count);

/// Fills [timestamps], an `Int64List` sized to the query count, with
/// nanosecond timestamps. Slots the GPU has not written are set to -1.
/// Returns whether the GPU reported a timing disjoint.
FLUTTER_GPU_EXPORT
extern bool InternalFlutterGpu_TimestampQuerySet_Resolve(
    flutter::gpu::TimestampQuerySet* wrapper,
    Dart_Handle timestamps);

}  // extern "C"

#endif  // FLUTTER_LIB_GPU_TIMESTAMP_QUERY_SET_H_
