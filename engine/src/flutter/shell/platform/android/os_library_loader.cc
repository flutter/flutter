// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/os_library_loader.h"

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

#if defined(_WIN32)
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#else
#include <dlfcn.h>
#endif

namespace flutter {
namespace android {

// =============================================================================
// DefaultOSLibrary Implementation
// =============================================================================

DefaultOSLibrary::DefaultOSLibrary(std::string name) : name_(std::move(name)) {
  TRACE_EVENT1("flutter", "DefaultOSLibrary::DefaultOSLibrary", "name",
               name_.c_str());
#if defined(_WIN32)
  if (name_.empty()) {
    handle_ = reinterpret_cast<void*>(GetModuleHandleW(nullptr));
    owns_handle_ = false;
  } else {
    int wlen = MultiByteToWideChar(CP_UTF8, 0, name_.c_str(), -1, nullptr, 0);
    if (wlen > 1) {
      std::wstring wname(wlen - 1, L'\0');
      MultiByteToWideChar(CP_UTF8, 0, name_.c_str(), -1, &wname[0], wlen);
      handle_ = reinterpret_cast<void*>(LoadLibraryW(wname.c_str()));
    }
  }
#else
  const char* dl_path = name_.empty() ? nullptr : name_.c_str();
  handle_ = dlopen(dl_path, RTLD_LAZY | RTLD_LOCAL);
  if (name_.empty()) {
    owns_handle_ = false;
  }
#endif
  if (!handle_) {
#if defined(_WIN32)
    DWORD error = GetLastError();
    FML_DLOG(INFO) << "DefaultOSLibrary: Failed to open dynamic library '"
                   << name_ << "', GetLastError=" << error;
#else
    [[maybe_unused]] const char* error = dlerror();
    FML_DLOG(INFO) << "DefaultOSLibrary: Failed to open dynamic library '"
                   << name_ << "': " << (error ? error : "unknown error");
#endif
  }
}

DefaultOSLibrary::DefaultOSLibrary(std::string name,
                                   void* handle,
                                   bool owns_handle)
    : name_(std::move(name)), handle_(handle), owns_handle_(owns_handle) {
  TRACE_EVENT1("flutter", "DefaultOSLibrary::DefaultOSLibrary(handle)", "name",
               name_.c_str());
}

DefaultOSLibrary::~DefaultOSLibrary() {
  TRACE_EVENT1("flutter", "DefaultOSLibrary::~DefaultOSLibrary", "name",
               name_.c_str());
  if (handle_ && owns_handle_) {
#if defined(_WIN32)
    FreeLibrary(reinterpret_cast<HMODULE>(handle_));
#else
    dlclose(handle_);
#endif
    handle_ = nullptr;
  }
}

const std::string& DefaultOSLibrary::GetName() const {
  return name_;
}

void* DefaultOSLibrary::ResolveSymbol(const char* symbol_name) const {
  TRACE_EVENT2("flutter", "DefaultOSLibrary::ResolveSymbol", "library",
               name_.c_str(), "symbol", symbol_name ? symbol_name : "<null>");
  if (!handle_ || !symbol_name) {
    return nullptr;
  }
#if defined(_WIN32)
  void* sym = reinterpret_cast<void*>(
      GetProcAddress(reinterpret_cast<HMODULE>(handle_), symbol_name));
  if (!sym) {
    DWORD error = GetLastError();
    FML_DLOG(INFO) << "DefaultOSLibrary: Symbol '" << symbol_name
                   << "' not found in library '" << name_
                   << "', GetLastError=" << error;
  }
#else
  dlerror();
  void* sym = dlsym(handle_, symbol_name);
  if (!sym) {
    [[maybe_unused]] const char* error = dlerror();
    FML_DLOG(INFO) << "DefaultOSLibrary: Symbol '" << symbol_name
                   << "' not found in library '" << name_
                   << "': " << (error ? error : "unknown error");
  }
#endif
  return sym;
}

bool DefaultOSLibrary::IsValid() const {
  return handle_ != nullptr;
}

// =============================================================================
// DefaultOSLibraryLoader Implementation
// =============================================================================

DefaultOSLibraryLoader::DefaultOSLibraryLoader() {
  TRACE_EVENT0("flutter", "DefaultOSLibraryLoader::DefaultOSLibraryLoader");
}

DefaultOSLibraryLoader::~DefaultOSLibraryLoader() {
  TRACE_EVENT0("flutter", "DefaultOSLibraryLoader::~DefaultOSLibraryLoader");
}

std::shared_ptr<OSLibrary> DefaultOSLibraryLoader::LoadDynamicLibrary(
    const char* library_name) {
  TRACE_EVENT1("flutter", "DefaultOSLibraryLoader::LoadDynamicLibrary", "name",
               library_name ? library_name : "<null>");
  if (!library_name) {
    return nullptr;
  }
  std::string key(library_name);
  {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = loaded_libraries_.find(key);
    if (it != loaded_libraries_.end()) {
      return it->second;
    }
  }

  // Perform expensive OS dynamic library loading outside application mutex
  // to eliminate AB-BA lock inversion hazards and dynamic linker
  // self-deadlocks.
  auto lib = std::make_shared<DefaultOSLibrary>(key);

  std::lock_guard<std::mutex> lock(mutex_);
  auto it = loaded_libraries_.find(key);
  if (it != loaded_libraries_.end()) {
    // Another thread loaded or negative-cached it while we were loading.
    return it->second;
  }

  if (!lib->IsValid()) {
    // Negative caching: store nullptr to prevent repeated disk I/O and dlopen
    // probes on the hot path for missing optional libraries.
    loaded_libraries_[key] = nullptr;
    return nullptr;
  }

  loaded_libraries_[key] = lib;
  return lib;
}

void* DefaultOSLibraryLoader::ResolveSymbol(const char* library_name,
                                            const char* symbol_name) {
  TRACE_EVENT2("flutter", "DefaultOSLibraryLoader::ResolveSymbol", "library",
               library_name ? library_name : "<null>", "symbol",
               symbol_name ? symbol_name : "<null>");
  if (!library_name || !symbol_name) {
    return nullptr;
  }
  auto lib = LoadDynamicLibrary(library_name);
  if (!lib) {
    return nullptr;
  }
  return lib->ResolveSymbol(symbol_name);
}

bool DefaultOSLibraryLoader::IsLibraryLoaded(const char* library_name) const {
  TRACE_EVENT1("flutter", "DefaultOSLibraryLoader::IsLibraryLoaded", "name",
               library_name ? library_name : "<null>");
  if (!library_name) {
    return false;
  }
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = loaded_libraries_.find(library_name);
  return it != loaded_libraries_.end() && it->second != nullptr &&
         it->second->IsValid();
}

// =============================================================================
// MockOSLibrary Implementation
// =============================================================================

MockOSLibrary::MockOSLibrary(std::string name) : name_(std::move(name)) {
  TRACE_EVENT1("flutter", "MockOSLibrary::MockOSLibrary", "name",
               name_.c_str());
}

MockOSLibrary::~MockOSLibrary() {
  TRACE_EVENT1("flutter", "MockOSLibrary::~MockOSLibrary", "name",
               name_.c_str());
}

const std::string& MockOSLibrary::GetName() const {
  return name_;
}

void* MockOSLibrary::ResolveSymbol(const char* symbol_name) const {
  TRACE_EVENT2("flutter", "MockOSLibrary::ResolveSymbol", "library",
               name_.c_str(), "symbol", symbol_name ? symbol_name : "<null>");
  if (!symbol_name || !is_valid_.load()) {
    return nullptr;
  }
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = symbols_.find(symbol_name);
  if (it != symbols_.end()) {
    return it->second;
  }
  return nullptr;
}

bool MockOSLibrary::IsValid() const {
  return is_valid_.load();
}

void MockOSLibrary::SetValid(bool valid) {
  TRACE_EVENT2("flutter", "MockOSLibrary::SetValid", "name", name_.c_str(),
               "valid", valid ? "true" : "false");
  is_valid_.store(valid);
}

void MockOSLibrary::SetSymbol(const std::string& symbol_name,
                              void* symbol_ptr) {
  TRACE_EVENT2("flutter", "MockOSLibrary::SetSymbol", "library", name_.c_str(),
               "symbol", symbol_name.c_str());
  std::lock_guard<std::mutex> lock(mutex_);
  symbols_[symbol_name] = symbol_ptr;
}

void MockOSLibrary::RemoveSymbol(const std::string& symbol_name) {
  TRACE_EVENT2("flutter", "MockOSLibrary::RemoveSymbol", "library",
               name_.c_str(), "symbol", symbol_name.c_str());
  std::lock_guard<std::mutex> lock(mutex_);
  symbols_.erase(symbol_name);
}

void MockOSLibrary::ClearSymbols() {
  TRACE_EVENT1("flutter", "MockOSLibrary::ClearSymbols", "library",
               name_.c_str());
  std::lock_guard<std::mutex> lock(mutex_);
  symbols_.clear();
}

// =============================================================================
// MockOSLibraryLoader Implementation
// =============================================================================

MockOSLibraryLoader::MockOSLibraryLoader() {
  TRACE_EVENT0("flutter", "MockOSLibraryLoader::MockOSLibraryLoader");
}

MockOSLibraryLoader::~MockOSLibraryLoader() {
  TRACE_EVENT0("flutter", "MockOSLibraryLoader::~MockOSLibraryLoader");
}

std::shared_ptr<OSLibrary> MockOSLibraryLoader::LoadDynamicLibrary(
    const char* library_name) {
  TRACE_EVENT1("flutter", "MockOSLibraryLoader::LoadDynamicLibrary", "name",
               library_name ? library_name : "<null>");
  if (!library_name) {
    return nullptr;
  }
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = libraries_.find(library_name);
  if (it != libraries_.end()) {
    return it->second;
  }
  return nullptr;
}

void* MockOSLibraryLoader::ResolveSymbol(const char* library_name,
                                         const char* symbol_name) {
  TRACE_EVENT2("flutter", "MockOSLibraryLoader::ResolveSymbol", "library",
               library_name ? library_name : "<null>", "symbol",
               symbol_name ? symbol_name : "<null>");
  if (!library_name || !symbol_name) {
    return nullptr;
  }
  auto lib = LoadDynamicLibrary(library_name);
  if (!lib) {
    return nullptr;
  }
  return lib->ResolveSymbol(symbol_name);
}

bool MockOSLibraryLoader::IsLibraryLoaded(const char* library_name) const {
  TRACE_EVENT1("flutter", "MockOSLibraryLoader::IsLibraryLoaded", "name",
               library_name ? library_name : "<null>");
  if (!library_name) {
    return false;
  }
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = libraries_.find(library_name);
  return it != libraries_.end() && it->second != nullptr &&
         it->second->IsValid();
}

void MockOSLibraryLoader::RegisterLibrary(const std::string& library_name,
                                          std::shared_ptr<OSLibrary> library) {
  TRACE_EVENT1("flutter", "MockOSLibraryLoader::RegisterLibrary", "name",
               library_name.c_str());
  if (!library) {
    return;
  }
  std::lock_guard<std::mutex> lock(mutex_);
  libraries_[library_name] = std::move(library);
}

void MockOSLibraryLoader::SetSymbol(const std::string& library_name,
                                    const std::string& symbol_name,
                                    void* symbol_ptr) {
  TRACE_EVENT2("flutter", "MockOSLibraryLoader::SetSymbol", "library",
               library_name.c_str(), "symbol", symbol_name.c_str());
  std::shared_ptr<MockOSLibrary> mock_lib;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = libraries_.find(library_name);
    if (it != libraries_.end() && it->second != nullptr) {
      if (it->second->AsMockOSLibrary() != nullptr) {
        mock_lib = std::static_pointer_cast<MockOSLibrary>(it->second);
      }
    }
    if (!mock_lib) {
      mock_lib = std::make_shared<MockOSLibrary>(library_name);
      libraries_[library_name] = mock_lib;
    }
  }
  mock_lib->SetSymbol(symbol_name, symbol_ptr);
}

void MockOSLibraryLoader::UnregisterLibrary(const std::string& library_name) {
  TRACE_EVENT1("flutter", "MockOSLibraryLoader::UnregisterLibrary", "name",
               library_name.c_str());
  std::lock_guard<std::mutex> lock(mutex_);
  libraries_.erase(library_name);
}

void MockOSLibraryLoader::ClearLibraries() {
  TRACE_EVENT0("flutter", "MockOSLibraryLoader::ClearLibraries");
  std::lock_guard<std::mutex> lock(mutex_);
  libraries_.clear();
}

}  // namespace android
}  // namespace flutter
