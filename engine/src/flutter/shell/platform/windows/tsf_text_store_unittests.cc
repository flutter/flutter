// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/tsf_text_store.h"

#include <wrl/client.h>
#include <wrl/implements.h>

#include <functional>

#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {

class FakeTsfDelegate : public TsfTextStoreDelegate {
 public:
  std::u16string GetTsfText() const override {
    get_text_call_count_++;
    return text_;
  }
  TextRange GetTsfSelection() const override {
    get_selection_call_count_++;
    return selection_;
  }
  void SetTsfSelection(const TextRange& range) override { selection_ = range; }
  void ReplaceTsfText(const TextRange& range,
                      const std::u16string& text) override {
    replace_call_count_++;
    last_replaced_range_ = range;
    last_replacement_text_ = text;
    text_.replace(range.start(), range.length(), text);
    selection_ = TextRange(range.start() + text.size());
  }
  void OnTsfComposeBegin() override {
    compose_begin_call_count_++;
    composing_ = true;
  }
  void OnTsfComposeUpdate(const std::u16string& text, int cursor_pos) override {
    compose_update_call_count_++;
    composing_text_ = text;
    cursor_pos_ = cursor_pos;
  }
  void OnTsfComposeEnd() override {
    compose_end_call_count_++;
    composing_ = false;
  }
  Rect GetTsfCaretRect() const override { return Rect({0, 0}, Size(1, 1)); }
  HWND GetTsfWindowHandle() const override { return nullptr; }

  std::u16string text_;
  TextRange selection_{0};
  mutable int get_text_call_count_ = 0;
  mutable int get_selection_call_count_ = 0;
  int replace_call_count_ = 0;
  TextRange last_replaced_range_{0};
  std::u16string last_replacement_text_;
  int compose_begin_call_count_ = 0;
  int compose_update_call_count_ = 0;
  int compose_end_call_count_ = 0;
  bool composing_ = false;
  std::u16string composing_text_;
  int cursor_pos_ = 0;
};

class FakeTextStoreACPSink
    : public Microsoft::WRL::RuntimeClass<
          Microsoft::WRL::RuntimeClassFlags<Microsoft::WRL::ClassicCom>,
          ITextStoreACPSink> {
 public:
  STDMETHODIMP OnTextChange(DWORD, const TS_TEXTCHANGE* change) override {
    text_change_call_count_++;
    last_text_change_ = *change;
    return S_OK;
  }

  STDMETHODIMP OnSelectionChange() override {
    selection_change_call_count_++;
    return S_OK;
  }

  STDMETHODIMP OnLayoutChange(TsLayoutCode code, TsViewCookie view) override {
    layout_change_call_count_++;
    last_layout_code_ = code;
    last_layout_view_ = view;
    return S_OK;
  }

  STDMETHODIMP OnStatusChange(DWORD) override { return S_OK; }

  STDMETHODIMP OnAttrsChange(LONG, LONG, ULONG, const TS_ATTRID*) override {
    return S_OK;
  }

  STDMETHODIMP OnLockGranted(DWORD lock_flags) override {
    lock_granted_call_count_++;
    last_lock_flags_ = lock_flags;
    return lock_callback_ ? lock_callback_(lock_flags) : S_OK;
  }

  STDMETHODIMP OnStartEditTransaction() override { return S_OK; }
  STDMETHODIMP OnEndEditTransaction() override { return S_OK; }

  std::function<HRESULT(DWORD)> lock_callback_;
  int lock_granted_call_count_ = 0;
  DWORD last_lock_flags_ = 0;
  int text_change_call_count_ = 0;
  TS_TEXTCHANGE last_text_change_{};
  int selection_change_call_count_ = 0;
  int layout_change_call_count_ = 0;
  TsLayoutCode last_layout_code_ = TS_LC_CREATE;
  TsViewCookie last_layout_view_ = 0;
};

class TsfTextStoreBehaviorTest : public ::testing::Test {
 protected:
  void SetUp() override {
    ASSERT_EQ(
        Microsoft::WRL::MakeAndInitialize<TsfTextStore>(&store_, &delegate_),
        S_OK);
    sink_ = Microsoft::WRL::Make<FakeTextStoreACPSink>();
    ASSERT_TRUE(store_);
    ASSERT_TRUE(sink_);
  }

  void AdviseSink(DWORD mask) {
    ASSERT_EQ(store_->AdviseSink(IID_ITextStoreACPSink, sink_.Get(), mask),
              S_OK);
  }

  FakeTsfDelegate delegate_;
  Microsoft::WRL::ComPtr<TsfTextStore> store_;
  Microsoft::WRL::ComPtr<FakeTextStoreACPSink> sink_;
};

}  // namespace

TEST_F(TsfTextStoreBehaviorTest, ReadAndWriteMethodsRequireAppropriateLock) {
  delegate_.text_ = u"hello";
  delegate_.selection_ = TextRange(1, 3);

  TS_SELECTION_ACP selection{};
  ULONG selection_count = 0;
  EXPECT_EQ(store_->GetSelection(TS_DEFAULT_SELECTION, 1, &selection,
                                 &selection_count),
            TS_E_NOLOCK);
  WCHAR text[1] = {};
  ULONG text_count = 0;
  ULONG run_count = 0;
  LONG next = 0;
  EXPECT_EQ(store_->GetText(0, -1, text, 1, &text_count, nullptr, 0, &run_count,
                            &next),
            TS_E_NOLOCK);
  LONG text_end = 0;
  EXPECT_EQ(store_->GetEndACP(&text_end), TS_E_NOLOCK);
  EXPECT_EQ(store_->SetSelection(1, &selection), TS_E_NOLOCK);
  EXPECT_EQ(store_->SetText(0, 0, 0, L"x", 1, nullptr), TS_E_NOLOCK);

  AdviseSink(0);
  sink_->lock_callback_ = [&](DWORD) {
    EXPECT_EQ(store_->GetEndACP(&text_end), S_OK);
    EXPECT_EQ(text_end, 5);
    EXPECT_EQ(store_->SetSelection(1, &selection), TS_E_NOLOCK);
    EXPECT_EQ(store_->SetText(0, 0, 0, L"x", 1, nullptr), TS_E_NOLOCK);
    return S_OK;
  };
  HRESULT session = E_FAIL;
  EXPECT_EQ(store_->RequestLock(TS_LF_READ, &session), S_OK);
  EXPECT_EQ(session, S_OK);
}

TEST_F(TsfTextStoreBehaviorTest, RequestLockGrantsLockWithSnapshotCache) {
  delegate_.text_ = u"cached";
  AdviseSink(0);
  sink_->lock_callback_ = [&](DWORD lock_flags) {
    EXPECT_EQ(lock_flags, static_cast<DWORD>(TS_LF_READ));
    delegate_.text_ = u"changed while locked";
    WCHAR text[16] = {};
    ULONG text_count = 0;
    ULONG run_count = 0;
    LONG next = 0;
    EXPECT_EQ(store_->GetText(0, -1, text, 16, &text_count, nullptr, 0,
                              &run_count, &next),
              S_OK);
    EXPECT_EQ(std::wstring(text, text_count), L"cached");
    return S_OK;
  };

  HRESULT session = E_FAIL;
  EXPECT_EQ(store_->RequestLock(TS_LF_READ, &session), S_OK);
  EXPECT_EQ(session, S_OK);
  EXPECT_EQ(sink_->lock_granted_call_count_, 1);
  EXPECT_EQ(sink_->last_lock_flags_, static_cast<DWORD>(TS_LF_READ));
  EXPECT_EQ(delegate_.get_text_call_count_, 1);

  delegate_.text_ = u"fresh";
  LONG start = -1;
  LONG end = -1;
  EXPECT_EQ(store_->QueryInsert(0, 5, 0, &start, &end), S_OK);
  EXPECT_EQ(start, 0);
  EXPECT_EQ(end, 5);
  EXPECT_EQ(delegate_.get_text_call_count_, 2);
}

TEST_F(TsfTextStoreBehaviorTest, SetTextReplacesTextOutsideComposition) {
  delegate_.text_ = u"hello";
  AdviseSink(0);
  sink_->lock_callback_ = [&](DWORD) {
    TS_TEXTCHANGE change{};
    EXPECT_EQ(store_->SetText(0, 1, 4, L"i", 1, &change), S_OK);
    EXPECT_EQ(change.acpStart, 1);
    EXPECT_EQ(change.acpOldEnd, 4);
    EXPECT_EQ(change.acpNewEnd, 2);
    return S_OK;
  };

  HRESULT session = E_FAIL;
  EXPECT_EQ(store_->RequestLock(TS_LF_READWRITE, &session), S_OK);
  EXPECT_EQ(session, S_OK);
  EXPECT_EQ(delegate_.replace_call_count_, 1);
  EXPECT_EQ(delegate_.last_replaced_range_.base(), 1u);
  EXPECT_EQ(delegate_.last_replaced_range_.extent(), 4u);
  EXPECT_EQ(delegate_.last_replacement_text_, u"i");
  EXPECT_EQ(delegate_.text_, u"hio");
  EXPECT_EQ(delegate_.compose_update_call_count_, 0);
}

TEST_F(TsfTextStoreBehaviorTest, SetTextUpdatesActiveComposition) {
  delegate_.text_ = u"hello";
  BOOL composition_accepted = FALSE;
  ASSERT_EQ(store_->OnStartComposition(nullptr, &composition_accepted), S_OK);
  ASSERT_TRUE(composition_accepted);
  AdviseSink(0);
  sink_->lock_callback_ = [&](DWORD) {
    EXPECT_EQ(store_->SetText(0, 1, 4, L"ime", 3, nullptr), S_OK);
    return S_OK;
  };

  HRESULT session = E_FAIL;
  EXPECT_EQ(store_->RequestLock(TS_LF_READWRITE, &session), S_OK);
  EXPECT_EQ(session, S_OK);
  EXPECT_EQ(delegate_.replace_call_count_, 0);
  EXPECT_EQ(delegate_.compose_update_call_count_, 1);
  EXPECT_EQ(delegate_.composing_text_, u"ime");
  EXPECT_EQ(delegate_.cursor_pos_, 3);
}

TEST_F(TsfTextStoreBehaviorTest, ReversedSelectionMapsInBothDirections) {
  delegate_.text_ = u"abcdef";
  delegate_.selection_ = TextRange(5, 2);
  AdviseSink(0);
  sink_->lock_callback_ = [&](DWORD) {
    TS_SELECTION_ACP selection{};
    ULONG selection_count = 0;
    EXPECT_EQ(store_->GetSelection(TS_DEFAULT_SELECTION, 1, &selection,
                                   &selection_count),
              S_OK);
    EXPECT_EQ(selection_count, 1u);
    EXPECT_EQ(selection.acpStart, 2);
    EXPECT_EQ(selection.acpEnd, 5);
    EXPECT_EQ(selection.style.ase, TS_AE_START);

    selection.acpStart = 1;
    selection.acpEnd = 4;
    selection.style.ase = TS_AE_START;
    EXPECT_EQ(store_->SetSelection(1, &selection), S_OK);
    return S_OK;
  };

  HRESULT session = E_FAIL;
  EXPECT_EQ(store_->RequestLock(TS_LF_READWRITE, &session), S_OK);
  EXPECT_EQ(session, S_OK);
  EXPECT_EQ(delegate_.selection_.base(), 4u);
  EXPECT_EQ(delegate_.selection_.extent(), 1u);
}

TEST_F(TsfTextStoreBehaviorTest, CompositionBeginAndEndAreForwardedToDelegate) {
  BOOL composition_accepted = FALSE;
  EXPECT_EQ(store_->OnStartComposition(nullptr, &composition_accepted), S_OK);
  EXPECT_TRUE(composition_accepted);
  EXPECT_TRUE(delegate_.composing_);
  EXPECT_EQ(delegate_.compose_begin_call_count_, 1);

  EXPECT_EQ(store_->OnEndComposition(nullptr), S_OK);
  EXPECT_FALSE(delegate_.composing_);
  EXPECT_EQ(delegate_.compose_end_call_count_, 1);
}

TEST_F(TsfTextStoreBehaviorTest, NotificationsAreGatedByAdviseMask) {
  delegate_.text_ = u"text";
  AdviseSink(TS_AS_TEXT_CHANGE | TS_AS_LAYOUT_CHANGE);

  store_->NotifyTextChanged();
  store_->NotifySelectionChanged();
  store_->NotifyLayoutChanged();
  EXPECT_EQ(sink_->text_change_call_count_, 1);
  EXPECT_EQ(sink_->last_text_change_.acpStart, 0);
  EXPECT_EQ(sink_->last_text_change_.acpOldEnd, 0);
  EXPECT_EQ(sink_->last_text_change_.acpNewEnd, 4);
  EXPECT_EQ(sink_->selection_change_call_count_, 0);
  EXPECT_EQ(sink_->layout_change_call_count_, 1);
  EXPECT_EQ(sink_->last_layout_code_, TS_LC_CHANGE);
  EXPECT_EQ(sink_->last_layout_view_, 1);

  delegate_.text_ = u"x";
  store_->NotifyTextChanged();
  EXPECT_EQ(sink_->text_change_call_count_, 2);
  EXPECT_EQ(sink_->last_text_change_.acpOldEnd, 4);
  EXPECT_EQ(sink_->last_text_change_.acpNewEnd, 1);

  AdviseSink(TS_AS_SEL_CHANGE);
  store_->NotifyTextChanged();
  store_->NotifySelectionChanged();
  store_->NotifyLayoutChanged();
  EXPECT_EQ(sink_->text_change_call_count_, 2);
  EXPECT_EQ(sink_->selection_change_call_count_, 1);
  EXPECT_EQ(sink_->layout_change_call_count_, 1);
}

TEST(TsfTextStoreTest, GetStatusSetsManualInputPaneFlag) {
  FakeTsfDelegate delegate;
  Microsoft::WRL::ComPtr<TsfTextStore> store;
  HRESULT hr =
      Microsoft::WRL::MakeAndInitialize<TsfTextStore>(&store, &delegate);
  ASSERT_EQ(hr, S_OK);
  ASSERT_TRUE(store);

  TS_STATUS status{};
  EXPECT_EQ(store->GetStatus(&status), S_OK);
  EXPECT_NE(status.dwDynamicFlags & TS_SD_INPUTPANEMANUALDISPLAYENABLE, 0u);
  EXPECT_NE(status.dwStaticFlags & TS_SS_NOHIDDENTEXT, 0u);
  EXPECT_NE(status.dwStaticFlags & TS_SS_TRANSITORY, 0u);
}

TEST(TsfTextStoreTest, GetStatusManualFlagIsDefault) {
  Microsoft::WRL::ComPtr<TsfTextStore> store;
  HRESULT hr = Microsoft::WRL::MakeAndInitialize<TsfTextStore>(&store, nullptr);
  ASSERT_EQ(hr, S_OK);

  TS_STATUS status{};
  EXPECT_EQ(store->GetStatus(&status), S_OK);
  EXPECT_EQ(status.dwDynamicFlags,
            static_cast<DWORD>(TS_SD_INPUTPANEMANUALDISPLAYENABLE));
}

TEST(TsfTextStoreTest, GetStatusRejectsNull) {
  Microsoft::WRL::ComPtr<TsfTextStore> store;
  HRESULT hr = Microsoft::WRL::MakeAndInitialize<TsfTextStore>(&store, nullptr);
  ASSERT_EQ(hr, S_OK);
  EXPECT_EQ(store->GetStatus(nullptr), E_INVALIDARG);
}

TEST(TsfTextStoreTest, EmptyStoreGetStatusSetsReadonly) {
  Microsoft::WRL::ComPtr<TsfTextStore> store;
  HRESULT hr = Microsoft::WRL::MakeAndInitialize<TsfTextStore>(&store, nullptr);
  ASSERT_EQ(hr, S_OK);
  store->UseEmptyTextStore(true);

  TS_STATUS status{};
  EXPECT_EQ(store->GetStatus(&status), S_OK);
  EXPECT_NE(status.dwDynamicFlags & TS_SD_INPUTPANEMANUALDISPLAYENABLE, 0u);
  EXPECT_NE(status.dwDynamicFlags & TS_SD_READONLY, 0u);
  EXPECT_NE(status.dwStaticFlags & TS_SS_NOHIDDENTEXT, 0u);
  EXPECT_NE(status.dwStaticFlags & TS_SS_TRANSITORY, 0u);
}

TEST(TsfTextStoreTest, EmptyStoreRequestLockFails) {
  Microsoft::WRL::ComPtr<TsfTextStore> store;
  HRESULT hr = Microsoft::WRL::MakeAndInitialize<TsfTextStore>(&store, nullptr);
  ASSERT_EQ(hr, S_OK);
  store->UseEmptyTextStore(true);

  HRESULT session = S_OK;
  EXPECT_EQ(store->RequestLock(TS_LF_READ, &session), E_FAIL);
  EXPECT_EQ(session, E_FAIL);
}

TEST(TsfTextStoreTest, RequestLockWithoutDelegateFails) {
  Microsoft::WRL::ComPtr<TsfTextStore> store;
  HRESULT hr = Microsoft::WRL::MakeAndInitialize<TsfTextStore>(&store, nullptr);
  ASSERT_EQ(hr, S_OK);

  HRESULT session = S_OK;
  EXPECT_EQ(store->RequestLock(TS_LF_READ, &session), E_UNEXPECTED);
  EXPECT_EQ(session, E_FAIL);
}

TEST(TsfTextStoreTest, GetWndWithoutDelegateIsNull) {
  Microsoft::WRL::ComPtr<TsfTextStore> store;
  HRESULT hr = Microsoft::WRL::MakeAndInitialize<TsfTextStore>(&store, nullptr);
  ASSERT_EQ(hr, S_OK);
  HWND hwnd = reinterpret_cast<HWND>(1);
  TsViewCookie view = 0;
  EXPECT_EQ(store->GetActiveView(&view), S_OK);
  EXPECT_EQ(store->GetWnd(view, &hwnd), S_OK);
  EXPECT_EQ(hwnd, nullptr);
}

}  // namespace testing
}  // namespace flutter
