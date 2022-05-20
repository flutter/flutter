// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/direct_manipulation.h"
#include "flutter/shell/platform/windows/testing/mock_window_binding_handler_delegate.h"

#include "gtest/gtest.h"

using testing::_;

namespace flutter {
namespace testing {

class MockIDirectManipulationViewport : public IDirectManipulationViewport {
 public:
  MockIDirectManipulationViewport() {}

  // Prevent copying.
  MockIDirectManipulationViewport(MockIDirectManipulationViewport const&) =
      delete;
  MockIDirectManipulationViewport& operator=(
      MockIDirectManipulationViewport const&) = delete;
  MOCK_METHOD0_WITH_CALLTYPE(STDMETHODCALLTYPE, AddRef, ULONG());
  MOCK_METHOD0_WITH_CALLTYPE(STDMETHODCALLTYPE, Release, ULONG());
  MOCK_METHOD2_WITH_CALLTYPE(STDMETHODCALLTYPE,
                             QueryInterface,
                             HRESULT(REFIID, void**));
  MOCK_METHOD0_WITH_CALLTYPE(STDMETHODCALLTYPE, Abandon, HRESULT());
  MOCK_METHOD1_WITH_CALLTYPE(STDMETHODCALLTYPE,
                             ActivateConfiguration,
                             HRESULT(DIRECTMANIPULATION_CONFIGURATION));
  MOCK_METHOD1_WITH_CALLTYPE(STDMETHODCALLTYPE,
                             AddConfiguration,
                             HRESULT(DIRECTMANIPULATION_CONFIGURATION));
  MOCK_METHOD1_WITH_CALLTYPE(STDMETHODCALLTYPE,
                             AddContent,
                             HRESULT(IDirectManipulationContent*));
  MOCK_METHOD3_WITH_CALLTYPE(STDMETHODCALLTYPE,
                             AddEventHandler,
                             HRESULT(HWND,
                                     IDirectManipulationViewportEventHandler*,
                                     DWORD*));
  MOCK_METHOD0_WITH_CALLTYPE(STDMETHODCALLTYPE, Disable, HRESULT());
  MOCK_METHOD0_WITH_CALLTYPE(STDMETHODCALLTYPE, Enable, HRESULT());
  MOCK_METHOD2_WITH_CALLTYPE(STDMETHODCALLTYPE,
                             GetPrimaryContent,
                             HRESULT(REFIID, void**));
  MOCK_METHOD1_WITH_CALLTYPE(STDMETHODCALLTYPE,
                             GetStatus,
                             HRESULT(DIRECTMANIPULATION_STATUS*));
  MOCK_METHOD3_WITH_CALLTYPE(STDMETHODCALLTYPE,
                             GetTag,
                             HRESULT(REFIID, void**, UINT32*));
  MOCK_METHOD1_WITH_CALLTYPE(STDMETHODCALLTYPE,
                             GetViewportRect,
                             HRESULT(RECT*));
  MOCK_METHOD0_WITH_CALLTYPE(STDMETHODCALLTYPE, ReleaseAllContacts, HRESULT());
  MOCK_METHOD1_WITH_CALLTYPE(STDMETHODCALLTYPE,
                             ReleaseContact,
                             HRESULT(UINT32));
  MOCK_METHOD1_WITH_CALLTYPE(STDMETHODCALLTYPE,
                             RemoveConfiguration,
                             HRESULT(DIRECTMANIPULATION_CONFIGURATION));
  MOCK_METHOD1_WITH_CALLTYPE(STDMETHODCALLTYPE,
                             RemoveContent,
                             HRESULT(IDirectManipulationContent*));
  MOCK_METHOD1_WITH_CALLTYPE(STDMETHODCALLTYPE,
                             RemoveEventHandler,
                             HRESULT(DWORD));
  MOCK_METHOD1_WITH_CALLTYPE(STDMETHODCALLTYPE,
                             SetChaining,
                             HRESULT(DIRECTMANIPULATION_MOTION_TYPES));
  MOCK_METHOD1_WITH_CALLTYPE(STDMETHODCALLTYPE, SetContact, HRESULT(UINT32));
  MOCK_METHOD1_WITH_CALLTYPE(STDMETHODCALLTYPE,
                             SetInputMode,
                             HRESULT(DIRECTMANIPULATION_INPUT_MODE));
  MOCK_METHOD1_WITH_CALLTYPE(STDMETHODCALLTYPE,
                             SetManualGesture,
                             HRESULT(DIRECTMANIPULATION_GESTURE_CONFIGURATION));
  MOCK_METHOD2_WITH_CALLTYPE(STDMETHODCALLTYPE,
                             SetTag,
                             HRESULT(IUnknown*, UINT32));
  MOCK_METHOD1_WITH_CALLTYPE(STDMETHODCALLTYPE,
                             SetUpdateMode,
                             HRESULT(DIRECTMANIPULATION_INPUT_MODE));
  MOCK_METHOD1_WITH_CALLTYPE(STDMETHODCALLTYPE,
                             SetViewportOptions,
                             HRESULT(DIRECTMANIPULATION_VIEWPORT_OPTIONS));
  MOCK_METHOD1_WITH_CALLTYPE(STDMETHODCALLTYPE,
                             SetViewportRect,
                             HRESULT(const RECT*));
  MOCK_METHOD2_WITH_CALLTYPE(STDMETHODCALLTYPE,
                             SetViewportTransform,
                             HRESULT(const float*, DWORD));
  MOCK_METHOD0_WITH_CALLTYPE(STDMETHODCALLTYPE, Stop, HRESULT());
  MOCK_METHOD2_WITH_CALLTYPE(STDMETHODCALLTYPE,
                             SyncDisplayTransform,
                             HRESULT(const float*, DWORD));
  MOCK_METHOD5_WITH_CALLTYPE(
      STDMETHODCALLTYPE,
      ZoomToRect,
      HRESULT(const float, const float, const float, const float, BOOL));
};

class MockIDirectManipulationContent : public IDirectManipulationContent {
 public:
  MockIDirectManipulationContent() {}

  // Prevent copying.
  MockIDirectManipulationContent(MockIDirectManipulationContent const&) =
      delete;
  MockIDirectManipulationContent& operator=(
      MockIDirectManipulationContent const&) = delete;
  MOCK_METHOD0_WITH_CALLTYPE(STDMETHODCALLTYPE, AddRef, ULONG());
  MOCK_METHOD0_WITH_CALLTYPE(STDMETHODCALLTYPE, Release, ULONG());
  MOCK_METHOD2_WITH_CALLTYPE(STDMETHODCALLTYPE,
                             QueryInterface,
                             HRESULT(REFIID, void**));
  MOCK_METHOD1_WITH_CALLTYPE(STDMETHODCALLTYPE, GetContentRect, HRESULT(RECT*));
  MOCK_METHOD2_WITH_CALLTYPE(STDMETHODCALLTYPE,
                             GetContentTransform,
                             HRESULT(float*, DWORD));
  MOCK_METHOD2_WITH_CALLTYPE(STDMETHODCALLTYPE,
                             GetOutputTransform,
                             HRESULT(float*, DWORD));
  MOCK_METHOD3_WITH_CALLTYPE(STDMETHODCALLTYPE,
                             GetTag,
                             HRESULT(REFIID, void**, UINT32*));
  MOCK_METHOD2_WITH_CALLTYPE(STDMETHODCALLTYPE,
                             GetViewport,
                             HRESULT(REFIID, void**));
  MOCK_METHOD1_WITH_CALLTYPE(STDMETHODCALLTYPE,
                             SetContentRect,
                             HRESULT(const RECT*));
  MOCK_METHOD2_WITH_CALLTYPE(STDMETHODCALLTYPE,
                             SetTag,
                             HRESULT(IUnknown*, UINT32));
  MOCK_METHOD2_WITH_CALLTYPE(STDMETHODCALLTYPE,
                             SyncContentTransform,
                             HRESULT(const float*, DWORD));
};

TEST(DirectManipulationTest, TestGesture) {
  MockIDirectManipulationContent content;
  MockWindowBindingHandlerDelegate delegate;
  MockIDirectManipulationViewport viewport;
  const float scale = 1.5;
  const float pan_x = 32.0;
  const float pan_y = 16.0;
  const int DISPLAY_WIDTH = 800;
  const int DISPLAY_HEIGHT = 600;
  auto owner = std::make_unique<DirectManipulationOwner>(nullptr);
  owner->SetBindingHandlerDelegate(&delegate);
  auto handler =
      fml::MakeRefCounted<DirectManipulationEventHandler>(owner.get());
  int32_t device_id = (int32_t) reinterpret_cast<int64_t>(handler.get());
  EXPECT_CALL(delegate, OnPointerPanZoomStart(device_id));
  handler->OnViewportStatusChanged((IDirectManipulationViewport*)&viewport,
                                   DIRECTMANIPULATION_RUNNING,
                                   DIRECTMANIPULATION_READY);
  EXPECT_CALL(content, GetContentTransform(_, 6))
      .WillOnce(::testing::Invoke(
          [scale, pan_x, pan_y](float* transform, DWORD size) {
            transform[0] = scale;
            transform[4] = pan_x;
            transform[5] = pan_y;
            return S_OK;
          }));
  EXPECT_CALL(delegate,
              OnPointerPanZoomUpdate(device_id, pan_x, pan_y, scale, 0));
  handler->OnContentUpdated((IDirectManipulationViewport*)&viewport,
                            (IDirectManipulationContent*)&content);
  EXPECT_CALL(delegate, OnPointerPanZoomEnd(device_id));
  EXPECT_CALL(viewport, GetViewportRect(_))
      .WillOnce(::testing::Invoke([DISPLAY_WIDTH, DISPLAY_HEIGHT](RECT* rect) {
        rect->left = 0;
        rect->top = 0;
        rect->right = DISPLAY_WIDTH;
        rect->bottom = DISPLAY_HEIGHT;
        return S_OK;
      }));
  EXPECT_CALL(viewport, ZoomToRect(0, 0, DISPLAY_WIDTH, DISPLAY_HEIGHT, false))
      .WillOnce(::testing::Return(S_OK));
  handler->OnViewportStatusChanged((IDirectManipulationViewport*)&viewport,
                                   DIRECTMANIPULATION_INERTIA,
                                   DIRECTMANIPULATION_RUNNING);
  handler->OnViewportStatusChanged((IDirectManipulationViewport*)&viewport,
                                   DIRECTMANIPULATION_READY,
                                   DIRECTMANIPULATION_INERTIA);
}

// Verify that scale mantissa rounding works as expected
TEST(DirectManipulationTest, TestRounding) {
  MockIDirectManipulationContent content;
  MockWindowBindingHandlerDelegate delegate;
  MockIDirectManipulationViewport viewport;
  const float scale = 1.5;
  const int DISPLAY_WIDTH = 800;
  const int DISPLAY_HEIGHT = 600;
  auto owner = std::make_unique<DirectManipulationOwner>(nullptr);
  owner->SetBindingHandlerDelegate(&delegate);
  auto handler =
      fml::MakeRefCounted<DirectManipulationEventHandler>(owner.get());
  int32_t device_id = (int32_t) reinterpret_cast<int64_t>(handler.get());
  EXPECT_CALL(delegate, OnPointerPanZoomStart(device_id));
  handler->OnViewportStatusChanged((IDirectManipulationViewport*)&viewport,
                                   DIRECTMANIPULATION_RUNNING,
                                   DIRECTMANIPULATION_READY);
  EXPECT_CALL(content, GetContentTransform(_, 6))
      .WillOnce(::testing::Invoke([scale](float* transform, DWORD size) {
        transform[0] = 1.5000001f;
        transform[4] = 4.0;
        transform[5] = 0.0;
        return S_OK;
      }))
      .RetiresOnSaturation();
  EXPECT_CALL(delegate,
              OnPointerPanZoomUpdate(device_id, 4.0, 0, 1.5000001f, 0))
      .Times(0);
  EXPECT_CALL(delegate, OnPointerPanZoomUpdate(device_id, 4.0, 0, 1.5f, 0))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(content, GetContentTransform(_, 6))
      .WillOnce(::testing::Invoke([scale](float* transform, DWORD size) {
        transform[0] = 1.50000065f;
        transform[4] = 2.0;
        transform[5] = 0.0;
        return S_OK;
      }))
      .RetiresOnSaturation();
  EXPECT_CALL(delegate,
              OnPointerPanZoomUpdate(device_id, 2.0, 0, 1.50000065f, 0))
      .Times(0);
  EXPECT_CALL(delegate,
              OnPointerPanZoomUpdate(device_id, 2.0, 0, 1.50000047f, 0))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(delegate, OnPointerPanZoomEnd(device_id));
  EXPECT_CALL(viewport, GetViewportRect(_))
      .WillOnce(::testing::Invoke([DISPLAY_WIDTH, DISPLAY_HEIGHT](RECT* rect) {
        rect->left = 0;
        rect->top = 0;
        rect->right = DISPLAY_WIDTH;
        rect->bottom = DISPLAY_HEIGHT;
        return S_OK;
      }));
  EXPECT_CALL(viewport, ZoomToRect(0, 0, DISPLAY_WIDTH, DISPLAY_HEIGHT, false))
      .WillOnce(::testing::Return(S_OK));
  handler->OnContentUpdated((IDirectManipulationViewport*)&viewport,
                            (IDirectManipulationContent*)&content);
  handler->OnContentUpdated((IDirectManipulationViewport*)&viewport,
                            (IDirectManipulationContent*)&content);
  handler->OnViewportStatusChanged((IDirectManipulationViewport*)&viewport,
                                   DIRECTMANIPULATION_INERTIA,
                                   DIRECTMANIPULATION_RUNNING);
  handler->OnViewportStatusChanged((IDirectManipulationViewport*)&viewport,
                                   DIRECTMANIPULATION_READY,
                                   DIRECTMANIPULATION_INERTIA);
}

}  // namespace testing
}  // namespace flutter
