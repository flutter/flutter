// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_OS_LIBRARY_LOADER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_OS_LIBRARY_LOADER_H_

#include <cstdint>
#include <memory>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

#include "flutter/fml/macros.h"

namespace flutter {
namespace android {

/// @brief Abstract interface representing a loaded dynamic shared library.
///
/// This abstraction shields callers from direct platform-specific handles
/// (such as dlopen void* or Windows HMODULE) and allows in-memory mock symbol
/// tables during host tests.
class OSLibrary {
 public:
  virtual ~OSLibrary() = default;

  /// @brief Returns the name or path of the library.
  virtual const std::string& GetName() const = 0;

  /// @brief Resolves a symbol from this library.
  /// @param symbol_name The name of the symbol/function to look up.
  /// @return Pointer to the resolved symbol, or nullptr if resolution failed.
  virtual void* ResolveSymbol(const char* symbol_name) const = 0;

  /// @brief Type-safe template helper to resolve function pointers.
  template <typename T>
  T ResolveFunction(const char* symbol_name) const {
    return reinterpret_cast<T>(ResolveSymbol(symbol_name));
  }

  /// @brief Returns true if the library was loaded successfully and is valid.
  virtual bool IsValid() const = 0;
};

/// @brief Abstract interface for loading and managing shared libraries at
/// runtime.
///
/// Enables host tests (macOS, Linux, Windows) to run without linking or loading
/// Android-specific shared libraries (such as libandroid.so or libEGL.so) by
/// providing virtualized symbol resolution and mock library injection.
class OSLibraryLoader {
 public:
  virtual ~OSLibraryLoader() = default;

  /// @brief Loads or retrieves a shared library by name.
  /// @param library_name Name or path of the library (e.g., "libandroid.so").
  /// @return Shared pointer to the OSLibrary instance, or nullptr on failure.
  virtual std::shared_ptr<OSLibrary> LoadDynamicLibrary(
      const char* library_name) = 0;

  /// @brief Resolves a symbol directly from a specified library.
  /// @param library_name Name of the library containing the symbol.
  /// @param symbol_name Name of the symbol to resolve.
  /// @return Pointer to the resolved symbol, or nullptr if unavailable.
  virtual void* ResolveSymbol(const char* library_name,
                              const char* symbol_name) = 0;

  /// @brief Type-safe template helper to resolve function pointers directly.
  template <typename T>
  T ResolveFunction(const char* library_name, const char* symbol_name) {
    return reinterpret_cast<T>(ResolveSymbol(library_name, symbol_name));
  }

  /// @brief Checks if a library is currently loaded and available.
  virtual bool IsLibraryLoaded(const char* library_name) const = 0;
};

/// @brief Default platform dynamic library implementation using dlopen / dlsym
/// / dlclose.
class DefaultOSLibrary : public OSLibrary {
 public:
  explicit DefaultOSLibrary(std::string name);
  DefaultOSLibrary(std::string name, void* handle, bool owns_handle);
  ~DefaultOSLibrary() override;

  const std::string& GetName() const override;
  void* ResolveSymbol(const char* symbol_name) const override;
  bool IsValid() const override;

 private:
  std::string name_;
  void* handle_ = nullptr;
  bool owns_handle_ = true;

  FML_DISALLOW_COPY_AND_ASSIGN(DefaultOSLibrary);
};

/// @brief Default dynamic loader implementation managing OS-level dynamic
/// libraries.
class DefaultOSLibraryLoader : public OSLibraryLoader {
 public:
  DefaultOSLibraryLoader();
  ~DefaultOSLibraryLoader() override;

  std::shared_ptr<OSLibrary> LoadDynamicLibrary(
      const char* library_name) override;
  void* ResolveSymbol(const char* library_name,
                      const char* symbol_name) override;
  bool IsLibraryLoaded(const char* library_name) const override;

 private:
  mutable std::mutex mutex_;
  std::unordered_map<std::string, std::shared_ptr<OSLibrary>> loaded_libraries_;

  FML_DISALLOW_COPY_AND_ASSIGN(DefaultOSLibraryLoader);
};

/// @brief In-memory mock library for host tests and deterministic symbol
/// injection.
class MockOSLibrary : public OSLibrary {
 public:
  explicit MockOSLibrary(std::string name);
  ~MockOSLibrary() override;

  const std::string& GetName() const override;
  void* ResolveSymbol(const char* symbol_name) const override;
  bool IsValid() const override;

  /// @brief Sets whether this mock library should report as valid.
  void SetValid(bool valid);

  /// @brief Injects a mock function or symbol pointer into this library.
  void SetSymbol(const std::string& symbol_name, void* symbol_ptr);

  /// @brief Removes a mock symbol from this library.
  void RemoveSymbol(const std::string& symbol_name);

  /// @brief Clears all injected symbols.
  void ClearSymbols();

 private:
  std::string name_;
  bool is_valid_ = true;
  mutable std::mutex mutex_;
  std::unordered_map<std::string, void*> symbols_;

  FML_DISALLOW_COPY_AND_ASSIGN(MockOSLibrary);
};

/// @brief Mock dynamic library loader for unit tests and host simulation.
class MockOSLibraryLoader : public OSLibraryLoader {
 public:
  MockOSLibraryLoader();
  ~MockOSLibraryLoader() override;

  std::shared_ptr<OSLibrary> LoadDynamicLibrary(
      const char* library_name) override;
  void* ResolveSymbol(const char* library_name,
                      const char* symbol_name) override;
  bool IsLibraryLoaded(const char* library_name) const override;

  /// @brief Registers a mock library instance under a given name.
  void RegisterLibrary(const std::string& library_name,
                       std::shared_ptr<OSLibrary> library);

  /// @brief Injects a mock symbol directly under a library name (auto-creating
  /// MockOSLibrary if needed).
  void SetSymbol(const std::string& library_name,
                 const std::string& symbol_name,
                 void* symbol_ptr);

  /// @brief Unregisters and removes a mock library.
  void UnregisterLibrary(const std::string& library_name);

  /// @brief Clears all registered mock libraries.
  void ClearLibraries();

 private:
  mutable std::mutex mutex_;
  std::unordered_map<std::string, std::shared_ptr<OSLibrary>> libraries_;

  FML_DISALLOW_COPY_AND_ASSIGN(MockOSLibraryLoader);
};

}  // namespace android
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_OS_LIBRARY_LOADER_H_
