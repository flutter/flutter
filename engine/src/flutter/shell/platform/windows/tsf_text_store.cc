// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/tsf_text_store.h"

#include "flutter/shell/platform/windows/text_input_plugin.h"

namespace flutter {

namespace {

// We support only one view.
const TsViewCookie kViewCookie = 1;

}  // namespace

TSFTextStore::TSFTextStore() {}

TSFTextStore::~TSFTextStore() {}

// IUnknown implementation (standard COM boilerplate).
ULONG STDMETHODCALLTYPE TSFTextStore::AddRef() {
  return InterlockedIncrement(&ref_count_);
}

ULONG STDMETHODCALLTYPE TSFTextStore::Release() {
  const LONG count = InterlockedDecrement(&ref_count_);
  if (!count) {
    delete this;
    return 0;
  }
  return static_cast<ULONG>(count);
}

HRESULT TSFTextStore::QueryInterface(REFIID iid, void** result) {
  if (iid == IID_IUnknown || iid == IID_ITextStoreACP) {
    *result = static_cast<ITextStoreACP*>(this);
  } else {
    *result = nullptr;
    return E_NOINTERFACE;
  }
  AddRef();
  return S_OK;
}

// === CORE METHOD 1: AdviseSink ===
// Chromium: chromium/ui/base/ime/win/tsf_text_store.cc:126-142
// 100% copied from Chromium logic
HRESULT TSFTextStore::AdviseSink(REFIID iid, IUnknown* unknown, DWORD mask) {
  if (!IsEqualGUID(iid, IID_ITextStoreACPSink))
    return E_INVALIDARG;
  if (text_store_acp_sink_) {
    if (text_store_acp_sink_.Get() == unknown) {
      text_store_acp_sink_mask_ = mask;
      return S_OK;
    } else {
      return CONNECT_E_ADVISELIMIT;
    }
  }
  if (FAILED(unknown->QueryInterface(IID_PPV_ARGS(&text_store_acp_sink_))))
    return E_UNEXPECTED;
  text_store_acp_sink_mask_ = mask;

  return S_OK;
}

// === CORE METHOD 2: GetTextExt ===
// Chromium: chromium/ui/base/ime/win/tsf_text_store.cc:361-469
// Adapted from Chromium with interface changes only
HRESULT TSFTextStore::GetTextExt(TsViewCookie view_cookie,
                                 LONG acp_start,
                                 LONG acp_end,
                                 RECT* rect,
                                 BOOL* clipped) {
  // 1. Parameter validation (same as Chromium)
  if (!rect || !clipped)
    return E_INVALIDARG;
  if (!text_input_plugin_)  // Interface change: text_input_client_ → text_input_plugin_
    return E_UNEXPECTED;

  // 2. View cookie validation (simplified: no stylus handwriting support)
  if (view_cookie != kViewCookie) {
    return E_INVALIDARG;
  }

  // 3. Lock check (same as Chromium)
  if (!HasReadLock())
    return TS_E_NOLOCK;

  // 4. Position validation (same logic as Chromium)
  if (!((static_cast<LONG>(composition_start_) <= acp_start) &&
        (acp_start <= acp_end) &&
        (acp_end <= static_cast<LONG>(string_buffer_.size())))) {
    return TS_E_INVALIDPOS;
  }

  // 5. Calculate relative positions (same as Chromium)
  const uint32_t start_pos = acp_start - composition_start_;
  const uint32_t end_pos = acp_end - composition_start_;

  // 6. Get cursor/caret position
  // Chromium logic: check HasCompositionText and get bounds
  // Simplified: directly get cursor position from Flutter
  RECT result_rect = {0};
  
  if (text_input_plugin_) {
    // Get cursor position from Flutter
    // Interface change: text_input_client_->GetCaretBounds() → text_input_plugin_->GetCursorRect()
    flutter::Rect cursor_rect = text_input_plugin_->GetCursorRect();
    
    // Convert to Windows RECT (client coordinates)
    result_rect.left = static_cast<LONG>(cursor_rect.left());
    result_rect.top = static_cast<LONG>(cursor_rect.top());
    result_rect.right = static_cast<LONG>(cursor_rect.right());
    result_rect.bottom = static_cast<LONG>(cursor_rect.bottom());
  } else {
    return TS_E_NOLAYOUT;
  }

  // 7. Convert to screen coordinates (same logic as Chromium)
  // Chromium: display::win::GetScreenWin()->DIPToScreenRect(...)
  // Flutter: use Windows API directly
  POINT screen_point;
  screen_point.x = result_rect.left;
  screen_point.y = result_rect.top;
  ::ClientToScreen(window_handle_, &screen_point);

  POINT bottom_right;
  bottom_right.x = result_rect.right;
  bottom_right.y = result_rect.bottom;
  ::ClientToScreen(window_handle_, &bottom_right);

  // Fill output rect
  rect->left = screen_point.x;
  rect->top = screen_point.y;
  rect->right = bottom_right.x;
  rect->bottom = bottom_right.y;

  *clipped = FALSE;

  return S_OK;
}

// === CORE METHOD 3: RequestLock ===
// Chromium: chromium/ui/base/ime/win/tsf_text_store.cc:622-690
// Copied from Chromium with Chromium-specific checks removed
HRESULT TSFTextStore::RequestLock(DWORD lock_flags, HRESULT* result) {
  // 1. Basic validation (same as Chromium)
  if (!text_input_plugin_)  // Interface change
    return E_UNEXPECTED;

  // 2. Sink check (same as Chromium)
  if (!text_store_acp_sink_.Get())
    return E_FAIL;
  if (!result)
    return E_INVALIDARG;

  // 3. Lock conflict handling (100% Chromium logic)
  if (current_lock_type_ != 0) {
    if (lock_flags & TS_LF_SYNC) {
      // Can't lock synchronously.
      *result = TS_E_SYNCHRONOUS;
      return S_OK;
    }
    // Queue the lock request.
    lock_queue_.push_back(lock_flags & TS_LF_READWRITE);
    *result = TS_S_ASYNC;
    return S_OK;
  }

  // 4. Lock (same as Chromium)
  current_lock_type_ = (lock_flags & TS_LF_READWRITE);

  // 5. Grant the lock (same as Chromium)
  *result = text_store_acp_sink_->OnLockGranted(current_lock_type_);

  // 6. Unlock (same as Chromium)
  current_lock_type_ = 0;

  // 7. Handle pending lock requests (100% Chromium logic)
  while (!lock_queue_.empty()) {
    current_lock_type_ = lock_queue_.front();
    lock_queue_.pop_front();
    text_store_acp_sink_->OnLockGranted(current_lock_type_);
    current_lock_type_ = 0;
  }

  return S_OK;
}

// === Helper Methods ===

bool TSFTextStore::HasReadLock() const {
  return current_lock_type_ != 0;
}

bool TSFTextStore::HasReadWriteLock() const {
  return (current_lock_type_ & TS_LF_READWRITE) == TS_LF_READWRITE;
}

void TSFTextStore::SetTextInputPlugin(TextInputPlugin* text_input_plugin) {
  text_input_plugin_ = text_input_plugin;
}

void TSFTextStore::SetWindowHandle(HWND window_handle) {
  window_handle_ = window_handle;
}

// === Other ITextStoreACP methods (minimal/stub implementations) ===

HRESULT TSFTextStore::FindNextAttrTransition(
    LONG acp_start,
    LONG acp_halt,
    ULONG num_filter_attributes,
    const TS_ATTRID* filter_attributes,
    DWORD flags,
    LONG* acp_next,
    BOOL* found,
    LONG* found_offset) {
  if (!acp_next || !found || !found_offset)
    return E_INVALIDARG;
  // We don't support any attributes.
  // So we always return "not found".
  *acp_next = 0;
  *found = FALSE;
  *found_offset = 0;
  return S_OK;
}

HRESULT TSFTextStore::GetACPFromPoint(TsViewCookie view_cookie,
                                      const POINT* point,
                                      DWORD flags,
                                      LONG* acp) {
  return E_NOTIMPL;
}

HRESULT TSFTextStore::GetActiveView(TsViewCookie* view_cookie) {
  if (!view_cookie)
    return E_INVALIDARG;
  // We support only one view.
  *view_cookie = kViewCookie;
  return S_OK;
}

HRESULT TSFTextStore::GetEmbedded(LONG acp_pos,
                                  REFGUID service,
                                  REFIID iid,
                                  IUnknown** unknown) {
  // We don't support any embedded objects.
  if (!unknown)
    return E_INVALIDARG;
  *unknown = nullptr;
  return E_NOTIMPL;
}

HRESULT TSFTextStore::GetEndACP(LONG* acp) {
  if (!acp)
    return E_INVALIDARG;
  if (!HasReadLock())
    return TS_E_NOLOCK;
  *acp = string_buffer_.size();
  return S_OK;
}

HRESULT TSFTextStore::GetFormattedText(LONG acp_start,
                                       LONG acp_end,
                                       IDataObject** data_object) {
  return E_NOTIMPL;
}

HRESULT TSFTextStore::GetScreenExt(TsViewCookie view_cookie, RECT* rect) {
  if (view_cookie != kViewCookie)
    return E_INVALIDARG;
  if (!rect)
    return E_INVALIDARG;

  // Return window client area in screen coordinates
  if (window_handle_) {
    POINT left_top = {0, 0};
    POINT right_bottom = {0, 0};
    RECT client_rect = {};
    if (GetClientRect(window_handle_, &client_rect)) {
      left_top.x = client_rect.left;
      left_top.y = client_rect.top;
      right_bottom.x = client_rect.right;
      right_bottom.y = client_rect.bottom;
      ::ClientToScreen(window_handle_, &left_top);
      ::ClientToScreen(window_handle_, &right_bottom);
      rect->left = left_top.x;
      rect->top = left_top.y;
      rect->right = right_bottom.x;
      rect->bottom = right_bottom.y;
      return S_OK;
    }
  }

  // Default fallback
  SetRect(rect, 0, 0, 0, 0);
  return S_OK;
}

HRESULT TSFTextStore::GetSelection(ULONG selection_index,
                                   ULONG selection_buffer_size,
                                   TS_SELECTION_ACP* selection_buffer,
                                   ULONG* fetched_count) {
  if (!selection_buffer)
    return E_INVALIDARG;
  if (!fetched_count)
    return E_INVALIDARG;
  if (!HasReadLock())
    return TS_E_NOLOCK;

  *fetched_count = 0;
  if ((selection_buffer_size > 0) &&
      ((selection_index == 0) || (selection_index == TS_DEFAULT_SELECTION))) {
    // Return cursor position as a zero-length selection
    selection_buffer[0].acpStart = composition_start_;
    selection_buffer[0].acpEnd = composition_start_;
    selection_buffer[0].style.ase = TS_AE_END;
    selection_buffer[0].style.fInterimChar = FALSE;
    *fetched_count = 1;
  }
  return S_OK;
}

HRESULT TSFTextStore::GetStatus(TS_STATUS* status) {
  if (!status)
    return E_INVALIDARG;

  status->dwDynamicFlags = 0;
  status->dwStaticFlags = TS_SS_NOHIDDENTEXT;

  return S_OK;
}

HRESULT TSFTextStore::GetText(LONG acp_start,
                              LONG acp_end,
                              wchar_t* text_buffer,
                              ULONG text_buffer_size,
                              ULONG* text_buffer_copied,
                              TS_RUNINFO* run_info_buffer,
                              ULONG run_info_buffer_size,
                              ULONG* run_info_buffer_copied,
                              LONG* next_acp) {
  if (!text_buffer_copied || !run_info_buffer_copied)
    return E_INVALIDARG;
  if (!text_buffer && text_buffer_size != 0)
    return E_INVALIDARG;
  if (!run_info_buffer && run_info_buffer_size != 0)
    return E_INVALIDARG;
  if (!next_acp)
    return E_INVALIDARG;
  if (!HasReadLock())
    return TF_E_NOLOCK;

  const LONG string_buffer_size = string_buffer_.size();
  if (acp_end == -1)
    acp_end = string_buffer_size;
  if (!((0 <= acp_start) && (acp_start <= acp_end) &&
        (acp_end <= string_buffer_size))) {
    return TF_E_INVALIDPOS;
  }

  acp_end = std::min(acp_end, acp_start + static_cast<LONG>(text_buffer_size));
  *text_buffer_copied = acp_end - acp_start;

  const std::wstring& result =
      string_buffer_.substr(acp_start, *text_buffer_copied);
  for (size_t i = 0; i < result.size(); ++i) {
    text_buffer[i] = result[i];
  }

  if (*text_buffer_copied > 0 && run_info_buffer_size) {
    run_info_buffer[0].uCount = *text_buffer_copied;
    run_info_buffer[0].type = TS_RT_PLAIN;
    *run_info_buffer_copied = 1;
  } else {
    *run_info_buffer_copied = 0;
  }

  *next_acp = acp_end;
  return S_OK;
}

HRESULT TSFTextStore::GetWnd(TsViewCookie view_cookie, HWND* window_handle) {
  if (!window_handle)
    return E_INVALIDARG;
  if (view_cookie != kViewCookie)
    return E_INVALIDARG;
  *window_handle = window_handle_;
  return S_OK;
}

HRESULT TSFTextStore::InsertEmbedded(DWORD flags,
                                     LONG acp_start,
                                     LONG acp_end,
                                     IDataObject* data_object,
                                     TS_TEXTCHANGE* change) {
  // We don't support any embedded objects.
  return E_NOTIMPL;
}

HRESULT TSFTextStore::InsertEmbeddedAtSelection(DWORD flags,
                                                IDataObject* data_object,
                                                LONG* acp_start,
                                                LONG* acp_end,
                                                TS_TEXTCHANGE* change) {
  // We don't support any embedded objects.
  return E_NOTIMPL;
}

HRESULT TSFTextStore::InsertTextAtSelection(DWORD flags,
                                            const wchar_t* text_buffer,
                                            ULONG text_buffer_size,
                                            LONG* acp_start,
                                            LONG* acp_end,
                                            TS_TEXTCHANGE* text_change) {
  // Minimal implementation
  return E_NOTIMPL;
}

HRESULT TSFTextStore::QueryInsert(LONG acp_test_start,
                                  LONG acp_test_end,
                                  ULONG text_size,
                                  LONG* acp_result_start,
                                  LONG* acp_result_end) {
  if (!acp_result_start || !acp_result_end || acp_test_start > acp_test_end)
    return E_INVALIDARG;

  *acp_result_start = acp_test_start;
  *acp_result_end = acp_test_end;
  return S_OK;
}

HRESULT TSFTextStore::QueryInsertEmbedded(const GUID* service,
                                          const FORMATETC* format,
                                          BOOL* insertable) {
  if (!format)
    return E_INVALIDARG;
  // We don't support any embedded objects.
  if (insertable)
    *insertable = FALSE;
  return S_OK;
}

HRESULT TSFTextStore::RequestAttrsAtPosition(
    LONG acp_pos,
    ULONG attribute_buffer_size,
    const TS_ATTRID* attribute_buffer,
    DWORD flags) {
  // We don't support any document attributes.
  return S_OK;
}

HRESULT TSFTextStore::RequestAttrsTransitioningAtPosition(
    LONG acp_pos,
    ULONG attribute_buffer_size,
    const TS_ATTRID* attribute_buffer,
    DWORD flags) {
  // We don't support any document attributes.
  return S_OK;
}

HRESULT TSFTextStore::RequestSupportedAttrs(
    DWORD flags,
    ULONG attribute_buffer_size,
    const TS_ATTRID* attribute_buffer) {
  // We don't support any document attributes.
  return S_OK;
}

HRESULT TSFTextStore::RetrieveRequestedAttrs(
    ULONG attribute_buffer_size,
    TS_ATTRVAL* attribute_buffer,
    ULONG* attribute_buffer_copied) {
  if (!attribute_buffer_copied)
    return E_INVALIDARG;
  *attribute_buffer_copied = 0;
  return S_OK;
}

HRESULT TSFTextStore::SetSelection(
    ULONG selection_buffer_size,
    const TS_SELECTION_ACP* selection_buffer) {
  return E_NOTIMPL;
}

HRESULT TSFTextStore::SetText(DWORD flags,
                              LONG acp_start,
                              LONG acp_end,
                              const wchar_t* text_buffer,
                              ULONG text_buffer_size,
                              TS_TEXTCHANGE* text_change) {
  return E_NOTIMPL;
}

HRESULT TSFTextStore::UnadviseSink(IUnknown* unknown) {
  if (!text_store_acp_sink_.Get())
    return E_UNEXPECTED;
  if (text_store_acp_sink_.Get() != unknown)
    return E_INVALIDARG;
  text_store_acp_sink_.Reset();
  text_store_acp_sink_mask_ = 0;
  return S_OK;
}

}  // namespace flutter
