// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <XCTest/XCTest.h>

#include "flutter/common/constants.h"
#include "flutter/flow/surface_frame.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViewsController.h"
#import "flutter/shell/platform/darwin/ios/ios_context_noop.h"
#import "flutter/shell/platform/darwin/ios/ios_external_view_embedder.h"

FLUTTER_ASSERT_ARC

namespace {
constexpr int64_t kSecondaryFlutterViewId = flutter::kFlutterImplicitViewId + 1;
constexpr int64_t kTertiaryFlutterViewId = flutter::kFlutterImplicitViewId + 2;
}  // namespace

@interface FlutterPlatformViewsControllerSpy : FlutterPlatformViewsController {
 @public
  int beginFrameCalls_;
  flutter::DlISize lastBeginFrameSize_;
  int64_t lastBeginFrameViewId_;

  int submitFrameCalls_;
  uintptr_t lastSubmittedFrameAddress_;
  int64_t lastSubmittedViewId_;

  int collectViewCalls_;
  int64_t lastCollectedViewId_;
}
@end

@implementation FlutterPlatformViewsControllerSpy

- (void)beginFrameWithSize:(flutter::DlISize)frameSize flutterViewId:(int64_t)flutterViewId {
  beginFrameCalls_++;
  lastBeginFrameSize_ = frameSize;
  lastBeginFrameViewId_ = flutterViewId;
}

- (BOOL)submitFrame:(std::unique_ptr<flutter::SurfaceFrame>)frame
       withIosContext:(const std::shared_ptr<flutter::IOSContext>&)iosContext
    withFlutterViewId:(int64_t)flutterViewId {
  submitFrameCalls_++;
  lastSubmittedFrameAddress_ = reinterpret_cast<uintptr_t>(frame.get());
  lastSubmittedViewId_ = flutterViewId;
  return YES;
}

- (void)collectView:(int64_t)flutterViewId {
  collectViewCalls_++;
  lastCollectedViewId_ = flutterViewId;
}

@end

@interface IOSExternalViewEmbedderTest : XCTestCase
@end

@implementation IOSExternalViewEmbedderTest

- (void)testPrepareFlutterViewCreatesPendingFrameAndExposesRootCanvas {
  auto iosContext = std::make_shared<flutter::IOSContextNoop>();
  FlutterPlatformViewsControllerSpy* controller = [[FlutterPlatformViewsControllerSpy alloc] init];

  int callbackCalls = 0;
  int64_t createdViewId = -1;
  flutter::DlISize createdFrameSize;
  flutter::DlCanvas* expectedCanvas = nullptr;

  flutter::IOSExternalViewEmbedder embedder(
      controller, iosContext, [&](int64_t flutter_view_id, flutter::DlISize& frame_size) {
        callbackCalls++;
        createdViewId = flutter_view_id;
        createdFrameSize = frame_size;
        flutter::SurfaceFrame::FramebufferInfo framebuffer_info;
        auto frame = std::make_unique<flutter::SurfaceFrame>(
            /*surface=*/nullptr,
            /*framebuffer_info=*/framebuffer_info,
            /*encode_callback=*/[](flutter::SurfaceFrame&, flutter::DlCanvas*) { return true; },
            /*submit_callback=*/[](flutter::SurfaceFrame&) { return true; },
            /*frame_size=*/frame_size,
            /*context_result=*/nullptr,
            /*display_list_fallback=*/true);
        expectedCanvas = frame->Canvas();
        return frame;
      });
  flutter::ExternalViewEmbedder& embedder_ref = embedder;

  const flutter::DlISize frameSize(100, 200);
  embedder_ref.PrepareFlutterView(/*flutter_view_id=*/kSecondaryFlutterViewId, frameSize,
                                  /*device_pixel_ratio=*/2.0);

  XCTAssertEqual(callbackCalls, 1);
  XCTAssertEqual(createdViewId, kSecondaryFlutterViewId);
  XCTAssertEqual(createdFrameSize.width, frameSize.width);
  XCTAssertEqual(createdFrameSize.height, frameSize.height);
  XCTAssertEqual(controller->beginFrameCalls_, 1);
  XCTAssertEqual(controller->lastBeginFrameViewId_, kSecondaryFlutterViewId);
  XCTAssertEqual(controller->lastBeginFrameSize_.width, frameSize.width);
  XCTAssertEqual(controller->lastBeginFrameSize_.height, frameSize.height);
  XCTAssertEqual(embedder_ref.GetRootCanvas(), expectedCanvas);
}

- (void)testSubmitFlutterViewSubmitsPendingFrameAndCurrentFrame {
  auto iosContext = std::make_shared<flutter::IOSContextNoop>();
  FlutterPlatformViewsControllerSpy* controller = [[FlutterPlatformViewsControllerSpy alloc] init];

  uintptr_t pendingFrameAddress = 0;
  flutter::IOSExternalViewEmbedder embedder(
      controller, iosContext, [&](int64_t flutter_view_id, flutter::DlISize& frame_size) {
        flutter::SurfaceFrame::FramebufferInfo framebuffer_info;
        auto frame = std::make_unique<flutter::SurfaceFrame>(
            /*surface=*/nullptr,
            /*framebuffer_info=*/framebuffer_info,
            /*encode_callback=*/[](flutter::SurfaceFrame&, flutter::DlCanvas*) { return true; },
            /*submit_callback=*/[](flutter::SurfaceFrame&) { return true; },
            /*frame_size=*/frame_size,
            /*context_result=*/nullptr,
            /*display_list_fallback=*/true);
        pendingFrameAddress = reinterpret_cast<uintptr_t>(frame.get());
        return frame;
      });
  flutter::ExternalViewEmbedder& embedder_ref = embedder;

  flutter::DlISize frameSize(64, 64);
  embedder_ref.PrepareFlutterView(/*flutter_view_id=*/kTertiaryFlutterViewId, frameSize,
                                  /*device_pixel_ratio=*/1.0);

  bool frameWasSubmitted = false;
  flutter::SurfaceFrame::FramebufferInfo framebuffer_info;
  auto frame = std::make_unique<flutter::SurfaceFrame>(
      /*surface=*/nullptr,
      /*framebuffer_info=*/framebuffer_info,
      /*encode_callback=*/[](flutter::SurfaceFrame&, flutter::DlCanvas*) { return true; },
      /*submit_callback=*/
      [&frameWasSubmitted](flutter::SurfaceFrame&) {
        frameWasSubmitted = true;
        return true;
      },
      /*frame_size=*/frameSize,
      /*context_result=*/nullptr,
      /*display_list_fallback=*/true);

  embedder_ref.SubmitFlutterView(/*flutter_view_id=*/kTertiaryFlutterViewId,
                                 /*context=*/nullptr,
                                 /*aiks_context=*/nullptr, std::move(frame));

  XCTAssertEqual(controller->submitFrameCalls_, 1);
  XCTAssertEqual(controller->lastSubmittedViewId_, kTertiaryFlutterViewId);
  XCTAssertEqual(controller->lastSubmittedFrameAddress_, pendingFrameAddress);
  XCTAssertTrue(frameWasSubmitted);
}

- (void)testCollectViewForwardsToPlatformViewsController {
  auto iosContext = std::make_shared<flutter::IOSContextNoop>();
  FlutterPlatformViewsControllerSpy* controller = [[FlutterPlatformViewsControllerSpy alloc] init];

  flutter::IOSExternalViewEmbedder embedder(
      controller, iosContext, [](int64_t flutter_view_id, flutter::DlISize& frame_size) {
        flutter::SurfaceFrame::FramebufferInfo framebuffer_info;
        return std::make_unique<flutter::SurfaceFrame>(
            /*surface=*/nullptr,
            /*framebuffer_info=*/framebuffer_info,
            /*encode_callback=*/[](flutter::SurfaceFrame&, flutter::DlCanvas*) { return true; },
            /*submit_callback=*/[](flutter::SurfaceFrame&) { return true; },
            /*frame_size=*/frame_size,
            /*context_result=*/nullptr,
            /*display_list_fallback=*/true);
      });

  static_cast<flutter::ExternalViewEmbedder&>(embedder).CollectView(
      /*view_id=*/kTertiaryFlutterViewId);

  XCTAssertEqual(controller->collectViewCalls_, 1);
  XCTAssertEqual(controller->lastCollectedViewId_, kTertiaryFlutterViewId);
}

@end
