// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "surface.h"

#include <fcntl.h>
#include <fdio/watcher.h>
#include <unistd.h>
#include <zircon/device/vfs.h>

#include "lib/fxl/files/unique_fd.h"

namespace flutter {

Surface::Surface(std::string debug_label)
    : debug_label_(std::move(debug_label)) {}

Surface::~Surface() = default;

// |shell::Surface|
bool Surface::IsValid() {
  return valid_;
}

// |shell::Surface|
std::unique_ptr<shell::SurfaceFrame> Surface::AcquireFrame(
    const SkISize& size) {
  return std::make_unique<shell::SurfaceFrame>(
      nullptr, [](const shell::SurfaceFrame& surface_frame, SkCanvas* canvas) {
        return true;
      });
}

// |shell::Surface|
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
  fxl::UniqueFD fd(open(kGpuDriverClass, O_DIRECTORY | O_RDONLY));
  if (fd.get() < 0) {
    FXL_DLOG(ERROR) << "Failed to open " << kGpuDriverClass;
    return false;
  }

  zx_status_t status = fdio_watch_directory(
      fd.get(), DriverWatcher, zx_deadline_after(ZX_SEC(5)), nullptr);
  return status == ZX_ERR_STOP;
}

}  // namespace flutter
