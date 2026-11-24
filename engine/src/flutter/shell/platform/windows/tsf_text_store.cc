// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/tsf_text_store.h"

#include <olectl.h>
#include <algorithm>
#include <cmath>

#include "flutter/fml/logging.h"

namespace flutter {

TsfTextStore::TsfTextStore() = default;

TsfTextStore::~TsfTextStore() = default;

HRESULT TsfTextStore::RuntimeClassInitialize(TsfTextStoreDelegate* delegate) {
  delegate_ = delegate;
  return S_OK;
}

void TsfTextStore::SetDelegate(TsfTextStoreDelegate* delegate) {
  delegate_ = delegate;
  last_known_text_ = delegate_ ? delegate_->GetTsfText() : std::u16string();
  cache_valid_ = false;
}

void TsfTextStore::UseEmptyTextStore(bool enabled) {
  is_empty_text_store_ = enabled;
}

void TsfTextStore::NotifyTextChanged() {
  const std::u16string previous_text = last_known_text_;
  cache_valid_ = false;
  const std::u16string text = CurrentText();
  last_known_text_ = text;
  if (text == previous_text || !sink_ || !(advise_mask_ & TS_AS_TEXT_CHANGE)) {
    return;
  }
  TS_TEXTCHANGE change{};
  change.acpStart = 0;
  change.acpOldEnd = static_cast<LONG>(previous_text.size());
  change.acpNewEnd = static_cast<LONG>(text.size());
  sink_->OnTextChange(0, &change);
}

void TsfTextStore::NotifySelectionChanged() {
  cache_valid_ = false;
  if (sink_ && (advise_mask_ & TS_AS_SEL_CHANGE)) {
    sink_->OnSelectionChange();
  }
}

void TsfTextStore::NotifyLayoutChanged() {
  if (sink_ && (advise_mask_ & TS_AS_LAYOUT_CHANGE)) {
    sink_->OnLayoutChange(TS_LC_CHANGE, kViewCookie);
  }
}

bool TsfTextStore::HasReadLock() const {
  return (lock_type_ & TS_LF_READ) == TS_LF_READ;
}

bool TsfTextStore::HasWriteLock() const {
  return (lock_type_ & TS_LF_READWRITE) == TS_LF_READWRITE;
}

void TsfTextStore::SyncFromDelegate() {
  if (!delegate_) {
    cached_text_.clear();
    cached_selection_ = TextRange(0);
    cache_valid_ = true;
    return;
  }
  cached_text_ = delegate_->GetTsfText();
  last_known_text_ = cached_text_;
  cached_selection_ = delegate_->GetTsfSelection();
  cache_valid_ = true;
}

std::u16string TsfTextStore::CurrentText() const {
  if (cache_valid_) {
    return cached_text_;
  }
  if (!delegate_) {
    return {};
  }
  return delegate_->GetTsfText();
}

TextRange TsfTextStore::CurrentSelection() const {
  if (cache_valid_) {
    return cached_selection_;
  }
  if (!delegate_) {
    return TextRange(0);
  }
  return delegate_->GetTsfSelection();
}

STDMETHODIMP TsfTextStore::AdviseSink(REFIID riid,
                                      IUnknown* punk,
                                      DWORD dwMask) {
  if (!IsEqualIID(riid, IID_ITextStoreACPSink) || punk == nullptr) {
    return E_INVALIDARG;
  }
  Microsoft::WRL::ComPtr<ITextStoreACPSink> sink;
  HRESULT hr = punk->QueryInterface(IID_PPV_ARGS(&sink));
  if (FAILED(hr)) {
    return E_INVALIDARG;
  }
  if (sink_) {
    if (sink_.Get() == sink.Get()) {
      advise_mask_ = dwMask;
      return S_OK;
    }
    return CONNECT_E_ADVISELIMIT;
  }
  sink_ = sink;
  advise_mask_ = dwMask;
  return S_OK;
}

STDMETHODIMP TsfTextStore::UnadviseSink(IUnknown* punk) {
  if (punk == nullptr || !sink_) {
    return CONNECT_E_NOCONNECTION;
  }
  Microsoft::WRL::ComPtr<ITextStoreACPSink> sink;
  if (FAILED(punk->QueryInterface(IID_PPV_ARGS(&sink))) ||
      sink_.Get() != sink.Get()) {
    return CONNECT_E_NOCONNECTION;
  }
  sink_.Reset();
  advise_mask_ = 0;
  return S_OK;
}

STDMETHODIMP TsfTextStore::RequestLock(DWORD dwLockFlags, HRESULT* phrSession) {
  if (!phrSession) {
    return E_INVALIDARG;
  }
  *phrSession = E_FAIL;
  // Chromium: deny locks on the Win11 dummy NONE store so TSF cannot treat
  // the HWND as an editor.
  if (is_empty_text_store_) {
    return E_FAIL;
  }
  // Chromium returns E_UNEXPECTED when no TextInputClient is attached, and
  // E_FAIL when the client type is already NONE (crbug.com/1483978).
  if (!delegate_) {
    return E_UNEXPECTED;
  }
  if (!sink_) {
    return E_UNEXPECTED;
  }
  if (lock_type_ != 0) {
    if (dwLockFlags & TS_LF_SYNC) {
      *phrSession = TS_E_SYNCHRONOUS;
      return S_OK;
    }
    pending_lock_ = dwLockFlags;
    *phrSession = TS_S_ASYNC;
    return S_OK;
  }

  SyncFromDelegate();
  lock_type_ = dwLockFlags;
  *phrSession = sink_->OnLockGranted(dwLockFlags);
  lock_type_ = 0;
  cache_valid_ = false;

  if (pending_lock_ != 0) {
    const DWORD pending = pending_lock_;
    pending_lock_ = 0;
    HRESULT ignored = S_OK;
    RequestLock(pending, &ignored);
  }
  return S_OK;
}

STDMETHODIMP TsfTextStore::GetStatus(TS_STATUS* pdcs) {
  if (!pdcs) {
    return E_INVALIDARG;
  }
  pdcs->dwDynamicFlags = TS_SD_INPUTPANEMANUALDISPLAYENABLE;
  if (is_empty_text_store_) {
    pdcs->dwDynamicFlags |= TS_SD_READONLY;
  }
  pdcs->dwStaticFlags = TS_SS_NOHIDDENTEXT | TS_SS_TRANSITORY;
  return S_OK;
}

STDMETHODIMP TsfTextStore::QueryInsert(LONG acpTestStart,
                                       LONG acpTestEnd,
                                       ULONG /*cch*/,
                                       LONG* pacpResultStart,
                                       LONG* pacpResultEnd) {
  if (!pacpResultStart || !pacpResultEnd) {
    return E_INVALIDARG;
  }
  const LONG end = static_cast<LONG>(CurrentText().size());
  if (acpTestStart < 0 || acpTestStart > acpTestEnd || acpTestEnd > end) {
    return E_INVALIDARG;
  }
  *pacpResultStart = acpTestStart;
  *pacpResultEnd = acpTestEnd;
  return S_OK;
}

STDMETHODIMP TsfTextStore::GetSelection(ULONG ulIndex,
                                        ULONG ulCount,
                                        TS_SELECTION_ACP* pSelection,
                                        ULONG* pcFetched) {
  if (!pSelection || !pcFetched) {
    return E_INVALIDARG;
  }
  *pcFetched = 0;
  if (!HasReadLock()) {
    return TS_E_NOLOCK;
  }
  if (ulCount == 0) {
    return S_OK;
  }
  if (ulIndex > 0 && ulIndex != TS_DEFAULT_SELECTION) {
    return S_OK;
  }
  const TextRange selection = CurrentSelection();
  pSelection[0].acpStart = static_cast<LONG>(selection.start());
  pSelection[0].acpEnd = static_cast<LONG>(selection.end());
  pSelection[0].style.ase = selection.reversed() ? TS_AE_START : TS_AE_END;
  pSelection[0].style.fInterimChar = FALSE;
  *pcFetched = 1;
  return S_OK;
}

STDMETHODIMP TsfTextStore::SetSelection(ULONG ulCount,
                                        const TS_SELECTION_ACP* pSelection) {
  if (!pSelection || ulCount == 0) {
    return E_INVALIDARG;
  }
  if (!HasWriteLock()) {
    return TS_E_NOLOCK;
  }
  const LONG end = static_cast<LONG>(CurrentText().size());
  if (pSelection[0].acpStart < 0 || pSelection[0].acpEnd < 0 ||
      pSelection[0].acpStart > end || pSelection[0].acpEnd > end) {
    return TF_E_INVALIDPOS;
  }
  TextRange range(static_cast<size_t>(pSelection[0].acpStart),
                  static_cast<size_t>(pSelection[0].acpEnd));
  if (pSelection[0].style.ase == TS_AE_START) {
    range = TextRange(static_cast<size_t>(pSelection[0].acpEnd),
                      static_cast<size_t>(pSelection[0].acpStart));
  }
  cached_selection_ = range;
  if (delegate_) {
    delegate_->SetTsfSelection(range);
  }
  return S_OK;
}

STDMETHODIMP TsfTextStore::GetText(LONG acpStart,
                                   LONG acpEnd,
                                   WCHAR* pchPlain,
                                   ULONG cchPlainReq,
                                   ULONG* pcchPlainRet,
                                   TS_RUNINFO* prgRunInfo,
                                   ULONG cRunInfoReq,
                                   ULONG* pcRunInfoRet,
                                   LONG* pacpNext) {
  if (!pcchPlainRet || !pcRunInfoRet || !pacpNext) {
    return E_INVALIDARG;
  }
  *pcchPlainRet = 0;
  *pcRunInfoRet = 0;
  *pacpNext = acpStart;
  if (!HasReadLock()) {
    return TS_E_NOLOCK;
  }
  const std::u16string text = CurrentText();
  const LONG text_end = static_cast<LONG>(text.size());
  if (acpStart < 0 || acpStart > text_end) {
    return TF_E_INVALIDPOS;
  }
  if (acpEnd == -1) {
    acpEnd = text_end;
  }
  if (acpEnd < acpStart || acpEnd > text_end) {
    return TF_E_INVALIDPOS;
  }
  const ULONG available = static_cast<ULONG>(acpEnd - acpStart);
  const ULONG to_copy =
      pchPlain && cchPlainReq > 0 ? std::min(cchPlainReq, available) : 0;
  if (to_copy > 0) {
    std::copy_n(text.data() + acpStart, to_copy, pchPlain);
  }
  *pcchPlainRet = to_copy;
  if (prgRunInfo && cRunInfoReq > 0) {
    prgRunInfo[0].uCount = available;
    prgRunInfo[0].type = TS_RT_PLAIN;
    *pcRunInfoRet = 1;
  }
  *pacpNext = acpStart + static_cast<LONG>(to_copy);
  return S_OK;
}

STDMETHODIMP TsfTextStore::SetText(DWORD /*dwFlags*/,
                                   LONG acpStart,
                                   LONG acpEnd,
                                   const WCHAR* pchText,
                                   ULONG cch,
                                   TS_TEXTCHANGE* pChange) {
  if (!HasWriteLock()) {
    return TS_E_NOLOCK;
  }
  const LONG text_end = static_cast<LONG>(CurrentText().size());
  if (acpStart < 0 || acpEnd < acpStart || acpEnd > text_end) {
    return TF_E_INVALIDPOS;
  }
  std::u16string inserted;
  if (pchText && cch > 0) {
    inserted.assign(reinterpret_cast<const char16_t*>(pchText), cch);
  }
  if (delegate_) {
    if (composing_) {
      delegate_->OnTsfComposeUpdate(inserted,
                                    static_cast<int>(inserted.size()));
    } else {
      delegate_->ReplaceTsfText(
          TextRange(static_cast<size_t>(acpStart), static_cast<size_t>(acpEnd)),
          inserted);
    }
    cached_text_ = delegate_->GetTsfText();
    last_known_text_ = cached_text_;
    cached_selection_ = delegate_->GetTsfSelection();
    cache_valid_ = true;
  }
  if (pChange) {
    pChange->acpStart = acpStart;
    pChange->acpOldEnd = acpEnd;
    pChange->acpNewEnd = acpStart + static_cast<LONG>(cch);
  }
  return S_OK;
}

STDMETHODIMP TsfTextStore::GetFormattedText(LONG /*acpStart*/,
                                            LONG /*acpEnd*/,
                                            IDataObject** ppDataObject) {
  if (ppDataObject) {
    *ppDataObject = nullptr;
  }
  return E_NOTIMPL;
}

STDMETHODIMP TsfTextStore::GetEmbedded(LONG /*acpPos*/,
                                       REFGUID /*rguidService*/,
                                       REFIID /*riid*/,
                                       IUnknown** ppunk) {
  if (ppunk) {
    *ppunk = nullptr;
  }
  return E_NOTIMPL;
}

STDMETHODIMP TsfTextStore::QueryInsertEmbedded(const GUID* /*pguidService*/,
                                               const FORMATETC* /*pFormatEtc*/,
                                               BOOL* pfInsertable) {
  if (!pfInsertable) {
    return E_INVALIDARG;
  }
  *pfInsertable = FALSE;
  return S_OK;
}

STDMETHODIMP TsfTextStore::InsertEmbedded(DWORD /*dwFlags*/,
                                          LONG /*acpStart*/,
                                          LONG /*acpEnd*/,
                                          IDataObject* /*pDataObject*/,
                                          TS_TEXTCHANGE* /*pChange*/) {
  return E_NOTIMPL;
}

STDMETHODIMP TsfTextStore::InsertTextAtSelection(DWORD dwFlags,
                                                 const WCHAR* pchText,
                                                 ULONG cch,
                                                 LONG* pacpStart,
                                                 LONG* pacpEnd,
                                                 TS_TEXTCHANGE* pChange) {
  if (!HasWriteLock() && !(dwFlags & TS_IAS_QUERYONLY)) {
    return TS_E_NOLOCK;
  }
  const TextRange selection = CurrentSelection();
  const LONG start = static_cast<LONG>(selection.start());
  const LONG end = static_cast<LONG>(selection.end());
  if (dwFlags & TS_IAS_QUERYONLY) {
    if (pacpStart) {
      *pacpStart = start;
    }
    if (pacpEnd) {
      *pacpEnd = start + static_cast<LONG>(cch);
    }
    return S_OK;
  }
  HRESULT hr = SetText(0, start, end, pchText, cch, pChange);
  if (FAILED(hr)) {
    return hr;
  }
  if (pacpStart) {
    *pacpStart = start;
  }
  if (pacpEnd) {
    *pacpEnd = start + static_cast<LONG>(cch);
  }
  return S_OK;
}

STDMETHODIMP TsfTextStore::InsertEmbeddedAtSelection(
    DWORD /*dwFlags*/,
    IDataObject* /*pDataObject*/,
    LONG* /*pacpStart*/,
    LONG* /*pacpEnd*/,
    TS_TEXTCHANGE* /*pChange*/) {
  return E_NOTIMPL;
}

STDMETHODIMP TsfTextStore::RequestSupportedAttrs(
    DWORD /*dwFlags*/,
    ULONG /*cFilterAttrs*/,
    const TS_ATTRID* /*paFilterAttrs*/) {
  return S_OK;
}

STDMETHODIMP TsfTextStore::RequestAttrsAtPosition(
    LONG /*acpPos*/,
    ULONG /*cFilterAttrs*/,
    const TS_ATTRID* /*paFilterAttrs*/,
    DWORD /*dwFlags*/) {
  return S_OK;
}

STDMETHODIMP TsfTextStore::RequestAttrsTransitioningAtPosition(
    LONG /*acpPos*/,
    ULONG /*cFilterAttrs*/,
    const TS_ATTRID* /*paFilterAttrs*/,
    DWORD /*dwFlags*/) {
  return S_OK;
}

STDMETHODIMP TsfTextStore::FindNextAttrTransition(
    LONG acpStart,
    LONG /*acpHalt*/,
    ULONG /*cFilterAttrs*/,
    const TS_ATTRID* /*paFilterAttrs*/,
    DWORD /*dwFlags*/,
    LONG* pacpNext,
    BOOL* pfFound,
    LONG* plFoundOffset) {
  if (pacpNext) {
    *pacpNext = acpStart;
  }
  if (pfFound) {
    *pfFound = FALSE;
  }
  if (plFoundOffset) {
    *plFoundOffset = 0;
  }
  return S_OK;
}

STDMETHODIMP TsfTextStore::RetrieveRequestedAttrs(ULONG /*ulCount*/,
                                                  TS_ATTRVAL* /*paAttrVals*/,
                                                  ULONG* pcFetched) {
  if (pcFetched) {
    *pcFetched = 0;
  }
  return S_OK;
}

STDMETHODIMP TsfTextStore::GetEndACP(LONG* pacp) {
  if (!pacp) {
    return E_INVALIDARG;
  }
  if (!HasReadLock()) {
    return TS_E_NOLOCK;
  }
  *pacp = static_cast<LONG>(CurrentText().size());
  return S_OK;
}

STDMETHODIMP TsfTextStore::GetActiveView(TsViewCookie* pvcView) {
  if (!pvcView) {
    return E_INVALIDARG;
  }
  *pvcView = kViewCookie;
  return S_OK;
}

STDMETHODIMP TsfTextStore::GetACPFromPoint(TsViewCookie /*vcView*/,
                                           const POINT* /*ptScreen*/,
                                           DWORD /*dwFlags*/,
                                           LONG* /*pacp*/) {
  return TS_E_NOLAYOUT;
}

STDMETHODIMP TsfTextStore::GetTextExt(TsViewCookie vcView,
                                      LONG /*acpStart*/,
                                      LONG /*acpEnd*/,
                                      RECT* prc,
                                      BOOL* pfClipped) {
  if (!prc || !pfClipped) {
    return E_INVALIDARG;
  }
  if (vcView != kViewCookie) {
    return E_INVALIDARG;
  }
  *pfClipped = FALSE;
  *prc = RECT{};
  if (!delegate_) {
    return TS_E_NOLAYOUT;
  }
  HWND hwnd = delegate_->GetTsfWindowHandle();
  if (!hwnd) {
    return TS_E_NOLAYOUT;
  }
  const Rect caret = delegate_->GetTsfCaretRect();
  POINT top_left{static_cast<LONG>(std::lround(caret.left())),
                 static_cast<LONG>(std::lround(caret.top()))};
  POINT bottom_right{static_cast<LONG>(std::lround(caret.right())),
                     static_cast<LONG>(std::lround(caret.bottom()))};
  if (!ClientToScreen(hwnd, &top_left) ||
      !ClientToScreen(hwnd, &bottom_right)) {
    return TS_E_NOLAYOUT;
  }
  prc->left = top_left.x;
  prc->top = top_left.y;
  prc->right = bottom_right.x;
  prc->bottom = bottom_right.y;
  return S_OK;
}

STDMETHODIMP TsfTextStore::GetScreenExt(TsViewCookie vcView, RECT* prc) {
  if (!prc) {
    return E_INVALIDARG;
  }
  if (vcView != kViewCookie) {
    return E_INVALIDARG;
  }
  *prc = RECT{};
  if (!delegate_) {
    return TS_E_NOLAYOUT;
  }
  HWND hwnd = delegate_->GetTsfWindowHandle();
  if (!hwnd) {
    return TS_E_NOLAYOUT;
  }
  RECT client{};
  if (!GetClientRect(hwnd, &client)) {
    return TS_E_NOLAYOUT;
  }
  POINT top_left{client.left, client.top};
  POINT bottom_right{client.right, client.bottom};
  if (!ClientToScreen(hwnd, &top_left) ||
      !ClientToScreen(hwnd, &bottom_right)) {
    return TS_E_NOLAYOUT;
  }
  prc->left = top_left.x;
  prc->top = top_left.y;
  prc->right = bottom_right.x;
  prc->bottom = bottom_right.y;
  return S_OK;
}

STDMETHODIMP TsfTextStore::GetWnd(TsViewCookie vcView, HWND* phwnd) {
  if (!phwnd) {
    return E_INVALIDARG;
  }
  if (vcView != kViewCookie) {
    return E_INVALIDARG;
  }
  *phwnd = delegate_ ? delegate_->GetTsfWindowHandle() : nullptr;
  return S_OK;
}

STDMETHODIMP TsfTextStore::OnStartComposition(
    ITfCompositionView* /*pComposition*/,
    BOOL* pfOk) {
  if (!pfOk) {
    return E_INVALIDARG;
  }
  *pfOk = TRUE;
  composing_ = true;
  if (delegate_) {
    delegate_->OnTsfComposeBegin();
  }
  return S_OK;
}

STDMETHODIMP TsfTextStore::OnUpdateComposition(
    ITfCompositionView* /*pComposition*/,
    ITfRange* /*pRangeNew*/) {
  return S_OK;
}

STDMETHODIMP TsfTextStore::OnEndComposition(
    ITfCompositionView* /*pComposition*/) {
  composing_ = false;
  if (delegate_) {
    delegate_->OnTsfComposeEnd();
  }
  return S_OK;
}

}  // namespace flutter
