// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/win32_platform_handler.h"

#include <windows.h>

#include <iostream>
#include <optional>

#include "flutter/shell/platform/common/cpp/json_method_codec.h"
#include "flutter/shell/platform/windows/flutter_windows_view.h"
#include "flutter/shell/platform/windows/string_conversion.h"

static constexpr char kChannelName[] = "flutter/platform";

static constexpr char kGetClipboardDataMethod[] = "Clipboard.getData";
static constexpr char kSetClipboardDataMethod[] = "Clipboard.setData";

static constexpr char kTextPlainFormat[] = "text/plain";
static constexpr char kTextKey[] = "text";

static constexpr char kClipboardError[] = "Clipboard error";
static constexpr char kUnknownClipboardFormatMessage[] =
    "Unknown clipboard format";

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
class ScopedClipboard {
 public:
  ScopedClipboard();
  ~ScopedClipboard();

  // Prevent copying.
  ScopedClipboard(ScopedClipboard const&) = delete;
  ScopedClipboard& operator=(ScopedClipboard const&) = delete;

  // Attempts to open the clipboard for the given window, returning true if
  // successful.
  bool Open(HWND window);

  // Returns true if there is string data available to get.
  bool HasString();

  // Returns string data from the clipboard.
  //
  // If getting a string fails, returns no value. Get error information with
  // ::GetLastError().
  //
  // Open(...) must have succeeded to call this method.
  std::optional<std::wstring> GetString();

  // Sets the string content of the clipboard, returning true on success.
  //
  // On failure, get error information with ::GetLastError().
  //
  // Open(...) must have succeeded to call this method.
  bool SetString(const std::wstring string);

 private:
  bool opened_ = false;
};

ScopedClipboard::ScopedClipboard() {}

ScopedClipboard::~ScopedClipboard() {
  if (opened_) {
    ::CloseClipboard();
  }
}

bool ScopedClipboard::Open(HWND window) {
  opened_ = ::OpenClipboard(window);
  return opened_;
}

bool ScopedClipboard::HasString() {
  // Allow either plain text format, since getting data will auto-interpolate.
  return ::IsClipboardFormatAvailable(CF_UNICODETEXT) ||
         ::IsClipboardFormatAvailable(CF_TEXT);
}

std::optional<std::wstring> ScopedClipboard::GetString() {
  assert(opened_);

  HANDLE data = ::GetClipboardData(CF_UNICODETEXT);
  if (data == nullptr) {
    return std::nullopt;
  }
  ScopedGlobalLock locked_data(data);
  if (!locked_data.get()) {
    return std::nullopt;
  }
  return std::optional<std::wstring>(static_cast<wchar_t*>(locked_data.get()));
}

bool ScopedClipboard::SetString(const std::wstring string) {
  assert(opened_);
  if (!::EmptyClipboard()) {
    return false;
  }
  size_t null_terminated_byte_count =
      sizeof(decltype(string)::traits_type::char_type) * (string.size() + 1);
  ScopedGlobalMemory destination_memory(GMEM_MOVEABLE,
                                        null_terminated_byte_count);
  ScopedGlobalLock locked_memory(destination_memory.get());
  if (!locked_memory.get()) {
    return false;
  }
  memcpy(locked_memory.get(), string.c_str(), null_terminated_byte_count);
  if (!::SetClipboardData(CF_UNICODETEXT, locked_memory.get())) {
    return false;
  }
  // The clipboard now owns the global memory.
  destination_memory.release();
  return true;
}

}  // namespace

PlatformHandler::PlatformHandler(flutter::BinaryMessenger* messenger,
                                 FlutterWindowsView* view)
    : channel_(std::make_unique<flutter::MethodChannel<rapidjson::Document>>(
          messenger,
          kChannelName,
          &flutter::JsonMethodCodec::GetInstance())),
      view_(view) {
  channel_->SetMethodCallHandler(
      [this](
          const flutter::MethodCall<rapidjson::Document>& call,
          std::unique_ptr<flutter::MethodResult<rapidjson::Document>> result) {
        HandleMethodCall(call, std::move(result));
      });
}

void PlatformHandler::HandleMethodCall(
    const flutter::MethodCall<rapidjson::Document>& method_call,
    std::unique_ptr<flutter::MethodResult<rapidjson::Document>> result) {
  const std::string& method = method_call.method_name();
  if (method.compare(kGetClipboardDataMethod) == 0) {
    // Only one string argument is expected.
    const rapidjson::Value& format = method_call.arguments()[0];

    if (strcmp(format.GetString(), kTextPlainFormat) != 0) {
      result->Error(kClipboardError, kUnknownClipboardFormatMessage);
      return;
    }
    ScopedClipboard clipboard;
    if (!clipboard.Open(std::get<HWND>(*view_->GetRenderTarget()))) {
      rapidjson::Document error_code;
      error_code.SetInt(::GetLastError());
      result->Error(kClipboardError, "Unable to open clipboard", &error_code);
      return;
    }
    if (!clipboard.HasString()) {
      rapidjson::Document null;
      result->Success(&null);
      return;
    }
    std::optional<std::wstring> clipboard_string = clipboard.GetString();
    if (!clipboard_string) {
      rapidjson::Document error_code;
      error_code.SetInt(::GetLastError());
      result->Error(kClipboardError, "Unable to get clipboard data",
                    &error_code);
      return;
    }

    rapidjson::Document document;
    document.SetObject();
    rapidjson::Document::AllocatorType& allocator = document.GetAllocator();
    document.AddMember(
        rapidjson::Value(kTextKey, allocator),
        rapidjson::Value(Utf8FromUtf16(*clipboard_string), allocator),
        allocator);
    result->Success(&document);
  } else if (method.compare(kSetClipboardDataMethod) == 0) {
    const rapidjson::Value& document = *method_call.arguments();
    rapidjson::Value::ConstMemberIterator itr = document.FindMember(kTextKey);
    if (itr == document.MemberEnd()) {
      result->Error(kClipboardError, kUnknownClipboardFormatMessage);
      return;
    }

    ScopedClipboard clipboard;

    if (!clipboard.Open(std::get<HWND>(*view_->GetRenderTarget()))) {
      rapidjson::Document error_code;
      error_code.SetInt(::GetLastError());
      result->Error(kClipboardError, "Unable to open clipboard", &error_code);
      return;
    }
    if (!clipboard.SetString(Utf16FromUtf8(itr->value.GetString()))) {
      rapidjson::Document error_code;
      error_code.SetInt(::GetLastError());
      result->Error(kClipboardError, "Unable to set clipboard data",
                    &error_code);
      return;
    }
    result->Success();
  } else {
    result->NotImplemented();
  }
}

}  // namespace flutter
