// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "runtime/dart/utils/tempfs.h"

#include <string>
#include <thread>

#include <lib/async-loop/cpp/loop.h>
#include <lib/fdio/namespace.h>
#include <lib/memfs/memfs.h>
#include <lib/syslog/global.h>
#include <zircon/errors.h>
#include <zircon/status.h>
#include <zircon/syscalls.h>

#include "runtime/dart/utils/logging.h"

namespace {

constexpr char kTmpPath[] = "/tmp";
[[maybe_unused]] constexpr size_t kMaxTmpPages = 1024;

void DispatchTempMemFS() {
  async::Loop loop(&kAsyncLoopConfigAttachToThread);
#if defined(DART_PRODUCT)
  zx_status_t status = memfs_install_at_with_page_limit(loop.dispatcher(),
                                                        kMaxTmpPages, kTmpPath);
#else
  // Hot reload uses /tmp to hold the updated dills and assets so do not
  // impose any size limitation in non product runners.
  zx_status_t status = memfs_install_at(loop.dispatcher(), kTmpPath);
#endif
  if (status != ZX_OK) {
    FX_LOGF(ERROR, LOG_TAG, "Failed to install a /tmp memfs: %s",
            zx_status_get_string(status));
    return;
  }
  loop.Run();
}

}  // namespace

namespace dart_utils {

// Set up a memfs bound to /tmp in the process-wide namespace that has the
// lifetime of the process.
void SetupRunnerTemp() {
  std::thread thread(DispatchTempMemFS);
  thread.detach();
}

void SetupComponentTemp(fdio_ns_t* ns) {
  // TODO(zra): Should isolates share a /tmp file system within a process, or
  // should isolates each get their own private memfs for /tmp? For now,
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
