// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/tsf_bridge.h"

#include <objbase.h>
#include <wrl/client.h>
#include <wrl/implements.h>

#include <memory>
#include <vector>

#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {

class FakeDocumentManager
    : public Microsoft::WRL::RuntimeClass<
          Microsoft::WRL::RuntimeClassFlags<Microsoft::WRL::ClassicCom>,
          ITfDocumentMgr> {
 public:
  STDMETHODIMP CreateContext(TfClientId,
                             DWORD,
                             IUnknown*,
                             ITfContext**,
                             TfEditCookie*) override {
    return E_NOTIMPL;
  }

  STDMETHODIMP Push(ITfContext*) override { return E_NOTIMPL; }

  STDMETHODIMP Pop(DWORD) override {
    pop_call_count++;
    return S_OK;
  }

  STDMETHODIMP GetTop(ITfContext**) override { return E_NOTIMPL; }
  STDMETHODIMP GetBase(ITfContext**) override { return E_NOTIMPL; }
  STDMETHODIMP EnumContexts(IEnumTfContexts**) override { return E_NOTIMPL; }

  int pop_call_count = 0;
};

class FakeThreadManager
    : public Microsoft::WRL::RuntimeClass<
          Microsoft::WRL::RuntimeClassFlags<Microsoft::WRL::ClassicCom>,
          ITfThreadMgr> {
 public:
  struct Association {
    HWND hwnd;
    ITfDocumentMgr* document_manager;
  };

  STDMETHODIMP Activate(TfClientId*) override { return E_NOTIMPL; }

  STDMETHODIMP Deactivate() override {
    deactivate_call_count++;
    return S_OK;
  }

  STDMETHODIMP CreateDocumentMgr(ITfDocumentMgr**) override {
    return E_NOTIMPL;
  }
  STDMETHODIMP EnumDocumentMgrs(IEnumTfDocumentMgrs**) override {
    return E_NOTIMPL;
  }
  STDMETHODIMP GetFocus(ITfDocumentMgr**) override { return E_NOTIMPL; }

  STDMETHODIMP SetFocus(ITfDocumentMgr* document_manager) override {
    set_focus_calls.push_back(document_manager);
    return S_OK;
  }

  STDMETHODIMP AssociateFocus(HWND hwnd,
                              ITfDocumentMgr* document_manager,
                              ITfDocumentMgr** previous) override {
    associate_focus_calls.push_back({hwnd, document_manager});
    if (previous != nullptr) {
      *previous = nullptr;
    }
    return S_OK;
  }

  STDMETHODIMP IsThreadFocus(BOOL*) override { return E_NOTIMPL; }
  STDMETHODIMP GetFunctionProvider(REFCLSID, ITfFunctionProvider**) override {
    return E_NOTIMPL;
  }
  STDMETHODIMP EnumFunctionProviders(IEnumTfFunctionProviders**) override {
    return E_NOTIMPL;
  }
  STDMETHODIMP GetGlobalCompartment(ITfCompartmentMgr**) override {
    return E_NOTIMPL;
  }

  std::vector<ITfDocumentMgr*> set_focus_calls;
  std::vector<Association> associate_focus_calls;
  int deactivate_call_count = 0;
};

class FakeTsfDelegate : public TsfTextStoreDelegate {
 public:
  std::u16string GetTsfText() const override { return {}; }
  TextRange GetTsfSelection() const override { return TextRange(0); }
  void SetTsfSelection(const TextRange&) override {}
  void ReplaceTsfText(const TextRange&, const std::u16string&) override {}
  void OnTsfComposeBegin() override {}
  void OnTsfComposeUpdate(const std::u16string&, int) override {}
  void OnTsfComposeEnd() override {}
  Rect GetTsfCaretRect() const override { return Rect({0, 0}, Size(1, 1)); }
  HWND GetTsfWindowHandle() const override { return nullptr; }
};

}  // namespace

class TsfBridgeWinTest : public ::testing::Test {
 protected:
  void SetUp() override {
    thread_manager_ = Microsoft::WRL::Make<FakeThreadManager>();
    empty_document_manager_ = Microsoft::WRL::Make<FakeDocumentManager>();
    editable_document_manager_ = Microsoft::WRL::Make<FakeDocumentManager>();
    ASSERT_TRUE(thread_manager_);
    ASSERT_TRUE(empty_document_manager_);
    ASSERT_TRUE(editable_document_manager_);
  }

  std::unique_ptr<TsfBridgeWin> CreateBridge() {
    return std::unique_ptr<TsfBridgeWin>(
        new TsfBridgeWin(thread_manager_.Get(), empty_document_manager_.Get(),
                         editable_document_manager_.Get(),
                         [this](TsfTextStoreDelegate* delegate) {
                           assigned_delegates_.push_back(delegate);
                         }));
  }

  Microsoft::WRL::ComPtr<FakeThreadManager> thread_manager_;
  Microsoft::WRL::ComPtr<FakeDocumentManager> empty_document_manager_;
  Microsoft::WRL::ComPtr<FakeDocumentManager> editable_document_manager_;
  std::vector<TsfTextStoreDelegate*> assigned_delegates_;
  FakeTsfDelegate delegate_;
};

TEST_F(TsfBridgeWinTest, FocusEditableSetsFocusWithoutAssociatingHwnd) {
  std::unique_ptr<TsfBridgeWin> bridge = CreateBridge();
  HWND hwnd = reinterpret_cast<HWND>(1);

  bridge->FocusEditable(hwnd, &delegate_);

  ASSERT_EQ(assigned_delegates_.size(), 1u);
  EXPECT_EQ(assigned_delegates_[0], &delegate_);
  ASSERT_EQ(thread_manager_->set_focus_calls.size(), 1u);
  EXPECT_EQ(thread_manager_->set_focus_calls[0],
            editable_document_manager_.Get());
  EXPECT_TRUE(thread_manager_->associate_focus_calls.empty());
}

TEST_F(TsfBridgeWinTest,
       FocusNonEditableAssociatesHwndWithoutAdditionalSetFocus) {
  std::unique_ptr<TsfBridgeWin> bridge = CreateBridge();
  HWND hwnd = reinterpret_cast<HWND>(1);
  bridge->FocusEditable(hwnd, &delegate_);

  bridge->FocusNonEditable(hwnd);

  ASSERT_EQ(assigned_delegates_.size(), 2u);
  EXPECT_EQ(assigned_delegates_[1], nullptr);
  ASSERT_EQ(thread_manager_->set_focus_calls.size(), 1u);
  ASSERT_EQ(thread_manager_->associate_focus_calls.size(), 1u);
  EXPECT_EQ(thread_manager_->associate_focus_calls[0].hwnd, hwnd);
  EXPECT_EQ(thread_manager_->associate_focus_calls[0].document_manager,
            empty_document_manager_.Get());
}

TEST_F(TsfBridgeWinTest, NullHwndUsesLastEditableHwnd) {
  std::unique_ptr<TsfBridgeWin> bridge = CreateBridge();
  HWND hwnd = reinterpret_cast<HWND>(1);
  bridge->FocusEditable(hwnd, &delegate_);

  bridge->FocusNonEditable(nullptr);
  bridge->FocusNonEditable(nullptr);

  ASSERT_EQ(thread_manager_->associate_focus_calls.size(), 2u);
  EXPECT_EQ(thread_manager_->associate_focus_calls[0].hwnd, hwnd);
  EXPECT_EQ(thread_manager_->associate_focus_calls[1].hwnd, hwnd);
  EXPECT_EQ(thread_manager_->set_focus_calls.size(), 1u);
}

TEST_F(TsfBridgeWinTest, ClearFocusClearsDelegateAndHwndAssociation) {
  std::unique_ptr<TsfBridgeWin> bridge = CreateBridge();
  HWND hwnd = reinterpret_cast<HWND>(1);
  bridge->FocusEditable(hwnd, &delegate_);
  bridge->FocusNonEditable(hwnd);

  bridge->ClearFocus();

  ASSERT_EQ(assigned_delegates_.size(), 3u);
  EXPECT_EQ(assigned_delegates_.back(), nullptr);
  ASSERT_EQ(thread_manager_->associate_focus_calls.size(), 2u);
  EXPECT_EQ(thread_manager_->associate_focus_calls[1].hwnd, hwnd);
  EXPECT_EQ(thread_manager_->associate_focus_calls[1].document_manager,
            nullptr);
}

TEST_F(TsfBridgeWinTest, NullHwndWithoutFallbackSetsFocusToEmptyDocument) {
  std::unique_ptr<TsfBridgeWin> bridge = CreateBridge();

  bridge->FocusNonEditable(nullptr);

  ASSERT_EQ(assigned_delegates_.size(), 1u);
  EXPECT_EQ(assigned_delegates_[0], nullptr);
  EXPECT_TRUE(thread_manager_->associate_focus_calls.empty());
  ASSERT_EQ(thread_manager_->set_focus_calls.size(), 1u);
  EXPECT_EQ(thread_manager_->set_focus_calls[0], empty_document_manager_.Get());
}

TEST(TsfBridgeWinInitializeTest, SkipsActivationWhenComIsMta) {
  const HRESULT hr = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
  if (hr == RPC_E_CHANGED_MODE) {
    GTEST_SKIP() << "Thread is already STA";
  }
  ASSERT_TRUE(SUCCEEDED(hr));

  TsfBridgeWin bridge;
  EXPECT_FALSE(bridge.available());

  if (hr == S_OK) {
    CoUninitialize();
  }
}

}  // namespace testing
}  // namespace flutter
