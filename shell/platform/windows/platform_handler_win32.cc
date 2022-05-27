// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/platform_handler_win32.h"

#include <windows.h>

#include <cstring>
#include <iostream>
#include <optional>

#include "flutter/fml/platform/win/wstring_conversion.h"
#include "flutter/shell/platform/windows/flutter_windows_view.h"

static constexpr char kValueKey[] = "value";
static constexpr int kAccessDeniedErrorCode = 5;
static constexpr int kErrorSuccess = 0;

namespace flutter {

namespace {

// A scoped wrapper for GlobalAlloc/GlobalFree.
class ScopedGlobalMemory {
 public:
  // Allocates |bytes| bytes of global memory with the given flags.
  ScopedGlobalMemory(unsigned int flags, size_t bytes) {
    memory_ = ::GlobalAlloc(flags, bytes);
    if (!memory_) {
      std::cerr << "Unable to allocate global memory: " << ::GetLastError();
    }
  }

  ~ScopedGlobalMemory() {
    if (memory_) {
      if (::GlobalFree(memory_) != nullptr) {
        std::cerr << "Failed to free global allocation: " << ::GetLastError();
      }
    }
  }

  // Prevent copying.
  ScopedGlobalMemory(ScopedGlobalMemory const&) = delete;
  ScopedGlobalMemory& operator=(ScopedGlobalMemory const&) = delete;

  // Returns the memory pointer, which will be nullptr if allocation failed.
  void* get() { return memory_; }

  void* release() {
    void* memory = memory_;
    memory_ = nullptr;
    return memory;
  }

 private:
  HGLOBAL memory_;
};

// A scoped wrapper for GlobalLock/GlobalUnlock.
class ScopedGlobalLock {
 public:
  // Attempts to acquire a global lock on |memory| for the life of this object.
  ScopedGlobalLock(HGLOBAL memory) {
    source_ = memory;
    if (memory) {
      locked_memory_ = ::GlobalLock(memory);
      if (!locked_memory_) {
        std::cerr << "Unable to acquire global lock: " << ::GetLastError();
      }
    }
  }

  ~ScopedGlobalLock() {
    if (locked_memory_) {
      if (!::GlobalUnlock(source_)) {
        DWORD error = ::GetLastError();
        if (error != NO_ERROR) {
          std::cerr << "Unable to release global lock: " << ::GetLastError();
        }
      }
    }
  }

  // Prevent copying.
  ScopedGlobalLock(ScopedGlobalLock const&) = delete;
  ScopedGlobalLock& operator=(ScopedGlobalLock const&) = delete;

  // Returns the locked memory pointer, which will be nullptr if acquiring the
  // lock failed.
  void* get() { return locked_memory_; }

 private:
  HGLOBAL source_;
  void* locked_memory_;
};

// A Clipboard wrapper that automatically closes the clipboard when it goes out
// of scope.
class ScopedClipboard : public ScopedClipboardInterface {
 public:
  ScopedClipboard();
  virtual ~ScopedClipboard();

  // Prevent copying.
  ScopedClipboard(ScopedClipboard const&) = delete;
  ScopedClipboard& operator=(ScopedClipboard const&) = delete;

  int Open(HWND window) override;

  bool HasString() override;

  std::variant<std::wstring, int> GetString() override;

  int SetString(const std::wstring string) override;

 private:
  bool opened_ = false;
};

ScopedClipboard::ScopedClipboard() {}

ScopedClipboard::~ScopedClipboard() {
  if (opened_) {
    ::CloseClipboard();
  }
}

int ScopedClipboard::Open(HWND window) {
  opened_ = ::OpenClipboard(window);

  if (!opened_) {
    return ::GetLastError();
  }

  return kErrorSuccess;
}

bool ScopedClipboard::HasString() {
  // Allow either plain text format, since getting data will auto-interpolate.
  return ::IsClipboardFormatAvailable(CF_UNICODETEXT) ||
         ::IsClipboardFormatAvailable(CF_TEXT);
}

std::variant<std::wstring, int> ScopedClipboard::GetString() {
  assert(opened_);

  HANDLE data = ::GetClipboardData(CF_UNICODETEXT);
  if (data == nullptr) {
    return ::GetLastError();
  }
  ScopedGlobalLock locked_data(data);

  if (!locked_data.get()) {
    return ::GetLastError();
  }
  return static_cast<wchar_t*>(locked_data.get());
}

int ScopedClipboard::SetString(const std::wstring string) {
  assert(opened_);
  if (!::EmptyClipboard()) {
    return ::GetLastError();
  }
  size_t null_terminated_byte_count =
      sizeof(decltype(string)::traits_type::char_type) * (string.size() + 1);
  ScopedGlobalMemory destination_memory(GMEM_MOVEABLE,
                                        null_terminated_byte_count);
  ScopedGlobalLock locked_memory(destination_memory.get());
  if (!locked_memory.get()) {
    return ::GetLastError();
  }
  memcpy(locked_memory.get(), string.c_str(), null_terminated_byte_count);
  if (!::SetClipboardData(CF_UNICODETEXT, locked_memory.get())) {
    return ::GetLastError();
  }
  // The clipboard now owns the global memory.
  destination_memory.release();
  return kErrorSuccess;
}

}  // namespace

// static
std::unique_ptr<PlatformHandler> PlatformHandler::Create(
    BinaryMessenger* messenger,
    FlutterWindowsView* view) {
  return std::make_unique<PlatformHandlerWin32>(messenger, view);
}

PlatformHandlerWin32::PlatformHandlerWin32(
    BinaryMessenger* messenger,
    FlutterWindowsView* view,
    std::optional<std::function<std::unique_ptr<ScopedClipboardInterface>()>>
        scoped_clipboard_provider)
    : PlatformHandler(messenger), view_(view) {
  if (scoped_clipboard_provider.has_value()) {
    scoped_clipboard_provider_ = scoped_clipboard_provider.value();
  } else {
    scoped_clipboard_provider_ = []() {
      return std::make_unique<ScopedClipboard>();
    };
  }
}

PlatformHandlerWin32::~PlatformHandlerWin32() = default;

void PlatformHandlerWin32::GetPlainText(
    std::unique_ptr<MethodResult<rapidjson::Document>> result,
    std::string_view key) {
  std::unique_ptr<ScopedClipboardInterface> clipboard =
      scoped_clipboard_provider_();

  int open_result = clipboard->Open(std::get<HWND>(*view_->GetRenderTarget()));
  if (open_result != kErrorSuccess) {
    rapidjson::Document error_code;
    error_code.SetInt(open_result);
    result->Error(kClipboardError, "Unable to open clipboard", error_code);
    return;
  }
  if (!clipboard->HasString()) {
    result->Success(rapidjson::Document());
    return;
  }
  std::variant<std::wstring, int> get_string_result = clipboard->GetString();
  if (std::holds_alternative<int>(get_string_result)) {
    rapidjson::Document error_code;
    error_code.SetInt(std::get<int>(get_string_result));
    result->Error(kClipboardError, "Unable to get clipboard data", error_code);
    return;
  }

  rapidjson::Document document;
  document.SetObject();
  rapidjson::Document::AllocatorType& allocator = document.GetAllocator();
  document.AddMember(
      rapidjson::Value(key.data(), allocator),
      rapidjson::Value(
          fml::WideStringToUtf8(std::get<std::wstring>(get_string_result)),
          allocator),
      allocator);
  result->Success(document);
}

void PlatformHandlerWin32::GetHasStrings(
    std::unique_ptr<MethodResult<rapidjson::Document>> result) {
  std::unique_ptr<ScopedClipboardInterface> clipboard =
      scoped_clipboard_provider_();

  bool hasStrings;
  int open_result = clipboard->Open(std::get<HWND>(*view_->GetRenderTarget()));
  if (open_result != kErrorSuccess) {
    // Swallow errors of type ERROR_ACCESS_DENIED. These happen when the app is
    // not in the foreground and GetHasStrings is irrelevant.
    // See https://github.com/flutter/flutter/issues/95817.
    if (open_result != kAccessDeniedErrorCode) {
      rapidjson::Document error_code;
      error_code.SetInt(open_result);
      result->Error(kClipboardError, "Unable to open clipboard", error_code);
      return;
    }
    hasStrings = false;
  } else {
    hasStrings = clipboard->HasString();
  }

  rapidjson::Document document;
  document.SetObject();
  rapidjson::Document::AllocatorType& allocator = document.GetAllocator();
  document.AddMember(rapidjson::Value(kValueKey, allocator),
                     rapidjson::Value(hasStrings), allocator);
  result->Success(document);
}

void PlatformHandlerWin32::SetPlainText(
    const std::string& text,
    std::unique_ptr<MethodResult<rapidjson::Document>> result) {
  std::unique_ptr<ScopedClipboardInterface> clipboard =
      scoped_clipboard_provider_();

  int open_result = clipboard->Open(std::get<HWND>(*view_->GetRenderTarget()));
  if (open_result != kErrorSuccess) {
    rapidjson::Document error_code;
    error_code.SetInt(open_result);
    result->Error(kClipboardError, "Unable to open clipboard", error_code);
    return;
  }
  int set_result = clipboard->SetString(fml::Utf8ToWideString(text));
  if (set_result != kErrorSuccess) {
    rapidjson::Document error_code;
    error_code.SetInt(set_result);
    result->Error(kClipboardError, "Unable to set clipboard data", error_code);
    return;
  }
  result->Success();
}

void PlatformHandlerWin32::SystemSoundPlay(
    const std::string& sound_type,
    std::unique_ptr<MethodResult<rapidjson::Document>> result) {
  if (sound_type.compare(kSoundTypeAlert) == 0) {
    MessageBeep(MB_OK);
    result->Success();
  } else {
    result->NotImplemented();
  }
}

}  // namespace flutter
