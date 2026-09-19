// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/tsf_bridge.h"

#include <objbase.h>

#include <utility>

#include "flutter/fml/logging.h"

namespace flutter {

namespace {

using TF_CreateThreadMgrFn = HRESULT(WINAPI*)(ITfThreadMgr**);

TF_CreateThreadMgrFn LoadCreateThreadMgr() {
  HMODULE module = LoadLibraryW(L"msctf.dll");
  if (!module) {
    return nullptr;
  }
  return reinterpret_cast<TF_CreateThreadMgrFn>(
      GetProcAddress(module, "TF_CreateThreadMgr"));
}

void LogTsfFailure(const char* api, HRESULT hr) {
  FML_LOG(WARNING) << "TSF " << api << " failed: 0x" << std::hex
                   << static_cast<unsigned long>(hr);
}

}  // namespace

TsfBridgeWin::TsfBridgeWin() {
  Initialize();
}

TsfBridgeWin::TsfBridgeWin(
    ITfThreadMgr* thread_mgr,
    ITfDocumentMgr* empty_document_mgr,
    ITfDocumentMgr* editable_document_mgr,
    std::function<void(TsfTextStoreDelegate*)> set_delegate)
    : thread_mgr_(thread_mgr),
      empty_document_mgr_(empty_document_mgr),
      editable_document_mgr_(editable_document_mgr),
      available_(true),
      set_delegate_(std::move(set_delegate)) {}

TsfBridgeWin::~TsfBridgeWin() {
  ClearFocus();
  if (empty_context_ && empty_document_mgr_) {
    empty_document_mgr_->Pop(TF_POPF_ALL);
  }
  if (editable_document_mgr_) {
    editable_document_mgr_->Pop(TF_POPF_ALL);
  }
  if (thread_mgr_) {
    thread_mgr_->Deactivate();
  }
}

bool TsfBridgeWin::available() const {
  return available_;
}

bool TsfBridgeWin::Initialize() {
  APTTYPE apt_type;
  APTTYPEQUALIFIER apt_qualifier;
  HRESULT hr = CoGetApartmentType(&apt_type, &apt_qualifier);
  if (FAILED(hr) || (apt_type != APTTYPE_STA && apt_type != APTTYPE_MAINSTA)) {
    LogTsfFailure("CoGetApartmentType(STA required)", hr);
    return false;
  }

  TF_CreateThreadMgrFn create_thread_mgr = LoadCreateThreadMgr();
  if (!create_thread_mgr) {
    LogTsfFailure("LoadLibrary(msctf.dll)",
                  HRESULT_FROM_WIN32(ERROR_PROC_NOT_FOUND));
    return false;
  }

  hr = create_thread_mgr(&thread_mgr_);
  if (FAILED(hr) || !thread_mgr_) {
    LogTsfFailure("TF_CreateThreadMgr", hr);
    thread_mgr_.Reset();
    return false;
  }

  hr = thread_mgr_->Activate(&client_id_);
  if (FAILED(hr)) {
    LogTsfFailure("ITfThreadMgr::Activate", hr);
    thread_mgr_.Reset();
    return false;
  }

  hr = thread_mgr_->CreateDocumentMgr(&empty_document_mgr_);
  if (FAILED(hr) || !empty_document_mgr_) {
    LogTsfFailure("CreateDocumentMgr(empty)", hr);
    thread_mgr_->Deactivate();
    thread_mgr_.Reset();
    return false;
  }
  MaybeInitializeEmptyTextStore();

  hr = thread_mgr_->CreateDocumentMgr(&editable_document_mgr_);
  if (FAILED(hr) || !editable_document_mgr_) {
    LogTsfFailure("CreateDocumentMgr(editable)", hr);
    thread_mgr_->Deactivate();
    thread_mgr_.Reset();
    return false;
  }

  hr = Microsoft::WRL::MakeAndInitialize<TsfTextStore>(&text_store_, nullptr);
  if (FAILED(hr) || !text_store_) {
    LogTsfFailure("TsfTextStore", hr);
    thread_mgr_->Deactivate();
    thread_mgr_.Reset();
    return false;
  }
  set_delegate_ = [this](TsfTextStoreDelegate* delegate) {
    text_store_->SetDelegate(delegate);
  };

  hr = editable_document_mgr_->CreateContext(
      client_id_, 0, static_cast<ITextStoreACP*>(text_store_.Get()),
      &editable_context_, &edit_cookie_);
  if (FAILED(hr) || !editable_context_) {
    LogTsfFailure("CreateContext", hr);
    thread_mgr_->Deactivate();
    thread_mgr_.Reset();
    return false;
  }

  hr = editable_document_mgr_->Push(editable_context_.Get());
  if (FAILED(hr)) {
    LogTsfFailure("Push", hr);
    thread_mgr_->Deactivate();
    thread_mgr_.Reset();
    return false;
  }

  available_ = true;
  return true;
}

void TsfBridgeWin::MaybeInitializeEmptyTextStore() {
  // Chromium probes Win11 empty-store support by QIing the thread manager
  // for GUID_COMPARTMENT_EMPTYCONTEXT. Failure means the Win10 path: a
  // document manager with no context.
  Microsoft::WRL::ComPtr<IUnknown> flag_empty_context;
  HRESULT hr = thread_mgr_->QueryInterface(
      GUID_COMPARTMENT_EMPTYCONTEXT,
      reinterpret_cast<void**>(flag_empty_context.ReleaseAndGetAddressOf()));
  if (FAILED(hr) || !flag_empty_context) {
    return;
  }

  hr = Microsoft::WRL::MakeAndInitialize<TsfTextStore>(&empty_text_store_,
                                                       nullptr);
  if (FAILED(hr) || !empty_text_store_) {
    LogTsfFailure("TsfTextStore(empty)", hr);
    empty_text_store_.Reset();
    return;
  }
  empty_text_store_->UseEmptyTextStore(true);

  hr = empty_document_mgr_->CreateContext(
      client_id_, 0, static_cast<ITextStoreACP*>(empty_text_store_.Get()),
      &empty_context_, &empty_edit_cookie_);
  if (FAILED(hr) || !empty_context_) {
    LogTsfFailure("CreateContext(empty)", hr);
    empty_context_.Reset();
    empty_text_store_.Reset();
    return;
  }

  hr = empty_document_mgr_->Push(empty_context_.Get());
  if (FAILED(hr)) {
    LogTsfFailure("Push(empty)", hr);
    empty_context_.Reset();
    empty_text_store_.Reset();
    return;
  }

  hr = InitializeDisabledContext(empty_context_.Get());
  if (FAILED(hr)) {
    LogTsfFailure("InitializeDisabledContext", hr);
  }
}

HRESULT TsfBridgeWin::InitializeDisabledContext(ITfContext* context) {
  Microsoft::WRL::ComPtr<ITfCompartmentMgr> compartment_mgr;
  HRESULT hr = context->QueryInterface(IID_PPV_ARGS(&compartment_mgr));
  if (FAILED(hr) || !compartment_mgr) {
    return FAILED(hr) ? hr : E_FAIL;
  }

  Microsoft::WRL::ComPtr<ITfCompartment> disabled;
  hr = compartment_mgr->GetCompartment(GUID_COMPARTMENT_KEYBOARD_DISABLED,
                                       &disabled);
  if (FAILED(hr) || !disabled) {
    return FAILED(hr) ? hr : E_FAIL;
  }
  VARIANT disabled_value{.vt = VT_I4, .lVal = 1};
  hr = disabled->SetValue(client_id_, &disabled_value);
  if (FAILED(hr)) {
    return hr;
  }

  Microsoft::WRL::ComPtr<ITfCompartment> empty_context;
  hr = compartment_mgr->GetCompartment(GUID_COMPARTMENT_EMPTYCONTEXT,
                                       &empty_context);
  if (FAILED(hr) || !empty_context) {
    return FAILED(hr) ? hr : E_FAIL;
  }
  VARIANT empty_value{.vt = VT_I4, .lVal = 1};
  return empty_context->SetValue(client_id_, &empty_value);
}

void TsfBridgeWin::FocusEditable(HWND hwnd, TsfTextStoreDelegate* delegate) {
  if (!available_ || hwnd == nullptr) {
    return;
  }
  if (associated_hwnd_ != nullptr && associated_hwnd_ != hwnd) {
    ClearAssociateFocus();
  }
  if (set_delegate_) {
    set_delegate_(delegate);
  }
  // Chromium non-NONE: SetFocus only. AssociateFocus of the editable
  // document onto the HWND is what makes Windows SIP heuristics treat
  // every later tap in the window as an editor.
  HRESULT hr = thread_mgr_->SetFocus(editable_document_mgr_.Get());
  if (FAILED(hr)) {
    LogTsfFailure("SetFocus(editable)", hr);
  }
  focused_hwnd_ = hwnd;
}

void TsfBridgeWin::FocusNonEditable(HWND hwnd) {
  if (!available_) {
    return;
  }
  if (set_delegate_) {
    set_delegate_(nullptr);
  }

  // Chromium TEXT_INPUT_TYPE_NONE: AssociateFocus only. It SetFocuses
  // internally. Calling SetFocus as well notifies TSF twice and can
  // re-invoke the SIP.
  HWND associate_hwnd = hwnd != nullptr ? hwnd : focused_hwnd_;
  if (associate_hwnd != nullptr) {
    if (associated_hwnd_ != nullptr && associated_hwnd_ != associate_hwnd) {
      ClearAssociateFocus();
    }
    Microsoft::WRL::ComPtr<ITfDocumentMgr> previous;
    HRESULT hr = thread_mgr_->AssociateFocus(
        associate_hwnd, empty_document_mgr_.Get(), &previous);
    if (FAILED(hr)) {
      LogTsfFailure("AssociateFocus(empty)", hr);
    }
  } else {
    HRESULT hr = thread_mgr_->SetFocus(empty_document_mgr_.Get());
    if (FAILED(hr)) {
      LogTsfFailure("SetFocus(empty)", hr);
    }
  }
  focused_hwnd_ = associate_hwnd;
  associated_hwnd_ = associate_hwnd;
}

void TsfBridgeWin::ClearFocus() {
  if (set_delegate_) {
    set_delegate_(nullptr);
  }
  ClearAssociateFocus();
  focused_hwnd_ = nullptr;
}

void TsfBridgeWin::ClearAssociateFocus() {
  if (!thread_mgr_ || associated_hwnd_ == nullptr) {
    associated_hwnd_ = nullptr;
    return;
  }
  Microsoft::WRL::ComPtr<ITfDocumentMgr> previous;
  HRESULT hr =
      thread_mgr_->AssociateFocus(associated_hwnd_, nullptr, &previous);
  if (FAILED(hr)) {
    LogTsfFailure("AssociateFocus(clear)", hr);
  }
  associated_hwnd_ = nullptr;
}

void TsfBridgeWin::AbortComposition() {
  if (!available_ || !editable_context_) {
    return;
  }
  Microsoft::WRL::ComPtr<ITfContextOwnerCompositionServices> composition;
  HRESULT hr = editable_context_.As(&composition);
  if (FAILED(hr) || !composition) {
    return;
  }
  composition->TerminateComposition(nullptr);
}

void TsfBridgeWin::NotifyTextChanged() {
  if (text_store_) {
    text_store_->NotifyTextChanged();
  }
}

void TsfBridgeWin::NotifySelectionChanged() {
  if (text_store_) {
    text_store_->NotifySelectionChanged();
  }
}

void TsfBridgeWin::NotifyLayoutChanged() {
  if (text_store_) {
    text_store_->NotifyLayoutChanged();
  }
}

}  // namespace flutter
