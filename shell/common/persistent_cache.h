// Copyright 2013 The Flutter Authors. All rights reserved.
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

namespace flutter {

/// A cache of SkData that gets stored to disk.
///
/// This is mainly used for Shaders but is also written to by Dart.  It is
/// thread-safe for reading and writing from multiple threads.
class PersistentCache : public GrContextOptions::PersistentCache {
 public:
  // Mutable static switch that can be set before GetCacheForProcess. If true,
  // we'll only read existing caches but not generate new ones. Some clients
  // (e.g., embedded devices) prefer generating persistent cache files for the
  // specific device beforehand, and ship them as readonly files in OTA
  // packages.
  static bool gIsReadOnly;

  static PersistentCache* GetCacheForProcess();

  static void SetCacheDirectoryPath(std::string path);

  ~PersistentCache() override;

  void AddWorkerTaskRunner(fml::RefPtr<fml::TaskRunner> task_runner);

  void RemoveWorkerTaskRunner(fml::RefPtr<fml::TaskRunner> task_runner);

  // Whether Skia tries to store any shader into this persistent cache after
  // |ResetStoredNewShaders| is called. This flag is usually reset before each
  // frame so we can know if Skia tries to compile new shaders in that frame.
  bool StoredNewShaders() const { return stored_new_shaders_; }
  void ResetStoredNewShaders() { stored_new_shaders_ = false; }
  void DumpSkp(const SkData& data);
  bool IsDumpingSkp() const { return is_dumping_skp_; }
  void SetIsDumpingSkp(bool value) { is_dumping_skp_ = value; }

 private:
  static std::string cache_base_path_;

  const bool is_read_only_;
  const std::shared_ptr<fml::UniqueFD> cache_directory_;
  mutable std::mutex worker_task_runners_mutex_;
  std::multiset<fml::RefPtr<fml::TaskRunner>> worker_task_runners_
      FML_GUARDED_BY(worker_task_runners_mutex_);

  bool stored_new_shaders_ = false;
  bool is_dumping_skp_ = false;

  bool IsValid() const;

  PersistentCache(bool read_only = false);

  // |GrContextOptions::PersistentCache|
  sk_sp<SkData> load(const SkData& key) override;

  // |GrContextOptions::PersistentCache|
  void store(const SkData& key, const SkData& data) override;

  fml::RefPtr<fml::TaskRunner> GetWorkerTaskRunner() const;

  FML_DISALLOW_COPY_AND_ASSIGN(PersistentCache);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_COMMON_PERSISTENT_CACHE_H_
