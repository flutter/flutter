// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TONIC_DART_ISOLATE_RELOADER_H_
#define FLUTTER_TONIC_DART_ISOLATE_RELOADER_H_

#include <string>
#include <vector>
#include <queue>

#include "base/callback_forward.h"
#include "base/macros.h"
#include "base/memory/weak_ptr.h"
#include "base/threading/thread.h"
#include "dart/runtime/include/dart_api.h"
#include "lib/ftl/synchronization/monitor.h"

namespace blink {
class DartLibraryProvider;

// Reloading an isolate must be an atomic operation, meaning, no other tasks
// can run while reloading. A nested run loop is not sufficient because other
// tasks that invoke Dart code can be run. When |HandleLibraryTag| is invoked
// the calling thread will be blocked until the load has fully completed. To
// avoid relying on the message loop we use our own queue and notification
// mechanism.
class DartIsolateReloader {
 public:
  // The |DartLibraryProvider| used to load the library sources.
  DartIsolateReloader(DartLibraryProvider* library_provider);
  ~DartIsolateReloader();

  static Dart_Handle HandleLibraryTag(Dart_LibraryTag tag,
                                      Dart_Handle library,
                                      Dart_Handle url);

 private:
  class LoadRequest;
  class LoadResult;

  void SendRequest(Dart_LibraryTag tag,
                   Dart_Handle url,
                   Dart_Handle library_url);

  void PostResult(std::unique_ptr<LoadResult> load_result);

  static void RequestTask(DartLibraryProvider* library_provider,
                          DartIsolateReloader* isolate_reloader,
                          intptr_t tag,
                          const std::string& url,
                          const std::string& library_url);

  void HandleLoadResultLocked(LoadResult* load_result);
  void ProcessResultQueueLocked();
  bool IsCompleteLocked();
  bool BlockUntilComplete();

  std::unique_ptr<base::Thread> thread_;
  DartLibraryProvider* library_provider_;

  ftl::Monitor monitor_;
  // The monitor is used to protect the following fields:
  Dart_Handle load_error_;
  std::queue<std::unique_ptr<LoadResult>> load_results_;
  intptr_t pending_requests_;
};

}  // namespace blink

#endif  // FLUTTER_TONIC_DART_ISOLATE_RELOADER_H_
