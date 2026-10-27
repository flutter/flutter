// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/callback_cache.h"

#include <sstream>

#include "flutter/fml/build_config.h"
#include "flutter/fml/file.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/mapping.h"
#include "flutter/fml/paths.h"
#include "rapidjson/document.h"
#include "rapidjson/stringbuffer.h"
#include "rapidjson/writer.h"

using rapidjson::Document;
using rapidjson::StringBuffer;
using rapidjson::Value;
using rapidjson::Writer;

namespace fml {

namespace {

static const char* kCacheName = "flutter_callback_cache.json";

static const char* kNameKey = "name";
static const char* kClassNameKey = "class_name";
static const char* kLibraryPathKey = "library_path";

int64_t GetHash(const std::string& name,
                const std::string& class_name,
                const std::string& library_path) {
  std::size_t h1 = std::hash<std::string>{}(name);
  std::size_t h2 = std::hash<std::string>{}(class_name);
  std::size_t h3 = std::hash<std::string>{}(library_path);
  return h1 ^ (h2 << 1) ^ (h3 << 2);
}

}  // namespace

std::mutex CallbackCache::mutex_;
std::string CallbackCache::cache_path_;
std::map<int64_t, CallbackRepresentation> CallbackCache::cache_;

void CallbackCache::SetCachePath(const std::string& path) {
  std::scoped_lock<std::mutex> lock(mutex_);
  cache_path_ = fml::paths::JoinPaths({path, kCacheName});
}

std::string CallbackCache::GetCachePath() {
  std::scoped_lock<std::mutex> lock(mutex_);
  return cache_path_;
}

std::unique_ptr<CallbackRepresentation> CallbackCache::GetCallbackInformation(
    int64_t handle) {
  std::scoped_lock<std::mutex> lock(mutex_);
  auto iterator = cache_.find(handle);
  if (iterator != cache_.end()) {
    return std::make_unique<CallbackRepresentation>(iterator->second);
  }
  return nullptr;
}

int64_t CallbackCache::GetCallbackHandle(const std::string& name,
                                         const std::string& class_name,
                                         const std::string& library_path) {
  std::scoped_lock<std::mutex> lock(mutex_);
  int64_t hash = GetHash(name, class_name, library_path);
  if (cache_.find(hash) == cache_.end()) {
    cache_[hash] = {name, class_name, library_path};
    SaveCacheToDisk();
  }
  return hash;
}

void CallbackCache::LoadCacheFromDisk() {
  std::scoped_lock<std::mutex> lock(mutex_);
  if (!cache_.empty() || cache_path_.empty()) {
    return;
  }
  // Don'tUse -> fml::FileMapping(const std::string& path) doesn't handle
  // failure gracefully.
  fml::UniqueFD fd =
      fml::OpenFile(cache_path_.c_str(), false, fml::FilePermission::kRead);
  if (!fd.is_valid()) {
    return;
  }
  fml::FileMapping mapping(fd, {fml::FileMapping::Protection::kRead});
  if (mapping.GetMapping() == nullptr) {
    return;
  }

  std::string contents{reinterpret_cast<const char*>(mapping.GetMapping()),
                       mapping.GetSize()};
  Document document;
  document.Parse(contents.c_str());
  if (!document.IsObject()) {
    FML_LOG(ERROR) << "Could notLoad callback cache, invalid JSON.";
    return;
  }

  auto root = document.GetObj();
  for (Value::ConstMemberIterator iterator = root.MemberBegin();
       iterator != root.MemberEnd(); ++iterator) {
    int64_t hash = std::stoll(iterator->name.GetString());
    auto entry = iterator->value.GetObj();

    Value::ConstMemberIterator name_it = entry.FindMember(kNameKey);
    Value::ConstMemberIterator class_name_it = entry.FindMember(kClassNameKey);
    Value::ConstMemberIterator library_path_it =
        entry.FindMember(kLibraryPathKey);

    // Clear the cache in the case the storage format has been updated.
    if ((name_it == entry.MemberEnd()) ||
        (class_name_it == entry.MemberEnd()) ||
        (library_path_it == entry.MemberEnd())) {
      cache_.clear();
      return;
    }

    std::string name = name_it->value.GetString();
    std::string class_name = class_name_it->value.GetString();
    std::string library_path = library_path_it->value.GetString();
    cache_[hash] = {name, class_name, library_path};
  }
}

void CallbackCache::ClearCacheForTesting() {
  std::scoped_lock<std::mutex> lock(mutex_);
  cache_.clear();
}

void CallbackCache::SaveCacheToDisk() {
  if (cache_path_.empty()) {
    return;
  }
  // Format:
  // {
  //   hash1: {
  //     "name": "Animation",
  //     "class_name": "_Animation",
  //     "library_path": "package:flutter/..."
  //   },
  //   hash2: {
  //     ...
  //   }
  // }
  Document d;
  d.SetObject();
  Document::AllocatorType& allocator = d.GetAllocator();
  for (auto iterator = cache_.begin(); iterator != cache_.end(); ++iterator) {
    int64_t hash = iterator->first;
    CallbackRepresentation cb = iterator->second;
    Value key;
    Value entry(rapidjson::kObjectType);

    std::ostringstream s;
    s << hash;
    std::string hash_str = s.str();
    key.SetString(hash_str.c_str(), hash_str.size(), allocator);

    Value name;
    name.SetString(cb.name.c_str(), cb.name.size(), allocator);
    Value class_name;
    class_name.SetString(cb.class_name.c_str(), cb.class_name.size(),
                         allocator);
    Value library_path;
    library_path.SetString(cb.library_path.c_str(), cb.library_path.size(),
                           allocator);

    entry.AddMember(rapidjson::StringRef(kNameKey), name, allocator);
    entry.AddMember(rapidjson::StringRef(kClassNameKey), class_name, allocator);
    entry.AddMember(rapidjson::StringRef(kLibraryPathKey), library_path,
                    allocator);
    d.AddMember(key, entry, allocator);
  }
  StringBuffer buffer;
  Writer<StringBuffer> writer(buffer);
  d.Accept(writer);

  const char* data = buffer.GetString();
  fml::NonOwnedMapping mapping(reinterpret_cast<const uint8_t*>(data),
                               buffer.GetSize());
  auto dir_name = fml::paths::GetDirectoryName(cache_path_);
  auto dir =
      fml::OpenDirectory(dir_name.c_str(), false, fml::FilePermission::kRead);
  fml::WriteAtomically(dir, kCacheName, mapping);
}

}  // namespace fml
