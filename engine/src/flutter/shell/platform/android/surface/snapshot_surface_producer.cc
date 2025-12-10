// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/surface/snapshot_surface_producer.h"

namespace flutter {

AndroidSnapshotSurfaceProducer::AndroidSnapshotSurfaceProducer(
    const GetAndroidSurfaceCallback& get_android_surface_callback)
    : get_android_surface_callback_(get_android_surface_callback) {}

std::unique_ptr<Surface>
AndroidSnapshotSurfaceProducer::CreateSnapshotSurface() {
  if (get_android_surface_callback_) {
return get_android_surface_callback_().CreateSnapshotSurface();
  }
  return nullptr;
}

}  // namespace flutter
