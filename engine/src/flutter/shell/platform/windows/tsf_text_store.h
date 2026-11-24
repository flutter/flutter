// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_TSF_TEXT_STORE_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_TSF_TEXT_STORE_H_

#include <msctf.h>
#include <ole2.h>
#include <textstor.h>
#include <windows.h>
#include <wrl/client.h>
#include <wrl/implements.h>

#include <string>

#include "flutter/fml/macros.h"
#include "flutter/shell/geometry/geometry.h"
#include "flutter/shell/platform/common/text_range.h"

#ifndef TS_SD_INPUTPANEMANUALDISPLAYENABLE
#define TS_SD_INPUTPANEMANUALDISPLAYENABLE 0x00000020
#endif

namespace flutter {

// Receives document mutations from |TsfTextStore|.
class TsfTextStoreDelegate {
 public:
  virtual ~TsfTextStoreDelegate() = default;

  virtual std::u16string GetTsfText() const = 0;
  virtual TextRange GetTsfSelection() const = 0;
  virtual void SetTsfSelection(const TextRange& range) = 0;
  virtual void ReplaceTsfText(const TextRange& range,
                              const std::u16string& text) = 0;
  virtual void OnTsfComposeBegin() = 0;
  virtual void OnTsfComposeUpdate(const std::u16string& text,
                                  int cursor_pos) = 0;
  virtual void OnTsfComposeEnd() = 0;
  virtual Rect GetTsfCaretRect() const = 0;
  virtual HWND GetTsfWindowHandle() const = 0;
};

// ITextStoreACP implementation used as the TSF IME for a Flutter text field.
//
// |GetStatus| always sets |TS_SD_INPUTPANEMANUALDISPLAYENABLE| so Windows does
// not auto-invoke the touch keyboard. Visibility is driven by InputPane
// TryShow / TryHide. The Win11 dummy NONE store also sets |TS_SD_READONLY|
// and denies |RequestLock|.
class TsfTextStore
    : public Microsoft::WRL::RuntimeClass<
          Microsoft::WRL::RuntimeClassFlags<Microsoft::WRL::ClassicCom>,
          ITextStoreACP,
          ITfContextOwnerCompositionSink> {
 public:
  TsfTextStore();
  ~TsfTextStore() override;

  HRESULT RuntimeClassInitialize(TsfTextStoreDelegate* delegate);

  void SetDelegate(TsfTextStoreDelegate* delegate);

  // Marks this store as Chromium's Win11 dummy / empty text store (NONE).
  // |GetStatus| then also sets |TS_SD_READONLY| and |RequestLock| fails.
  void UseEmptyTextStore(bool enabled);
  bool is_empty_text_store() const { return is_empty_text_store_; }

  // Notifies TSF that the document text or selection changed from Flutter.
  void NotifyTextChanged();
  void NotifySelectionChanged();
  void NotifyLayoutChanged();

  // ITextStoreACP
  STDMETHODIMP AdviseSink(REFIID riid, IUnknown* punk, DWORD dwMask) override;
  STDMETHODIMP UnadviseSink(IUnknown* punk) override;
  STDMETHODIMP RequestLock(DWORD dwLockFlags, HRESULT* phrSession) override;
  STDMETHODIMP GetStatus(TS_STATUS* pdcs) override;
  STDMETHODIMP QueryInsert(LONG acpTestStart,
                           LONG acpTestEnd,
                           ULONG cch,
                           LONG* pacpResultStart,
                           LONG* pacpResultEnd) override;
  STDMETHODIMP GetSelection(ULONG ulIndex,
                            ULONG ulCount,
                            TS_SELECTION_ACP* pSelection,
                            ULONG* pcFetched) override;
  STDMETHODIMP SetSelection(ULONG ulCount,
                            const TS_SELECTION_ACP* pSelection) override;
  STDMETHODIMP GetText(LONG acpStart,
                       LONG acpEnd,
                       WCHAR* pchPlain,
                       ULONG cchPlainReq,
                       ULONG* pcchPlainRet,
                       TS_RUNINFO* prgRunInfo,
                       ULONG cRunInfoReq,
                       ULONG* pcRunInfoRet,
                       LONG* pacpNext) override;
  STDMETHODIMP SetText(DWORD dwFlags,
                       LONG acpStart,
                       LONG acpEnd,
                       const WCHAR* pchText,
                       ULONG cch,
                       TS_TEXTCHANGE* pChange) override;
  STDMETHODIMP GetFormattedText(LONG acpStart,
                                LONG acpEnd,
                                IDataObject** ppDataObject) override;
  STDMETHODIMP GetEmbedded(LONG acpPos,
                           REFGUID rguidService,
                           REFIID riid,
                           IUnknown** ppunk) override;
  STDMETHODIMP QueryInsertEmbedded(const GUID* pguidService,
                                   const FORMATETC* pFormatEtc,
                                   BOOL* pfInsertable) override;
  STDMETHODIMP InsertEmbedded(DWORD dwFlags,
                              LONG acpStart,
                              LONG acpEnd,
                              IDataObject* pDataObject,
                              TS_TEXTCHANGE* pChange) override;
  STDMETHODIMP InsertTextAtSelection(DWORD dwFlags,
                                     const WCHAR* pchText,
                                     ULONG cch,
                                     LONG* pacpStart,
                                     LONG* pacpEnd,
                                     TS_TEXTCHANGE* pChange) override;
  STDMETHODIMP InsertEmbeddedAtSelection(DWORD dwFlags,
                                         IDataObject* pDataObject,
                                         LONG* pacpStart,
                                         LONG* pacpEnd,
                                         TS_TEXTCHANGE* pChange) override;
  STDMETHODIMP RequestSupportedAttrs(DWORD dwFlags,
                                     ULONG cFilterAttrs,
                                     const TS_ATTRID* paFilterAttrs) override;
  STDMETHODIMP RequestAttrsAtPosition(LONG acpPos,
                                      ULONG cFilterAttrs,
                                      const TS_ATTRID* paFilterAttrs,
                                      DWORD dwFlags) override;
  STDMETHODIMP RequestAttrsTransitioningAtPosition(
      LONG acpPos,
      ULONG cFilterAttrs,
      const TS_ATTRID* paFilterAttrs,
      DWORD dwFlags) override;
  STDMETHODIMP FindNextAttrTransition(LONG acpStart,
                                      LONG acpHalt,
                                      ULONG cFilterAttrs,
                                      const TS_ATTRID* paFilterAttrs,
                                      DWORD dwFlags,
                                      LONG* pacpNext,
                                      BOOL* pfFound,
                                      LONG* plFoundOffset) override;
  STDMETHODIMP RetrieveRequestedAttrs(ULONG ulCount,
                                      TS_ATTRVAL* paAttrVals,
                                      ULONG* pcFetched) override;
  STDMETHODIMP GetEndACP(LONG* pacp) override;
  STDMETHODIMP GetActiveView(TsViewCookie* pvcView) override;
  STDMETHODIMP GetACPFromPoint(TsViewCookie vcView,
                               const POINT* ptScreen,
                               DWORD dwFlags,
                               LONG* pacp) override;
  STDMETHODIMP GetTextExt(TsViewCookie vcView,
                          LONG acpStart,
                          LONG acpEnd,
                          RECT* prc,
                          BOOL* pfClipped) override;
  STDMETHODIMP GetScreenExt(TsViewCookie vcView, RECT* prc) override;
  STDMETHODIMP GetWnd(TsViewCookie vcView, HWND* phwnd) override;

  // ITfContextOwnerCompositionSink
  STDMETHODIMP OnStartComposition(ITfCompositionView* pComposition,
                                  BOOL* pfOk) override;
  STDMETHODIMP OnUpdateComposition(ITfCompositionView* pComposition,
                                   ITfRange* pRangeNew) override;
  STDMETHODIMP OnEndComposition(ITfCompositionView* pComposition) override;

 private:
  static constexpr TsViewCookie kViewCookie = 1;

  bool HasReadLock() const;
  bool HasWriteLock() const;
  void SyncFromDelegate();
  std::u16string CurrentText() const;
  TextRange CurrentSelection() const;

  TsfTextStoreDelegate* delegate_ = nullptr;
  bool is_empty_text_store_ = false;
  Microsoft::WRL::ComPtr<ITextStoreACPSink> sink_;
  DWORD advise_mask_ = 0;
  DWORD lock_type_ = 0;
  DWORD pending_lock_ = 0;
  bool composing_ = false;
  std::u16string cached_text_;
  std::u16string last_known_text_;
  TextRange cached_selection_{0};
  bool cache_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(TsfTextStore);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_TSF_TEXT_STORE_H_
