// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_PERSISTENT_CACHE_H_
#define FLUTTER_SHELL_COMMON_PERSISTENT_CACHE_H_

#include <memory>
#include <mutex>
#include <set>

#include "flutter/fml/macros.h"
#include "flutter/fml/synchronization/thread_annotations.h"
#include "flutter/fml/task_runner.h"
#include "flutter/fml/unique_fd.h"
#include "third_party/skia/include/gpu/GrContextOptions.h"

namespace shell {

class PersistentCache : public GrContextOptions::PersistentCache {
 public:
  static PersistentCache* GetCacheForProcess();

  ~PersistentCache() override;

  void AddWorkerTaskRunner(fml::RefPtr<fml::TaskRunner> task_runner);

  void RemoveWorkerTaskRunner(fml::RefPtr<fml::TaskRunner> task_runner);

 private:
  std::shared_ptr<fml::UniqueFD> cache_directory_;
  mutable std::mutex worker_task_runners_mutex_;
  std::multiset<fml::RefPtr<fml::TaskRunner>> worker_task_runners_
      FML_GUARDED_BY(worker_task_runners_mutex_);

  bool IsValid() const;

  PersistentCache();

  // |GrContextOptions::PersistentCache|
  sk_sp<SkData> load(const SkData& key) override;

  // |GrContextOptions::PersistentCache|
  void store(const SkData& key, const SkData& data) override;

  fml::RefPtr<fml::TaskRunner> GetWorkerTaskRunner() const;

  FML_DISALLOW_COPY_AND_ASSIGN(PersistentCache);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_COMMON_PERSISTENT_CACHE_H_
