// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "tempfs.h"

#include <future>
#include <string>
#include <thread>

#include <lib/async-loop/cpp/loop.h>
#include <lib/async-loop/default.h>
#include <lib/async/cpp/task.h>
#include <lib/fdio/namespace.h>
#include <lib/syslog/global.h>
#include <lib/vfs/cpp/pseudo_dir.h>
#include <zircon/errors.h>
#include <zircon/status.h>
#include <zircon/syscalls.h>

#include "logging.h"

namespace {

constexpr char kTmpPath[] = "/tmp";

}  // namespace

namespace dart_utils {

RunnerTemp::RunnerTemp()
    : loop_(std::make_unique<async::Loop>(
          &kAsyncLoopConfigNoAttachToCurrentThread)) {
  loop_->StartThread("RunnerTemp");
  Start();
}

RunnerTemp::~RunnerTemp() = default;

static vfs::PseudoDir tmp_dir;

void RunnerTemp::Start() {
  std::promise<zx_status_t> finished;
  async::PostTask(loop_->dispatcher(), [this, &finished]() {
    finished.set_value([this]() {
      zx::channel client, server;
      if (zx_status_t status = zx::channel::create(0, &client, &server);
          status != ZX_OK) {
        return status;
      }
      if (zx_status_t status =
              tmp_dir.Serve(fuchsia::io::OpenFlags::RIGHT_READABLE |
                                fuchsia::io::OpenFlags::RIGHT_WRITABLE |
                                fuchsia::io::OpenFlags::DIRECTORY,
                            std::move(server), loop_->dispatcher());
          status != ZX_OK) {
        return status;
      }
      fdio_ns_t* ns;
      if (zx_status_t status = fdio_ns_get_installed(&ns); status != ZX_OK) {
        return status;
      }
      if (zx_status_t status = fdio_ns_bind(ns, kTmpPath, client.release());
          status != ZX_OK) {
        return status;
      }
      return ZX_OK;
    }());
  });
  if (zx_status_t status = finished.get_future().get(); status != ZX_OK) {
    FX_LOGF(ERROR, LOG_TAG, "Failed to install a /tmp virtual filesystem: %s",
            zx_status_get_string(status));
  }
}

void RunnerTemp::SetupComponent(fdio_ns_t* ns) {
  // TODO(zra): Should isolates share a /tmp file system within a process, or
  // should isolates each get their own private file system for /tmp? For now,
  // sharing the process-wide /tmp simplifies hot reload since the hot reload
  // devfs requires sharing between the service isolate and the app isolates.
  zx_status_t status;
  fdio_flat_namespace_t* rootns;
  status = fdio_ns_export_root(&rootns);
  if (status != ZX_OK) {
    FX_LOGF(ERROR, LOG_TAG, "Failed to export root ns: %s",
            zx_status_get_string(status));
    return;
  }

  zx_handle_t tmp_dir_handle;
  for (size_t i = 0; i < rootns->count; i++) {
    if (strcmp(rootns->path[i], kTmpPath) == 0) {
      tmp_dir_handle = rootns->handle[i];
    } else {
      zx_handle_close(rootns->handle[i]);
      rootns->handle[i] = ZX_HANDLE_INVALID;
    }
  }
  free(rootns);
  rootns = nullptr;

  status = fdio_ns_bind(ns, kTmpPath, tmp_dir_handle);
  if (status != ZX_OK) {
    zx_handle_close(tmp_dir_handle);
    FX_LOGF(ERROR, LOG_TAG,
            "Failed to bind /tmp directory into isolate namespace: %s",
            zx_status_get_string(status));
  }
}

}  // namespace dart_utils
