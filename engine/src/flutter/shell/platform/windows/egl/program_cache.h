// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_EGL_PROGRAM_CACHE_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_EGL_PROGRAM_CACHE_H_

#include <EGL/egl.h>
#include <EGL/eglext.h>

#include <condition_variable>
#include <cstdint>
#include <deque>
#include <filesystem>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <thread>
#include <unordered_map>
#include <vector>

#include "flutter/fml/macros.h"

namespace flutter {
namespace egl {

// Keeps the GL programs that ANGLE compiles, so that later launches load them
// instead of compiling them again.
//
// ANGLE translates every GL program to HLSL and compiles it with the Direct3D
// shader compiler when it is linked. Impeller links its built-in programs at
// startup, so every launch spent most of its startup time in that compiler.
//
// ANGLE hands its compiled programs to this cache through
// EGL_ANDROID_blob_cache. ANGLE derives each key from the shader sources, its
// own program format version, the GPU and the driver version, and it rejects a
// stored program whose GPU or Direct3D feature level does not match. A
// rejected or undecodable program is compiled again and replaces the entry.
//
// Each entry is one file named after its key. The file records the key, the
// value size and a checksum, and it is written to a temporary file that then
// replaces the entry in one step. A truncated, corrupted or mismatched file
// reads as a miss and is deleted.
//
// Entries live in a folder named after the engine version. Folders that
// earlier engine versions left behind are removed. The total size is bounded:
// when an entry would exceed it, the entries used least recently are removed.
class ProgramCache {
 public:
  static constexpr size_t kDefaultMaxTotalBytes = 32 * 1024 * 1024;
  static constexpr size_t kDefaultMaxEntryBytes = 4 * 1024 * 1024;
  static constexpr size_t kMaxQueuedBytes = 16 * 1024 * 1024;

  struct Options {
    // The folder that holds a folder for each engine version.
    std::filesystem::path directory;

    // Names this engine version's folder.
    std::string version;

    // The largest total size of this version's entries, in bytes.
    size_t max_total_bytes = kDefaultMaxTotalBytes;

    // The largest entry that is kept, in bytes.
    size_t max_entry_bytes = kDefaultMaxEntryBytes;

    // Whether Set writes on a background thread. When false, Set writes
    // before it returns.
    bool write_in_background = true;
  };

  explicit ProgramCache(Options options);

  // Finishes queued writes before it returns.
  ~ProgramCache();

  // Stores |value| for |key|. The data is copied.
  //
  // This is the set function of EGL_ANDROID_blob_cache.
  void Set(const void* key,
           EGLsizeiANDROID key_size,
           const void* value,
           EGLsizeiANDROID value_size);

  // Returns the size of the value for |key|, or 0 if there is none. Copies the
  // value to |value| if it is at least |value_size| bytes.
  //
  // This is the get function of EGL_ANDROID_blob_cache. ANGLE calls it twice
  // for a hit: first to learn the size, then with a buffer of that size. The
  // first call reads and checks the file; the second copies what it read.
  EGLsizeiANDROID Get(const void* key,
                      EGLsizeiANDROID key_size,
                      void* value,
                      EGLsizeiANDROID value_size);

  // Waits until every queued write has reached the disk.
  void Flush();

  // The folder that holds this engine version's entries.
  const std::filesystem::path& version_directory() const {
    return version_directory_;
  }

  // The name of the version folder for |version|.
  static std::string VersionDirectoryName(const std::string& version);

  // The file name of the entry for |key|.
  static std::wstring EntryFileName(const std::string& key);

  // Makes |cache| the process's cache and registers it with |display| through
  // EGL_ANDROID_blob_cache.
  //
  // The callbacks of EGL_ANDROID_blob_cache carry no context, so a process has
  // one cache. The first installed cache stays; a later one is dropped and
  // the first is registered with |display| instead. The cache is never
  // destroyed, because ANGLE can call it until the process exits.
  //
  // Returns false if the display does not support EGL_ANDROID_blob_cache.
  static bool InstallForDisplay(EGLDisplay display,
                                std::unique_ptr<ProgramCache> cache);

 private:
  struct Entry {
    uint64_t size = 0;
    // When the entry was written or last refreshed by a hit, in FILETIME
    // units.
    uint64_t last_used = 0;
  };

  struct PendingWrite {
    std::string key;
    std::shared_ptr<const std::vector<uint8_t>> value;
  };

  std::filesystem::path EntryPath(const std::string& key) const;

  // Reads and checks the entry file for |key|. Deletes a file that fails the
  // checks.
  std::optional<std::vector<uint8_t>> ReadEntry(const std::string& key) const;

  // Writes the entry file for |key| and updates the index. Runs on the writer
  // thread, or in Set when writing synchronously.
  void WriteEntry(const std::string& key, const std::vector<uint8_t>& value);

  // Indexes this version's entries and removes what earlier runs left
  // behind: other versions' folders and stale temporary files.
  void PrepareDirectory();

  // Removes the entries used least recently until the total fits.
  void EvictIfNeeded();

  void WriterLoop();

  const Options options_;
  const std::filesystem::path version_directory_;

  // Guards the fields below it.
  std::mutex mutex_;
  std::condition_variable writer_wakeup_;
  std::condition_variable writes_done_;
  std::deque<PendingWrite> queue_;
  size_t queued_bytes_ = 0;
  bool writing_ = false;
  bool stopping_ = false;
  // Values that Set accepted and that have not reached the disk yet.
  std::unordered_map<std::string, std::shared_ptr<const std::vector<uint8_t>>>
      pending_;
  // The value that the first call of a Get pair read.
  std::string last_read_key_;
  std::optional<std::vector<uint8_t>> last_read_value_;

  // Owned by whichever thread writes: the writer thread, or Set's caller when
  // writing synchronously under |mutex_|. Keyed by entry file name.
  bool prepared_ = false;
  std::unordered_map<std::wstring, Entry> index_;
  uint64_t total_bytes_ = 0;
  uint64_t temporary_file_counter_ = 0;

  std::thread writer_;

  FML_DISALLOW_COPY_AND_ASSIGN(ProgramCache);
};

// Decides where the program cache lives, or whether there is one.
struct ProgramCacheLocation {
  // The path the app configured, if it configured one. Empty turns the cache
  // off.
  std::optional<std::wstring> configured_path;

  // The engine switches. In debug and profile builds these include
  // FLUTTER_ENGINE_SWITCHES. `--program-cache-path=<folder>` overrides the
  // configured path, and an empty folder turns the cache off.
  std::vector<std::string> switches;

  // The user's local application data folder, such as
  // C:\Users\name\AppData\Local.
  std::filesystem::path local_app_data;

  // The executable's company and product names, from its version resource.
  std::wstring company_name;
  std::wstring product_name;

  // The executable's file name without its extension.
  std::wstring executable_stem;

  // Returns the folder, or nullopt if there is no cache.
  //
  // A relative path is taken as relative to the local application data
  // folder. By default the folder is
  // <local app data>\<company>\<product>\flutter_program_cache, which is where
  // Flutter's path_provider puts the application's cache folder.
  std::optional<std::filesystem::path> Resolve() const;

  // Fills in the folders and names from this process and user.
  static ProgramCacheLocation ForCurrentProcess(
      std::optional<std::wstring> configured_path,
      std::vector<std::string> switches);
};

}  // namespace egl
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_EGL_PROGRAM_CACHE_H_
