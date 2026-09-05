// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/os_library_loader.h"

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

#if defined(_WIN32)
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
  handle_ = reinterpret_cast<void*>(LoadLibraryA(name_.c_str()));
#else
  handle_ = dlopen(name_.c_str(), RTLD_LAZY | RTLD_LOCAL);
#endif
  if (!handle_) {
    FML_DLOG(INFO) << "DefaultOSLibrary: Failed to open dynamic library '"
                   << name_ << "'";
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
#else
  void* sym = dlsym(handle_, symbol_name);
#endif
  if (!sym) {
    FML_DLOG(INFO) << "DefaultOSLibrary: Symbol '" << symbol_name
                   << "' not found in library '" << name_ << "'";
  }
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
  std::lock_guard<std::mutex> lock(mutex_);
  std::string key(library_name);
  auto it = loaded_libraries_.find(key);
  if (it != loaded_libraries_.end()) {
    return it->second;
  }
  auto lib = std::make_shared<DefaultOSLibrary>(key);
  if (!lib->IsValid()) {
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
  return loaded_libraries_.find(library_name) != loaded_libraries_.end();
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
  if (!symbol_name || !is_valid_) {
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
  return is_valid_;
}

void MockOSLibrary::SetValid(bool valid) {
  TRACE_EVENT2("flutter", "MockOSLibrary::SetValid", "name", name_.c_str(),
               "valid", valid ? "true" : "false");
  is_valid_ = valid;
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
  return libraries_.find(library_name) != libraries_.end();
}

void MockOSLibraryLoader::RegisterLibrary(const std::string& library_name,
                                          std::shared_ptr<OSLibrary> library) {
  TRACE_EVENT1("flutter", "MockOSLibraryLoader::RegisterLibrary", "name",
               library_name.c_str());
  std::lock_guard<std::mutex> lock(mutex_);
  libraries_[library_name] = std::move(library);
}

void MockOSLibraryLoader::SetSymbol(const std::string& library_name,
                                    const std::string& symbol_name,
                                    void* symbol_ptr) {
  TRACE_EVENT2("flutter", "MockOSLibraryLoader::SetSymbol", "library",
               library_name.c_str(), "symbol", symbol_name.c_str());
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = libraries_.find(library_name);
  std::shared_ptr<MockOSLibrary> mock_lib;
  if (it != libraries_.end()) {
    mock_lib = std::static_pointer_cast<MockOSLibrary>(it->second);
  }
  if (!mock_lib) {
    mock_lib = std::make_shared<MockOSLibrary>(library_name);
    libraries_[library_name] = mock_lib;
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
