// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/persistent_cache.h"

#include <memory>
#include <string>
#include <string_view>

#include "flutter/fml/base32.h"
#include "flutter/fml/file.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/mapping.h"
#include "flutter/fml/paths.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/version/version.h"

namespace flutter {

std::string PersistentCache::cache_base_path_;

static std::string SkKeyToFilePath(const SkData& data) {
  if (data.data() == nullptr || data.size() == 0) {
    return "";
  }

  std::string_view view(reinterpret_cast<const char*>(data.data()),
                        data.size());

  auto encode_result = fml::Base32Encode(view);

  if (!encode_result.first) {
    return "";
  }

  return encode_result.second;
}

bool PersistentCache::gIsReadOnly = false;

PersistentCache* PersistentCache::GetCacheForProcess() {
  static std::unique_ptr<PersistentCache> gPersistentCache;
  static std::once_flag once = {};
  std::call_once(
      once, []() { gPersistentCache.reset(new PersistentCache(gIsReadOnly)); });
  return gPersistentCache.get();
}

void PersistentCache::SetCacheDirectoryPath(std::string path) {
  cache_base_path_ = path;
}

namespace {
std::shared_ptr<fml::UniqueFD> MakeCacheDirectory(
    const std::string& global_cache_base_path,
    bool read_only) {
  fml::UniqueFD cache_base_dir;
  if (global_cache_base_path.length()) {
    cache_base_dir = fml::OpenDirectory(global_cache_base_path.c_str(), false,
                                        fml::FilePermission::kRead);
  } else {
    cache_base_dir = fml::paths::GetCachesDirectory();
  }

  if (cache_base_dir.is_valid()) {
    return std::make_shared<fml::UniqueFD>(CreateDirectory(
        cache_base_dir,
        {"flutter_engine", GetFlutterEngineVersion(), "skia", GetSkiaVersion()},
        read_only ? fml::FilePermission::kRead
                  : fml::FilePermission::kReadWrite));
  } else {
    return std::make_shared<fml::UniqueFD>();
  }
}
}  // namespace

PersistentCache::PersistentCache(bool read_only)
    : is_read_only_(read_only),
      cache_directory_(MakeCacheDirectory(cache_base_path_, read_only)) {
  if (!IsValid()) {
    FML_LOG(WARNING) << "Could not acquire the persistent cache directory. "
                        "Caching of GPU resources on disk is disabled.";
  }
}

PersistentCache::~PersistentCache() = default;

bool PersistentCache::IsValid() const {
  return cache_directory_ && cache_directory_->is_valid();
}

// |GrContextOptions::PersistentCache|
sk_sp<SkData> PersistentCache::load(const SkData& key) {
  TRACE_EVENT0("flutter", "PersistentCacheLoad");
  if (!IsValid()) {
    return nullptr;
  }
  auto file_name = SkKeyToFilePath(key);
  if (file_name.size() == 0) {
    return nullptr;
  }
  auto file = fml::OpenFile(*cache_directory_, file_name.c_str(), false,
                            fml::FilePermission::kRead);
  if (!file.is_valid()) {
    return nullptr;
  }
  auto mapping = std::make_unique<fml::FileMapping>(file);
  if (mapping->GetSize() == 0) {
    return nullptr;
  }

  TRACE_EVENT0("flutter", "PersistentCacheLoadHit");
  return SkData::MakeWithCopy(mapping->GetMapping(), mapping->GetSize());
}

static void PersistentCacheStore(fml::RefPtr<fml::TaskRunner> worker,
                                 std::shared_ptr<fml::UniqueFD> cache_directory,
                                 std::string key,
                                 std::unique_ptr<fml::Mapping> value) {
  auto task =
      fml::MakeCopyable([cache_directory,             //
                         file_name = std::move(key),  //
                         mapping = std::move(value)   //
  ]() mutable {
        TRACE_EVENT0("flutter", "PersistentCacheStore");
        if (!fml::WriteAtomically(*cache_directory,   //
                                  file_name.c_str(),  //
                                  *mapping)           //
        ) {
          FML_DLOG(WARNING)
              << "Could not write cache contents to persistent store.";
        }
      });

  if (!worker) {
    FML_LOG(WARNING)
        << "The persistent cache has no available workers. Performing the task "
           "on the current thread. This slow operation is going to occur on a "
           "frame workload.";
    task();
  } else {
    worker->PostTask(std::move(task));
  }
}

// |GrContextOptions::PersistentCache|
void PersistentCache::store(const SkData& key, const SkData& data) {
  stored_new_shaders_ = true;

  if (is_read_only_) {
    return;
  }

  if (!IsValid()) {
    return;
  }

  auto file_name = SkKeyToFilePath(key);

  if (file_name.size() == 0) {
    return;
  }

  auto mapping = std::make_unique<fml::DataMapping>(
      std::vector<uint8_t>{data.bytes(), data.bytes() + data.size()});

  if (mapping == nullptr || mapping->GetSize() == 0) {
    return;
  }

  PersistentCacheStore(GetWorkerTaskRunner(), cache_directory_,
                       std::move(file_name), std::move(mapping));
}

void PersistentCache::DumpSkp(const SkData& data) {
  if (is_read_only_ || !IsValid()) {
    FML_LOG(ERROR) << "Could not dump SKP from read-only or invalid persistent "
                      "cache.";
    return;
  }

  std::stringstream name_stream;
  auto ticks = fml::TimePoint::Now().ToEpochDelta().ToNanoseconds();
  name_stream << "shader_dump_" << std::to_string(ticks) << ".skp";
  std::string file_name = name_stream.str();
  FML_LOG(INFO) << "Dumping " << file_name;
  auto mapping = std::make_unique<fml::DataMapping>(
      std::vector<uint8_t>{data.bytes(), data.bytes() + data.size()});
  PersistentCacheStore(GetWorkerTaskRunner(), cache_directory_,
                       std::move(file_name), std::move(mapping));
}

void PersistentCache::AddWorkerTaskRunner(
    fml::RefPtr<fml::TaskRunner> task_runner) {
  std::scoped_lock lock(worker_task_runners_mutex_);
  worker_task_runners_.insert(task_runner);
}

void PersistentCache::RemoveWorkerTaskRunner(
    fml::RefPtr<fml::TaskRunner> task_runner) {
  std::scoped_lock lock(worker_task_runners_mutex_);
  auto found = worker_task_runners_.find(task_runner);
  if (found != worker_task_runners_.end()) {
    worker_task_runners_.erase(found);
  }
}

fml::RefPtr<fml::TaskRunner> PersistentCache::GetWorkerTaskRunner() const {
  fml::RefPtr<fml::TaskRunner> worker;

  std::scoped_lock lock(worker_task_runners_mutex_);
  if (!worker_task_runners_.empty()) {
    worker = *worker_task_runners_.begin();
  }

  return worker;
}

}  // namespace flutter
