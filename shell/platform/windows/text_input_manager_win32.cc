// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/text_input_manager_win32.h"

#include <imm.h>

#include <cassert>
#include <memory>

namespace flutter {

// RAII wrapper for the Win32 Input Method Manager context.
class ImmContext {
 public:
  ImmContext(HWND window_handle)
      : context_(::ImmGetContext(window_handle)),
        window_handle_(window_handle) {
    assert(window_handle);
  }

  ~ImmContext() {
    if (context_ != nullptr) {
      ::ImmReleaseContext(window_handle_, context_);
    }
  }

  // Prevent copying.
  ImmContext(const ImmContext& other) = delete;
  ImmContext& operator=(const ImmContext& other) = delete;

  // Returns true if a valid IMM context has been obtained.
  bool IsValid() const { return context_ != nullptr; }

  // Returns the IMM context.
  HIMC get() {
    assert(context_);
    return context_;
  }

 private:
  HWND window_handle_;
  HIMC context_;
};

void TextInputManagerWin32::SetWindowHandle(HWND window_handle) {
  window_handle_ = window_handle;
}

void TextInputManagerWin32::CreateImeWindow() {
  if (window_handle_ == nullptr) {
    return;
  }

  // Some IMEs ignore calls to ::ImmSetCandidateWindow() and use the position of
  // the current system caret instead via ::GetCaretPos(). In order to behave
  // as expected with these IMEs, we create a temporary system caret.
  if (!ime_active_) {
    ::CreateCaret(window_handle_, nullptr, 1, 1);
  }
  ime_active_ = true;

  // Set the position of the IME windows.
  UpdateImeWindow();
}

void TextInputManagerWin32::DestroyImeWindow() {
  if (window_handle_ == nullptr) {
    return;
  }

  // Destroy the system caret created in CreateImeWindow().
  if (ime_active_) {
    ::DestroyCaret();
  }
  ime_active_ = false;
}

void TextInputManagerWin32::UpdateImeWindow() {
  if (window_handle_ == nullptr) {
    return;
  }

  ImmContext imm_context(window_handle_);
  if (imm_context.IsValid()) {
    MoveImeWindow(imm_context.get());
  }
}

void TextInputManagerWin32::UpdateCaretRect(const Rect& rect) {
  caret_rect_ = rect;

  if (window_handle_ == nullptr) {
    return;
  }

  ImmContext imm_context(window_handle_);
  if (imm_context.IsValid()) {
    MoveImeWindow(imm_context.get());
  }
}

long TextInputManagerWin32::GetComposingCursorPosition() const {
  if (window_handle_ == nullptr) {
    return false;
  }

  ImmContext imm_context(window_handle_);
  if (imm_context.IsValid()) {
    // Read the cursor position within the composing string.
    return ImmGetCompositionString(imm_context.get(), GCS_CURSORPOS, nullptr,
                                   0);
  }
  return -1;
}

std::optional<std::u16string> TextInputManagerWin32::GetComposingString()
    const {
  return GetString(GCS_COMPSTR);
}

std::optional<std::u16string> TextInputManagerWin32::GetResultString() const {
  return GetString(GCS_RESULTSTR);
}

void TextInputManagerWin32::AbortComposing() {
  if (window_handle_ == nullptr || !ime_active_) {
    return;
  }

  ImmContext imm_context(window_handle_);
  if (imm_context.IsValid()) {
    // Cancel composing and close the candidates window.
    ::ImmNotifyIME(imm_context.get(), NI_COMPOSITIONSTR, CPS_CANCEL, 0);
    ::ImmNotifyIME(imm_context.get(), NI_CLOSECANDIDATE, 0, 0);

    // Clear the composing string.
    wchar_t composition_str[] = L"";
    wchar_t reading_str[] = L"";
    ::ImmSetCompositionStringW(imm_context.get(), SCS_SETSTR, composition_str,
                               sizeof(wchar_t), reading_str, sizeof(wchar_t));
  }
}

std::optional<std::u16string> TextInputManagerWin32::GetString(int type) const {
  if (window_handle_ == nullptr || !ime_active_) {
    return std::nullopt;
  }
  ImmContext imm_context(window_handle_);
  if (imm_context.IsValid()) {
    // Read the composing string length.
    const long compose_bytes =
        ::ImmGetCompositionString(imm_context.get(), type, nullptr, 0);
    const long compose_length = compose_bytes / sizeof(wchar_t);
    if (compose_length < 0) {
      return std::nullopt;
    }

    std::u16string text(compose_length, '\0');
    ::ImmGetCompositionString(imm_context.get(), type, &text[0], compose_bytes);
    return text;
  }
  return std::nullopt;
}

void TextInputManagerWin32::MoveImeWindow(HIMC imm_context) {
  if (GetFocus() != window_handle_ || !ime_active_) {
    return;
  }
  LONG left = caret_rect_.left();
  LONG top = caret_rect_.top();
  LONG right = caret_rect_.right();
  LONG bottom = caret_rect_.bottom();
  ::SetCaretPos(left, bottom);

  // Set the position of composition text.
  COMPOSITIONFORM composition_form = {CFS_POINT, {left, top}};
  ::ImmSetCompositionWindow(imm_context, &composition_form);

  // Set the position of candidate window.
  CANDIDATEFORM candidate_form = {
      0, CFS_EXCLUDE, {left, bottom}, {left, top, right, bottom}};
  ::ImmSetCandidateWindow(imm_context, &candidate_form);
}

}  // namespace flutter
