// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// TSF (Text Services Framework) implementation for Flutter Windows.
// Adapted from Chromium's TSFTextStore implementation.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_TSF_TEXT_STORE_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_TSF_TEXT_STORE_H_

#include <msctf.h>
#include <wrl/client.h>

#include <deque>
#include <string>

namespace flutter {

class TextInputPlugin;

// TSFTextStore implements the ITextStoreACP interface to interact with
// Windows Text Services Framework (TSF) for modern IME support.
//
// This replaces the legacy IMM32 API to provide proper IME candidate window
// positioning for modern Windows IMEs such as Microsoft Pinyin, Sogou Pinyin,
// and other CJK input methods.
//
// Based on Chromium's ui/base/ime/win/tsf_text_store.h implementation.
class TSFTextStore : public ITextStoreACP {
 public:
  TSFTextStore();

  TSFTextStore(const TSFTextStore&) = delete;
  TSFTextStore& operator=(const TSFTextStore&) = delete;

  virtual ~TSFTextStore();

  // IUnknown:
  IFACEMETHODIMP_(ULONG) AddRef() override;
  IFACEMETHODIMP_(ULONG) Release() override;
  IFACEMETHODIMP QueryInterface(REFIID iid, void** ppv) override;

  // ITextStoreACP (core methods):
  IFACEMETHODIMP AdviseSink(REFIID iid, IUnknown* unknown, DWORD mask) override;
  IFACEMETHODIMP GetTextExt(TsViewCookie view_cookie,
                            LONG acp_start,
                            LONG acp_end,
                            RECT* rect,
                            BOOL* clipped) override;
  IFACEMETHODIMP RequestLock(DWORD lock_flags, HRESULT* result) override;

  // ITextStoreACP (additional required methods - minimal implementation):
  IFACEMETHODIMP FindNextAttrTransition(LONG acp_start,
                                        LONG acp_halt,
                                        ULONG num_filter_attributes,
                                        const TS_ATTRID* filter_attributes,
                                        DWORD flags,
                                        LONG* acp_next,
                                        BOOL* found,
                                        LONG* found_offset) override;
  IFACEMETHODIMP GetACPFromPoint(TsViewCookie view_cookie,
                                 const POINT* point,
                                 DWORD flags,
                                 LONG* acp) override;
  IFACEMETHODIMP GetActiveView(TsViewCookie* view_cookie) override;
  IFACEMETHODIMP GetEmbedded(LONG acp_pos,
                             REFGUID service,
                             REFIID iid,
                             IUnknown** unknown) override;
  IFACEMETHODIMP GetEndACP(LONG* acp) override;
  IFACEMETHODIMP GetFormattedText(LONG acp_start,
                                  LONG acp_end,
                                  IDataObject** data_object) override;
  IFACEMETHODIMP GetScreenExt(TsViewCookie view_cookie, RECT* rect) override;
  IFACEMETHODIMP GetSelection(ULONG selection_index,
                              ULONG selection_buffer_size,
                              TS_SELECTION_ACP* selection_buffer,
                              ULONG* fetched_count) override;
  IFACEMETHODIMP GetStatus(TS_STATUS* pdcs) override;
  IFACEMETHODIMP GetText(LONG acp_start,
                         LONG acp_end,
                         wchar_t* text_buffer,
                         ULONG text_buffer_size,
                         ULONG* text_buffer_copied,
                         TS_RUNINFO* run_info_buffer,
                         ULONG run_info_buffer_size,
                         ULONG* run_info_buffer_copied,
                         LONG* next_acp) override;
  IFACEMETHODIMP GetWnd(TsViewCookie view_cookie, HWND* window_handle) override;
  IFACEMETHODIMP InsertEmbedded(DWORD flags,
                                LONG acp_start,
                                LONG acp_end,
                                IDataObject* data_object,
                                TS_TEXTCHANGE* change) override;
  IFACEMETHODIMP InsertEmbeddedAtSelection(DWORD flags,
                                           IDataObject* data_object,
                                           LONG* acp_start,
                                           LONG* acp_end,
                                           TS_TEXTCHANGE* change) override;
  IFACEMETHODIMP InsertTextAtSelection(DWORD flags,
                                       const wchar_t* text_buffer,
                                       ULONG text_buffer_size,
                                       LONG* acp_start,
                                       LONG* acp_end,
                                       TS_TEXTCHANGE* text_change) override;
  IFACEMETHODIMP QueryInsert(LONG acp_test_start,
                             LONG acp_test_end,
                             ULONG text_size,
                             LONG* acp_result_start,
                             LONG* acp_result_end) override;
  IFACEMETHODIMP QueryInsertEmbedded(const GUID* service,
                                     const FORMATETC* format,
                                     BOOL* insertable) override;
  IFACEMETHODIMP RequestAttrsAtPosition(LONG acp_pos,
                                        ULONG attribute_buffer_size,
                                        const TS_ATTRID* attribute_buffer,
                                        DWORD flags) override;
  IFACEMETHODIMP RequestAttrsTransitioningAtPosition(
      LONG acp_pos,
      ULONG attribute_buffer_size,
      const TS_ATTRID* attribute_buffer,
      DWORD flags) override;
  IFACEMETHODIMP RequestSupportedAttrs(
      DWORD flags,
      ULONG attribute_buffer_size,
      const TS_ATTRID* attribute_buffer) override;
  IFACEMETHODIMP RetrieveRequestedAttrs(
      ULONG attribute_buffer_size,
      TS_ATTRVAL* attribute_buffer,
      ULONG* attribute_buffer_copied) override;
  IFACEMETHODIMP SetSelection(
      ULONG selection_buffer_size,
      const TS_SELECTION_ACP* selection_buffer) override;
  IFACEMETHODIMP SetText(DWORD flags,
                         LONG acp_start,
                         LONG acp_end,
                         const wchar_t* text_buffer,
                         ULONG text_buffer_size,
                         TS_TEXTCHANGE* text_change) override;
  IFACEMETHODIMP UnadviseSink(IUnknown* unknown) override;

  // Sets the TextInputPlugin instance.
  void SetTextInputPlugin(TextInputPlugin* text_input_plugin);

  // Sets the window handle.
  void SetWindowHandle(HWND window_handle);

 private:
  // Checks if the document has a read lock.
  bool HasReadLock() const;

  // Checks if the document has a read and write lock.
  bool HasReadWriteLock() const;

  // The reference count of this instance.
  volatile LONG ref_count_ = 0;

  // A pointer of ITextStoreACPSink, this instance is given in AdviseSink.
  Microsoft::WRL::ComPtr<ITextStoreACPSink> text_store_acp_sink_;

  // The current mask of |text_store_acp_sink_|.
  DWORD text_store_acp_sink_mask_ = 0;

  // HWND of the current view window.
  HWND window_handle_ = nullptr;

  // Current lock type.
  DWORD current_lock_type_ = 0;

  // Queue of pending lock requests.
  std::deque<DWORD> lock_queue_;

  // Pointer to the TextInputPlugin (Flutter's text input interface).
  TextInputPlugin* text_input_plugin_ = nullptr;

  // Text composition start position.
  size_t composition_start_ = 0;

  // Internal text buffer (simplified: just for position tracking).
  std::wstring string_buffer_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_TSF_TEXT_STORE_H_
