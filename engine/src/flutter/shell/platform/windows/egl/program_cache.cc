// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/egl/program_cache.h"

#include <windows.h>

#include <knownfolders.h>
#include <shlobj.h>

#include <algorithm>
#include <atomic>
#include <cstdio>
#include <cstring>
#include <string_view>
#include <system_error>

#include "flutter/fml/logging.h"
#include "flutter/fml/platform/win/wstring_conversion.h"
#include "flutter/fml/trace_event.h"

namespace flutter {
namespace egl {

namespace {

// "FPC1" in file order.
constexpr uint32_t kFileMagic = 0x31435046;
constexpr uint32_t kFileFormatVersion = 1;

struct FileHeader {
  uint32_t magic = 0;
  uint32_t format_version = 0;
  uint32_t key_size = 0;
  uint32_t value_size = 0;
  // FNV-1a of the key and then the value.
  uint64_t checksum = 0;
};
static_assert(sizeof(FileHeader) == 24);

// ANGLE's keys are 20-byte hashes. Longer keys are hashed for the file name;
// the file still holds the whole key.
constexpr size_t kMaxHexKeyBytes = 32;
constexpr size_t kMaxKeyBytes = 1024;

// FILETIME counts 100-nanosecond intervals.
constexpr uint64_t kTicksPerSecond = 10'000'000;
// A temporary file this old belongs to a write that did not finish.
constexpr uint64_t kStaleTemporaryFileTicks = 10 * 60 * kTicksPerSecond;
// A hit refreshes the time of an entry older than this, which orders
// evictions by use without writing on every hit.
constexpr uint64_t kLastUsedGranularityTicks = 24 * 60 * 60 * kTicksPerSecond;

constexpr uint64_t kFnvOffset = 14695981039346656037ull;

uint64_t Fnv1a(uint64_t hash, const void* data, size_t size) {
  const auto* bytes = static_cast<const uint8_t*>(data);
  for (size_t i = 0; i < size; i++) {
    hash = (hash ^ bytes[i]) * 1099511628211ull;
  }
  return hash;
}

uint64_t Checksum(const std::string& key, const uint8_t* value, size_t size) {
  return Fnv1a(Fnv1a(kFnvOffset, key.data(), key.size()), value, size);
}

std::wstring Hex(const void* data, size_t size) {
  static constexpr wchar_t kDigits[] = L"0123456789abcdef";
  const auto* bytes = static_cast<const uint8_t*>(data);
  std::wstring hex;
  hex.reserve(size * 2);
  for (size_t i = 0; i < size; i++) {
    hex.push_back(kDigits[bytes[i] >> 4]);
    hex.push_back(kDigits[bytes[i] & 0xf]);
  }
  return hex;
}

std::wstring Hex64(uint64_t value) {
  wchar_t text[17];
  swprintf_s(text, L"%016llx", value);
  return text;
}

bool IsLowerHex(std::wstring_view text) {
  return !text.empty() && std::all_of(text.begin(), text.end(), [](wchar_t c) {
    return (c >= L'0' && c <= L'9') || (c >= L'a' && c <= L'f');
  });
}

// "<hex key>.bin" or "h<hex hash>.bin".
bool IsEntryFileName(std::wstring_view name) {
  constexpr std::wstring_view kExtension = L".bin";
  if (!name.ends_with(kExtension)) {
    return false;
  }
  std::wstring_view stem = name.substr(0, name.size() - kExtension.size());
  if (stem.starts_with(L'h')) {
    stem.remove_prefix(1);
  }
  return IsLowerHex(stem);
}

// "<entry file name>.<process id>-<counter>.tmp".
bool IsTemporaryFileName(std::wstring_view name) {
  if (!name.ends_with(L".tmp")) {
    return false;
  }
  const size_t entry_end = name.find(L".bin.");
  return entry_end != std::wstring_view::npos &&
         IsEntryFileName(name.substr(0, entry_end + 4));
}

// "v1-<16 hex digits>".
bool IsVersionDirectoryName(std::wstring_view name) {
  return name.size() == 19 && name.starts_with(L"v1-") &&
         IsLowerHex(name.substr(3));
}

uint64_t ToTicks(const FILETIME& time) {
  return (static_cast<uint64_t>(time.dwHighDateTime) << 32) |
         time.dwLowDateTime;
}

uint64_t NowTicks() {
  FILETIME now;
  ::GetSystemTimeAsFileTime(&now);
  return ToTicks(now);
}

// Calls |visit| for each item in |directory|, except "." and "..".
template <typename Visit>
void ForEachItem(const std::filesystem::path& directory, Visit visit) {
  WIN32_FIND_DATAW data;
  HANDLE find = ::FindFirstFileExW((directory / L"*").c_str(), FindExInfoBasic,
                                   &data, FindExSearchNameMatch, nullptr, 0);
  if (find == INVALID_HANDLE_VALUE) {
    return;
  }
  do {
    const std::wstring_view name = data.cFileName;
    if (name != L"." && name != L"..") {
      visit(data);
    }
  } while (::FindNextFileW(find, &data));
  ::FindClose(find);
}

bool WriteAll(HANDLE file, const void* data, size_t size) {
  const auto* bytes = static_cast<const uint8_t*>(data);
  while (size > 0) {
    DWORD written = 0;
    const DWORD chunk = static_cast<DWORD>(std::min<size_t>(size, 1 << 30));
    if (!::WriteFile(file, bytes, chunk, &written, nullptr) || written == 0) {
      return false;
    }
    bytes += written;
    size -= written;
  }
  return true;
}

bool ReadAll(HANDLE file, void* data, size_t size) {
  auto* bytes = static_cast<uint8_t*>(data);
  while (size > 0) {
    DWORD read = 0;
    const DWORD chunk = static_cast<DWORD>(std::min<size_t>(size, 1 << 30));
    if (!::ReadFile(file, bytes, chunk, &read, nullptr) || read == 0) {
      return false;
    }
    bytes += read;
    size -= read;
  }
  return true;
}

class ScopedHandle {
 public:
  explicit ScopedHandle(HANDLE handle) : handle_(handle) {}
  ~ScopedHandle() {
    if (is_valid()) {
      ::CloseHandle(handle_);
    }
  }
  bool is_valid() const { return handle_ != INVALID_HANDLE_VALUE; }
  HANDLE get() const { return handle_; }

 private:
  HANDLE handle_;

  FML_DISALLOW_COPY_AND_ASSIGN(ScopedHandle);
};

// Mirrors the folder names that Flutter's path_provider uses on Windows.
std::wstring SanitizeFolderName(std::wstring_view raw) {
  constexpr std::wstring_view kReserved = L"<>:\"/\\|?*";
  std::wstring name;
  for (wchar_t c : raw) {
    const bool reserved =
        c < 32 || kReserved.find(c) != std::wstring_view::npos;
    name.push_back(reserved ? L'_' : c);
  }
  // Windows removes trailing spaces and periods from folder names.
  while (!name.empty() && (name.back() == L' ' || name.back() == L'.')) {
    name.pop_back();
  }
  if (name.size() > 255) {
    name.resize(255);
  }
  return name;
}

std::wstring GetExecutablePath() {
  std::wstring path(MAX_PATH, L'\0');
  while (true) {
    const DWORD length = ::GetModuleFileNameW(nullptr, path.data(),
                                              static_cast<DWORD>(path.size()));
    if (length == 0) {
      return {};
    }
    if (length < path.size()) {
      path.resize(length);
      return path;
    }
    path.resize(path.size() * 2);
  }
}

// Reads CompanyName and ProductName from the first translation of the
// executable's version resource.
void ReadVersionStrings(const std::wstring& executable,
                        std::wstring* company,
                        std::wstring* product) {
  DWORD ignored = 0;
  const DWORD size = ::GetFileVersionInfoSizeW(executable.c_str(), &ignored);
  if (size == 0) {
    return;
  }
  std::vector<uint8_t> data(size);
  if (!::GetFileVersionInfoW(executable.c_str(), 0, size, data.data())) {
    return;
  }
  struct Translation {
    WORD language;
    WORD code_page;
  };
  Translation* translations = nullptr;
  UINT length = 0;
  if (!::VerQueryValueW(data.data(), L"\\VarFileInfo\\Translation",
                        reinterpret_cast<void**>(&translations), &length) ||
      length < sizeof(Translation)) {
    return;
  }
  auto query = [&](const wchar_t* name) -> std::wstring {
    wchar_t block[64];
    swprintf_s(block, L"\\StringFileInfo\\%04x%04x\\%s",
               translations[0].language, translations[0].code_page, name);
    wchar_t* value = nullptr;
    UINT value_length = 0;
    if (!::VerQueryValueW(data.data(), block, reinterpret_cast<void**>(&value),
                          &value_length) ||
        value == nullptr || value_length == 0) {
      return {};
    }
    return std::wstring(value, wcsnlen(value, value_length));
  };
  *company = query(L"CompanyName");
  *product = query(L"ProductName");
}

// The process's cache. Never destroyed, because ANGLE can call it until the
// process exits.
std::atomic<ProgramCache*> g_process_cache{nullptr};
std::mutex g_install_mutex;

void SetBlob(const void* key,
             EGLsizeiANDROID key_size,
             const void* value,
             EGLsizeiANDROID value_size) {
  if (ProgramCache* cache = g_process_cache.load(std::memory_order_acquire)) {
    cache->Set(key, key_size, value, value_size);
  }
}

EGLsizeiANDROID GetBlob(const void* key,
                        EGLsizeiANDROID key_size,
                        void* value,
                        EGLsizeiANDROID value_size) {
  if (ProgramCache* cache = g_process_cache.load(std::memory_order_acquire)) {
    return cache->Get(key, key_size, value, value_size);
  }
  return 0;
}

}  // namespace

ProgramCache::ProgramCache(Options options)
    : options_(std::move(options)),
      version_directory_(
          options_.directory /
          fml::Utf8ToWideString(VersionDirectoryName(options_.version))) {}

ProgramCache::~ProgramCache() {
  {
    std::lock_guard<std::mutex> lock(mutex_);
    stopping_ = true;
  }
  writer_wakeup_.notify_all();
  if (writer_.joinable()) {
    writer_.join();
  }
}

std::string ProgramCache::VersionDirectoryName(const std::string& version) {
  const uint64_t hash = Fnv1a(kFnvOffset, version.data(), version.size());
  return "v1-" + fml::WideStringToUtf8(Hex64(hash));
}

std::wstring ProgramCache::EntryFileName(const std::string& key) {
  if (key.size() <= kMaxHexKeyBytes) {
    return Hex(key.data(), key.size()) + L".bin";
  }
  return L"h" + Hex64(Fnv1a(kFnvOffset, key.data(), key.size())) + L".bin";
}

std::filesystem::path ProgramCache::EntryPath(const std::string& key) const {
  return version_directory_ / EntryFileName(key);
}

void ProgramCache::Set(const void* key,
                       EGLsizeiANDROID key_size,
                       const void* value,
                       EGLsizeiANDROID value_size) {
  if (key == nullptr || value == nullptr || key_size <= 0 || value_size <= 0 ||
      static_cast<size_t>(key_size) > kMaxKeyBytes ||
      static_cast<size_t>(value_size) > options_.max_entry_bytes) {
    return;
  }
  std::string key_bytes(static_cast<const char*>(key), key_size);
  const auto* value_bytes = static_cast<const uint8_t*>(value);
  auto data = std::make_shared<const std::vector<uint8_t>>(
      value_bytes, value_bytes + value_size);

  std::lock_guard<std::mutex> lock(mutex_);
  if (last_read_key_ == key_bytes) {
    last_read_key_.clear();
    last_read_value_.reset();
  }
  if (!options_.write_in_background) {
    WriteEntry(key_bytes, *data);
    return;
  }
  // A dropped write is compiled and offered again on a later launch.
  if (stopping_ || queued_bytes_ + data->size() > kMaxQueuedBytes) {
    return;
  }
  queued_bytes_ += data->size();
  pending_[key_bytes] = data;
  queue_.push_back(PendingWrite{std::move(key_bytes), std::move(data)});
  if (!writer_.joinable()) {
    // Started on the first write, so a launch that only reads has no thread.
    writer_ = std::thread([this] { WriterLoop(); });
  }
  writer_wakeup_.notify_one();
}

EGLsizeiANDROID ProgramCache::Get(const void* key,
                                  EGLsizeiANDROID key_size,
                                  void* value,
                                  EGLsizeiANDROID value_size) {
  if (key == nullptr || key_size <= 0 ||
      static_cast<size_t>(key_size) > kMaxKeyBytes) {
    return 0;
  }
  std::string key_bytes(static_cast<const char*>(key), key_size);

  std::lock_guard<std::mutex> lock(mutex_);
  const std::vector<uint8_t>* found = nullptr;
  bool from_last_read = false;
  if (auto pending = pending_.find(key_bytes); pending != pending_.end()) {
    found = pending->second.get();
  } else {
    if (last_read_key_ != key_bytes || !last_read_value_.has_value()) {
      last_read_value_ = ReadEntry(key_bytes);
      last_read_key_ = last_read_value_.has_value() ? key_bytes : std::string();
    }
    if (last_read_value_.has_value()) {
      found = &last_read_value_.value();
      from_last_read = true;
    }
  }
  if (found == nullptr) {
    return 0;
  }
  const auto size = static_cast<EGLsizeiANDROID>(found->size());
  if (value != nullptr && value_size >= size) {
    std::memcpy(value, found->data(), found->size());
    if (from_last_read) {
      // The pair is complete; release the copy.
      last_read_key_.clear();
      last_read_value_.reset();
    }
  }
  return size;
}

void ProgramCache::Flush() {
  std::unique_lock<std::mutex> lock(mutex_);
  writes_done_.wait(lock, [this] { return queue_.empty() && !writing_; });
}

std::optional<std::vector<uint8_t>> ProgramCache::ReadEntry(
    const std::string& key) const {
  TRACE_EVENT0("flutter", "ProgramCache::Load");
  const std::filesystem::path path = EntryPath(key);
  // Readers never block a writer that replaces the entry or evicts it.
  constexpr DWORD kShare =
      FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE;
  bool can_modify = true;
  HANDLE handle = ::CreateFileW(
      path.c_str(), GENERIC_READ | FILE_WRITE_ATTRIBUTES | DELETE, kShare,
      nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (handle == INVALID_HANDLE_VALUE &&
      ::GetLastError() == ERROR_ACCESS_DENIED) {
    can_modify = false;
    handle = ::CreateFileW(path.c_str(), GENERIC_READ, kShare, nullptr,
                           OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
  }
  ScopedHandle file(handle);
  if (!file.is_valid()) {
    return std::nullopt;
  }

  LARGE_INTEGER file_size = {};
  FileHeader header;
  const uint64_t smallest = sizeof(FileHeader) + key.size();
  bool valid =
      ::GetFileSizeEx(file.get(), &file_size) &&
      static_cast<uint64_t>(file_size.QuadPart) >= smallest &&
      static_cast<uint64_t>(file_size.QuadPart) <=
          smallest + options_.max_entry_bytes &&
      ReadAll(file.get(), &header, sizeof(header)) &&
      header.magic == kFileMagic &&
      header.format_version == kFileFormatVersion &&
      header.key_size == key.size() &&
      smallest + header.value_size == static_cast<uint64_t>(file_size.QuadPart);

  std::optional<std::vector<uint8_t>> value;
  if (valid) {
    std::string stored_key(key.size(), '\0');
    std::vector<uint8_t> data(header.value_size);
    valid = ReadAll(file.get(), stored_key.data(), stored_key.size()) &&
            stored_key == key &&
            ReadAll(file.get(), data.data(), data.size()) &&
            Checksum(key, data.data(), data.size()) == header.checksum;
    if (valid) {
      value = std::move(data);
    }
  }

  if (!valid) {
    if (can_modify) {
      // Deletes this file, even if a writer has since given its name to a
      // new entry.
      FILE_DISPOSITION_INFO disposition = {TRUE};
      ::SetFileInformationByHandle(file.get(), FileDispositionInfo,
                                   &disposition, sizeof(disposition));
    }
    return std::nullopt;
  }

  FILETIME written;
  const uint64_t now = NowTicks();
  if (can_modify && ::GetFileTime(file.get(), nullptr, nullptr, &written) &&
      now > ToTicks(written) &&
      now - ToTicks(written) > kLastUsedGranularityTicks) {
    FILETIME now_time = {static_cast<DWORD>(now),
                         static_cast<DWORD>(now >> 32)};
    ::SetFileTime(file.get(), nullptr, nullptr, &now_time);
  }
  TRACE_EVENT_INSTANT0("flutter", "ProgramCache hit");
  return value;
}

void ProgramCache::WriteEntry(const std::string& key,
                              const std::vector<uint8_t>& value) {
  TRACE_EVENT0("flutter", "ProgramCache::Store");
  if (!prepared_) {
    PrepareDirectory();
    prepared_ = true;
  }
  const std::wstring name = EntryFileName(key);
  const std::filesystem::path path = version_directory_ / name;
  const std::filesystem::path temporary =
      version_directory_ /
      (name + L"." + std::to_wstring(::GetCurrentProcessId()) + L"-" +
       std::to_wstring(++temporary_file_counter_) + L".tmp");

  FileHeader header;
  header.magic = kFileMagic;
  header.format_version = kFileFormatVersion;
  header.key_size = static_cast<uint32_t>(key.size());
  header.value_size = static_cast<uint32_t>(value.size());
  header.checksum = Checksum(key, value.data(), value.size());

  bool written = false;
  {
    ScopedHandle file(::CreateFileW(temporary.c_str(), GENERIC_WRITE, 0,
                                    nullptr, CREATE_NEW, FILE_ATTRIBUTE_NORMAL,
                                    nullptr));
    if (!file.is_valid()) {
      return;
    }
    written = WriteAll(file.get(), &header, sizeof(header)) &&
              WriteAll(file.get(), key.data(), key.size()) &&
              WriteAll(file.get(), value.data(), value.size());
  }
  // The rename replaces an entry in one step, so a reader sees the old file
  // or the new one, never a partial one.
  if (!written || !::MoveFileExW(temporary.c_str(), path.c_str(),
                                 MOVEFILE_REPLACE_EXISTING)) {
    ::DeleteFileW(temporary.c_str());
    return;
  }

  const uint64_t size = sizeof(header) + key.size() + value.size();
  if (auto existing = index_.find(name); existing != index_.end()) {
    total_bytes_ -= existing->second.size;
  }
  index_[name] = Entry{size, NowTicks()};
  total_bytes_ += size;
  EvictIfNeeded();
}

void ProgramCache::PrepareDirectory() {
  std::error_code error;
  std::filesystem::create_directories(version_directory_, error);

  // Folders that other engine versions left behind. Only files this cache
  // writes are deleted, and a folder only once it is empty, so a folder that
  // holds anything else is kept.
  const std::wstring own_name = version_directory_.filename().wstring();
  ForEachItem(options_.directory, [&](const WIN32_FIND_DATAW& item) {
    const std::wstring_view name = item.cFileName;
    if ((item.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == 0 ||
        (item.dwFileAttributes & FILE_ATTRIBUTE_REPARSE_POINT) != 0 ||
        name == own_name || !IsVersionDirectoryName(name)) {
      return;
    }
    const std::filesystem::path old_directory = options_.directory / name;
    ForEachItem(old_directory, [&](const WIN32_FIND_DATAW& file) {
      if ((file.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == 0 &&
          (IsEntryFileName(file.cFileName) ||
           IsTemporaryFileName(file.cFileName))) {
        ::DeleteFileW((old_directory / file.cFileName).c_str());
      }
    });
    ::RemoveDirectoryW(old_directory.c_str());
  });

  const uint64_t now = NowTicks();
  ForEachItem(version_directory_, [&](const WIN32_FIND_DATAW& file) {
    if ((file.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
      return;
    }
    const std::wstring name = file.cFileName;
    const uint64_t modified = ToTicks(file.ftLastWriteTime);
    if (IsTemporaryFileName(name)) {
      if (now > modified && now - modified > kStaleTemporaryFileTicks) {
        ::DeleteFileW((version_directory_ / name).c_str());
      }
      return;
    }
    if (!IsEntryFileName(name)) {
      return;
    }
    const uint64_t size =
        (static_cast<uint64_t>(file.nFileSizeHigh) << 32) | file.nFileSizeLow;
    index_[name] = Entry{size, modified};
    total_bytes_ += size;
  });
  EvictIfNeeded();
}

void ProgramCache::EvictIfNeeded() {
  while (total_bytes_ > options_.max_total_bytes && !index_.empty()) {
    auto oldest = std::min_element(
        index_.begin(), index_.end(), [](const auto& a, const auto& b) {
          return a.second.last_used < b.second.last_used;
        });
    ::DeleteFileW((version_directory_ / oldest->first).c_str());
    total_bytes_ -= oldest->second.size;
    index_.erase(oldest);
  }
}

void ProgramCache::WriterLoop() {
  std::unique_lock<std::mutex> lock(mutex_);
  while (true) {
    writer_wakeup_.wait(lock, [this] { return stopping_ || !queue_.empty(); });
    if (queue_.empty()) {
      return;
    }
    PendingWrite write = std::move(queue_.front());
    queue_.pop_front();
    writing_ = true;
    lock.unlock();
    WriteEntry(write.key, *write.value);
    lock.lock();
    writing_ = false;
    queued_bytes_ -= write.value->size();
    if (auto found = pending_.find(write.key);
        found != pending_.end() && found->second == write.value) {
      pending_.erase(found);
    }
    if (queue_.empty()) {
      writes_done_.notify_all();
    }
  }
}

bool ProgramCache::InstallForDisplay(EGLDisplay display,
                                     std::unique_ptr<ProgramCache> cache) {
  const char* extensions = ::eglQueryString(display, EGL_EXTENSIONS);
  if (extensions == nullptr ||
      std::strstr(extensions, "EGL_ANDROID_blob_cache") == nullptr) {
    return false;
  }
  const auto set_blob_cache_funcs =
      reinterpret_cast<PFNEGLSETBLOBCACHEFUNCSANDROIDPROC>(
          ::eglGetProcAddress("eglSetBlobCacheFuncsANDROID"));
  if (set_blob_cache_funcs == nullptr) {
    return false;
  }
  {
    std::lock_guard<std::mutex> lock(g_install_mutex);
    if (g_process_cache.load(std::memory_order_acquire) == nullptr) {
      g_process_cache.store(cache.release(), std::memory_order_release);
    }
  }
  set_blob_cache_funcs(display, &SetBlob, &GetBlob);
  // EGL_BAD_PARAMETER means another engine in this process already set the
  // functions for this display, and they use the same cache.
  const EGLint error = ::eglGetError();
  return error == EGL_SUCCESS || error == EGL_BAD_PARAMETER;
}

std::optional<std::filesystem::path> ProgramCacheLocation::Resolve() const {
  std::optional<std::wstring> path = configured_path;
  constexpr std::string_view kSwitch = "--program-cache-path=";
  for (const std::string& value : switches) {
    if (value.starts_with(kSwitch)) {
      path =
          fml::Utf8ToWideString(std::string_view(value).substr(kSwitch.size()));
    }
  }
  if (path.has_value()) {
    if (path->empty()) {
      return std::nullopt;
    }
    const std::filesystem::path folder(*path);
    if (folder.is_absolute()) {
      return folder;
    }
    if (local_app_data.empty()) {
      return std::nullopt;
    }
    return local_app_data / folder;
  }

  if (local_app_data.empty()) {
    return std::nullopt;
  }
  std::wstring product = SanitizeFolderName(product_name);
  if (product.empty()) {
    product = SanitizeFolderName(executable_stem);
  }
  if (product.empty()) {
    return std::nullopt;
  }
  std::filesystem::path folder = local_app_data;
  if (const std::wstring company = SanitizeFolderName(company_name);
      !company.empty()) {
    folder /= company;
  }
  return folder / product / L"flutter_program_cache";
}

ProgramCacheLocation ProgramCacheLocation::ForCurrentProcess(
    std::optional<std::wstring> configured_path,
    std::vector<std::string> switches) {
  ProgramCacheLocation location;
  location.configured_path = std::move(configured_path);
  location.switches = std::move(switches);

  PWSTR local_app_data = nullptr;
  if (SUCCEEDED(::SHGetKnownFolderPath(FOLDERID_LocalAppData, KF_FLAG_DEFAULT,
                                       nullptr, &local_app_data))) {
    location.local_app_data = local_app_data;
  }
  ::CoTaskMemFree(local_app_data);

  const std::wstring executable = GetExecutablePath();
  location.executable_stem = std::filesystem::path(executable).stem().wstring();
  ReadVersionStrings(executable, &location.company_name,
                     &location.product_name);
  return location;
}

}  // namespace egl
}  // namespace flutter
