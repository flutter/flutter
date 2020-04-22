// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/persistent_cache.h"

#include <memory>
#include <string>
#include <string_view>

#include "rapidjson/document.h"
#include "third_party/skia/include/utils/SkBase64.h"

#include "flutter/fml/base32.h"
#include "flutter/fml/file.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/mapping.h"
#include "flutter/fml/paths.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/version/version.h"

namespace flutter {

std::string PersistentCache::cache_base_path_;
std::string PersistentCache::asset_path_;

std::mutex PersistentCache::instance_mutex_;
std::unique_ptr<PersistentCache> PersistentCache::gPersistentCache;

std::string PersistentCache::SkKeyToFilePath(const SkData& data) {
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

std::atomic<bool> PersistentCache::cache_sksl_ = false;
std::atomic<bool> PersistentCache::strategy_set_ = false;

void PersistentCache::SetCacheSkSL(bool value) {
  if (strategy_set_ && value != cache_sksl_) {
    FML_LOG(ERROR) << "Cache SkSL can only be set before the "
                      "GrContextOptions::fShaderCacheStrategy is set.";
    return;
  }
  cache_sksl_ = value;
}

PersistentCache* PersistentCache::GetCacheForProcess() {
  std::scoped_lock lock(instance_mutex_);
  if (gPersistentCache == nullptr) {
    gPersistentCache.reset(new PersistentCache(gIsReadOnly));
  }
  return gPersistentCache.get();
}

void PersistentCache::ResetCacheForProcess() {
  std::scoped_lock lock(instance_mutex_);
  gPersistentCache.reset(new PersistentCache(gIsReadOnly));
  strategy_set_ = false;
}

void PersistentCache::SetCacheDirectoryPath(std::string path) {
  cache_base_path_ = path;
}

namespace {
static std::shared_ptr<fml::UniqueFD> MakeCacheDirectory(
    const std::string& global_cache_base_path,
    bool read_only,
    bool cache_sksl) {
  fml::UniqueFD cache_base_dir;
  if (global_cache_base_path.length()) {
    cache_base_dir = fml::OpenDirectory(global_cache_base_path.c_str(), false,
                                        fml::FilePermission::kRead);
  } else {
    cache_base_dir = fml::paths::GetCachesDirectory();
  }

  if (cache_base_dir.is_valid()) {
    std::vector<std::string> components = {
        "flutter_engine", GetFlutterEngineVersion(), "skia", GetSkiaVersion()};
    if (cache_sksl) {
      components.push_back(PersistentCache::kSkSLSubdirName);
    }
    return std::make_shared<fml::UniqueFD>(
        CreateDirectory(cache_base_dir, components,
                        read_only ? fml::FilePermission::kRead
                                  : fml::FilePermission::kReadWrite));
  } else {
    return std::make_shared<fml::UniqueFD>();
  }
}
}  // namespace

sk_sp<SkData> ParseBase32(const std::string& input) {
  std::pair<bool, std::string> decode_result = fml::Base32Decode(input);
  if (!decode_result.first) {
    FML_LOG(ERROR) << "Base32 can't decode: " << input;
    return nullptr;
  }
  const std::string& data_string = decode_result.second;
  return SkData::MakeWithCopy(data_string.data(), data_string.length());
}

sk_sp<SkData> ParseBase64(const std::string& input) {
  SkBase64 decoder;
  auto error = decoder.decode(input.c_str(), input.length());
  if (error != SkBase64::Error::kNoError) {
    FML_LOG(ERROR) << "Base64 decode error: " << error;
    FML_LOG(ERROR) << "Base64 can't decode: " << input;
    return nullptr;
  }
  return SkData::MakeWithCopy(decoder.getData(), decoder.getDataSize());
}

std::vector<PersistentCache::SkSLCache> PersistentCache::LoadSkSLs() {
  TRACE_EVENT0("flutter", "PersistentCache::LoadSkSLs");
  std::vector<PersistentCache::SkSLCache> result;
  fml::FileVisitor visitor = [&result](const fml::UniqueFD& directory,
                                       const std::string& filename) {
    sk_sp<SkData> key = ParseBase32(filename);
    sk_sp<SkData> data = LoadFile(directory, filename);
    if (key != nullptr && data != nullptr) {
      result.push_back({key, data});
    } else {
      FML_LOG(ERROR) << "Failed to load: " << filename;
    }
    return true;
  };

  // Only visit sksl_cache_directory_ if this persistent cache is valid.
  // However, we'd like to continue visit the asset dir even if this persistent
  // cache is invalid.
  if (IsValid()) {
    fml::VisitFiles(*sksl_cache_directory_, visitor);
  }

  fml::UniqueFD root_asset_dir = fml::OpenDirectory(asset_path_.c_str(), false,
                                                    fml::FilePermission::kRead);
  fml::UniqueFD sksl_asset_dir =
      fml::OpenDirectoryReadOnly(root_asset_dir, kSkSLSubdirName);
  auto sksl_asset_file = fml::OpenFileReadOnly(sksl_asset_dir, kAssetFileName);
  if (!sksl_asset_file.is_valid()) {
    FML_LOG(INFO) << "No sksl asset file found.";
  } else {
    FML_LOG(INFO) << "Found sksl asset. Loading SkSLs from it...";
    auto mapping = std::make_unique<fml::FileMapping>(sksl_asset_file);
    rapidjson::Document json_doc;
    rapidjson::ParseResult parse_result =
        json_doc.Parse(reinterpret_cast<const char*>(mapping->GetMapping()),
                       mapping->GetSize());
    if (parse_result != rapidjson::ParseErrorCode::kParseErrorNone) {
      FML_LOG(ERROR) << "Failed to parse json file: " << kAssetFileName;
    } else {
      for (auto& item : json_doc["data"].GetObject()) {
        sk_sp<SkData> key = ParseBase32(item.name.GetString());
        sk_sp<SkData> sksl = ParseBase64(item.value.GetString());
        if (key != nullptr && sksl != nullptr) {
          result.push_back({key, sksl});
        } else {
          FML_LOG(ERROR) << "Failed to load: " << item.name.GetString();
        }
      }
    }
  }

  return result;
}

PersistentCache::PersistentCache(bool read_only)
    : is_read_only_(read_only),
      cache_directory_(MakeCacheDirectory(cache_base_path_, read_only, false)),
      sksl_cache_directory_(
          MakeCacheDirectory(cache_base_path_, read_only, true)) {
  if (!IsValid()) {
    FML_LOG(WARNING) << "Could not acquire the persistent cache directory. "
                        "Caching of GPU resources on disk is disabled.";
  }
}

PersistentCache::~PersistentCache() = default;

bool PersistentCache::IsValid() const {
  return cache_directory_ && cache_directory_->is_valid();
}

sk_sp<SkData> PersistentCache::LoadFile(const fml::UniqueFD& dir,
                                        const std::string& file_name) {
  auto file = fml::OpenFileReadOnly(dir, file_name.c_str());
  if (!file.is_valid()) {
    return nullptr;
  }
  auto mapping = std::make_unique<fml::FileMapping>(file);
  if (mapping->GetSize() == 0) {
    return nullptr;
  }
  return SkData::MakeWithCopy(mapping->GetMapping(), mapping->GetSize());
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
  auto result = PersistentCache::LoadFile(*cache_directory_, file_name);
  if (result != nullptr) {
    TRACE_EVENT0("flutter", "PersistentCacheLoadHit");
  } else {
    FML_LOG(INFO) << "PersistentCache::load failed: " << file_name;
  }
  return result;
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

  PersistentCacheStore(GetWorkerTaskRunner(),
                       cache_sksl_ ? sksl_cache_directory_ : cache_directory_,
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

void PersistentCache::UpdateAssetPath(const std::string& path) {
  FML_LOG(INFO) << "PersistentCache::UpdateAssetPath: " << path;
  asset_path_ = path;
}

}  // namespace flutter
