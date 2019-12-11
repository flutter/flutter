// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "surface.h"

#include <fcntl.h>
#include <lib/fdio/watcher.h>
#include <unistd.h>

#include "flutter/fml/unique_fd.h"

namespace flutter_runner {

Surface::Surface(std::string debug_label)
    : debug_label_(std::move(debug_label)) {}

Surface::~Surface() = default;

// |flutter::Surface|
bool Surface::IsValid() {
  return valid_;
}

// |flutter::Surface|
std::unique_ptr<flutter::SurfaceFrame> Surface::AcquireFrame(
    const SkISize& size) {
  return std::make_unique<flutter::SurfaceFrame>(
      nullptr, true,
      [](const flutter::SurfaceFrame& surface_frame, SkCanvas* canvas) {
        return true;
      });
}

// |flutter::Surface|
GrContext* Surface::GetContext() {
  return nullptr;
}

static zx_status_t DriverWatcher(int dirfd,
                                 int event,
                                 const char* fn,
                                 void* cookie) {
  if (event == WATCH_EVENT_ADD_FILE && !strcmp(fn, "000")) {
    return ZX_ERR_STOP;
  }
  return ZX_OK;
}

bool Surface::CanConnectToDisplay() {
  constexpr char kGpuDriverClass[] = "/dev/class/gpu";
  fml::UniqueFD fd(open(kGpuDriverClass, O_DIRECTORY | O_RDONLY));
  if (fd.get() < 0) {
    FML_DLOG(ERROR) << "Failed to open " << kGpuDriverClass;
    return false;
  }

  zx_status_t status = fdio_watch_directory(
      fd.get(), DriverWatcher, zx_deadline_after(ZX_SEC(5)), nullptr);
  return status == ZX_ERR_STOP;
}

// |flutter::Surface|
SkMatrix Surface::GetRootTransformation() const {
  // This backend does not support delegating to the underlying platform to
  // query for root surface transformations. Just return identity.
  SkMatrix matrix;
  matrix.reset();
  return matrix;
}

}  // namespace flutter_runner
