// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_TSF_BRIDGE_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_TSF_BRIDGE_H_

#include <msctf.h>
#include <windows.h>
#include <wrl/client.h>

#include <functional>
#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/windows/tsf_text_store.h"

namespace flutter {

namespace testing {
class TsfBridgeWinTest;
}  // namespace testing

// Owns the TSF thread manager and the editable / non-editable documents.
//
// Chromium (ui/base/ime/win/tsf_bridge.cc, tsf_text_store.cc, and
// on_screen_keyboard_display_manager_input_pane.cc) splits Windows tablet
// keyboard into two layers. This type is the TSF / IME layer. InputPane
// TryShow / TryHide is the visibility layer (OnScreenKeyboard).
//
// HWND association vs thread focus (the gap that reopens the SIP):
//
// Chromium OnTextInputTypeChanged:
//   TEXT_INPUT_TYPE_NONE → ITfThreadMgr::AssociateFocus(hwnd, empty_doc)
//       only. AssociateFocus SetFocuses internally; they never call both.
//   any editor type     → ITfThreadMgr::SetFocus(editable_doc) only.
//       They never AssociateFocus the editable document onto the HWND.
//
// Windows SIP heuristics look at the document associated with the HWND, not
// at thread focus. Binding the editable store to the HWND (what we used to
// do) makes every later tap in the window look like an editor, so the OS
// re-shows the keyboard after pop / button / slider. Chromium avoids that
// by associating the HWND only with NONE (Win11 dummy store, or a Win10
// document with no context).
//
// FocusEditable  = Chromium non-NONE: SetFocus(editable) only.
// FocusNonEditable = Chromium NONE: AssociateFocus(hwnd, empty) only.
//
// Win11 empty store: probe ITfThreadMgr for GUID_COMPARTMENT_EMPTYCONTEXT,
// then a dummy ITextStoreACP with KEYBOARD_DISABLED + EMPTYCONTEXT
// compartments, TS_SD_READONLY, and denied RequestLock. Win10: empty
// document manager with no context.
//
// Flutter mapping (framework does not blur on tap-outside):
//   setClient / show after a pointer on the field → FocusEditable
//   clearClient / pointer that misses the field   → FocusNonEditable
//   InputPane Showing / Hiding                    → do not change TSF
//       (Chromium never updates TSF from InputPane events; hide+SetFocus
//       re-shows the SIP).
class TsfBridge {
 public:
  virtual ~TsfBridge() = default;

  // True if TSF and COM initialized successfully.
  virtual bool available() const = 0;

  // Chromium non-NONE: SetFocus the editable document. Does not AssociateFocus
  // that document onto |hwnd|. No-op if TSF is unavailable or |hwnd| is null.
  virtual void FocusEditable(HWND hwnd, TsfTextStoreDelegate* delegate) = 0;

  // Chromium NONE: AssociateFocus |hwnd| to the empty document. Does not also
  // call SetFocus. No-op if TSF is unavailable. Null |hwnd| uses the last
  // focused HWND, or SetFocus(empty) if there is none.
  virtual void FocusNonEditable(HWND hwnd) = 0;

  // Detaches the text-store delegate and any document associated with an HWND.
  virtual void ClearFocus() = 0;

  // Aborts any active TSF composition.
  virtual void AbortComposition() = 0;

  // Pushes Flutter-side text/selection/layout changes to TSF.
  virtual void NotifyTextChanged() = 0;
  virtual void NotifySelectionChanged() = 0;
  virtual void NotifyLayoutChanged() = 0;
};

// Default TSF bridge. Resolves TF_CreateThreadMgr from msctf.dll. Fails
// soft if COM is MTA or uninitialized (CO_E_NOTINITIALIZED).
class TsfBridgeWin : public TsfBridge {
 public:
  TsfBridgeWin();
  ~TsfBridgeWin() override;

  // |TsfBridge|
  bool available() const override;
  void FocusEditable(HWND hwnd, TsfTextStoreDelegate* delegate) override;
  void FocusNonEditable(HWND hwnd) override;
  void ClearFocus() override;
  void AbortComposition() override;
  void NotifyTextChanged() override;
  void NotifySelectionChanged() override;
  void NotifyLayoutChanged() override;

  // Exposed for tests that construct a store without the thread manager.
  TsfTextStore* text_store() const { return text_store_.Get(); }

 private:
  TsfBridgeWin(ITfThreadMgr* thread_mgr,
               ITfDocumentMgr* empty_document_mgr,
               ITfDocumentMgr* editable_document_mgr,
               std::function<void(TsfTextStoreDelegate*)> set_delegate);

  bool Initialize();
  void MaybeInitializeEmptyTextStore();
  HRESULT InitializeDisabledContext(ITfContext* context);
  void ClearAssociateFocus();

  Microsoft::WRL::ComPtr<ITfThreadMgr> thread_mgr_;
  Microsoft::WRL::ComPtr<ITfDocumentMgr> empty_document_mgr_;
  Microsoft::WRL::ComPtr<ITfContext> empty_context_;
  Microsoft::WRL::ComPtr<TsfTextStore> empty_text_store_;
  Microsoft::WRL::ComPtr<ITfDocumentMgr> editable_document_mgr_;
  Microsoft::WRL::ComPtr<ITfContext> editable_context_;
  Microsoft::WRL::ComPtr<TsfTextStore> text_store_;
  TfClientId client_id_ = TF_CLIENTID_NULL;
  TfEditCookie edit_cookie_ = TF_INVALID_EDIT_COOKIE;
  TfEditCookie empty_edit_cookie_ = TF_INVALID_EDIT_COOKIE;
  HWND focused_hwnd_ = nullptr;
  HWND associated_hwnd_ = nullptr;
  bool available_ = false;
  std::function<void(TsfTextStoreDelegate*)> set_delegate_;

  friend class testing::TsfBridgeWinTest;

  FML_DISALLOW_COPY_AND_ASSIGN(TsfBridgeWin);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_TSF_BRIDGE_H_
