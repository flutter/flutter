// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/text_input_manager_win32.h"

#include <imm.h>

#include <memory>

namespace flutter {

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

  HIMC imm_context = ::ImmGetContext(window_handle_);
  if (imm_context) {
    MoveImeWindow(imm_context);
    ::ImmReleaseContext(window_handle_, imm_context);
  }
}

void TextInputManagerWin32::UpdateCaretRect(const Rect& rect) {
  caret_rect_ = rect;

  if (window_handle_ == nullptr) {
    return;
  }

  // TODO(cbracken): wrap these in an RAII container.
  HIMC imm_context = ::ImmGetContext(window_handle_);
  if (imm_context) {
    MoveImeWindow(imm_context);
    ::ImmReleaseContext(window_handle_, imm_context);
  }
}

long TextInputManagerWin32::GetComposingCursorPosition() const {
  if (window_handle_ == nullptr) {
    return false;
  }

  HIMC imm_context = ::ImmGetContext(window_handle_);
  if (imm_context) {
    // Read the cursor position within the composing string.
    const int pos =
        ImmGetCompositionStringW(imm_context, GCS_CURSORPOS, nullptr, 0);
    ::ImmReleaseContext(window_handle_, imm_context);
    return pos;
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

std::optional<std::u16string> TextInputManagerWin32::GetString(int type) const {
  if (window_handle_ == nullptr || !ime_active_) {
    return std::nullopt;
  }
  HIMC imm_context = ::ImmGetContext(window_handle_);
  if (imm_context) {
    // Read the composing string length.
    const long compose_bytes =
        ::ImmGetCompositionString(imm_context, type, nullptr, 0);
    const long compose_length = compose_bytes / sizeof(wchar_t);
    if (compose_length <= 0) {
      ::ImmReleaseContext(window_handle_, imm_context);
      return std::nullopt;
    }

    std::u16string text(compose_length, '\0');
    ::ImmGetCompositionString(imm_context, type, &text[0], compose_bytes);
    ::ImmReleaseContext(window_handle_, imm_context);
    return text;
  }
  return std::nullopt;
}

void TextInputManagerWin32::MoveImeWindow(HIMC imm_context) {
  if (GetFocus() != window_handle_ || !ime_active_) {
    return;
  }
  LONG x = caret_rect_.left();
  LONG y = caret_rect_.top();
  ::SetCaretPos(x, y);

  COMPOSITIONFORM cf = {CFS_POINT, {x, y}};
  ::ImmSetCompositionWindow(imm_context, &cf);

  CANDIDATEFORM candidate_form = {0, CFS_CANDIDATEPOS, {x, y}, {0, 0, 0, 0}};
  ::ImmSetCandidateWindow(imm_context, &candidate_form);
}

}  // namespace flutter
