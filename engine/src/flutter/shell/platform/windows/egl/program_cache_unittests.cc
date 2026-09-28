// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/egl/program_cache.h"

#include <windows.h>

#include <filesystem>
#include <fstream>
#include <thread>
#include <vector>

#include "flutter/fml/file.h"
#include "flutter/fml/platform/win/wstring_conversion.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {

using egl::ProgramCache;
using egl::ProgramCacheLocation;

constexpr uint64_t kTicksPerDay = 24ull * 60 * 60 * 10'000'000;

// A temporary folder that is emptied before fml removes it, since fml only
// removes an empty folder.
class TemporaryFolder {
 public:
  ~TemporaryFolder() {
    std::error_code error;
    for (const auto& item :
         std::filesystem::directory_iterator(path(), error)) {
      std::filesystem::remove_all(item.path(), error);
    }
  }

  std::filesystem::path path() const {
    return std::filesystem::path(fml::Utf8ToWideString(directory_.path()));
  }

 private:
  fml::ScopedTemporaryDirectory directory_;
};

std::filesystem::path PathOf(const TemporaryFolder& folder) {
  return folder.path();
}

ProgramCache::Options MakeOptions(const std::filesystem::path& directory,
                                  std::string version = "engine-a") {
  ProgramCache::Options options;
  options.directory = directory;
  options.version = std::move(version);
  options.write_in_background = false;
  return options;
}

// ANGLE's keys are 20-byte hashes.
std::string MakeKey(char fill) {
  return std::string(20, fill);
}

std::vector<uint8_t> MakeValue(size_t size, uint8_t seed) {
  std::vector<uint8_t> value(size);
  for (size_t i = 0; i < size; i++) {
    value[i] = static_cast<uint8_t>(seed + i * 7);
  }
  return value;
}

void Store(ProgramCache& cache,
           const std::string& key,
           const std::vector<uint8_t>& value) {
  cache.Set(key.data(), static_cast<EGLsizeiANDROID>(key.size()), value.data(),
            static_cast<EGLsizeiANDROID>(value.size()));
}

// Loads a value the way ANGLE does: the size first, then the bytes.
std::optional<std::vector<uint8_t>> Load(ProgramCache& cache,
                                         const std::string& key) {
  const auto key_size = static_cast<EGLsizeiANDROID>(key.size());
  const EGLsizeiANDROID size = cache.Get(key.data(), key_size, nullptr, 0);
  if (size <= 0) {
    return std::nullopt;
  }
  std::vector<uint8_t> value(size);
  if (cache.Get(key.data(), key_size, value.data(), size) != size) {
    return std::nullopt;
  }
  return value;
}

std::filesystem::path EntryPath(const ProgramCache& cache,
                                const std::string& key) {
  return cache.version_directory() / ProgramCache::EntryFileName(key);
}

void WriteFile(const std::filesystem::path& path, const std::string& text) {
  std::ofstream(path, std::ios::binary) << text;
}

uint64_t Now() {
  FILETIME now;
  ::GetSystemTimeAsFileTime(&now);
  return (static_cast<uint64_t>(now.dwHighDateTime) << 32) | now.dwLowDateTime;
}

void SetLastWriteTime(const std::filesystem::path& path, uint64_t ticks) {
  HANDLE file = ::CreateFileW(path.c_str(), FILE_WRITE_ATTRIBUTES,
                              FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr,
                              OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
  ASSERT_NE(file, INVALID_HANDLE_VALUE);
  FILETIME time = {static_cast<DWORD>(ticks), static_cast<DWORD>(ticks >> 32)};
  EXPECT_TRUE(::SetFileTime(file, nullptr, nullptr, &time));
  ::CloseHandle(file);
}

uint64_t LastWriteTime(const std::filesystem::path& path) {
  WIN32_FILE_ATTRIBUTE_DATA data;
  EXPECT_TRUE(
      ::GetFileAttributesExW(path.c_str(), GetFileExInfoStandard, &data));
  return (static_cast<uint64_t>(data.ftLastWriteTime.dwHighDateTime) << 32) |
         data.ftLastWriteTime.dwLowDateTime;
}

// gtest cannot print std::filesystem::path, so tests compare strings.
std::wstring Resolved(const ProgramCacheLocation& location) {
  const std::optional<std::filesystem::path> path = location.Resolve();
  return path.has_value() ? path->wstring() : L"<no cache>";
}

}  // namespace

TEST(ProgramCacheTest, LoadsWhatAnEarlierInstanceStored) {
  TemporaryFolder directory;
  const std::vector<uint8_t> value = MakeValue(300, 1);
  {
    ProgramCache cache(MakeOptions(PathOf(directory)));
    Store(cache, MakeKey('a'), value);
  }
  ProgramCache cache(MakeOptions(PathOf(directory)));
  EXPECT_EQ(Load(cache, MakeKey('a')), value);
  EXPECT_EQ(Load(cache, MakeKey('b')), std::nullopt);
}

TEST(ProgramCacheTest, SizeQueryDoesNotCopy) {
  TemporaryFolder directory;
  ProgramCache cache(MakeOptions(PathOf(directory)));
  const std::string key = MakeKey('a');
  Store(cache, key, MakeValue(64, 2));

  std::vector<uint8_t> small(63, 0xee);
  EXPECT_EQ(cache.Get(key.data(), 20, small.data(), 63), 64);
  EXPECT_EQ(small, std::vector<uint8_t>(63, 0xee));
}

TEST(ProgramCacheTest, BackgroundWritesAreVisibleBeforeTheyReachTheDisk) {
  TemporaryFolder directory;
  ProgramCache::Options options = MakeOptions(PathOf(directory));
  options.write_in_background = true;
  const std::vector<uint8_t> value = MakeValue(1000, 3);
  {
    ProgramCache cache(options);
    Store(cache, MakeKey('a'), value);
    EXPECT_EQ(Load(cache, MakeKey('a')), value);
    cache.Flush();
    EXPECT_TRUE(std::filesystem::exists(EntryPath(cache, MakeKey('a'))));
  }
  ProgramCache cache(options);
  EXPECT_EQ(Load(cache, MakeKey('a')), value);
}

TEST(ProgramCacheTest, DestructionFinishesQueuedWrites) {
  TemporaryFolder directory;
  ProgramCache::Options options = MakeOptions(PathOf(directory));
  options.write_in_background = true;
  {
    ProgramCache cache(options);
    for (char c = 'a'; c <= 'z'; c++) {
      Store(cache, MakeKey(c), MakeValue(5000, c));
    }
  }
  ProgramCache cache(MakeOptions(PathOf(directory)));
  for (char c = 'a'; c <= 'z'; c++) {
    EXPECT_EQ(Load(cache, MakeKey(c)), MakeValue(5000, c));
  }
}

TEST(ProgramCacheTest, CorruptedValueIsAMissAndIsDeleted) {
  TemporaryFolder directory;
  ProgramCache cache(MakeOptions(PathOf(directory)));
  Store(cache, MakeKey('a'), MakeValue(100, 4));
  const std::filesystem::path path = EntryPath(cache, MakeKey('a'));
  {
    std::fstream file(path, std::ios::binary | std::ios::in | std::ios::out);
    file.seekp(-1, std::ios::end);
    file.put('\x5a');
  }
  EXPECT_EQ(Load(cache, MakeKey('a')), std::nullopt);
  EXPECT_FALSE(std::filesystem::exists(path));
}

TEST(ProgramCacheTest, TruncatedFileIsAMissAndIsDeleted) {
  TemporaryFolder directory;
  ProgramCache cache(MakeOptions(PathOf(directory)));
  Store(cache, MakeKey('a'), MakeValue(100, 5));
  const std::filesystem::path path = EntryPath(cache, MakeKey('a'));
  std::filesystem::resize_file(path, std::filesystem::file_size(path) - 30);
  EXPECT_EQ(Load(cache, MakeKey('a')), std::nullopt);
  EXPECT_FALSE(std::filesystem::exists(path));
}

TEST(ProgramCacheTest, EntryOfAnotherKeyIsAMiss) {
  TemporaryFolder directory;
  ProgramCache cache(MakeOptions(PathOf(directory)));
  Store(cache, MakeKey('a'), MakeValue(100, 6));
  std::filesystem::copy_file(EntryPath(cache, MakeKey('a')),
                             EntryPath(cache, MakeKey('b')));
  EXPECT_EQ(Load(cache, MakeKey('b')), std::nullopt);
  EXPECT_TRUE(Load(cache, MakeKey('a')).has_value());
}

TEST(ProgramCacheTest, EmptyAndOversizedValuesAreNotStored) {
  TemporaryFolder directory;
  ProgramCache::Options options = MakeOptions(PathOf(directory));
  options.max_entry_bytes = 100;
  ProgramCache cache(options);
  Store(cache, MakeKey('a'), MakeValue(101, 7));
  Store(cache, MakeKey('b'), {});
  Store(cache, MakeKey('c'), MakeValue(100, 7));
  EXPECT_EQ(Load(cache, MakeKey('a')), std::nullopt);
  EXPECT_EQ(Load(cache, MakeKey('b')), std::nullopt);
  EXPECT_EQ(Load(cache, MakeKey('c')), MakeValue(100, 7));
}

TEST(ProgramCacheTest, LongKeysAreHashedIntoTheFileName) {
  TemporaryFolder directory;
  ProgramCache cache(MakeOptions(PathOf(directory)));
  const std::string key(100, 'k');
  Store(cache, key, MakeValue(50, 8));
  EXPECT_EQ(ProgramCache::EntryFileName(key).size(), 21u);
  EXPECT_EQ(Load(cache, key), MakeValue(50, 8));
}

TEST(ProgramCacheTest, EvictsTheEntriesUsedLeastRecently) {
  TemporaryFolder directory;
  // An entry file holds a 24-byte header, the key and the value: 144 bytes.
  ProgramCache::Options options = MakeOptions(PathOf(directory));
  options.max_total_bytes = 300;
  {
    ProgramCache cache(options);
    Store(cache, MakeKey('a'), MakeValue(100, 9));
    Store(cache, MakeKey('b'), MakeValue(100, 9));
    SetLastWriteTime(EntryPath(cache, MakeKey('a')), Now() - kTicksPerDay / 2);
    SetLastWriteTime(EntryPath(cache, MakeKey('b')), Now() - kTicksPerDay / 4);
  }
  ProgramCache cache(options);
  Store(cache, MakeKey('c'), MakeValue(100, 9));
  EXPECT_EQ(Load(cache, MakeKey('a')), std::nullopt);
  EXPECT_TRUE(Load(cache, MakeKey('b')).has_value());
  EXPECT_TRUE(Load(cache, MakeKey('c')).has_value());
}

TEST(ProgramCacheTest, HitRefreshesTheTimeOfAnOldEntry) {
  TemporaryFolder directory;
  ProgramCache cache(MakeOptions(PathOf(directory)));
  Store(cache, MakeKey('a'), MakeValue(100, 10));
  Store(cache, MakeKey('b'), MakeValue(100, 10));
  const uint64_t two_days_ago = Now() - 2 * kTicksPerDay;
  const uint64_t hour_ago = Now() - kTicksPerDay / 24;
  SetLastWriteTime(EntryPath(cache, MakeKey('a')), two_days_ago);
  SetLastWriteTime(EntryPath(cache, MakeKey('b')), hour_ago);

  ASSERT_TRUE(Load(cache, MakeKey('a')).has_value());
  ASSERT_TRUE(Load(cache, MakeKey('b')).has_value());
  EXPECT_GT(LastWriteTime(EntryPath(cache, MakeKey('a'))),
            Now() - kTicksPerDay / 24);
  // Recent entries are not rewritten on every hit.
  EXPECT_EQ(LastWriteTime(EntryPath(cache, MakeKey('b'))), hour_ago);
}

TEST(ProgramCacheTest, VersionsHaveSeparateFolders) {
  TemporaryFolder directory;
  const std::filesystem::path root = PathOf(directory);
  std::filesystem::path old_folder;
  {
    ProgramCache cache(MakeOptions(root, "engine-a"));
    Store(cache, MakeKey('a'), MakeValue(100, 11));
    old_folder = cache.version_directory();
  }
  ProgramCache cache(MakeOptions(root, "engine-b"));
  EXPECT_NE(cache.version_directory().wstring(), old_folder.wstring());
  EXPECT_EQ(Load(cache, MakeKey('a')), std::nullopt);
  // The first write removes the other version's folder.
  Store(cache, MakeKey('b'), MakeValue(100, 11));
  EXPECT_FALSE(std::filesystem::exists(old_folder));
}

TEST(ProgramCacheTest, CleanupOnlyRemovesFilesThisCacheWrites) {
  TemporaryFolder directory;
  const std::filesystem::path root = PathOf(directory);
  const std::filesystem::path shared =
      root / fml::Utf8ToWideString(ProgramCache::VersionDirectoryName("x"));
  const std::filesystem::path other_version =
      root / fml::Utf8ToWideString(ProgramCache::VersionDirectoryName("y"));
  const std::filesystem::path unrelated = root / L"unrelated";
  for (const auto& folder : {shared, other_version, unrelated}) {
    std::filesystem::create_directories(folder);
    WriteFile(folder / L"0a1b.bin", "entry");
    WriteFile(folder / L"0a1b.bin.12-3.tmp", "temporary");
  }
  WriteFile(shared / L"notes.txt", "keep");

  ProgramCache cache(MakeOptions(root, "engine-a"));
  Store(cache, MakeKey('a'), MakeValue(100, 12));

  EXPECT_FALSE(std::filesystem::exists(other_version));
  EXPECT_FALSE(std::filesystem::exists(shared / L"0a1b.bin"));
  EXPECT_FALSE(std::filesystem::exists(shared / L"0a1b.bin.12-3.tmp"));
  EXPECT_TRUE(std::filesystem::exists(shared / L"notes.txt"));
  EXPECT_TRUE(std::filesystem::exists(unrelated / L"0a1b.bin"));
  EXPECT_TRUE(std::filesystem::exists(unrelated / L"0a1b.bin.12-3.tmp"));
}

TEST(ProgramCacheTest, RemovesStaleTemporaryFiles) {
  TemporaryFolder directory;
  const std::filesystem::path root = PathOf(directory);
  const std::filesystem::path folder =
      root / fml::Utf8ToWideString(ProgramCache::VersionDirectoryName("a"));
  std::filesystem::create_directories(folder);
  WriteFile(folder / L"0a.bin.1-1.tmp", "stale");
  WriteFile(folder / L"0b.bin.1-2.tmp", "in progress");
  SetLastWriteTime(folder / L"0a.bin.1-1.tmp", Now() - kTicksPerDay / 24);

  ProgramCache cache(MakeOptions(root, "a"));
  Store(cache, MakeKey('a'), MakeValue(100, 13));
  EXPECT_FALSE(std::filesystem::exists(folder / L"0a.bin.1-1.tmp"));
  EXPECT_TRUE(std::filesystem::exists(folder / L"0b.bin.1-2.tmp"));
}

TEST(ProgramCacheTest, ThreadsCanStoreAndLoadAtTheSameTime) {
  TemporaryFolder directory;
  ProgramCache::Options options = MakeOptions(PathOf(directory));
  options.write_in_background = true;
  ProgramCache cache(options);
  constexpr int kThreads = 4;
  std::vector<std::thread> threads;
  threads.reserve(kThreads);
  for (int t = 0; t < kThreads; t++) {
    threads.emplace_back([&cache, t] {
      for (int i = 0; i < 50; i++) {
        std::string key = MakeKey('a');
        key[0] = static_cast<char>(t);
        key[1] = static_cast<char>(i);
        Store(cache, key, MakeValue(200 + i, static_cast<uint8_t>(t)));
        EXPECT_EQ(Load(cache, key),
                  MakeValue(200 + i, static_cast<uint8_t>(t)));
      }
    });
  }
  for (auto& thread : threads) {
    thread.join();
  }
  cache.Flush();
  ProgramCache reopened(MakeOptions(PathOf(directory)));
  for (int t = 0; t < kThreads; t++) {
    for (int i = 0; i < 50; i++) {
      std::string key = MakeKey('a');
      key[0] = static_cast<char>(t);
      key[1] = static_cast<char>(i);
      EXPECT_EQ(Load(reopened, key),
                MakeValue(200 + i, static_cast<uint8_t>(t)));
    }
  }
}

TEST(ProgramCacheLocationTest, DefaultsToTheApplicationCacheFolder) {
  ProgramCacheLocation location;
  location.local_app_data = L"C:\\Users\\u\\AppData\\Local";
  location.company_name = L"ai.vibewall";
  location.product_name = L"vibewall";
  location.executable_stem = L"runner";
  EXPECT_EQ(Resolved(location),
            std::wstring(L"C:\\Users\\u\\AppData\\Local\\ai.vibewall"
                         L"\\vibewall\\flutter_program_cache"));
}

TEST(ProgramCacheLocationTest, FallsBackToTheExecutableName) {
  ProgramCacheLocation location;
  location.local_app_data = L"C:\\Local";
  location.executable_stem = L"app";
  EXPECT_EQ(Resolved(location),
            std::wstring(L"C:\\Local\\app\\flutter_program_cache"));
}

TEST(ProgramCacheLocationTest, SanitizesFolderNames) {
  ProgramCacheLocation location;
  location.local_app_data = L"C:\\Local";
  location.company_name = L"A<B>:C. ";
  location.product_name = L"P|Q?";
  EXPECT_EQ(Resolved(location), std::wstring(L"C:\\Local\\A_B__C\\P_Q_\\"
                                             L"flutter_program_cache"));
}

TEST(ProgramCacheLocationTest, UsesTheConfiguredPath) {
  ProgramCacheLocation location;
  location.local_app_data = L"C:\\Local";
  location.product_name = L"app";

  location.configured_path = L"D:\\cache";
  EXPECT_EQ(Resolved(location), std::wstring(L"D:\\cache"));

  location.configured_path = L"relative\\cache";
  EXPECT_EQ(Resolved(location), std::wstring(L"C:\\Local\\relative\\cache"));

  location.configured_path = L"";
  EXPECT_EQ(Resolved(location), L"<no cache>");
}

TEST(ProgramCacheLocationTest, SwitchOverridesTheConfiguredPath) {
  ProgramCacheLocation location;
  location.local_app_data = L"C:\\Local";
  location.product_name = L"app";
  location.configured_path = L"D:\\cache";

  location.switches = {"--enable-impeller", "--program-cache-path=E:\\test"};
  EXPECT_EQ(Resolved(location), std::wstring(L"E:\\test"));

  location.switches = {"--program-cache-path="};
  EXPECT_EQ(Resolved(location), L"<no cache>");
}

TEST(ProgramCacheLocationTest, NoDefaultWithoutTheLocalAppDataFolder) {
  ProgramCacheLocation location;
  location.product_name = L"app";
  EXPECT_EQ(Resolved(location), L"<no cache>");
}

}  // namespace testing
}  // namespace flutter
